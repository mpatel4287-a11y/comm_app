// lib/screens/user/enhanced_user_dashboard.dart

// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import '../../services/session_manager.dart';
import '../../services/theme_service.dart';
import '../../services/language_service.dart';
import '../../widgets/top_action_bar.dart';
import 'family_tree_view.dart';
import 'advanced_search_screen.dart';
import 'user_calendar_screen.dart';
import 'dart:math';

class EnhancedUserDashboard extends StatefulWidget {
  const EnhancedUserDashboard({super.key});

  @override
  State<EnhancedUserDashboard> createState() => _EnhancedUserDashboardState();
}

class _EnhancedUserDashboardState extends State<EnhancedUserDashboard> {
  final MemberService _memberService = MemberService();
  final ScrollController _scrollController = ScrollController();

  List<MemberModel> _allMembers = [];
  List<MemberModel> _randomSuggestions = [];
  List<MemberModel> _newMembers = [];

  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _familyDocId;
  String? _familyName;
  MemberModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupLiveUpdates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);

    try {
      final familyDocId = await SessionManager.getFamilyDocId();
      final familyName = await SessionManager.getFamilyName();
      final memberDocId = await SessionManager.getMemberDocId();
      final subFamilyDocId = await SessionManager.getSubFamilyDocId();

      _familyDocId = familyDocId;
      _familyName = familyName;

      // Load current user
      if (memberDocId != null && familyDocId != null) {
        _currentUser = await _memberService.getMember(
          mainFamilyDocId: familyDocId,
          subFamilyDocId: subFamilyDocId ?? '',
          memberId: memberDocId,
        );
      }

      // Load all members
      _allMembers = await _memberService.getAllMembers();

      // Generate random suggestions
      _generateRandomSuggestions();

      // Get new members (last 7 days)
      _loadNewMembers();

      // Load statistics
      await _loadStatistics();

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      setState(() => _loading = false);
    }
  }

  void _setupLiveUpdates() {
    // Live stream for new members
    _memberService.streamAllMembers().listen((members) {
      if (mounted) {
        setState(() {
          _allMembers = members;
          _generateRandomSuggestions();
          _loadNewMembers();
        });
      }
    });
  }

  void _generateRandomSuggestions() {
    if (_allMembers.isEmpty) return;

    final random = Random();
    final suggestions = <MemberModel>[];
    final availableMembers = List<MemberModel>.from(_allMembers);

    // Filter out current user
    if (_currentUser != null) {
      availableMembers.removeWhere((m) => m.id == _currentUser!.id);
    }

    // Get 5 random members
    for (int i = 0; i < 5 && availableMembers.isNotEmpty; i++) {
      final index = random.nextInt(availableMembers.length);
      suggestions.add(availableMembers.removeAt(index));
    }

    setState(() => _randomSuggestions = suggestions);
  }

  void _loadNewMembers() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    _newMembers = _allMembers.where((member) {
      return member.createdAt.isAfter(weekAgo);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_newMembers.length > 10) {
      _newMembers = _newMembers.take(10).toList();
    }
  }

  Future<void> _loadStatistics() async {
    final total = await _memberService.getMemberCount();
    final active = await _memberService.getActiveMemberCount();
    final newThisMonth = await _memberService.getNewMembersThisMonth();

    setState(() {
      _stats = {'total': total, 'active': active, 'newThisMonth': newThisMonth};
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(lang.translate('user_dashboard')),
          backgroundColor: Colors.blue.shade900,
          actions: [
            TextButton(
              onPressed: () {
                final newLang = lang.currentLanguage == 'en' ? 'gu' : 'en';
                lang.setLanguage(newLang);
              },
              child: Text(
                lang.currentLanguage == 'en' ? 'GUJ' : 'ENG',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const TopActionBar(showProfile: true),
            const SizedBox(width: 8),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(lang.translate('user_dashboard')),
        backgroundColor: Colors.blue.shade900,
        actions: [
          TextButton(
            onPressed: () {
              final newLang = lang.currentLanguage == 'en' ? 'gu' : 'en';
              lang.setLanguage(newLang);
            },
            child: Text(
              lang.currentLanguage == 'en' ? 'GUJ' : 'ENG',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TopActionBar(
            showProfile: true,
            onNotificationTap: () {
              Navigator.pushNamed(context, '/user/notifications');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header with Family Info
            SliverToBoxAdapter(child: _buildHeaderSection(lang, isDark)),

            // Quick Stats
            SliverToBoxAdapter(child: _buildQuickStats(lang, isDark)),

            // Global Search Section
            SliverToBoxAdapter(child: _buildSearchSection(lang, isDark)),

            // Random Suggestions
            if (_randomSuggestions.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  lang.translate('random_suggestions'),
                  lang.translate('discover_members'),
                  Icons.auto_awesome,
                  () => _generateRandomSuggestions(),
                  lang,
                  isDark,
                ),
              ),
            SliverToBoxAdapter(child: _buildMemberSuggestions(lang, isDark)),

            // New Members Section
            if (_newMembers.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  lang.translate('new_members'),
                  lang.translate('recently_joined'),
                  Icons.new_releases,
                  null,
                  lang,
                  isDark,
                ),
              ),
            if (_newMembers.isNotEmpty)
              SliverToBoxAdapter(child: _buildNewMembersSection(lang, isDark)),

            // Family Tree Section
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                lang.translate('family_tree'),
                lang.translate('view_family_tree'),
                Icons.account_tree,
                () {
                  if (_familyDocId != null && _familyName != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyTreeView(
                          mainFamilyDocId: _familyDocId!,
                          familyName: _familyName!,
                        ),
                      ),
                    );
                  }
                },
                lang,
                isDark,
              ),
            ),

            // Community Activity
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                lang.translate('community_activity'),
                lang.translate('recent_activity'),
                Icons.trending_up,
                () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserCalendarScreen(),
                    ),
                  );
                },
                lang,
                isDark,
              ),
            ),
            SliverToBoxAdapter(child: _buildCommunityActivity(lang, isDark)),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _familyName ?? 'Community',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${lang.translate('total_members')}: ${_stats['total'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              lang.translate('total_members'),
              '${_stats['total'] ?? 0}',
              Icons.people,
              Colors.blue,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              lang.translate('active_members'),
              '${_stats['active'] ?? 0}',
              Icons.check_circle,
              Colors.green,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              lang.translate('new_this_month'),
              '${_stats['newThisMonth'] ?? 0}',
              Icons.trending_up,
              Colors.orange,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('global_search'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdvancedSearchScreen(allMembers: _allMembers),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.translate('search_members'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lang.translate('filter_by')}: ${lang.translate('blood_group')}, ${lang.translate('city')}, ${lang.translate('family')}...',
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
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    LanguageService lang,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade900, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue.shade700),
              onPressed: onTap,
              tooltip: lang.translate('refresh'),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberSuggestions(LanguageService lang, bool isDark) {
    if (_randomSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _randomSuggestions.length,
        itemBuilder: (context, index) {
          final member = _randomSuggestions[index];
          return _buildMemberCard(member, lang, isDark, true);
        },
      ),
    );
  }

  Widget _buildNewMembersSection(LanguageService lang, bool isDark) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _newMembers.length,
        itemBuilder: (context, index) {
          final member = _newMembers[index];
          return _buildMemberCard(member, lang, isDark, false);
        },
      ),
    );
  }

  Widget _buildMemberCard(
    MemberModel member,
    LanguageService lang,
    bool isDark,
    bool isSuggestion,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child:
                      member.photoUrl.isNotEmpty &&
                          member.photoUrl.startsWith('http')
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            member.photoUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarPlaceholder(member),
                          ),
                        )
                      : _buildAvatarPlaceholder(member),
                ),
                if (isSuggestion)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Member Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (member.bloodGroup.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.bloodtype,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.bloodGroup,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (member.nativeHome.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          member.nativeHome,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(MemberModel member) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
      ),
      child: Center(
        child: Text(
          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityActivity(LanguageService lang, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final events = snapshot.data!.docs;
        if (events.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                lang.translate('no_events'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return Column(
          children: events.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as dynamic)?.toDate();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.event, color: Colors.blue.shade900),
                ),
                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: date != null
                    ? Text('${date.day}/${date.month}/${date.year}')
                    : null,
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
