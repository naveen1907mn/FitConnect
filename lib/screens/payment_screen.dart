import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitconnect/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatefulWidget {
  final String sessionType;
  final DateTime sessionDate;
  final String sessionTime;

  const PaymentScreen({
    super.key,
    required this.sessionType,
    required this.sessionDate,
    required this.sessionTime,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  // Session prices in INR
  final Map<String, double> _prices = {
    'Yoga': 299.0,
    'Gym': 399.0,
    'Zumba': 349.0,
  };

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final double amount = _prices[widget.sessionType] ?? 299.0;
      final user = FirebaseAuth.instance.currentUser;
      
      final bool success = await PaymentService.showRazorpayCheckout(
        context: context,
        amount: amount.toString(),
        name: 'FitConnect',
        description: '${widget.sessionType} Session',
        prefillEmail: user?.email,
        prefillContact: '',
      );
      
      if (success && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amount = _prices[widget.sessionType] ?? 299.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
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
            _buildDetailRow('Type', widget.sessionType),
            _buildDetailRow(
              'Date',
              DateFormat('EEE, MMM d, yyyy').format(widget.sessionDate),
            ),
            _buildDetailRow('Time', widget.sessionTime),
            const Divider(height: 32),
            _buildDetailRow(
              'Amount',
              '₹${amount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Pay Now'),
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
                    Text('• This is a test payment using Razorpay test mode'),
                    Text('• No actual payment will be processed'),
                    Text('• Use any card number for testing'),
                    Text('• Use any future expiry date'),
                    Text('• Use any 3-digit CVV'),
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
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
} 