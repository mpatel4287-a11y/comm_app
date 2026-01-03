// lib/screens/admin/analytics_dashboard.dart

// ignore_for_file: unnecessary_cast, unused_local_variable

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/family_service.dart';
import '../../services/member_service.dart';
import '../../services/event_service.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: FutureBuilder(
        future: Future.wait([
          FamilyService().getFamilyCount(),
          FamilyService().getActiveFamilyCount(),
          FamilyService().getBlockedFamilyCount(),
          MemberService().getMemberCount(),
          MemberService().getActiveMemberCount(),
          MemberService().getUnmarriedCount(),
          EventService().getEventCount(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final totalFamilies = data[0] as int;
          final activeFamilies = data[1] as int;
          final blockedFamilies = data[2] as int;
          final totalMembers = data[3] as int;
          final activeMembers = data[4] as int;
          final unmarriedMembers = data[5] as int;
          final totalEvents = data[6] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Key Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.family_restroom,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                totalFamilies.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Total Families',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Colors.green,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                totalMembers.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Total Members',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.teal,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activeMembers.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Active Members',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Colors.orange,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                totalEvents.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Total Events',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Family Status Pie Chart
                const Text(
                  'Family Status Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: activeFamilies.toDouble(),
                              title: 'Active',
                              color: Colors.green,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: blockedFamilies.toDouble(),
                              title: 'Blocked',
                              color: Colors.red,
                              radius: 50,
                            ),
                            if (totalFamilies -
                                    activeFamilies -
                                    blockedFamilies >
                                0)
                              PieChartSectionData(
                                value:
                                    (totalFamilies -
                                            activeFamilies -
                                            blockedFamilies)
                                        .toDouble(),
                                title: 'Inactive',
                                color: Colors.grey,
                                radius: 50,
                              ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Member Status Pie Chart
                const Text(
                  'Member Status Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: activeMembers.toDouble(),
                              title: 'Active',
                              color: Colors.green,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: (totalMembers - activeMembers).toDouble(),
                              title: 'Inactive',
                              color: Colors.red,
                              radius: 50,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bar Chart - Categories
                const Text(
                  'Category Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BarChart(
                        BarChartData(
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: totalFamilies.toDouble(),
                                  color: Colors.blue.shade900,
                                  width: 30,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: totalMembers.toDouble(),
                                  color: Colors.green,
                                  width: 30,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: unmarriedMembers.toDouble(),
                                  color: Colors.orange,
                                  width: 30,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: totalEvents.toDouble(),
                                  color: Colors.purple,
                                  width: 30,
                                ),
                              ],
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return const Text('Families');
                                    case 1:
                                      return const Text('Members');
                                    case 2:
                                      return const Text('Unmarried');
                                    case 3:
                                      return const Text('Events');
                                    default:
                                      return const Text('');
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Family Stats
                const Text(
                  'Family Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Active Families',
                  activeFamilies.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Blocked Families',
                  blockedFamilies.toString(),
                  Icons.block,
                  Colors.red,
                ),
                const SizedBox(height: 24),

                // Member Stats
                const Text(
                  'Member Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Unmarried Members',
                  unmarriedMembers.toString(),
                  Icons.person,
                  Colors.purple,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Inactive Members',
                  (totalMembers - activeMembers).toString(),
                  Icons.cancel,
                  Colors.grey,
                ),
                const SizedBox(height: 24),

                // Activity Chart
                const Text(
                  'Activity Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProgressRow(
                          'Family Coverage',
                          totalFamilies > 0
                              ? (activeFamilies / totalFamilies * 100).round()
                              : 0,
                        ),
                        const SizedBox(height: 12),
                        _buildProgressRow(
                          'Member Activity',
                          totalMembers > 0
                              ? (activeMembers / totalMembers * 100).round()
                              : 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('$percentage%')],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 8,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 80
                ? Colors.green
                : percentage >= 50
                ? Colors.orange
                : Colors.red,
          ),
        ),
      ],
    );
  }
}
