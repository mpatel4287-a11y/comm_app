// lib/screens/user/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ramanagara Patidar Samaj',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Effective Date: August 2026\nVersion 1.0.0',
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
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(context, '1. Introduction & Overview'),
            _buildParagraph(
              'Ramanagara Patidar Samaj ("we", "our", or "us") respects your privacy and is committed to protecting the personal data of our community members. This Privacy Policy describes how we collect, use, disclose, and safeguard your personal information when you use our mobile application.',
            ),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '2. Information We Collect'),
            _buildParagraph(
              'To deliver community directory, family tree visualization, event announcements, and organizational management services, we may collect the following categories of information:',
            ),
            _buildBulletPoint('Personal Identifiers', 'Full name, Member Identification Number (MID), family name, date of birth, age, gender, and blood group.'),
            _buildBulletPoint('Contact Information', 'Mobile phone numbers, residential/business address, and email address (if provided).'),
            _buildBulletPoint('Family & Organizational Data', 'Family relationships (Head of Family, relationships, sub-families), firm/business details, and committee designations.'),
            _buildBulletPoint('Photos & Media', 'Profile photos, firm images, and community event photos explicitly uploaded by you or community administrators.'),
            _buildBulletPoint('Device & Push Notification Data', 'Firebase Cloud Messaging (FCM) registration token to deliver essential announcements, meeting reminders, and community alerts.'),
            _buildBulletPoint('Biometric Authentication Data', 'If enabled, fingerprint or face authentication is processed entirely locally on your device by the Android OS and is never stored on or transmitted to our servers.'),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '3. How We Use Your Information'),
            _buildParagraph(
              'We use the collected information strictly for community administration and service purposes:',
            ),
            _buildBulletPoint('Directory & Search', 'Allowing registered community members to search, view family connections, and connect with other members.'),
            _buildBulletPoint('Event Management', 'Notifying members about cultural events, sammelans, and general body meetings.'),
            _buildBulletPoint('Business/Firm Network', 'Showcasing community-owned businesses, firms, and professionals.'),
            _buildBulletPoint('Security & Verification', 'Verifying active membership status and authenticating role-based administrative access.'),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '4. Data Storage & Security'),
            _buildParagraph(
              'All data collected is stored securely using Google Firebase Cloud Firestore and Firebase Cloud Storage. Data transmissions between the app and backend services are encrypted in transit using industry-standard Transport Layer Security (TLS/HTTPS). Access to administrative management tools is restricted to authorized committee personnel.',
            ),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '5. Data Sharing & Third Parties'),
            _buildParagraph(
              'We do not sell, rent, trade, or monetize your personal information to any third parties or advertisers. Data is only accessible to verified community members according to community privacy rules and processed by verified infrastructure providers (Google Firebase).',
            ),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '6. Account & Data Deletion'),
            _buildParagraph(
              'In accordance with Google Play data safety policies, members have the right to request deletion of their account and associated personal data at any time. You can initiate a deletion request through the app Settings menu or by contacting the community administrators directly. Upon confirmation, your profile, authentication credentials, and uploaded photos will be permanently removed from our active database.',
            ),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '7. Children\'s Privacy'),
            _buildParagraph(
              'Our application includes family records where minor family members may be recorded under their parents or legal guardians as part of the family lineage. We do not independently solicit or collect personal information directly from children under 13.',
            ),

            const SizedBox(height: 20),

            _buildSectionTitle(context, '8. Contact & Grievance Officer'),
            _buildParagraph(
              'If you have any questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact the administrative committee:',
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ramanagara Patidar Samaj Administration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Email: support@ramanagarapatidar.org (or community admin)'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl('https://comm-app.web.app'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_browser, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Website: https://comm-app.web.app',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Terms of Service Summary
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Terms of Service Summary'),
            _buildParagraph(
              'By accessing and using this application, you agree to comply with community code of conduct rules. The directory information is intended strictly for internal community welfare and social connectivity. Misuse of member contact details for commercial spam or harassment is strictly prohibited and subject to account termination.',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
