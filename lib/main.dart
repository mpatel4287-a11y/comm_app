import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/family_list_screen.dart';
import 'admin/member_list_screen.dart';
import 'user/user_dashboard.dart';
import 'screens/admin/group_management_screen.dart';
import 'screens/admin/event_management_screen.dart';
import 'screens/admin/analytics_dashboard.dart';
import 'screens/admin/system_health_screen.dart';
import 'screens/user/settings_screen.dart';
import 'screens/user/member_detail_screen.dart';

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

      // ✅ ALWAYS START FROM LOGIN
      initialRoute: '/login',

      routes: {
        '/login': (_) => const LoginScreen(),

        // ADMIN
        '/admin': (_) => const AdminDashboard(),
        '/admin/families': (_) => const FamilyListScreen(),
        '/admin/groups': (_) => const GroupManagementScreen(),
        '/admin/events': (_) => const EventManagementScreen(),
        '/admin/analytics': (_) => const AnalyticsDashboard(),
        '/admin/system-health': (_) => const SystemHealthScreen(),

        // USER
        '/home': (_) => const UserDashboard(),
        '/user/settings': (_) => const SettingsScreen(),
        '/user/member-detail': (_) => const MemberDetailScreen(memberId: ''),
      },

      // ✅ MEMBER SCREEN WITH ARGUMENTS
      onGenerateRoute: (settings) {
        if (settings.name == '/admin/members') {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (_) =>
                MemberListScreen(args['familyDocId'], args['familyName']),
          );
        }
        return null;
      },
    );
  }
}
