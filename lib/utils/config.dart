import 'package:fitconnect/utils/constants.dart';

class AppConfig {
  // Razorpay API keys from Constants
  static String razorpayKeyId = Constants.razorpayKeyId;
  static String razorpayKeySecret = Constants.razorpayKeySecret;
  
  // App settings
  static bool useTestPayments = false;
  
  // Initialize config
  static void initializeConfig() {
    // Configuration initialization code goes here
  }
} 