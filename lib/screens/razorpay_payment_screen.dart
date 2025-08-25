import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fitconnect/utils/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RazorpayPaymentScreen extends StatefulWidget {
  final String amount;
  final String name;
  final String description;
  final String? prefillEmail;
  final String? prefillContact;
  final bool updateMembership;

  const RazorpayPaymentScreen({
    Key? key,
    required this.amount,
    required this.name,
    required this.description,
    this.prefillEmail,
    this.prefillContact,
    this.updateMembership = false,
  }) : super(key: key);

  @override
  State<RazorpayPaymentScreen> createState() => _RazorpayPaymentScreenState();
}

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Show fallback dialog directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFallbackPaymentDialog();
    });
  }

  Future<void> _storeTransaction({
    required String paymentId,
    required String orderId,
    required String signature,
    required String status,
    String? errorCode,
    String? errorMessage,
    String? walletName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create a transaction record
        await FirebaseFirestore.instance.collection('transactions').add({
          'user_id': user.uid,
          'user_email': user.email,
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
          'amount': widget.amount,
          'amount_in_paise': (double.parse(widget.amount) * 100).toInt(),
          'description': widget.description,
          'status': status,
          'error_code': errorCode,
          'error_message': errorMessage,
          'wallet_name': walletName,
          'created_at': FieldValue.serverTimestamp(),
          'test_mode': true, // Indicate this is a test transaction
        });
      }
    } catch (e) {
      debugPrint("Error storing transaction: $e");
    }
  }

  Future<void> _updateMembershipStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Calculate membership expiry date (30 days from now)
        final DateTime now = DateTime.now();
        final DateTime expiryDate = now.add(const Duration(days: 30));
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'membership_active': true,
          'membership_updated_at': FieldValue.serverTimestamp(),
          'membership_expiry': Timestamp.fromDate(expiryDate),
          'membership_type': 'premium',
        });
      }
    } catch (e) {
      debugPrint("Error updating membership status: $e");
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
            Text('Session: ${widget.name}'),
            Text('Description: ${widget.description}'),
            Text('Amount: ₹${widget.amount}'),
            const SizedBox(height: 16),
            const Text('This is a test payment. No actual payment will be processed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Store cancelled transaction
              _storeTransaction(
                paymentId: mockPaymentId,
                orderId: 'fallback_cancelled',
                signature: 'fallback',
                status: 'cancelled',
              );
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store successful test transaction
              await _storeTransaction(
                paymentId: mockPaymentId,
                orderId: 'fallback_success',
                signature: 'fallback',
                status: 'success',
              );
              
              // Update membership status if requested
              if (widget.updateMembership) {
                await _updateMembershipStatus();
              }
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
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 