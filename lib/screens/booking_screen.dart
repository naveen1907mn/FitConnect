import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fitconnect/services/payment_service.dart';
import 'package:fitconnect/utils/notification_utils.dart';
import 'package:fitconnect/screens/auth/login_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  bool _firestoreInitialized = false;
  
  String _selectedType = 'Yoga';
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '06:00 AM';
  bool _isLoading = false;
  
  final List<String> _sessionTypes = ['Yoga', 'Gym', 'Zumba'];
  final List<String> _timeSlots = [
    '06:00 AM', 
    '07:00 AM', 
    '08:00 AM', 
    '09:00 AM', 
    '05:00 PM', 
    '06:00 PM', 
    '07:00 PM'
  ];

  // Session prices in INR
  final Map<String, double> _prices = {
    'Yoga': 299.0,
    'Gym': 399.0,
    'Zumba': 349.0,
  };
  
  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }
  
  Future<void> _initializeFirebase() async {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      
      // Always set to true since we're just getting the instance
      _firestoreInitialized = true;
      print("Firestore initialized successfully");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _bookSession() async {
    // Check if user is logged in
    if (_auth.currentUser == null) {
      // Show dialog to prompt user to login
      if (!mounted) return;
      
      NotificationUtils.showNotificationWithAction(
        context,
        'Please login to book a session',
        'Login',
        () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        isError: true,
      );
      return;
    }
    
    // Check if Firestore is initialized
    if (!_firestoreInitialized) {
      if (!mounted) return;
      NotificationUtils.showNotification(
        context,
        'Database not initialized. Please try again later.',
        isError: true,
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print("Starting booking process...");
      
      // Restore payment functionality
      final double amount = _prices[_selectedType] ?? 299.0;
      final user = _auth.currentUser;
      
      print("Initiating payment with Razorpay...");
      final bool paymentSuccessful = await PaymentService.showRazorpayCheckout(
        context: context,
        amount: amount.toString(),
        name: 'FitConnect',
        description: '$_selectedType Session',
        prefillEmail: user?.email,
        prefillContact: '',
      );
      
      print("Payment result: $paymentSuccessful");
      
      // If payment was successful, create the booking
      if (paymentSuccessful) {
        final String userId = _auth.currentUser!.uid;
        
        print("Creating booking document in Firestore...");
        try {
          // Create a Map with the booking data
          Map<String, dynamic> bookingData = {
            'userId': userId,
            'type': _selectedType,
            'date': Timestamp.fromDate(_selectedDate),
            'time': _selectedTime,
            'attendance': false,
            'created_at': FieldValue.serverTimestamp(),
          };
          
          print("Booking data: $bookingData");
          
          // Use a simpler approach to add the document
          DocumentReference docRef = _firestore.collection('booking').doc();
          await docRef.set(bookingData);
          
          print("Booking created successfully with ID: ${docRef.id}");
          
          if (!mounted) return;
          NotificationUtils.showNotification(
            context,
            'Session booked successfully!',
          );
        } catch (firestoreError) {
          print("Firestore error details: $firestoreError");
          throw firestoreError;
        }
      } else {
        if (!mounted) return;
        NotificationUtils.showNotification(
          context,
          'Payment was cancelled or failed',
          isError: true,
        );
      }
    } catch (e) {
      print("Error during booking: $e");
      if (e.toString().contains('NotInitializedError')) {
        print("Firestore not initialized error detected");
      }
      
      if (!mounted) return;
      NotificationUtils.showNotification(
        context,
        'Error booking session: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Session Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _sessionTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTime,
                  isExpanded: true,
                  items: _timeSlots.map((String time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTime = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Price:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${(_prices[_selectedType] ?? 299.0).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _bookSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Book Now'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Yoga sessions focus on flexibility and mindfulness'),
                    Text('• Gym sessions include full access to equipment'),
                    Text('• Zumba sessions are high-energy dance workouts'),
                    SizedBox(height: 8),
                    Text('• All sessions are 50 minutes long'),
                    Text('• Please arrive 10 minutes before your session'),
                    Text('• Bring your own water bottle and towel'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 