// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _familyCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    // Check if user is already logged in
    final hasSession = await SessionManager.hasSession();
    if (hasSession) {
      final isAdmin = await SessionManager.getIsAdmin();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          isAdmin == true ? '/admin' : '/home',
        );
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _auth.login(
      familyId: _familyCtrl.text,
      password: _passwordCtrl.text,
    );

    setState(() => _loading = false);

    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }

    Navigator.pushReplacementNamed(context, res.isAdmin ? '/admin' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 20),
            TextField(
              controller: _familyCtrl,
              decoration: const InputDecoration(labelText: 'Family ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
