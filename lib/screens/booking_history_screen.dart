import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _bookings = [];
        });
        return;
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('booking')
          .where('userId', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      final List<Map<String, dynamic>> bookings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    if (date is Timestamp) {
      return DateFormat('EEE, MMM d, yyyy').format(date.toDate());
    }
    
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(
                  child: Text(
                    'No bookings found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final bool hasAttended = booking['attendance'] == true;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  booking['type'] ?? 'Unknown Session',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    hasAttended ? 'Attended' : 'Not Attended',
                                    style: TextStyle(
                                      color: hasAttended ? Colors.white : Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: hasAttended
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(_formatDate(booking['date'])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(booking['time'] ?? 'N/A'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!hasAttended)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to QR code screen
                                    // This will be implemented later
                                  },
                                  icon: const Icon(Icons.qr_code),
                                  label: const Text('Show QR Code'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBookings,
        child: const Icon(Icons.refresh),
      ),
    );
  }
} 