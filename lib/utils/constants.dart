class Constants {
  // Razorpay API keys - replace with your own keys in production
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
  static const String razorpayKeySecret = 'YOUR_RAZORPAY_KEY_SECRET';
  
  // App constants
  static const String appName = 'FitConnect';
  static const String appVersion = '1.0.0';
  
  // Session types
  static const List<String> sessionTypes = ['Yoga', 'Gym', 'Zumba'];
  
  // Session prices
  static const Map<String, double> sessionPrices = {
    'Yoga': 299.0,
    'Gym': 399.0,
    'Zumba': 349.0,
  };
} 