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
import '../../services/notification_service.dart';


import 'family_tree_view.dart';
import 'member_detail_screen.dart';
import 'user_calendar_screen.dart';
import 'user_notification_screen.dart';
import 'settings_screen.dart';
import 'user_search_tab.dart'; 
import '../admin/family_list_screen.dart';
import 'dart:math';

class EnhancedUserDashboard extends StatefulWidget {
  const EnhancedUserDashboard({super.key});

  @override
  State<EnhancedUserDashboard> createState() => _EnhancedUserDashboardState();
}

class _EnhancedUserDashboardState extends State<EnhancedUserDashboard> {
  final MemberService _memberService = MemberService();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();


  List<MemberModel> _allMembers = [];
  List<MemberModel> _randomSuggestions = [];
  List<MemberModel> _newMembers = [];

  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _familyDocId;
  String? _familyName;


  MemberModel? _currentUser;
  String? _userRole;
  int _selectedIndex = 2; // Default to HOME tab

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
      final role = await SessionManager.getRole();
      
      _userRole = role;
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
    // Live stream for members
    _memberService.streamAllMembers().listen((members) {
      if (mounted) {
        setState(() {
          _allMembers = members;
          _generateRandomSuggestions();
          _loadNewMembers();
          _calculateStats();
        });
      }
    });

