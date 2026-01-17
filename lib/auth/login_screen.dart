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
  final _auth = AuthService();
  final _passwordCtrl = TextEditingController();
  
  // MID Parts
  final _midFamilyCtrl = TextEditingController();
  final _midSubFamilyCtrl = TextEditingController();
  final _midRandomCtrl = TextEditingController();

  // Admin Mode
  final _adminIdCtrl = TextEditingController();
  bool _isAdminMode = false;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final hasSession = await SessionManager.hasSession();
    if (hasSession) {
      final isAdmin = await SessionManager.getIsAdmin();
      final role = await SessionManager.getRole();
      if (mounted) {
        // Redirect based on role/admin status
        if (isAdmin == true || role == 'manager') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    String loginId = '';
    if (_isAdminMode) {
      loginId = _adminIdCtrl.text.trim();
    } else {
      // Format: F-XXX-SXX-XXX
      final f = _midFamilyCtrl.text.trim().toUpperCase();
      final s = _midSubFamilyCtrl.text.trim().toUpperCase();
      final r = _midRandomCtrl.text.trim();
      if (f.isEmpty || s.isEmpty || r.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Complete MID required (F-XXX-SXX-XXX)';
        });
        return;
      }
      loginId = 'F-$f-S$s-$r';
    }

    final res = await _auth.login(
      loginId: loginId,
      password: _passwordCtrl.text,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (!res.success) {
        setState(() => _error = res.message);
        return;
      }
      
      // Navigate based on role/admin status
      if (res.isAdmin || res.role == 'manager') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              Icon(Icons.lock_person_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                _isAdminMode ? 'Admin Portal' : 'Community Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              if (!_isAdminMode) ...[
                // MID INPUT (F-XXX-SXX-XXX)
                const Text('Enter Member ID (MID)', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFixedLabel('F-'),
                      _buildMidInput(_midFamilyCtrl, 3, 'XXX'),
                      _buildFixedLabel('-S'),
                      _buildMidInput(_midSubFamilyCtrl, 2, 'XX'),
                      _buildFixedLabel('-'),
                      _buildMidInput(_midRandomCtrl, 3, 'XXX'),
                    ],
                  ),
                ),
              ] else ...[
                // ADMIN ID INPUT (ADM-83288)
                TextField(
                  controller: _adminIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Admin Login ID (ADM-XXXXXXX)',
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              
              // PASSWORD INPUT
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.key_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _login,
                        child: Text(_isAdminMode ? 'CONTINUE AS ADMIN' : 'LOGIN'),
                      ),
                    ),
              
              const SizedBox(height: 48),

              // Hidden Developer Button
              GestureDetector(
                onTap: () {
                  setState(() => _isAdminMode = !_isAdminMode);
                },
                child: Text(
                  'developer',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMidInput(TextEditingController ctrl, int length, String hint) {
    return Container(
      width: length == 2 ? 45 : 60,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextField(
        controller: ctrl,
        maxLength: length,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
        ),
        onChanged: (v) {
          if (v.length == length) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
