import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/content_management_service.dart';
import '../services/portfolio_firebase_service.dart';
import '../widgets/timeline_item.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  final ContentManagementService _contentService = ContentManagementService();
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _impactPeople;
  String? _impactHours;
  String? _impactEvents;
  bool _showAll = false;

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
      } else {
        sanitized[key] = value.toString();
      }
    });
    return sanitized;
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _asString(dynamic v, [String? fb]) {
    if (v == null) return fb ?? '';
    return _safeString(v);
  }

  Future<void> _loadContent() async {
    try {
      final content = await _contentService.getVolunteerContent();
      final items = await _firebaseService.getVolunteerExperience();
      if (items.isNotEmpty) {
        if (mounted) {
          setState(() {
            _items = items.map((e) => _sanitizeMap(e)).toList();
            _loading = false;
          });
        }
        return;
      }
      if (content != null && content['volunteer'] is Map) {
        final vol = content['volunteer'] as Map<String, dynamic>;
        if (vol['volunteer'] is List) {
          setState(() => _items = List<Map<String, dynamic>>.from(vol['volunteer']));
        }
        final impact = vol['impact'];
        if (impact is Map<String, dynamic>) {
          _impactPeople = impact['people']?.toString();
          _impactHours = impact['hours']?.toString();
          _impactEvents = impact['events']?.toString();
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
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
            _buildVolunteerContent(),
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
          'VOLUNTEER',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Community Impact',
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

  Widget _buildVolunteerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I believe in the power of community and giving back. Through various volunteer roles and community initiatives, I\'ve had the opportunity to make a positive impact and help others grow in their tech journey.',
          style: AppTheme.bodyLarge,
        ),
        const SizedBox(height: 48),
        _buildImpactMetrics(),
      ],
    );
  }

  Widget _buildImpactMetrics() {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 600;
    return Wrap(
      spacing: isSmall ? 32 : 64,
      runSpacing: 24,
      children: [
        _buildMetricItem(_impactPeople ?? '500+', 'People Helped'),
        _buildMetricItem(_impactHours ?? '50+', 'Hours Volunteered'),
        _buildMetricItem(_impactEvents ?? '10+', 'Events Organized'),
      ],
    );
  }

  Widget _buildMetricItem(String value, String label) {
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
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIMELINE',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Involvement', 
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
        if (_items.isEmpty)
          Text(
            'No volunteer experience added yet.',
            style: AppTheme.bodyMedium,
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _showAll ? _items.length : (_items.length > 4 ? 4 : _items.length),
            separatorBuilder: (c, i) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final item = _items[index];
              final reducedMotion = MediaQuery.of(context).disableAnimations;
              final timelineWidget = TimelineItem(
                title: _asString(item['title'], 'Volunteer Role'),
                subtitle: _asString(item['organization'], 'Community Organization'),
                description: _asString(item['description'], 'Volunteer work description'),
                date: _asString(item['date'], '2023'),
                color: AppTheme.accentPrimary,
                isFirst: index == 0,
                isLast: index == _items.length - 1,
                isActive: item['ongoing'] == true,
              );

              return RepaintBoundary(
                child: reducedMotion
                    ? timelineWidget
                    : timelineWidget
                        .animate(delay: (index * 60).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0),
              );
            },
          ),
          if (_items.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentPrimary,
                  textStyle: AppTheme.labelMeta,
                ),
                child: Text(_showAll ? 'Show Less' : 'Show More'),
              ),
            ),
        ],
      ],
    );
  }
}
