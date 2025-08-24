import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitconnect/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userBookings = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load user profile
      final authService = Provider.of<AuthService>(context, listen: false);
      final profile = await authService.getUserProfile();
      
      // Load user bookings
      if (_auth.currentUser != null) {
        final String userId = _auth.currentUser!.uid;
        final QuerySnapshot snapshot = await _firestore
            .collection('bookings')
            .doc(userId)
            .collection('sessions')
            .orderBy('date', descending: true)
            .get();
        
        final bookings = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'type': data['type'],
            'date': data['date'],
            'time': data['time'],
            'attendance': data['attendance'],
          };
        }).toList();
        
        setState(() {
          _userProfile = profile;
          _userBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }
  
  Widget _buildProfileContent() {
    if (_userProfile == null) {
      return const Center(
        child: Text('Failed to load profile data'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _userProfile!['name'][0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile!['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile!['email'],
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _userProfile!['membership_active']
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userProfile!['membership_active']
                          ? 'Active Membership'
                          : 'Inactive Membership',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Membership upgrade button (if not active)
          if (!_userProfile!['membership_active']) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to membership purchase screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membership purchase coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Recent bookings
          const Text(
            'Recent Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_userBookings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No bookings found'),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userBookings.length > 3 ? 3 : _userBookings.length,
              itemBuilder: (context, index) {
                final booking = _userBookings[index];
                final DateTime bookingDate = (booking['date'] as Timestamp).toDate();
                final bool isAttended = booking['attendance'] ?? false;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSessionColor(booking['type']),
                      child: Text(
                        booking['type'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(booking['type']),
                    subtitle: Text(
                      '${bookingDate.day}/${bookingDate.month}/${bookingDate.year} at ${booking['time']}',
                    ),
                    trailing: Container(
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
                  ),
                );
              },
            ),
          
          if (_userBookings.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full booking history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full booking history coming soon!'),
                    ),
                  );
                },
                child: const Text('View All Bookings'),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Color _getSessionColor(String type) {
    switch (type) {
      case 'Yoga':
        return Colors.purple;
      case 'Gym':
        return Colors.blue;
      case 'Zumba':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 