import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reader_hub_app/UI/Authentication/LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _signOut() async {
    /**
   * تقوم هذه الدالة بتسجيل خروج المستخدم الحالي
   * ثم تعيد توجيهه إلى شاشة تسجيل الدخول.
   */

    // Sign out the user from FirebaseAuth
    await FirebaseAuth.instance.signOut();

    // Navigate to LoginScreen after sign out
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  String _formatTimestamp(Timestamp timestamp) {
    /**
   * تقوم هذه الدالة بتحويل الطابع الزمني
   * إلى نص منسق لعرضه بشكل مفهوم للمستخدم.
   */

    // Convert timestamp to DateTime
    final date = timestamp.toDate();

    // Format the date into a readable string
    return DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData.data()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Profile',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileItem('First Name', user['firstName']),
          _buildProfileItem('Last Name', user['lastName']),
          _buildProfileItem('Email', user['email']),
          _buildProfileItem('Phone', user['phone']),
          _buildProfileItem('Role', user['role']),
          _buildProfileItem('Joined Date', _formatTimestamp(user['createdAt'])),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
