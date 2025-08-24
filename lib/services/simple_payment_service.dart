import 'package:flutter/material.dart';

class SimplePaymentService {
  static Future<bool> showPaymentDialog({
    required BuildContext context,
    required String amount,
    required String name,
    required String description,
  }) async {
    print("Showing simple payment dialog");
    final bool result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session: $name'),
            Text('Description: $description'),
            Text('Amount: ₹$amount'),
            const SizedBox(height: 16),
            const Text('This is a test payment. No actual payment will be processed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    ) ?? false;
    
    print("Payment dialog result: $result");
    return result;
  }
} 