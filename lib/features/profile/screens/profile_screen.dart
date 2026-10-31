import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import 'notification_screen.dart';
import 'security_screen.dart';
import 'support_screen.dart';

import 'package:g_shipping/shared/widgets/animated_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'user@gshipping.com';
    final String displayName = user?.displayName ?? 'Người dùng GShipping';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Phần Avatar và Tên
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Phần Menu cài đặt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cài đặt tài khoản',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileItem(
                    icon: Icons.person_outline,
                    title: 'Chỉnh sửa thông tin',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Icons.notifications_none,
                    title: 'Thông báo',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Icons.security,
                    title: 'Bảo mật & Mật khẩu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecurityScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileItem(
                    icon: Icons.help_outline,
                    title: 'Trung tâm hỗ trợ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Phần Thông tin ứng dụng
            Center(
              child: Column(
                children: [
                  Text(
                    'GShipping v1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Nút Đăng xuất
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF2563EB)),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          onTap: null, // Handle by AnimatedCard
        ),
      ),
    );
  }
}
