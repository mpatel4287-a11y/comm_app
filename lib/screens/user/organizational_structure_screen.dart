// lib/screens/user/organizational_structure_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/role_service.dart';
import '../../services/member_service.dart';
import '../../models/organizational_role_model.dart';
import '../../models/member_model.dart';
import 'member_detail_screen.dart';
import '../admin/role_management_screen.dart';
import '../../services/session_manager.dart';
import '../../widgets/animation_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrganizationalStructureScreen extends StatefulWidget {
  const OrganizationalStructureScreen({super.key});

  @override
  State<OrganizationalStructureScreen> createState() => _OrganizationalStructureScreenState();
}

class _OrganizationalStructureScreenState extends State<OrganizationalStructureScreen> with SingleTickerProviderStateMixin {
  final RoleService _roleService = RoleService();
  final MemberService _memberService = MemberService();
  late TabController _tabController;
  List<MemberModel> _allMembers = [];
  bool _isAdminOrManager = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: RoleService.defaultCategories.length, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    try {
      final members = await _memberService.getAllMembers().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Loading timed out after 15s');
          return []; // Return empty list on timeout
        },
      );
      
      final role = await SessionManager.getRole();
      final isAdmin = await SessionManager.getIsAdmin() ?? false;

      if (mounted) {
        setState(() {
          _allMembers = members;
          _isAdminOrManager = isAdmin || role == 'manager' || role == 'admin';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading organizational data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(Provider.of<LanguageService>(context).translate('committees_roles'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_isAdminOrManager)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Manage Roles',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          isScrollable: true,
          tabs: RoleService.defaultCategories.map((c) {
            // Translate category name for tabs
            final tabLang = Provider.of<LanguageService>(context, listen: false);
            final key = c.toLowerCase().replaceAll(' ', '_');
            final translated = tabLang.translate(key);
            return Tab(text: translated == key ? c : translated);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: RoleService.defaultCategories.map((category) {
          final lang = Provider.of<LanguageService>(context);
          return _buildRoleView(category, lang);
        }).toList(),
      ),
    );
  }

  Widget _buildRoleView(String category, LanguageService lang) {
    return StreamBuilder<List<OrganizationalRoleModel>>(
      stream: _roleService.streamRolesByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Index building or loading error. If this is a new setup, it might take a few minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text('${lang.translate('coming_soon_for')} $category', style: const TextStyle(color: Colors.grey)),
          );
        }

        final roles = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            return _buildRoleRow(role, index, lang);
          },
        );
      },
    );
  }

  Widget _buildRoleRow(OrganizationalRoleModel role, int index, LanguageService lang) {
    final assignedMembers = _allMembers.where((m) => role.memberMids.contains(m.mid)).toList();

    return SlideInAnimation(
      delay: Duration(milliseconds: 100 * index),
      beginOffset: const Offset(0, 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang.translate(role.roleTitle.toLowerCase().replaceAll(' ', '_')).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 16,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.onSurface,
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (assignedMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              child: Text(lang.translate('to_be_announced'), style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13)),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: assignedMembers.map((m) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildMemberMiniCard(m),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMemberMiniCard(MemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberDetailScreen(memberId: member.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'photo_${member.id}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: member.photoUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(member.photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: member.photoUrl.isEmpty
                        ? Center(
                            child: Text(
                              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 10,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              member.mid,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
