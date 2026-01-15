// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth/login_screen.dart';
// Updated imports to use lib/screens/admin/
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/family_list_screen.dart';
import 'screens/admin/member_list_screen.dart';
import 'screens/admin/group_management_screen.dart';
import 'screens/admin/event_management_screen.dart';
import 'screens/admin/analytics_dashboard.dart';
import 'screens/admin/system_health_screen.dart';
import 'user/user_dashboard.dart';
import 'screens/user/settings_screen.dart';
import 'screens/user/member_detail_screen.dart';
import 'services/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Community App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // Always start from login - the login screen will check session and redirect
      home: const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminDashboard(),
        '/admin/families': (_) => const FamilyListScreen(),
        '/admin/groups': (_) => const GroupManagementScreen(),
        '/admin/events': (_) => const EventManagementScreen(),
        '/admin/analytics': (_) => const AnalyticsDashboard(),
        '/admin/system-health': (_) => const SystemHealthScreen(),
        '/home': (_) => const UserDashboard(),
        '/user/settings': (_) => const SettingsScreen(),
        '/user/member-detail': (_) => const MemberDetailScreen(memberId: '', familyDocId: null),
      },
      onGenerateRoute: (settings) {
        // Handle admin members route with arguments
        if (settings.name == '/admin/members') {
          if (settings.arguments == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('Error: Missing arguments for member list'),
                ),
              ),
            );
          }
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => MemberListScreen(
              familyDocId: args['familyDocId'],
              familyName: args['familyName'],
              subFamilyDocId: args['subFamilyDocId'], // NEW: Pass subFamilyDocId
            ),
          );
        }
        // Fallback for any unhandled route - go to login
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      },
    );
  }
}
