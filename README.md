FitConnect

A Flutter + Firebase fitness app for authentication, session booking, QR attendance, and payment gateway integration.

Getting Started

This project was built as part of the Code-X-Novas Flutter + Firebase Developer Assignment.

Features Implemented

🔑 Firebase Authentication (Email/Password)

👤 User Profile stored in Firestore

📊 Dashboard with profile data + progress indicator

📝 Session Booking (Yoga, Gym, Zumba) saved in Firestore

📱 QR Attendance (Generate + Scan QR for bookings)

💳 Razorpay Payment Integration (test mode)

Features Skipped (Optional)

Push Notifications (FCM)

Referral System

Cafeteria Ordering System

Google Fit / Apple Health API sync

Setup

Clone the repo

git clone https://github.com/your-username/fitconnect_flutter_firebase.git
cd fitconnect_flutter_firebase


Install dependencies

flutter pub get


Setup Firebase

Create Firebase project & enable Authentication + Firestore.

Add google-services.json (Android) in android/app/.

Add GoogleService-Info.plist (iOS) in ios/Runner/.

Run the app

flutter run


Build APK

flutter build apk --release

Firestore Structure
users/{uid}:
  name, email, membership_active, referral_code(optional)

bookings/{uid}/sessions/{sessionId}:
  type, date, attendance

Author

👨‍💻 Naveen Mayandi
Flutter + Firebase Developer