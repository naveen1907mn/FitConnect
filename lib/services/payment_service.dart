import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fitconnect/utils/config.dart';
import 'package:fitconnect/utils/notification_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PaymentService {
  static Future<bool> showRazorpayCheckout({
    required BuildContext context,
    required String amount,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    bool updateMembership = false,
  }) async {
    print("Starting Razorpay payment process...");
    
    // Create a completer to wait for the payment result
    final completer = Completer<bool>();
    bool paymentSuccess = false;
    bool isCompleted = false;
    
    try {
      print("Creating Razorpay instance...");
      final Razorpay razorpay = Razorpay();
      
      print("Setting up Razorpay handlers...");
      // Set up event handlers
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        print("Payment successful! Payment ID: ${response.paymentId}");
        paymentSuccess = true;
        
        // Update membership status if requested
        if (updateMembership) {
          await _updateMembershipStatus();
        }
        
        isCompleted = true;
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });
      
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        print("Payment failed! Error: ${response.code} - ${response.message}");
        paymentSuccess = false;
        isCompleted = true;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        print("External wallet selected: ${response.walletName}");
        paymentSuccess = false;
        isCompleted = true;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // Convert amount to paise (smallest currency unit)
      final amountInPaise = (double.parse(amount) * 100).toInt();
      
      // Create options for Razorpay checkout
      final Map<String, dynamic> options = {
        'key': AppConfig.razorpayKeyId,
        'amount': amountInPaise,
        'name': 'FitConnect',
        'description': description,
        'prefill': {
          'email': prefillEmail ?? '',
          'contact': prefillContact ?? '',
        },
        'theme': {
          'color': '#6C63FF',
        },
      };
      
      print("Opening Razorpay with options: $options");
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Opening payment gateway..."),
                ],
              ),
            ),
          );
        },
      );
      
      // Wait a moment to show the loading dialog
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      try {
        // Open Razorpay checkout
        razorpay.open(options);
      } catch (e) {
        print("Error opening Razorpay: $e");
        // Fall back to dialog approach if Razorpay fails to open
        if (context.mounted) {
          Navigator.of(context).pop(); // Close any open dialogs
          return _showFallbackPaymentDialog(
            context: context,
            amount: amount,
            name: name,
            description: description,
            updateMembership: updateMembership,
          );
        }
      }
      
      // Set a timeout for the payment process
      Timer(const Duration(minutes: 2), () {
        if (!isCompleted) {
          print("Payment timed out after 2 minutes");
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      });
      
      // Wait for the payment result
      print("Waiting for payment completion...");
      paymentSuccess = await completer.future;
      
      // Cleanup
      razorpay.clear();
      print("Razorpay instance cleared");
      
      return paymentSuccess;
    } catch (e) {
      print("Error during Razorpay payment: $e");
      
      // Show error dialog
      if (context.mounted) {
        NotificationUtils.showNotification(
          context,
          "Payment error: ${e.toString()}",
          isError: true,
        );
      }
      
      // If the completer hasn't completed yet, complete it with false
      if (!isCompleted && !completer.isCompleted) {
        completer.complete(false);
      }
      
      // Fall back to dialog approach if Razorpay fails
      return _showFallbackPaymentDialog(
        context: context,
        amount: amount,
        name: name,
        description: description,
        updateMembership: updateMembership,
      );
    }
  }
  
  // Update membership status in Firestore
  static Future<void> _updateMembershipStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'membership_active': true,
          'membership_updated_at': FieldValue.serverTimestamp(),
        });
        print("Membership status updated successfully");
      }
    } catch (e) {
      print("Error updating membership status: $e");
    }
  }
  
  // Fallback payment dialog when Razorpay fails to initialize
  static Future<bool> _showFallbackPaymentDialog({
    required BuildContext context,
    required String amount,
    required String name,
    required String description,
    bool updateMembership = false,
  }) async {
    print("Showing fallback payment dialog");
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
            const Text('Razorpay could not be initialized.'),
            const SizedBox(height: 8),
            const Text('This is a test payment. No actual payment will be processed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update membership status if requested
              if (updateMembership) {
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
    
    print("Fallback payment result: $result");
    return result;
  }
} 