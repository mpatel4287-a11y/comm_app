// lib/screens/user/member_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/member_model.dart';
import '../../../services/member_service.dart';
import '../../../services/session_manager.dart';
import 'qr_share_screen.dart';

class MemberDetailScreen extends StatefulWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final MemberService _memberService = MemberService();
  MemberModel? _member;
  bool _loading = true;
  String? _familyDocId;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    final member = await _memberService.getMember(widget.memberId);
    final docId = await SessionManager.getFamilyDocId();
    setState(() {
      _member = member;
      _familyDocId = docId;
      _loading = false;
    });
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Share via QR Code'),
              onTap: () {
                Navigator.pop(context);
                if (_member != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRShareScreen(
                        memberId: _member!.id,
                        memberName: _member!.fullName,
                        memberMid: _member!.mid,
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Normally'),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_member == null) {
      return const Scaffold(body: Center(child: Text('Member not found')));
    }

    final member = _member!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareOptions,
          ),
          if (_familyDocId != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'share') {
                  _showShareOptions();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share'),
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
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade900,
                    backgroundImage: member.photoUrl.isNotEmpty
                        ? NetworkImage(member.photoUrl)
                        : null,
                    child: member.photoUrl.isEmpty
                        ? Text(
                            member.fullName.isNotEmpty
                                ? member.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (member.surname.isNotEmpty)
                    Text(
                      member.surname,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
            _buildSectionHeader('Personal Information'),
            _buildDetailCard([
              _buildDetailRow('Member ID', member.mid),
              _buildDetailRow('Age', '${member.age} years'),
              _buildDetailRow('Birth Date', member.birthDate),
              _buildDetailRow(
                'Date of Death',
                member.tod.isEmpty ? '-' : member.tod,
              ),
              _buildDetailRow(
                'Blood Group',
                member.bloodGroup.isEmpty ? '-' : member.bloodGroup,
              ),
              _buildDetailRow('Marriage Status', member.marriageStatus),
              _buildDetailRow(
                'Gotra',
                member.gotra.isEmpty ? '-' : member.gotra,
              ),
              _buildDetailRow(
                'Native Home',
                member.nativeHome.isEmpty ? '-' : member.nativeHome,
              ),
            ]),

            const SizedBox(height: 16),

            // Family Information
            _buildSectionHeader('Family Information'),
            _buildDetailCard([
              _buildDetailRow('Family Name', member.familyName),
              _buildDetailRow('Family ID', member.familyId),
              if (member.parentMid.isNotEmpty)
                _buildDetailRow('Parent Member', member.parentMid),
            ]),

            const SizedBox(height: 16),

            // Contact Information
            _buildSectionHeader('Contact Information'),
            _buildDetailCard([
              _buildDetailRow('Phone', member.phone),
              _buildLocationRow(
                'Address',
                member.address,
                member.googleMapLink,
              ),
            ]),

            const SizedBox(height: 16),

            // Social Media
            _buildSectionHeader('Social Media'),
            _buildDetailCard([
              if (member.whatsapp.isNotEmpty)
                _buildSocialRow('WhatsApp', member.whatsapp, Icons.chat),
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
                          const Text('View on Map'),
                      ],
                    ),
                    trailing: const Icon(Icons.business),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      // Quick Actions
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: member.phone.isNotEmpty
                  ? () => _callPhone(member.phone)
                  : null,
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
            ),
            TextButton.icon(
              onPressed: member.whatsapp.isNotEmpty
                  ? () => _openWhatsapp(member.whatsapp)
                  : null,
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp'),
            ),
            TextButton.icon(
              onPressed: member.phone.isNotEmpty
                  ? () => _sendSms(member.phone)
                  : null,
              icon: const Icon(Icons.sms),
              label: const Text('SMS'),
            ),
          ],
        ),
      ),
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
