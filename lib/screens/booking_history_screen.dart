import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _transactions = [];
  
  late TabController _tabController;

  // Add a state variable to track index errors
  bool _hasIndexError = false;
  String _indexErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadBookings(),
      _loadTransactions(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  // Update the _loadBookings method to work without composite indexes
  Future<void> _loadBookings() async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        debugPrint('No user ID available for loading bookings');
        setState(() {
          _bookings = [];
        });
        return;
      }

      debugPrint('Loading bookings for user: $userId');
      
      try {
        // Simplified query without orderBy to avoid requiring composite index
        final QuerySnapshot snapshot = await _firestore
            .collection('booking')
            .where('userId', isEqualTo: userId)
            .get();

        debugPrint('Found ${snapshot.docs.length} bookings');
        
        final List<Map<String, dynamic>> bookings = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        
        // Sort the bookings in memory instead of in the query
        bookings.sort((a, b) {
          final Timestamp? timestampA = a['created_at'] as Timestamp?;
          final Timestamp? timestampB = b['created_at'] as Timestamp?;
          
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          
          return timestampB.compareTo(timestampA); // Descending order
        });

        setState(() {
          _bookings = bookings;
          _hasIndexError = false;
          _indexErrorMessage = '';
        });
      } catch (e) {
        debugPrint('Error loading bookings: $e');
        if (e.toString().contains('failed-precondition') && 
            e.toString().contains('requires an index')) {
          setState(() {
            _hasIndexError = true;
            _indexErrorMessage = 'Firestore index is being built. Please try again in a few minutes.';
          });
        }
        throw e;
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }
  
  // Update the _loadTransactions method to work without composite indexes
  Future<void> _loadTransactions() async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        debugPrint('No user ID available for loading transactions');
        setState(() {
          _transactions = [];
        });
        return;
      }

      debugPrint('Loading transactions for user: $userId');
      
      try {
        // Simplified query without orderBy to avoid requiring composite index
        final QuerySnapshot snapshot = await _firestore
            .collection('transactions')
            .where('user_id', isEqualTo: userId)
            .get();

        debugPrint('Found ${snapshot.docs.length} transactions');
        
        final List<Map<String, dynamic>> transactions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        
        // Sort the transactions in memory instead of in the query
        transactions.sort((a, b) {
          final Timestamp? timestampA = a['created_at'] as Timestamp?;
          final Timestamp? timestampB = b['created_at'] as Timestamp?;
          
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          
          return timestampB.compareTo(timestampA); // Descending order
        });

        setState(() {
          _transactions = transactions;
          _hasIndexError = false;
          _indexErrorMessage = '';
        });
      } catch (e) {
        debugPrint('Error loading transactions: $e');
        if (e.toString().contains('failed-precondition') && 
            e.toString().contains('requires an index')) {
          setState(() {
            _hasIndexError = true;
            _indexErrorMessage = 'Firestore index is being built. Please try again in a few minutes.';
          });
        }
        throw e;
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    if (date is Timestamp) {
      return DateFormat('EEE, MMM d, yyyy').format(date.toDate());
    }
    
    return 'N/A';
  }
  
  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy - h:mm a').format(date.toDate());
    }
    
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasIndexError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Database Index Required',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _indexErrorMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsTab(),
                    _buildPaymentsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Center(
        child: Text(
          'No bookings found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
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
                        // Show a simple QR code dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Booking QR Code'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code,
                                  size: 120,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Booking ID: ${booking['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Session: ${booking['type'] ?? 'N/A'}'),
                                Text('Date: ${_formatDate(booking['date'])}'),
                                Text('Time: ${booking['time'] ?? 'N/A'}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
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
    );
  }
  
  Widget _buildPaymentsTab() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No payment history found',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final bool isSuccess = transaction['status'] == 'success';
        
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
                    Expanded(
                      child: Text(
                        transaction['description'] ?? 'Payment',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: Text(
                        isSuccess ? 'Success' : transaction['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          color: isSuccess ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isSuccess
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16),
                    const SizedBox(width: 8),
                    Text('₹${transaction['amount'] ?? 'N/A'}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(_formatDateTime(transaction['created_at'])),
                  ],
                ),
                if (transaction['payment_id'] != null && 
                    transaction['payment_id'] != 'failed' && 
                    transaction['payment_id'] != 'error' &&
                    transaction['payment_id'] != 'timeout') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ID: ${transaction['payment_id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
} 