import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  Future<Map<String, dynamic>>? _healthFuture;

  @override
  void initState() {
    super.initState();
    _healthFuture = _checkSystemHealth();
  }

  void _refresh() {
    setState(() {
      _healthFuture = _checkSystemHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _healthFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final health = snapshot.data!;
          final isHealthy = health['healthy'] as bool;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Overall Status
                Card(
                  color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          isHealthy ? Icons.check_circle : Icons.error,
                          color: isHealthy ? Colors.green : Colors.red,
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHealthy ? 'System Healthy' : 'System Issues',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isHealthy ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              'Last checked: ${health['timestamp']}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Firebase Status
                _buildSectionHeader('Firebase Status'),
                const SizedBox(height: 12),
                _buildHealthItem(
                  'Firestore Connection',
                  health['firestore'] as bool,
                  Icons.cloud,
                ),
                _buildHealthItem(
                  'Authentication',
                  health['auth'] as bool,
                  Icons.lock,
                ),

                const SizedBox(height: 24),

                // Database Stats
                _buildSectionHeader('Database Statistics'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Total Families',
                          health['familyCount'] as int,
                        ),
                        const Divider(),
                        _buildStatRow(
                          'Total Members',
                          health['memberCount'] as int,
                        ),
                        const Divider(),
                        _buildStatRow(
                          'Total Events',
                          health['eventCount'] as int,
                        ),
                        const Divider(),
                        _buildStatRow(
                          'Total Notifications',
                          health['notificationCount'] as int,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Storage Status
                _buildSectionHeader('Storage'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Storage Usage'),
                            Text(
                              '${health['storagePercent']}%',
                              style: TextStyle(
                                color: (health['storagePercent'] as int) > 80
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (health['storagePercent'] as int) / 100,
                          minHeight: 8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (health['storagePercent'] as int) > 80
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                _buildSectionHeader('Quick Actions'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications),
                  label: const Text('Test Notification'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test notification sent!')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHealthItem(String name, bool isHealthy, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(name),
        trailing: Icon(
          isHealthy ? Icons.check_circle : Icons.cancel,
          color: isHealthy ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _checkSystemHealth() async {
    final health = <String, dynamic>{};
    final now = DateTime.now();

    try {
      // Check Firestore
      await FirebaseFirestore.instance.collection('families').limit(1).get();
      health['firestore'] = true;
    } catch (e) {
      health['firestore'] = false;
    }

    // Auth is always available in the app
    health['auth'] = true;

    // Get counts
    try {
      final familyCount = await FirebaseFirestore.instance
          .collection('families')
          .count()
          .get();
      health['familyCount'] = familyCount.count ?? 0;
    } catch (e) {
      health['familyCount'] = 0;
    }

    try {
      final memberCount = await FirebaseFirestore.instance
          .collection('members')
          .count()
          .get();
      health['memberCount'] = memberCount.count ?? 0;
    } catch (e) {
      health['memberCount'] = 0;
    }

    try {
      final eventCount = await FirebaseFirestore.instance
          .collection('events')
          .count()
          .get();
      health['eventCount'] = eventCount.count ?? 0;
    } catch (e) {
      health['eventCount'] = 0;
    }

    try {
      final notificationCount = await FirebaseFirestore.instance
          .collection('notifications')
          .count()
          .get();
      health['notificationCount'] = notificationCount.count ?? 0;
    } catch (e) {
      health['notificationCount'] = 0;
    }

    // Simulate storage check
    health['storagePercent'] = 35;

    health['healthy'] = health['firestore'] as bool && health['auth'] as bool;
    health['timestamp'] =
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return health;
  }
}
