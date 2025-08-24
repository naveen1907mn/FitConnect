# FitConnect - Fitness Session Booking App

A Flutter + Firebase application for booking fitness sessions, tracking attendance with QR codes, and managing user profiles.

## Features Implemented

### Phase 1 (Core Features)

1. **Authentication**
   - Email/password signup & login
   - User profiles stored in Firestore

2. **Dashboard**
   - Profile data display
   - Membership status indicator
   - Quick action buttons for booking and QR scanning

3. **Session Booking**
   - Book Yoga, Gym, or Zumba sessions
   - Date and time slot selection
   - Different pricing for each session type
   - Bookings stored in Firestore

4. **QR Attendance**
   - QR code generation for each booking
   - Scanner to mark attendance
   - Attendance status tracking in Firestore

5. **Payment Integration**
   - Razorpay payment gateway integration
   - On successful payment, updates membership_active status in Firestore
   - Multiple membership plans with different pricing
   - Fallback to dialog-based approach if Razorpay initialization fails

### Phase 2 (Bonus Features)

- Booking history screen to view past and upcoming sessions
- Membership management screen with different plans

## Setup Instructions

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Firebase account
- Razorpay account (for payment gateway)

### Firebase Setup
1. Create a new Firebase project
2. Enable Email/Password Authentication
3. Create Firestore Database
4. Add Android app to your Firebase project
5. Download `google-services.json` and place it in the `android/app` directory

### Environment Setup
1. Create a `.env` file in the root directory with:
```
RAZORPAY_KEY_ID=rzp_test_R98nDyrvpNzYDc
RAZORPAY_KEY_SECRET=gdGEerEYY5Jgbl14sV6VL2il
```

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/fitconnect.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Firestore Structure

- **users**: User profiles with name, email, and membership status
  - Fields: name, email, membership_active, membership_updated_at

- **booking**: Session bookings with type, date, time, and attendance status
  - Fields: userId, type, date, time, attendance, created_at

## Testing

1. Sign up with email and password
2. Book a session by selecting type, date, and time
3. Complete the payment process
4. View your booking in the booking history
5. Use the QR code to mark attendance
6. Purchase a membership plan to update your membership status

## Testing Razorpay Integration

For testing the Razorpay payment gateway:
- Use card number: 4111 1111 1111 1111
- Any future expiry date
- Any CVV (e.g., 123)
- Any name

## Technologies Used

- Flutter for UI
- Firebase Authentication for user management
- Firestore for database
- QR Flutter for QR code generation
- Mobile Scanner for QR scanning
- Razorpay Flutter plugin for payment gateway