    // Live stream for families
    FirebaseFirestore.instance.collection('families').where('isAdmin', isEqualTo: false).snapshots().listen((snap) {
      if (mounted) {
        setState(() {
          _stats['totalFamilies'] = snap.docs.length;
        });
      }
    });
  }

  void _calculateStats() {
    if (_allMembers.isEmpty) return;

    final total = _allMembers.length;
    final active = _allMembers.where((m) => m.isActive).length;
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final newThisMonth = _allMembers.where((m) => m.createdAt.isAfter(startOfMonth)).length;

    int myFamilyCount = 0;
    if (_familyDocId != null) {
      myFamilyCount = _allMembers.where((m) => m.familyDocId == _familyDocId).length;
    }

    setState(() {
      _stats['total'] = total;
      _stats['active'] = active;
      _stats['newThisMonth'] = newThisMonth;
      _stats['myFamilyCount'] = myFamilyCount;
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

  void _navigateToMember(MemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberDetailScreen(
          memberId: member.id,
          familyDocId: member.familyDocId,
          subFamilyDocId: member.subFamilyDocId,
        ),
      ),
    );
  }

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lang = Provider.of<LanguageService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return PopScope(
      canPop: _selectedIndex == 2,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 2) {
          setState(() => _selectedIndex = 2);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // 0. CALENDAR (Swapped)
            const UserCalendarScreen(),
            
            // 1. SEARCH
            const UserSearchTab(),
            
            // 2. HOME (Swapped)
            _buildHomeTab(context, lang, isDark),
            
            // 3. NOTIFICATIONS
            const UserNotificationScreen(),
  
            // 4. PROFILE (Settings)
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          indicatorColor: Colors.blue.shade900.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today, color: Colors.blue.shade900),
              label: lang.translate('events'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: Colors.blue.shade900),
              label: lang.translate('connect'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Colors.blue.shade900),
              label: lang.translate('home'),
            ),
            NavigationDestination(
              icon: StreamBuilder<int>(
                stream: _notificationService.streamUnreadCount(_familyDocId ?? ''),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.data ?? 0;
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.notifications_outlined),
                  );
                },
              ),
              selectedIcon: StreamBuilder<int>(
                stream: _notificationService.streamUnreadCount(_familyDocId ?? ''),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.data ?? 0;
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    child: Icon(Icons.notifications, color: Colors.blue.shade900),
                  );
                },
              ),
              label: lang.translate('notifications'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person, color: Colors.blue.shade900),
              label: lang.translate('profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, LanguageService lang, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. App Bar with Profile Quick Link (Shortened)
          SliverAppBar(
            expandedHeight: 60.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade900,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Text(
                '${lang.translate('welcome')}, ${_currentUser?.fullName.split(' ')[0] ?? 'User'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade800, Colors.blue.shade900],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: _currentUser?.photoUrl.isNotEmpty == true
                        ? NetworkImage(_currentUser!.photoUrl)
                        : null,
                    child: _currentUser?.photoUrl.isEmpty ?? true
                        ? Text(
                            _currentUser?.fullName.isNotEmpty == true 
                                ? _currentUser!.fullName[0].toUpperCase() 
                                : '?',
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),

          // 2. Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Statistics (Unbound layout fix)
                _buildQuickStats(lang, isDark),
                const SizedBox(height: 16),

                // Manager Specific Tools
                if (_userRole == 'manager') ...[
                  _buildManagerTools(lang, isDark),
                  const SizedBox(height: 16),
                ],
                
                // Section: Family Tree
                _buildSectionHeader(
                  lang.translate('family_tree'),
                  lang.translate('view_ancestry'),
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
                _buildFamilyStats(lang, isDark),

                // Section: Community Activity (Events)
                _buildSectionHeader(
                  lang.translate('community_activity'),
                  lang.translate('recent_events'),
                  Icons.event_note,
                  () => setState(() => _selectedIndex = 2), // Go to Calendar tab
                  lang,
                  isDark,
                ),
                _buildCommunityActivity(lang, isDark),

                // Section: New Members
                if (_newMembers.isNotEmpty) ...[
                  _buildSectionHeader(
                    lang.translate('new_members'),
                    lang.translate('recently_joined'),
                    Icons.person_add,
                    null,
                    lang,
                    isDark,
                  ),
                  _buildNewMembersSection(lang, isDark),
                ],

                // Section: Member Spotlight
                if (_randomSuggestions.isNotEmpty) ...[
                  _buildSectionHeader(
                    lang.translate('member_spotlight'),
                    lang.translate('discover_members'),
                    Icons.stars,
                    () => _generateRandomSuggestions(),
                    lang,
                    isDark,
                  ),
                  _buildMemberSuggestions(lang, isDark),
                ],

                const SizedBox(height: 50),
              ]),
            ),
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
          // 1) Total Members
          Expanded(
            child: InkWell(
              onTap: () => _switchTab(1), // Navigate to Search/Connect
              borderRadius: BorderRadius.circular(12),
              child: _buildStatCard(
                lang.translate('total_members'),
                '${_stats['total'] ?? 0}',
                Icons.people,
                Colors.blue,
                isDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 2) Total Families
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyListScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: _buildStatCard(
                lang.translate('families'),
                '${_stats['totalFamilies'] ?? 0}',
                Icons.family_restroom,
                Colors.purple,
                isDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 3) My Family
          Expanded(
            child: _buildStatCard(
              lang.translate('my_family'),
              '${_stats['myFamilyCount'] ?? 0}',
              Icons.home_work,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700, size: 16),
            ],
          ),
        ),
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
    return InkWell(
      onTap: () => _navigateToMember(member),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                  // ... Keep existing children ...
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
                Icon(Icons.event_busy, color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 12),
                Text(
                  lang.translate('no_events'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Show recent events
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final doc = events[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Event';
            final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          _getMonth(date.month),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildManagerTools(LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manager Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildManagerToolCard(
                  icon: Icons.notifications_active,
                  label: lang.translate('notifications'),
                  color: Colors.redAccent,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/notifications'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildManagerToolCard(
                  icon: Icons.event,
                  label: lang.translate('events'),
                  color: Colors.blueAccent,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/events'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildManagerToolCard(
                  icon: Icons.family_restroom,
                  label: lang.translate('families'),
                  color: Colors.purple,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/families'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildManagerToolCard(
                  icon: Icons.groups,
                  label: lang.translate('groups'),
                  color: Colors.green,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/groups'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagerToolCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFamilyStats(LanguageService lang, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: InkWell(
        onTap: () => _switchTab(1), // Switch to Connect tab
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSmallStat(lang.translate('families'), '${_stats['totalFamilies'] ?? 0}', Colors.purple),
            _buildSmallStat(lang.translate('members'), '${_stats['total'] ?? 0}', Colors.blue),
            _buildSmallStat(lang.translate('groups'), '${_stats['totalGroups'] ?? 0}', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
