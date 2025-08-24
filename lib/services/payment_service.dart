import 'package:flutter/material.dart';
import 'package:fitconnect/utils/config.dart';

class PaymentService {
  // Show a simple payment dialog instead of WebView
  static Future<bool> showRazorpayCheckout({
    required BuildContext context,
    required String amount,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
  }) async {
    // Show a simple dialog instead of WebView
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

    return result;
  }
} 