import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fitconnect/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StandaloneRazorpayScreen extends StatefulWidget {
  final String? prefilledAmount;
  final String? sessionType;
  final DateTime? sessionDate;
  final String? sessionTime;
  final bool isForBooking;

  const StandaloneRazorpayScreen({
    super.key,
    this.prefilledAmount,
    this.sessionType,
    this.sessionDate,
    this.sessionTime,
    this.isForBooking = false,
  });

  @override
  State<StandaloneRazorpayScreen> createState() => _StandaloneRazorpayScreenState();
}

class _StandaloneRazorpayScreenState extends State<StandaloneRazorpayScreen> {
  late Razorpay _razorpay;
  TextEditingController amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Initialize amount if provided
    if (widget.prefilledAmount != null) {
      amountController.text = widget.prefilledAmount!;
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isLoading = true;
    });

    Fluttertoast.showToast(
      msg: "SUCCESS: ${response.paymentId}",
      toastLength: Toast.LENGTH_SHORT,
    );

    // Store transaction in Firestore
    await _storeTransaction(
      paymentId: response.paymentId ?? 'unknown',
      orderId: response.orderId ?? 'unknown',
      signature: response.signature ?? 'unknown',
      status: 'success',
    );

    // Create booking if this is for a booking
    if (widget.isForBooking && widget.sessionType != null && 
        widget.sessionDate != null && widget.sessionTime != null) {
      await _createBooking();
    }

    setState(() {
      _isLoading = false;
    });

    // Return success result
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "ERROR: ${response.code} - ${response.message}",
      toastLength: Toast.LENGTH_SHORT,
    );

    // Return failure result
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "EXTERNAL_WALLET: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );

    // Return success for external wallet
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _storeTransaction({
    required String paymentId,
    required String orderId,
    required String signature,
    required String status,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fix the number parsing issue
        double amountValue = double.tryParse(amountController.text) ?? 0.0;
        int amountInPaise = (amountValue * 100).toInt();
        
        // Create a transaction record
        await FirebaseFirestore.instance.collection('transactions').add({
          'user_id': user.uid,
          'user_email': user.email,
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
          'amount': amountController.text,
          'amount_in_paise': amountInPaise,
          'description': widget.sessionType != null 
              ? '${widget.sessionType} Session' 
              : 'Test Payment',
          'status': status,
          'created_at': FieldValue.serverTimestamp(),
          'test_mode': true, // Indicate this is a test transaction
        });
      }
    } catch (e) {
      debugPrint("Error storing transaction: $e");
    }
  }

  Future<void> _createBooking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && widget.sessionType != null && 
          widget.sessionDate != null && widget.sessionTime != null) {
        
        // Create booking data
        Map<String, dynamic> bookingData = {
          'userId': user.uid,
          'type': widget.sessionType,
          'date': Timestamp.fromDate(widget.sessionDate!),
          'time': widget.sessionTime,
          'attendance': false,
          'created_at': FieldValue.serverTimestamp(),
        };

        debugPrint("Creating booking document in Firestore...");
        debugPrint("Booking data: $bookingData");

        // Add booking to Firestore
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('booking')
            .add(bookingData);

        debugPrint("Booking created successfully with ID: ${docRef.id}");
      }
    } catch (e) {
      debugPrint("Error creating booking: $e");
    }
  }

  void openCheckout() {
    // Fix the number parsing issue
    double amountValue = double.tryParse(amountController.text) ?? 0.0;
    int amount = (amountValue * 100).toInt(); // Convert to paise
    
    var options = {
      'key': Constants.razorpayKeyId,
      'amount': amount,
      'name': 'FitConnect',
      'description': widget.sessionType != null 
          ? '${widget.sessionType} Session' 
          : 'Test Payment',
      'prefill': {
        'contact': '8888888888',
        'email': FirebaseAuth.instance.currentUser?.email ?? 'test@example.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      
      // Show fallback dialog if Razorpay fails
      _showFallbackPaymentDialog();
    }
  }
  
  void _showFallbackPaymentDialog() async {
    // Generate a mock payment ID for the test transaction
    final String mockPaymentId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    
    final bool result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session: ${widget.sessionType ?? "Test Payment"}'),
            Text('Amount: ₹${amountController.text}'),
            if (widget.sessionDate != null)
              Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(widget.sessionDate!)}'),
            if (widget.sessionTime != null)
              Text('Time: ${widget.sessionTime}'),
            const SizedBox(height: 16),
            const Text('This is a test payment. No actual payment will be processed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              
              // Store successful test transaction
              await _storeTransaction(
                paymentId: mockPaymentId,
                orderId: 'fallback_success',
                signature: 'fallback',
                status: 'success',
              );
              
              // Create booking if this is for a booking
              if (widget.isForBooking && widget.sessionType != null && 
                  widget.sessionDate != null && widget.sessionTime != null) {
                await _createBooking();
              }
              
              setState(() {
                _isLoading = false;
              });
              
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    ) ?? false;
    
    // Return the result
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isForBooking ? 'Complete Payment' : 'Payment'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Type', widget.sessionType ?? 'Test Payment'),
                if (widget.sessionDate != null)
                  _buildDetailRow(
                    'Date',
                    DateFormat('EEE, MMM d, yyyy').format(widget.sessionDate!),
                  ),
                if (widget.sessionTime != null)
                  _buildDetailRow('Time', widget.sessionTime!),
                const Divider(height: 32),
                _buildDetailRow(
                  'Amount',
                  '₹${amountController.text}',
                  isHighlighted: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (amountController.text.isNotEmpty) {
                        openCheckout();
                      } else {
                        Fluttertoast.showToast(
                          msg: "Please enter an amount",
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pay Now'),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Payment Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This is a secure payment processed through Razorpay. Your payment details are encrypted and secure.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 