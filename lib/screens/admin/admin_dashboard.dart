// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/session_manager.dart';
import '../../services/theme_service.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await SessionManager.getRole();
    setState(() => _role = role);
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AuthService().logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _role == 'manager';

    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isManager ? 'Manager Portal' : 'Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Family & Members'),
            const SizedBox(height: 12),
            if (!isManager)
              _buildDashboardCard(
                context,
                icon: Icons.family_restroom,
                title: 'Families',
                subtitle: 'Manage family records',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/admin/families'),
              ),
            if (!isManager) const SizedBox(height: 12),
            _buildDashboardCard(
              context,
              icon: Icons.people,
              title: 'Members',
              subtitle: 'Manage member records',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/admin/families'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Organization'),
            const SizedBox(height: 12),
            _buildDashboardCard(
              context,
              icon: Icons.groups,
              title: 'Groups',
              subtitle: 'Manage yuvak, mahila, sanskar groups',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/admin/groups'),
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              context,
              icon: Icons.event,
              title: 'Events',
              subtitle: 'Manage events and activities',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/admin/events'),
            ),
            
            if (!isManager) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Insights'),
              const SizedBox(height: 12),
              _buildDashboardCard(
                context,
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View statistics and reports',
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
              ),
              const SizedBox(height: 12),
              _buildDashboardCard(
                context,
                icon: Icons.health_and_safety,
                title: 'System Health',
                subtitle: 'Monitor system status',
                color: Colors.red,
                onTap: () => Navigator.pushNamed(context, '/admin/system-health'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
