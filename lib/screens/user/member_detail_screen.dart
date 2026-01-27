// lib/screens/user/member_detail_screen.dart

// ignore_for_file: unused_field, unused_element, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/member_model.dart';
import '../../../services/member_service.dart';
import '../../../services/session_manager.dart';
import '../../../services/language_service.dart';
import 'package:provider/provider.dart';

// Helper widget to handle profile images with error handling
class ProfileImage extends StatefulWidget {
  final String? photoUrl;
  final String fullName;
  final double radius;

  const ProfileImage({
    super.key,
    this.photoUrl,
    required this.fullName,
    this.radius = 60,
  });

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.photoUrl ?? '';
    final hasValidUrl = photoUrl.isNotEmpty && photoUrl.startsWith('http');

    if (!hasValidUrl || _hasError) {
      // Show initials when no valid URL or error occurred
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.blue.shade900,
        child: Text(
          widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
          style: TextStyle(fontSize: widget.radius * 0.6, color: Colors.white),
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.blue.shade900,
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (_, __) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }
}

/// Attractive loading spinner widget
class _LoadingSpinner extends StatefulWidget {
  const _LoadingSpinner();

  @override
  State<_LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<_LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade700,
                    Colors.blue.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}

class MemberDetailScreen extends StatefulWidget {
  final String memberId;
  final String? familyDocId;
  final String? subFamilyDocId; // NEW: Optional sub-family ID

