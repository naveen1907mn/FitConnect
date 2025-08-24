import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  bool _isProcessing = false;
  String _scanResult = '';
  List<Map<String, dynamic>> _userBookings = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserBookings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserBookings() async {
    if (_auth.currentUser == null) return;
    
    try {
      final String userId = _auth.currentUser!.uid;
      final QuerySnapshot snapshot = await _firestore
          .collection('booking')
          .where('userId', isEqualTo: userId)
          .where('attendance', isEqualTo: false)
          .get();
      
      final bookings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'type': data['type'] ?? 'Unknown',
          'date': data['date'],
          'time': data['time'] ?? 'N/A',
          'attendance': data['attendance'] ?? false,
        };
      }).toList();
      
      setState(() {
        _userBookings = bookings;
      });
      
      print("Loaded ${bookings.length} bookings");
    } catch (e) {
      print("Error loading bookings: $e");
    }
  }
  
  Future<void> _processQRScan(String scanData) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _scanResult = '';
    });
    
    try {
      // Parse the QR data
      final Map<String, dynamic> qrData = jsonDecode(scanData);
      
      if (qrData.containsKey('bookingId')) {
        // Mark attendance in Firestore
        await _firestore
            .collection('booking')
            .doc(qrData['bookingId'])
            .update({
          'attendance': true,
          'attended_at': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _scanResult = 'Attendance marked successfully!';
        });
        
        // Refresh the bookings list
        _loadUserBookings();
      } else {
        setState(() {
          _scanResult = 'Invalid QR code format';
        });
      }
    } catch (e) {
      setState(() {
        _scanResult = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
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
        title: const Text('QR Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My QR Codes'),
            Tab(text: 'Scan QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateQRTab(),
          _buildScanQRTab(),
        ],
      ),
    );
  }
  
  Widget _buildGenerateQRTab() {
    if (_userBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No upcoming bookings found.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserBookings,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadUserBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userBookings.length,
        itemBuilder: (context, index) {
          final booking = _userBookings[index];
          final bool isAttended = booking['attendance'] ?? false;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['type'] ?? 'Unknown Session',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(booking['date'])} at ${booking['time']}',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAttended ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isAttended ? 'Attended' : 'Not Attended',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: QrImageView(
                        data: jsonEncode({
                          'bookingId': booking['id'],
                          'type': booking['type'],
                        }),
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Show this QR code to mark your attendance',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildScanQRTab() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
                _processQRScan(barcodes[0].rawValue!);
              }
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.black12,
          child: Column(
            children: [
              if (_isProcessing)
                const CircularProgressIndicator()
              else if (_scanResult.isNotEmpty)
                Text(
                  _scanResult,
                  style: TextStyle(
                    color: _scanResult.contains('Error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!_isProcessing && _scanResult.isEmpty)
                const Text('Scan a QR code to mark attendance'),
            ],
          ),
        ),
      ],
    );
  }
} 