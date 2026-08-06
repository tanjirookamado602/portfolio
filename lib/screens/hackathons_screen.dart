import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/portfolio_firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HackathonsScreen extends StatefulWidget {
  const HackathonsScreen({super.key});

  @override
  State<HackathonsScreen> createState() => _HackathonsScreenState();
}

class _HackathonsScreenState extends State<HackathonsScreen> {
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  List<Map<String, dynamic>> _items = [];
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
    return value.toString();
  }

  String _asString(dynamic v, [String? fb]) {
    if (v == null) return fb ?? '';
    return _safeString(v);
  }

  Future<void> _loadContent() async {
    List<Map<String, dynamic>> resolved = [];

    try {
      final remoteItems = await _firebaseService.getHackathons();
      if (remoteItems.isNotEmpty) {
        resolved = remoteItems
            .map((e) => _sanitizeMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _items = resolved;
        _loading = false;
      });
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
            if (_items.isEmpty)
              Text(
                'No hackathons listed yet.',
                style: AppTheme.bodyMedium,
              )
            else
              _buildHackathonsGrid(),
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
          'COMPETITIONS',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hackathons',
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

  Widget _buildHackathonsGrid() {
    final width = MediaQuery.of(context).size.width;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (c, i) => const SizedBox(height: 32),
      itemBuilder: (context, index) {
        final item = _items[index];
        final eventName = _asString(item['event'], item['title']);
        final projectTitle = item['event'] != null ? _asString(item['title'], '') : '';
        final description = _asString(item['description'], item['short']);
        final achievement = _asString(item['achievement'], '');
        final date = _asString(item['date'], '');
        final role = _asString(item['role'], '');
        final link = _asString(item['link'], '');
        final linkText = _asString(item['linkText'], 'View Details');

        final reducedMotion = MediaQuery.of(context).disableAnimations;

        final card = Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            border: Border.all(color: AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (width < 600) ...[
                Text(
                  eventName,
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTheme.labelMeta.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        eventName,
                        style: AppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: AppTheme.labelMeta.copyWith(color: AppTheme.textMuted),
                      ),
                  ],
                ),
              if (projectTitle.isNotEmpty || achievement.isNotEmpty || role.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (projectTitle.isNotEmpty)
                      Text(
                        projectTitle,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.accentPrimary,
                        ),
                      ),
                    if (achievement.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgPrimary,
                          border: Border.all(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          achievement,
                          style: AppTheme.labelMeta.copyWith(
                            color: AppTheme.accentSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (role.isNotEmpty)
                      Text(
                        role,
                        style: AppTheme.labelMeta.copyWith(color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (description.isNotEmpty)
                Text(
                  description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.ink.withOpacity(0.8),
                  ),
                ),
              if (link.isNotEmpty) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () async {
                    final uri = Uri.parse(link);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(linkText.isNotEmpty ? linkText : 'View Details'),
                ),
              ],
            ],
          ),
        );

        return RepaintBoundary(
          child: reducedMotion
              ? card
              : card
                  .animate(delay: (index * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0),
        );
      },
    );
  }
}