  const MemberDetailScreen({
    super.key,
    required this.memberId,
    this.familyDocId,
    this.subFamilyDocId,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final MemberService _memberService = MemberService();
  MemberModel? _member;
  bool _loading = true;
  String? _familyDocId;
  String? _currentUserRole;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() => _loading = true);
    
    try {
      MemberModel? member;
      
      // If familyDocId and subFamilyDocId are provided, use them
      if (widget.familyDocId != null && widget.familyDocId!.isNotEmpty &&
          widget.subFamilyDocId != null && widget.subFamilyDocId!.isNotEmpty) {
        member = await _memberService.getMember(
          mainFamilyDocId: widget.familyDocId!,
          subFamilyDocId: widget.subFamilyDocId!,
          memberId: widget.memberId,
        );
        if (member != null) {
          setState(() {
            _member = member;
            _familyDocId = widget.familyDocId;
            _loading = false;
          });
          return;
        }
      }
      
      // If not found or IDs not provided, search across all families
      final allMembers = await _memberService.getAllMembers();
      member = allMembers.firstWhere(
        (m) => m.id == widget.memberId,
        orElse: () => allMembers.firstWhere(
          (m) => m.mid == widget.memberId,
          orElse: () => throw Exception('Member not found'),
        ),
      );
      
      final isAdmin = await SessionManager.getIsAdmin() ?? false;
      final userRole = await SessionManager.getRole() ?? 'member';

      setState(() {
        _member = member;
        _familyDocId = member?.familyDocId ?? widget.familyDocId ?? '';
        _isAdmin = isAdmin;
        _currentUserRole = userRole;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading member: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _generateShareText() {
    if (_member == null) return '';
    final m = _member!;
    return '''
${m.fullName} ${m.surname}
Member ID: ${m.mid}
Family: ${m.familyName}
Phone: ${m.phone}
${m.address.isNotEmpty ? 'Address: ${m.address}' : ''}
${m.bloodGroup.isNotEmpty ? 'Blood Group: ${m.bloodGroup}' : ''}
''';
  }

  Future<void> _shareNormally() async {
    if (_member == null) return;
    await Share.share(
      _generateShareText(),
      subject: '${_member!.fullName} Profile',
    );
  }

  void _showShareOptions() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.translate('share_profile'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: Colors.blue),
              title: Text(lang.translate('digital_id')),
              onTap: () {
                Navigator.pop(context);
                if (_member != null) {
                  Navigator.pushNamed(
                    context,
                    '/user/digital-id',
                    arguments: _member,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: Text(lang.translate('share')),
              onTap: () {
                Navigator.pop(context);
                _shareNormally();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleManagerRole() async {
    if (_member == null || _familyDocId == null) return;
    
    final lang = Provider.of<LanguageService>(context, listen: false);
    final isCurrentlyManager = _member!.role == 'manager';
    final nextRole = isCurrentlyManager ? 'member' : 'manager';
    final actionText = isCurrentlyManager ? lang.translate('demote_to_member').toLowerCase() : lang.translate('promote_to_manager').toLowerCase();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentlyManager ? lang.translate('demote_member') : lang.translate('promote_member')),
        content: Text('${lang.translate('are_you_sure_role')} $actionText ${_member!.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lang.translate('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isCurrentlyManager ? lang.translate('demote') : lang.translate('promote')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await _memberService.updateMemberRole(
          mainFamilyDocId: _familyDocId!,
          subFamilyDocId: widget.subFamilyDocId ?? '',
          memberId: _member!.id,
          newRole: nextRole,
        );
        await _loadMember(); // Reload to update UI
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isCurrentlyManager ? lang.translate('demoted_success') : lang.translate('promoted_success'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${lang.translate('error')}: $e'), backgroundColor: Colors.red),
          );
        }
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LoadingSpinner(),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_member == null) {
      return Scaffold(body: Center(child: Text(lang.translate('member_not_found'))));
    }

    final member = _member!;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('member_details')),
        backgroundColor: Colors.blue.shade900,
        actions: [
          // More options menu
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'call':
                  _callPhone(member.phone);
                  break;
                case 'whatsapp':
                  _openWhatsapp(member.whatsapp);
                  break;
                case 'message':
                  _sendSms(member.phone);
                  break;
                case 'location':
                  _openMap(member.googleMapLink);
                  break;
                case 'share':
                  _showShareOptions();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (member.phone.isNotEmpty)
                const PopupMenuItem(
                  value: 'call',
                  child: Row(
                    children: [
                      Icon(Icons.call, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Call'),
                    ],
                  ),
                ),
              if (member.whatsapp.isNotEmpty)
                const PopupMenuItem(
                  value: 'whatsapp',
                  child: Row(
                    children: [
                      Icon(Icons.chat, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('WhatsApp'),
                    ],
                  ),
                ),
              if (member.phone.isNotEmpty)
                const PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      Icon(Icons.sms, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Message'),
                    ],
                  ),
                ),
              if (member.googleMapLink.isNotEmpty)
                const PopupMenuItem(
                  value: 'location',
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Location'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(lang.translate('share_profile')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  ProfileImage(
                    photoUrl: member.photoUrl,
                    fullName: member.fullName,
                    radius: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Member ID: ${member.mid}',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  if (member.role == 'manager')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        lang.translate('manager').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Digital ID Button directly on profile
                  ElevatedButton.icon(
                    onPressed: () {
                       Navigator.pushNamed(
                        context,
                        '/user/digital-id',
                        arguments: member,
                      );
                    },
                    icon: const Icon(Icons.badge_rounded),
                    label: Text(lang.translate('digital_id')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (member.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: member.tags.map((tag) {
                        return Chip(label: Text(tag));
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information
            _buildSectionHeader(lang.translate('personal_info')),
            _buildDetailCard([
              _buildDetailRow(lang.translate('member_id'), member.mid),
              _buildDetailRow(lang.translate('full_name'), member.fullName),
              if (member.surname.isNotEmpty)
                _buildDetailRow(lang.translate('surname'), member.surname),
              if (member.fatherName.isNotEmpty)
                _buildDetailRow(lang.translate('father_name'), member.fatherName),
              if (member.motherName.isNotEmpty)
                _buildDetailRow(lang.translate('mother_name'), member.motherName),
              _buildDetailRow(lang.translate('age'), '${member.age} ${lang.translate('years')}'),
              _buildDetailRow(lang.translate('birth_date'), member.birthDate),
              if (member.education.isNotEmpty)
                _buildDetailRow(lang.translate('education'), member.education),
              if (member.tod.isNotEmpty)
                _buildDetailRow(lang.translate('date_of_death'), member.tod),
              if (member.bloodGroup.isNotEmpty)
                _buildDetailRow(lang.translate('blood_group'), member.bloodGroup),
              _buildDetailRow(lang.translate('marriage_status'), member.marriageStatus),
              if (member.gotra.isNotEmpty)
                _buildDetailRow(lang.translate('gotra'), member.gotra),
              if (member.nativeHome.isNotEmpty)
                _buildDetailRow(lang.translate('native_home'), member.nativeHome),
              if (member.surdhan.isNotEmpty)
                _buildDetailRow('Surdhan', member.surdhan),
            ]),

            const SizedBox(height: 16),

            // Family Information
            _buildSectionHeader(lang.translate('family_info')),
            _buildDetailCard([
              _buildDetailRow(lang.translate('family_name'), member.familyName),
              _buildDetailRow('DKT Family ID', member.familyId),
              if (member.parentMid.isNotEmpty)
                _buildDetailRow(lang.translate('parent_mid'), member.parentMid),
            ]),

            const SizedBox(height: 16),

            // Contact Information
            _buildSectionHeader(lang.translate('contact_info')),
            _buildDetailCard([
              _buildDetailRow(lang.translate('phone'), member.phone),
              if (member.email.isNotEmpty)
                _buildDetailRow('E-mail ID', member.email),
              _buildLocationRow(
                lang.translate('address'),
                member.address,
                member.googleMapLink,
              ),
            ]),

            const SizedBox(height: 16),

            // Social Media
            _buildSectionHeader(lang.translate('social_media')),
            _buildDetailCard([
              if (member.whatsapp.isNotEmpty)
                _buildSocialRow('WhatsApp', member.whatsapp, Icons.message),
              if (member.instagram.isNotEmpty)
                _buildSocialRow(
                  'Instagram',
                  member.instagram,
                  Icons.camera_alt,
                ),
              if (member.facebook.isNotEmpty)
                _buildSocialRow('Facebook', member.facebook, Icons.facebook),
            ]),

            const SizedBox(height: 16),

            // Firms/Business
            if (member.firms.isNotEmpty) ...[
              _buildSectionHeader('Firms / Business'),
              ...member.firms.map(
                (firm) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(firm['name'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((firm['phone'] ?? '').isNotEmpty)
                          Text('Phone: ${firm['phone']}'),
                        if ((firm['mapLink'] ?? '').isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                              final url = firm['mapLink'];
                              if (url != null && url.isNotEmpty) {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.map,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'View on Map',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.business),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Social Media
            const SizedBox(height: 24),

            // Admin Actions
            if (_isAdmin) ...[
              _buildSectionHeader(lang.translate('admin_actions')),
              _buildDetailCard([
                ListTile(
                  leading: Icon(
                    member.role == 'manager' ? Icons.person_remove : Icons.person_add,
                    color: member.role == 'manager' ? Colors.red : Colors.green,
                  ),
                  title: Text(member.role == 'manager' ? lang.translate('demote_to_member') : lang.translate('promote_to_manager')),
                  subtitle: Text(member.role == 'manager' ? lang.translate('demote_subtitle') : lang.translate('promote_subtitle')),
                  onTap: _toggleManagerRole,
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    if (_member == null) return const SizedBox.shrink();
    final member = _member!;

    if (member.phone.isEmpty &&
        member.whatsapp.isEmpty &&
        member.googleMapLink.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (member.phone.isNotEmpty) ...[
          _buildQuickActionFab(
            icon: Icons.call,
            label: 'Call',
            color: Colors.green,
            onPressed: () => _callPhone(member.phone),
          ),
          const SizedBox(height: 8),
        ],
        if (member.whatsapp.isNotEmpty) ...[
          _buildQuickActionFab(
            icon: Icons.chat,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onPressed: () => _openWhatsapp(member.whatsapp),
          ),
          const SizedBox(height: 8),
        ],
        if (member.googleMapLink.isNotEmpty) ...[
          _buildQuickActionFab(
            icon: Icons.location_on,
            label: 'Map',
            color: Colors.red,
            onPressed: () => _openMap(member.googleMapLink),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionFab({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        FloatingActionButton.small(
          backgroundColor: color,
          foregroundColor: Colors.white,
          onPressed: onPressed,
          child: Icon(icon),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String address, String mapLink) {
    final displayAddress = address.isEmpty ? '-' : address;
    final hasMapLink = mapLink.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayAddress,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (hasMapLink)
                  IconButton(
                    icon: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 24,
                    ),
                    onPressed: () => _openMap(mapLink),
                    tooltip: 'Open in Google Maps',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String platform, String value, IconData icon) {
    final hasValue = value.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: hasValue ? () => _openSocialMedia(platform, value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 24, color: _getSocialColor(platform)),
              const SizedBox(width: 12),
              Text(platform),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: hasValue ? Colors.blue : null,
                  decoration: hasValue
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              if (hasValue)
                Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSocialColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return Colors.green;
      case 'instagram':
        return Colors.pink;
      case 'facebook':
        return Colors.blue.shade800;
      default:
        return Colors.blue.shade900;
    }
  }

  void _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWhatsapp(String phone) async {
    // Remove any non-digit characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openMap(String url) async {
    if (url.isEmpty) return;

    // Check if URL is a valid URL format
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme.isNotEmpty || url.startsWith('http'))) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // If it's not a full URL, search on Google Maps
      final searchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(url)}',
      );
      if (await canLaunchUrl(searchUrl)) {
        await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openSocialMedia(String platform, String value) async {
    String? url;

    switch (platform.toLowerCase()) {
      case 'whatsapp':
        final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
        url = 'https://wa.me/$cleanPhone';
        break;
      case 'instagram':
        // Handle both username and URL
        if (value.startsWith('http')) {
          url = value;
        } else {
          url = 'https://instagram.com/$value';
        }
        break;
      case 'facebook':
        // Handle both username and URL
        if (value.startsWith('http')) {
          url = value;
        } else {
          url = 'https://facebook.com/$value';
        }
        break;
    }

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
