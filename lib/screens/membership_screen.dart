import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitconnect/services/payment_service.dart';
import 'package:fitconnect/utils/notification_utils.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isMembershipActive = false;
  
  // Membership plans
  final List<Map<String, dynamic>> _membershipPlans = [
    {
      'title': 'Monthly',
      'price': 999.0,
      'description': '30 days unlimited access',
      'features': [
        'Unlimited gym access',
        'All yoga classes',
        'All zumba classes',
        'Fitness consultation',
      ],
    },
    {
      'title': 'Quarterly',
      'price': 2499.0,
      'description': '90 days unlimited access',
      'features': [
        'Unlimited gym access',
        'All yoga classes',
        'All zumba classes',
        'Fitness consultation',
        'Personalized diet plan',
      ],
      'bestValue': true,
    },
    {
      'title': 'Annual',
      'price': 8999.0,
      'description': '365 days unlimited access',
      'features': [
        'Unlimited gym access',
        'All yoga classes',
        'All zumba classes',
        'Fitness consultation',
        'Personalized diet plan',
        'Monthly progress tracking',
        'Free merchandise',
      ],
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _loadMembershipStatus();
  }
  
  Future<void> _loadMembershipStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _isMembershipActive = userDoc.data()?['membership_active'] ?? false;
          });
        }
      }
    } catch (e) {
      print("Error loading membership status: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _purchaseMembership(Map<String, dynamic> plan) async {
    if (_auth.currentUser == null) {
      NotificationUtils.showNotification(
        context,
        'Please login to purchase a membership',
        isError: true,
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bool paymentSuccessful = await PaymentService.showRazorpayCheckout(
        context: context,
        amount: plan['price'].toString(),
        name: 'FitConnect',
        description: '${plan['title']} Membership',
        prefillEmail: _auth.currentUser?.email,
        updateMembership: true, // This will update membership_active to true
      );
      
      if (paymentSuccessful) {
        setState(() {
          _isMembershipActive = true;
        });
        
        if (!mounted) return;
        NotificationUtils.showNotification(
          context,
          '${plan['title']} membership purchased successfully!',
        );
      }
    } catch (e) {
      print("Error during membership purchase: $e");
      if (!mounted) return;
      NotificationUtils.showNotification(
        context,
        'Error purchasing membership: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isMembershipActive
              ? _buildActiveMembership()
              : _buildMembershipPlans(),
    );
  }
  
  Widget _buildActiveMembership() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Active Membership',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have an active membership with unlimited access to all facilities.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadMembershipStatus,
                  child: const Text('Refresh Status'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMembershipPlans() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose a Membership Plan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ..._membershipPlans.map((plan) => _buildMembershipCard(plan)),
      ],
    );
  }
  
  Widget _buildMembershipCard(Map<String, dynamic> plan) {
    final bool isBestValue = plan['bestValue'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isBestValue ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBestValue
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          if (isBestValue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                'BEST VALUE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${plan['price'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(plan['description']),
                const SizedBox(height: 16),
                const Text(
                  'Features:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  plan['features'].length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(plan['features'][index]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _purchaseMembership(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Purchase'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 