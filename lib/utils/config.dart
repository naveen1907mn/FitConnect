import 'package:flutter_dotenv/flutter_dotenv.dart';
 
class AppConfig {
  // Razorpay API keys
  static String razorpayKeyId = dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_R98nDyrvpNzYDc';
  static String razorpayKeySecret = dotenv.env['RAZORPAY_KEY_SECRET'] ?? 'gdGEerEYY5Jgbl14sV6VL2il';
} 