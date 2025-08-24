import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fitconnect/utils/config.dart';

class PaymentService {
  // Generate a Razorpay checkout URL with the provided options
  static String generateRazorpayCheckoutUrl({
    required String amount,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    String? orderId,
    Map<String, dynamic>? notes,
  }) {
    // Convert amount to paise (smallest currency unit)
    final amountInPaise = (double.parse(amount) * 100).toInt().toString();
    
    // Create options for Razorpay checkout
    final Map<String, dynamic> options = {
      'key': AppConfig.razorpayKeyId,
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'prefill': {
        'email': prefillEmail ?? '',
        'contact': prefillContact ?? '',
      },
      'theme': {
        'color': '#6C63FF',
      },
    };
    
    // Add order ID if provided
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }
    
    // Add notes if provided
    if (notes != null) {
      options['notes'] = notes;
    }
    
    // Encode options to base64
    final String encodedOptions = base64Url.encode(utf8.encode(json.encode(options)));
    
    // Generate checkout URL
    return 'https://api.razorpay.com/v1/checkout/embedded?options=$encodedOptions';
  }
  
  // Show Razorpay checkout in a WebView
  static Future<bool> showRazorpayCheckout({
    required BuildContext context,
    required String amount,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
  }) async {
    bool paymentSuccess = false;
    
    // Generate checkout URL
    final String checkoutUrl = generateRazorpayCheckoutUrl(
      amount: amount,
      name: name,
      description: description,
      prefillEmail: prefillEmail,
      prefillContact: prefillContact,
    );
    
    // Create WebView controller
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check for success or failure URLs
            if (request.url.contains('razorpay_payment_id=')) {
              paymentSuccess = true;
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
    
    // Show WebView in a dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Razorpay Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: WebViewWidget(controller: controller),
              ),
            ],
          ),
        ),
      ),
    );
    
    return paymentSuccess;
  }
} 