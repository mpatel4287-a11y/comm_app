// lib/screens/admin/analytics_dashboard.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Real-time Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Demographics', icon: Icon(Icons.people_outline)),
            Tab(text: 'Growth', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDemographicsTab(),
          _buildGrowthTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.streamMemberDistribution(),
      builder: (context, mSnapshot) {
        return StreamBuilder<Map<String, int>>(
          stream: _analyticsService.streamOverviewStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !mSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            
            final data = snapshot.data!;
            final mData = mSnapshot.data!;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Platform Overview'),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard('Total Families', data['totalFamilies']?.toString() ?? '0', Icons.family_restroom, Colors.blue),
                      _buildMetricCard('Total Members', data['totalMembers']?.toString() ?? '0', Icons.people, Colors.green, subValue: '${mData['active']} Active'),
                      _buildMetricCard('Male Members', mData['male']?.toString() ?? '0', Icons.male, Colors.blueAccent),
                      _buildMetricCard('Female Members', mData['female']?.toString() ?? '0', Icons.female, Colors.pinkAccent),
                      _buildMetricCard('Total Events', data['totalEvents']?.toString() ?? '0', Icons.event_available, Colors.orange),
                      _buildMetricCard('Engagement', '84%', Icons.auto_graph, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Family Distribution'),
                  const SizedBox(height: 16),
                  StreamBuilder<Map<String, int>>(
                    stream: _analyticsService.streamFamilyDistribution(),
                    builder: (context, fSnapshot) {
                      if (!fSnapshot.hasData) return const SizedBox(height: 200);
                      final fData = fSnapshot.data!;
                      return _buildPieChartCard(
                        'Family Access Status',
                        [
                          PieChartSectionData(value: fData['active']!.toDouble(), title: 'Active', color: Colors.green, radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          PieChartSectionData(value: fData['blocked']!.toDouble(), title: 'Blocked', color: Colors.red, radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      );
                    }
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildDemographicsTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.streamMemberDistribution(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        
        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Gender & Marriage Distribution'),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildPieChartCard(
                    'Gender',
                    [
                      PieChartSectionData(value: data['male'].toDouble(), title: 'Male', color: Colors.blue, radius: 50, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
                      PieChartSectionData(value: data['female'].toDouble(), title: 'Female', color: Colors.pink, radius: 50, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  )),
                  const SizedBox(width: 16),
                   Expanded(child: _buildPieChartCard(
                    'Status',
                    [
                      PieChartSectionData(value: data['married'].toDouble(), title: 'Married', color: Colors.indigo, radius: 50, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
                      PieChartSectionData(value: data['unmarried'].toDouble(), title: 'Single', color: Colors.teal, radius: 50, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Age Demographics'),
              const SizedBox(height: 16),
              _buildBarChartCard(data['ageRanges'] as Map<String, int>),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrowthTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _analyticsService.streamGrowthData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        
        final growthData = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('User Growth (Last 6 Months)'),
              const SizedBox(height: 16),
              _buildLineChartCard(growthData),
              const SizedBox(height: 32),
              _buildSectionTitle('Recent Performance'),
              _buildPerformanceTile('New Enrollments', growthData.last['count'].toString(), '+12% from last month', Colors.green),
              _buildPerformanceTile('App Engagement', '84%', '+5% from last week', Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? subValue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (subValue != null)
                 Text(subValue, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(String title, List<PieChartSectionData> sections) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(Map<String, int> ageData) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: ageData.values.isEmpty ? 10 : (ageData.values.reduce((a, b) => a > b ? a : b).toDouble() + 5),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final keys = ageData.keys.toList();
                  if (value.toInt() < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(keys[value.toInt()], style: const TextStyle(color: Colors.white60, fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: ageData.entries.toList().asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  color: Colors.blueAccent,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChartCard(List<Map<String, dynamic>> growthData) {
    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < growthData.length) {
                    final month = growthData[value.toInt()]['month'].toString().split('-').last;
                    return Text(month, style: const TextStyle(color: Colors.white54, fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: growthData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['count'].toDouble())).toList(),
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTile(String title, String value, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Text(sub, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
