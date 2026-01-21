// lib/screens/user/digital_id_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/member_model.dart';
import '../../services/language_service.dart';

class DigitalIdScreen extends StatelessWidget {
  final MemberModel member;

  const DigitalIdScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('digital_id')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareCard(member, lang),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.8),
              theme.colorScheme.secondary.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // THE ID CARD
                _buildIdCard(context, lang, theme),
                
                const SizedBox(height: 40),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    lang.translate('community_pride'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdCard(BuildContext context, LanguageService lang, ThemeData theme) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.92,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.familyName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        lang.translate('digital_id'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Photo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: member.photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(member.photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: member.photoUrl.isEmpty
                      ? Icon(Icons.person, size: 60, color: theme.colorScheme.primary)
                      : null,
                ),
                
                const SizedBox(height: 16),
                
                // Name and MID
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (member.surname.isNotEmpty)
                  Text(
                    member.surname,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'MID: ${member.mid}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                
                // Details Grid
                _buildDetailsSection(lang),
                
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: jsonEncode({
                          'type': 'member',
                          'mid': member.mid,
                          'memberId': member.id,
                          'familyDocId': member.familyDocId,
                          'subFamilyDocId': member.subFamilyDocId,
                          'fullName': member.fullName,
                          'phone': member.phone,
                        }),
                        version: QrVersions.auto,
                        size: 140.0,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: theme.colorScheme.primary,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.translate('scan_to_save_contact'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(LanguageService lang) {
    return Column(
      children: [
        // Row 1: Blood Group & Birth Date
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                lang.translate('blood_group'),
                member.bloodGroup.isNotEmpty ? member.bloodGroup : '-',
                Icons.bloodtype,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                lang.translate('birth_date'),
                member.birthDate.isNotEmpty ? member.birthDate : '-',
                Icons.cake,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 2: Father & Mother
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                lang.translate('father_name'),
                member.fatherName.isNotEmpty ? member.fatherName : '-',
                Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                lang.translate('mother_name'),
                member.motherName.isNotEmpty ? member.motherName : '-',
                Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 3: Gotra & Education
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                lang.translate('gotra'),
                member.gotra.isNotEmpty ? member.gotra : '-',
                Icons.family_restroom,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                lang.translate('education'),
                member.education.isNotEmpty ? member.education : '-',
                Icons.school,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 4: Native Home & Marriage Status
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                lang.translate('native_home'),
                member.nativeHome.isNotEmpty ? member.nativeHome : '-',
                Icons.home,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                lang.translate('marriage_status'),
                lang.translate(member.marriageStatus),
                Icons.favorite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 5: Phone & Address
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                lang.translate('phone'),
                member.phone.isNotEmpty ? member.phone : '-',
                Icons.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                lang.translate('address'),
                member.address.isNotEmpty
                    ? (member.address.length > 20
                        ? '${member.address.substring(0, 20)}...'
                        : member.address)
                    : '-',
                Icons.location_on,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _shareCard(MemberModel member, LanguageService lang) {
    final text = '${lang.translate('digital_id')}\n'
        '${lang.translate('member_profile')}: ${member.fullName}\n'
        'MID: ${member.mid}\n'
        '${lang.translate('family_id')}: ${member.familyName}\n'
        '${lang.translate('phone')}: ${member.phone}';
    Share.share(text);
  }
}
