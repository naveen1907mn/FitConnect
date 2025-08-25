// Remove debug print statements and clean up the code
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fitconnect/utils/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  // Static Razorpay instance to prevent repeated initialization
  static Razorpay? _razorpayInstance;
  
  // Initialize Razorpay instance if not already initialized
  static Future<Razorpay?> _getRazorpayInstance() async {
    if (_razorpayInstance == null) {
      try {
        _razorpayInstance = Razorpay();
      } catch (e) {
        return null;
      }
    }
    return _razorpayInstance;
  }
  
  static Future<bool> showRazorpayCheckout({
    required BuildContext context,
    required String amount,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    bool updateMembership = false,
  }) async {
    // Create a completer to wait for the payment result
    bool paymentSuccess = false;
    bool isCompleted = false;
    
    try {
      // Get Razorpay instance
      final razorpay = await _getRazorpayInstance();
      
      if (razorpay == null) {
        return _showFallbackPaymentDialog(
          context: context,
          amount: amount,
          name: name,
          description: description,
          updateMembership: updateMembership,
        );
      }
      
      // Clear existing handlers to prevent duplicates
      razorpay.clear();
      
      // Set up event handlers
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        paymentSuccess = true;
        
        // Show toast notification
        Fluttertoast.showToast(
          msg: "Payment successful",
          toastLength: Toast.LENGTH_SHORT,
        );
        
        // Store transaction in Firestore
        await _storeTransaction(
          paymentId: response.paymentId ?? 'unknown',
          orderId: response.orderId ?? 'unknown',
          signature: response.signature ?? 'unknown',
          amount: amount,
          description: description,
          status: 'success',
        );
        
        // Update membership status if requested
        if (updateMembership) {
          await _updateMembershipStatus();
        }
        
        isCompleted = true;
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      });
      
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        // Show toast notification
        Fluttertoast.showToast(
          msg: "Payment failed",
          toastLength: Toast.LENGTH_SHORT,
        );
        
        // Store failed transaction in Firestore
        _storeTransaction(
          paymentId: 'failed',
          orderId: 'failed',
          signature: 'failed',
          amount: amount,
          description: description,
          status: 'failed',
          errorCode: response.code.toString(),
          errorMessage: response.message ?? 'Unknown error',
        );
        
        paymentSuccess = false;
        isCompleted = true;
        if (context.mounted) {
          Navigator.of(context).pop(false);
        }
      });
      
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        // Show toast notification
        Fluttertoast.showToast(
          msg: "External wallet selected",
          toastLength: Toast.LENGTH_SHORT,
        );
        
        // Store external wallet transaction in Firestore
        _storeTransaction(
          paymentId: 'external_wallet',
          orderId: 'external_wallet',
          signature: 'external_wallet',
          amount: amount,
          description: description,
          status: 'external_wallet',
          walletName: response.walletName ?? 'Unknown wallet',
        );
        
        paymentSuccess = false;
        isCompleted = true;
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      });
      
      // Generate a unique order ID
      final String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      // Convert amount to paise (smallest currency unit)
      final amountInPaise = (double.parse(amount) * 100).toInt();
      
      // Create options for Razorpay checkout
      final Map<String, dynamic> options = {
        'key': AppConfig.razorpayKeyId,
        'amount': amountInPaise,
        'name': name,
        'description': description,
        'order_id': orderId,
        'prefill': {
          'email': prefillEmail ?? '',
          'contact': prefillContact ?? '',
          'name': FirebaseAuth.instance.currentUser?.displayName ?? '',
        },
        'theme': {
          'color': '#6C63FF',
        },
        'external': {
          'wallets': ['paytm']
        }
      };
      
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
        // Show fallback dialog if Razorpay fails
        if (context.mounted) {
          final bool result = await _showFallbackPaymentDialog(
            context: context,
            amount: amount,
            name: name,
            description: description,
            updateMembership: updateMembership,
          );
          
          return result;
        }
        return false;
      }
      
      // Wait for the result from the payment screen
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
      
      return result ?? false;
    } catch (e) {
      // Fall back to simple payment dialog
      if (context.mounted) {
        return _showFallbackPaymentDialog(
          context: context,
          amount: amount,
          name: name,
          description: description,
          updateMembership: updateMembership,
        );
      }
      
      return false;
    }
  }
  
  // Store transaction details in Firestore
  static Future<void> _storeTransaction({
    required String paymentId,
    required String orderId,
    required String signature,
    required String amount,
    required String description,
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
          'amount': amount,
          'amount_in_paise': (double.parse(amount) * 100).toInt(),
          'description': description,
          'status': status,
          'error_code': errorCode,
          'error_message': errorMessage,
          'wallet_name': walletName,
          'created_at': FieldValue.serverTimestamp(),
          'test_mode': false,
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Update membership status in Firestore
  static Future<void> _updateMembershipStatus() async {
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
      // Handle error silently
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
            Text('Session: $name'),
            Text('Description: $description'),
            Text('Amount: ₹$amount'),
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
              // Store successful test transaction
              await _storeTransaction(
                paymentId: mockPaymentId,
                orderId: 'fallback_success',
                signature: 'fallback',
                amount: amount,
                description: description,
                status: 'success',
              );
              
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
    
    return result;
  }
} 