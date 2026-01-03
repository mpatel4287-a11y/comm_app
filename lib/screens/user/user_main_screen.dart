// lib/screens/user/user_main_screen.dart

import 'package:flutter/material.dart';
import 'user_home_screen.dart';
import 'user_explore_screen.dart';
import 'user_calendar_screen.dart';
import 'user_profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UserHomeScreen(),
    const UserExploreScreen(),
    const UserCalendarScreen(),
    const UserProfileScreen(),
  ];

  final List<String> _titles = ['Home', 'Explore', 'Calendar', 'Profile'];

  final List<IconData> _icons = [
    Icons.home,
    Icons.search,
    Icons.calendar_month,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: List.generate(
          _titles.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            label: _titles[index],
            selectedIcon: Icon(_icons[index], color: Colors.blue.shade900),
          ),
        ),
      ),
    );
  }
}
