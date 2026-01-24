// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
import 'screens/admin/notification_center_screen.dart';
import 'screens/user/digital_id_screen.dart';
import 'models/member_model.dart';
import 'screens/user/settings_screen.dart';
import 'screens/user/member_detail_screen.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/user/enhanced_user_dashboard.dart';
import 'screens/user/user_notification_screen.dart';
import 'screens/user/user_calendar_screen.dart';
import 'screens/user/user_search_tab.dart';
import 'services/session_manager.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final themeService = ThemeService();
  await themeService.initialize();

  final languageService = LanguageService();
  await languageService.initialize();

  // Initialize FCM (non-blocking - don't let it prevent app startup)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM in the background without blocking app startup
  FcmService.initialize().catchError((error) {
    // Silently handle FCM initialization errors
    // The app will still work without push notifications
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeService),
        ChangeNotifierProvider(create: (_) => languageService),
      ],
      child: const MyApp(),
    ),
  );
}

/// Initial routing widget that checks session and redirects to appropriate screen
class InitialRoute extends StatefulWidget {
  const InitialRoute({super.key});

  @override
  State<InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRoute> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Check for existing session
    final hasSession = await SessionManager.hasSession();
    final isAdmin = await SessionManager.getIsAdmin();
    await SessionManager.getRole();

    if (mounted) {
      // Navigate based on role/admin status
      if (hasSession && isAdmin == true) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (hasSession) {
        // Manager also goes here now
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a minimal loading screen while checking session
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final languageService = Provider.of<LanguageService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ramanagara Patidar Samaj',
      theme: themeService.getTheme(),
      locale: languageService.locale,
      supportedLocales: const [Locale('en'), Locale('gu')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final scale = themeService.textScale;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      // Start with initial route - it will check session and redirect
      home: const InitialRoute(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminDashboard(),
        '/admin/families': (_) => const FamilyListScreen(),
        '/admin/groups': (_) => const GroupManagementScreen(),
        '/admin/events': (_) => const EventManagementScreen(),
        '/admin/analytics': (_) => const AnalyticsDashboard(),
        '/admin/system-health': (_) => const SystemHealthScreen(),
        '/admin/notifications': (_) => const NotificationCenterScreen(),
        '/home': (_) => const EnhancedUserDashboard(),
        '/user/settings': (_) => const SettingsScreen(),
        '/user/profile': (_) => const UserProfileScreen(),
        '/user/notifications': (_) => const UserNotificationScreen(),
        '/user/member-detail': (_) =>
            const MemberDetailScreen(memberId: '', familyDocId: null),
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
              subFamilyDocId:
                  args['subFamilyDocId'], // NEW: Pass subFamilyDocId
            ),
          );
        }
        if (settings.name == '/user/digital-id') {
          final args = settings.arguments as MemberModel;
          return MaterialPageRoute(
            builder: (_) => DigitalIdScreen(member: args),
          );
        }
        // Fallback for any unhandled route - go to login
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      },
    );
  }
}
