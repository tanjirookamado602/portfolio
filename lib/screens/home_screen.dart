import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/content_management_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/platform_image.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onViewWorkPressed;
  final VoidCallback? onContactPressed;

  const HomeScreen({
    super.key,
    required this.onViewWorkPressed,
    this.onContactPressed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContentManagementService _contentService = ContentManagementService();
  Map<String, dynamic>? _contactContent;
  Map<String, dynamic>? _content;
  bool _loading = true;

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> raw) {
    final sanitized = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is String || value is num || value is bool || value == null) {
        sanitized[key] = value;
      } else if (value is List) {
        sanitized[key] = value;
      } else if (value is Map) {
        sanitized[key] = value.toString();
      } else {
        sanitized[key] = value.toString();
      }
    });
    return sanitized;
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List) {
      return value
          .map((e) => _safeString(e))
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((e) => '${_safeString(e.key)}: ${_safeString(e.value)}')
          .join(', ');
    }
    return value.toString();
  }

  String _asString(dynamic v, [String? fb]) {
    if (v == null) return fb ?? '';
    return _safeString(v);
  }

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final homeRemote = await _contentService.getHomeContent();
      final contactRemote = await _contentService.getContactContent();

      if (mounted) {
        setState(() {
          if (homeRemote != null && homeRemote.isNotEmpty) {
            _content = _sanitizeMap(Map<String, dynamic>.from(homeRemote));
          }
          if (contactRemote != null && contactRemote.isNotEmpty) {
            _contactContent =
                _sanitizeMap(Map<String, dynamic>.from(contactRemote));
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
        ),
      );
    }

    final hero = _asString(_content?['hero'], "Muhammad Assad Ullah");
    final subtitle = _asString(_content?['subtitle'], 'Flutter developer building offline-first, AI-integrated mobile apps.');
    final description = _asString(_content?['description'],
        'Focused on performant architectures, offline synchronization, and local LLM integrations.');
    final profileImage = _asString(_content?['profileImage'], '');

    final linkedin = _asString(
        _contactContent?['linkedin'], _asString(_content?['linkedin'], ''));
    final resume = _asString(
        _contactContent?['resume'], _asString(_content?['resume'], ''));

    String getLinkedinUrl(String val) {
      if (val.isEmpty) return '';
      if (val.startsWith('http')) return val;
      return 'https://linkedin.com/in/$val';
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final linkedinUrl = getLinkedinUrl(linkedin);
    final availabilityText = _asString(_content?['availabilityText'], 'Available for work');

    final contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Availability Tag
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accentSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              availabilityText,
              style: AppTheme.labelMeta.copyWith(
                color: AppTheme.accentSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        
        // Hero Display Large
        _HeroTitle(text: hero).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),

        // Subtitle Editorial Sentence
        Text(
          subtitle,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
            fontSize: isMobile ? 16 : 18,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 16),
        Text(
          description,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: isMobile ? 16 : 18,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 250.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 40),

        // Actions
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton(
              onPressed: widget.onViewWorkPressed,
              child: const Text('View Projects'),
            ),
            if (linkedinUrl.isNotEmpty)
              OutlinedButton(
                onPressed: () => _launchUrl(linkedinUrl),
                child: const Text('LinkedIn'),
              ),
            if (widget.onContactPressed != null)
              OutlinedButton(
                onPressed: widget.onContactPressed,
                child: const Text('Email'),
              ),
            if (resume.isNotEmpty)
              OutlinedButton(
                onPressed: () => _launchUrl(resume),
                child: const Text('Download CV'),
              ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
      ],
    );

    final avatarWidget = _HeroAvatar(imageUrl: profileImage)
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideY(begin: 0.05, end: 0);

    return AnimatedBackground(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 100,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.responsivePadding(context),
          vertical: isMobile ? 64 : 120,
        ),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: AppTheme.maxContentWidth(context)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isWide) ...[
                    Expanded(flex: 6, child: contentWidget),
                    const SizedBox(width: 48),
                    Expanded(flex: 4, child: avatarWidget),
                  ] else ...[
                    contentWidget,
                    const SizedBox(height: 48),
                    avatarWidget,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

class _HeroTitle extends StatelessWidget {
  final String text;
  const _HeroTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontSize = width > 900 ? 72.0 : (width > 600 ? 56.0 : 40.0);
    return Text(
      text,
      style: AppTheme.displayLarge.copyWith(
        fontSize: fontSize,
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String imageUrl;
  const _HeroAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final size = width > 700 ? 380.0 : (width > 400 ? 280.0 : 240.0);

    return Center(
      child: Container(
        width: size,
        height: size * 1.15,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          border: Border.all(color: AppTheme.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl.isEmpty
              ? const Center(
                  child: Icon(Icons.person, size: 80, color: AppTheme.textFaint),
                )
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.75, 0.15, 0.10, 0, 0,
                    0.10, 0.80, 0.10, 0, 0,
                    0.10, 0.15, 0.75, 0, 0,
                    0,    0,    0,    1, 0,
                  ]),
                  child: PlatformImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: size,
                    height: size * 1.15,
                  ),
                ),
        ),
      ),
    );
  }
}
