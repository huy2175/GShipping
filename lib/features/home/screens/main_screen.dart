import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../../contacts/screens/contacts_screen.dart';
import '../../shifts/screens/shifts_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../shared/widgets/custom_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ContactsScreen(),
    const ShiftsScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(icon: Icons.map, label: 'Bản đồ'),
    BottomNavItem(icon: Icons.people, label: 'Khách hàng'),
    BottomNavItem(icon: Icons.calendar_month, label: 'Ca làm việc'),
    BottomNavItem(icon: Icons.person, label: 'Cá nhân'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
