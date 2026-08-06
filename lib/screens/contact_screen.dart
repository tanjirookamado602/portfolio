import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/content_management_service.dart';
import '../services/contact_form_service.dart';
import '../widgets/contact_form.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final ContentManagementService _contentService = ContentManagementService();
  final ContactFormService _contactFormService = ContactFormService();
  Map<String, dynamic>? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final remote = await _contentService.getContactContent();
      if (remote != null && remote.isNotEmpty) {
        if (mounted) {
          setState(() {
            _content = Map<String, dynamic>.from(remote);
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _asString(dynamic v, [String? fb]) {
    if (v == null) return fb ?? '';
    return _safeString(v);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppTheme.responsivePadding(context), 
          vertical: isMobile ? 64 : 120,
      ),
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppTheme.maxContentWidth(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 60),
            _buildContactContent(),
            const SizedBox(height: 80),
            _buildContactForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACT',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get In Touch',
          style: AppTheme.displayMedium.copyWith(
            fontSize: width < 600 ? 28 : 44,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: AppTheme.borderSubtle,
        ),
      ],
    );
  }

  Widget _buildContactContent() {
    final email = _asString(_content?['email'], '');
    final phone = _asString(_content?['phone'], '');
    final location = _asString(_content?['location'], '');
    final social = _asString(_content?['social'], '');

    if (email.isEmpty && phone.isEmpty && location.isEmpty && social.isEmpty) {
      return Text(
        'No contact information added yet.',
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactItemsColumn(email, phone, location, social),
          const SizedBox(height: 48),
          _buildQuickActions(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildContactItemsColumn(email, phone, location, social),
        ),
        const SizedBox(width: 60),
        Expanded(
          child: _buildQuickActions(),
        ),
      ],
    );
  }

  Widget _buildContactItemsColumn(String email, String phone, String location, String social) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Details',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        if (email.isNotEmpty) ...[
          _buildContactItem(
            title: 'Email',
            value: email,
            onTap: () => _launchUrl('mailto:$email'),
          ),
          const SizedBox(height: 16),
        ],
        if (phone.isNotEmpty) ...[
          _buildContactItem(
            title: 'Phone',
            value: phone,
            onTap: () => _launchUrl('tel:$phone'),
          ),
          const SizedBox(height: 16),
        ],
        if (location.isNotEmpty) ...[
          _buildContactItem(
            title: 'Location',
            value: location,
            onTap: null,
          ),
          const SizedBox(height: 16),
        ],
        if (social.isNotEmpty) ...[
          _buildContactItem(
            title: 'LinkedIn',
            value: social,
            onTap: () => _launchUrl('https://linkedin.com/in/$social'),
          ),
        ],
      ],
    );
  }

  Widget _buildContactItem({
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTheme.labelMeta.copyWith(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final resume = _asString(_content?['resume'], '');
    final github = _asString(_content?['github'], '');
    final social = _asString(_content?['social'], '');
    final linkedin = _asString(_content?['linkedin'], '');

    final scheduleMeeting = _asString(_content?['scheduleMeeting'], '');
    String meetingLink = '';
    if (scheduleMeeting.isNotEmpty) {
      meetingLink = scheduleMeeting;
    } else if (social.contains('calendly')) {
      meetingLink = social;
    } else if (linkedin.contains('calendly')) {
      meetingLink = linkedin;
    } else {
      meetingLink = 'https://calendly.com';
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.borderSubtle),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          if (resume.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _trackResumeDownload();
                  _launchUrl(resume);
                },
                child: const Text('Download CV'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (meetingLink.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _launchUrl(meetingLink),
                child: const Text('Schedule Meeting'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (github.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _launchUrl(github),
                child: const Text('View GitHub'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Send Message", style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        ContactForm(
          onSubmit: (name, email, subject, message) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message sent successfully!'),
                backgroundColor: AppTheme.accentPrimary,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _trackResumeDownload() async {
    try {
      await _contactFormService.trackResumeDownload(
        userAgent: 'Web Browser',
      );
    } catch (e) {
      debugPrint('Failed to track resume download: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
