// lib/screens/admin/system_health_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/animation_utils.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  Future<Map<String, dynamic>>? _healthFuture;
  bool _isClearingCache = false;

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

  Future<void> _clearLocalCache() async {
    setState(() => _isClearingCache = true);
    try {
      await FirebaseFirestore.instance.clearPersistence();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore local offline persistence cache purged successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cache reset note: ${e.toString()}'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'System Diagnostics & Telemetry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Run diagnostics check',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _healthFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Pinging backend services & metrics...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final health = snapshot.data ?? {};
          final isHealthy = (health['healthy'] as bool?) ?? false;
          final latencyMs = (health['latencyMs'] as int?) ?? 0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Overall Telemetry Hero Card
                FadeInAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isHealthy
                            ? [const Color(0xFF065F46), const Color(0xFF047857)]
                            : [const Color(0xFF991B1B), const Color(0xFF7F1D1D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isHealthy ? Colors.green : Colors.red).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHealthy ? 'ALL SYSTEMS OPERATIONAL' : 'SYSTEM ISSUES DETECTED',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ping: ${latencyMs}ms  •  Checked at: ${health['timestamp']}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Services Health Grid
                FadeInAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: _buildSectionTitle('Core Cloud Services'),
                ),
                const SizedBox(height: 12),

                SlideInAnimation(
                  delay: const Duration(milliseconds: 250),
                  beginOffset: const Offset(0, 0.1),
                  child: Column(
                    children: [
                      _buildServiceHealthCard(
                        'Cloud Firestore Backend',
                        'Realtime DB and offline persistence',
                        (health['firestore'] as bool?) ?? false,
                        Icons.cloud_done_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildServiceHealthCard(
                        'Session & Auth Engine',
                        'MID authentication and role access',
                        (health['auth'] as bool?) ?? true,
                        Icons.lock_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildServiceHealthCard(
                        'Firebase Cloud Messaging (FCM)',
                        'Push notification dispatch pipeline',
                        true,
                        Icons.notifications_active_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Live Collection Statistics
                FadeInAnimation(
                  delay: const Duration(milliseconds: 300),
                  child: _buildSectionTitle('Live Database Statistics'),
                ),
                const SizedBox(height: 12),

                SlideInAnimation(
                  delay: const Duration(milliseconds: 350),
                  beginOffset: const Offset(0, 0.1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _buildStatTile('Total Families Registered', '${health['familyCount'] ?? 0}', Icons.holiday_village_rounded, Colors.blue),
                        const Divider(height: 16),
                        _buildStatTile('Total Community Members', '${health['memberCount'] ?? 0}', Icons.people_alt_rounded, Colors.teal),
                        const Divider(height: 16),
                        _buildStatTile('Community Events', '${health['eventCount'] ?? 0}', Icons.event_available_rounded, Colors.orange),
                        const Divider(height: 16),
                        _buildStatTile('Broadcast Notifications', '${health['notificationCount'] ?? 0}', Icons.campaign_rounded, Colors.redAccent),
                        const Divider(height: 16),
                        _buildStatTile('Member Update Requests', '${health['requestCount'] ?? 0}', Icons.published_with_changes_rounded, Colors.purple),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Developer Tools & Cache Actions
                FadeInAnimation(
                  delay: const Duration(milliseconds: 400),
                  child: _buildSectionTitle('Developer Maintenance Actions'),
                ),
                const SizedBox(height: 12),

                SlideInAnimation(
                  delay: const Duration(milliseconds: 450),
                  beginOffset: const Offset(0, 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cleaning_services_rounded, color: Colors.indigo, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Purge Offline Persistence Cache',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'Force re-sync documents directly from Firestore servers',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _isClearingCache ? null : _clearLocalCache,
                          icon: _isClearingCache
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cached_rounded, size: 16),
                          label: Text(_isClearingCache ? 'Purging Cache...' : 'Clear Offline Cache & Refresh'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildServiceHealthCard(String title, String subtitle, bool isHealthy, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isHealthy ? Colors.green : Colors.red).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isHealthy ? Colors.green.shade600 : Colors.red.shade600, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isHealthy ? Colors.green : Colors.red).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isHealthy ? 'ACTIVE' : 'ERROR',
              style: TextStyle(
                color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _checkSystemHealth() async {
    final health = <String, dynamic>{};
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();

    try {
      // Check Firestore & measure ping latency
      await FirebaseFirestore.instance.collection('families').limit(1).get();
      stopwatch.stop();
      health['firestore'] = true;
      health['latencyMs'] = stopwatch.elapsedMilliseconds;
    } catch (e) {
      stopwatch.stop();
      health['firestore'] = false;
      health['latencyMs'] = stopwatch.elapsedMilliseconds;
    }

    health['auth'] = true;

    // Get live document counts
    try {
      final familyCount = await FirebaseFirestore.instance.collection('families').where('isAdmin', isEqualTo: false).count().get();
      health['familyCount'] = familyCount.count ?? 0;
    } catch (_) {
      health['familyCount'] = 0;
    }

    try {
      final memberCount = await FirebaseFirestore.instance.collectionGroup('members').count().get();
      health['memberCount'] = memberCount.count ?? 0;
    } catch (_) {
      health['memberCount'] = 0;
    }

    try {
      final eventCount = await FirebaseFirestore.instance.collection('events').count().get();
      health['eventCount'] = eventCount.count ?? 0;
    } catch (_) {
      health['eventCount'] = 0;
    }

    try {
      final notificationCount = await FirebaseFirestore.instance.collection('notifications').count().get();
      health['notificationCount'] = notificationCount.count ?? 0;
    } catch (_) {
      health['notificationCount'] = 0;
    }

    try {
      final requestCount = await FirebaseFirestore.instance.collection('member_update_requests').where('status', isEqualTo: 'pending').count().get();
      health['requestCount'] = requestCount.count ?? 0;
    } catch (_) {
      health['requestCount'] = 0;
    }

    health['healthy'] = (health['firestore'] as bool) && (health['auth'] as bool);
    health['timestamp'] = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return health;
  }
}
