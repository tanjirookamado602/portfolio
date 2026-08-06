import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/portfolio_firebase_service.dart';
import '../widgets/timeline_item.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, dynamic>? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

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
      return value.map((e) => _safeString(e)).where((s) => s.isNotEmpty).join(', ');
    }
    if (value is Map) {
      return value.entries.map((e) => '${_safeString(e.key)}: ${_safeString(e.value)}').join(', ');
    }
    return value.toString();
  }

  String _asString(dynamic v, [String? fb]) {
    if (v == null) return fb ?? '';
    return _safeString(v);
  }

  Future<void> _loadContent() async {
    try {
      final remoteAbout = await PortfolioFirebaseService().getContent('about');

      if (mounted) {
        setState(() {
          if (remoteAbout != null) {
            _content = _sanitizeMap(Map<String, dynamic>.from(remoteAbout));
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
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
          strokeWidth: 3,
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
            const SizedBox(height: 48),
            _buildAboutContent(),
            const SizedBox(height: 80),
            _buildTimeline(),
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
          'ABOUT',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get to know me better',
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

  Widget _buildAboutContent() {
    final body = _asString(
      _content?['body'] ?? _content?['description'],
      'I am a passionate Flutter developer with a strong background in mobile app development and AI technologies. I love creating innovative solutions and exploring new technologies.',
    );

    final List<String> techStack = [
      'Flutter', 'Dart', 'Firebase', 'SQLite', 'Bloc', 'Provider', 'REST APIs', 'Git', 'Local LLMs'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          body,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
          ),
        ),
        const SizedBox(height: 32),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: techStack.map((tech) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border.all(color: AppTheme.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tech,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
        
        const SizedBox(height: 48),
        _buildStats(),
      ],
    );
  }

  Widget _buildStats() {
    return FutureBuilder<Map<String, int>>(
      future: _getStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'projects': 0, 'skills': 0, 'years': 0};
        final width = MediaQuery.of(context).size.width;
        final isSmall = width < 600;

        return Wrap(
          spacing: isSmall ? 32 : 64,
          runSpacing: 24,
          children: [
            _buildStatItem('${stats['years']}+', 'Years Experience'),
            _buildStatItem('${stats['projects']}+', 'Projects Completed'),
            _buildStatItem('${stats['skills']}+', 'Technologies Mastered'),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _getStats() async {
    try {
      final projectsList = await PortfolioFirebaseService().getProjects();
      final skillsList = await PortfolioFirebaseService().getSkills();

      int years = 0;
      final experience = _content?['experience'];
      if (experience is List && experience.isNotEmpty) {
        DateTime? earliest;
        for (var item in experience) {
          try {
            final startDate = item['startDate'];
            if (startDate != null) {
              final yearMatch = RegExp(r'\d{4}').firstMatch(startDate.toString());
              if (yearMatch != null) {
                final year = int.parse(yearMatch.group(0)!);
                final date = DateTime(year);
                if (earliest == null || date.isBefore(earliest)) {
                  earliest = date;
                }
              }
            }
          } catch (_) {}
        }
        if (earliest != null) {
          years = DateTime.now().year - earliest.year;
          if (years < 0) years = 0;
        }
      }
      if (years == 0 && experience is List && experience.isNotEmpty) {
        years = 1;
      }

      return {
        'projects': projectsList.length,
        'skills': skillsList.length,
        'years': years,
      };
    } catch (e) {
      return {'projects': 0, 'skills': 0, 'years': 0};
    }
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.displayLarge.copyWith(
            color: AppTheme.accentPrimary,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.textMuted,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final experience = _content?['experience'];
    final width = MediaQuery.of(context).size.width;
    if (experience is List && experience.isNotEmpty) {
      final items = List<Map<String, dynamic>>.from(experience);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPERIENCE',
            style: AppTheme.labelMeta.copyWith(
              color: AppTheme.accentPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'My Journey', 
            style: AppTheme.displayMedium.copyWith(
              fontSize: width < 600 ? 28 : 44,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: AppTheme.borderSubtle,
          ),
          const SizedBox(height: 48),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final it = items[index];
              return TimelineItem(
                title: _asString(it['title'] ?? it['name'], 'Untitled'),
                subtitle: _asString(it['company'] ?? it['subtitle'], ''),
                description: _asString(it['description'], ''),
                date: _asString(it['startDate'], '') +
                    (it['endDate'] != null ? ' - ${_asString(it['endDate'])}' : ''),
                color: AppTheme.accentPrimary,
                isFirst: index == 0,
                isLast: index == items.length - 1,
                isActive: index == 0,
              );
            },
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          'No experience timeline added yet.',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
