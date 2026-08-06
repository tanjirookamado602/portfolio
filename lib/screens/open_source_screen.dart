import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/content_management_service.dart';
import '../services/portfolio_firebase_service.dart';
import '../utils/url_utils.dart';

class OpenSourceScreen extends StatefulWidget {
  const OpenSourceScreen({super.key});

  @override
  State<OpenSourceScreen> createState() => _OpenSourceScreenState();
}

class _OpenSourceScreenState extends State<OpenSourceScreen> {
  final ContentManagementService _contentService = ContentManagementService();
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  Map<String, dynamic>? _sectionContent;
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
      final content = await _contentService.getOpenSourceContent();
      final items = await _firebaseService.getOpenSourceContributions();
      if (mounted) {
        setState(() {
          _sectionContent = content;
          _items = items.map((e) => _sanitizeMap(e)).toList();
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
        height: 300,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    final title = _asString(_sectionContent?['title'], 'Open Source Contributions');
    final description = _asString(_sectionContent?['description'], 'Merged pull requests and contributions to public repositories');

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
            _buildHeader(title, description),
            const SizedBox(height: 48),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Open source contributions coming soon.',
                  style: AppTheme.bodyMedium,
                ),
              )
            else
              _buildContributionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String description) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPEN SOURCE',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTheme.displayMedium.copyWith(
            fontSize: width < 600 ? 28 : 44,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textMuted),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: AppTheme.borderSubtle,
        ),
      ],
    );
  }

  Widget _buildContributionsList() {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (context, index) => Container(
        height: 1,
        color: AppTheme.borderSubtle,
      ),
      itemBuilder: (context, index) {
        final item = _items[index];
        final repoName = _asString(item['repoName'], 'Repository');
        final itemDesc = _asString(item['description'], '');
        final prLink = _asString(item['prLink'], '');
        final countStr = _asString(item['mergedPrCount'], '');
        final List<String> tags = List<String>.from(item['tags'] ?? []);

        final rowWidget = Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          repoName,
                          style: AppTheme.displayMedium.copyWith(
                            fontSize: 22,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      if (countStr.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            border: Border.all(color: AppTheme.borderSubtle),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$countStr merged PRs',
                            style: AppTheme.labelMeta.copyWith(
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (itemDesc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      itemDesc,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.ink.withOpacity(0.85),
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          border: Border.all(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              );

              final actionButton = prLink.isNotEmpty
                  ? InkWell(
                      onTap: () => UrlUtils.launch(prLink),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Merged PRs',
                              style: AppTheme.labelMeta.copyWith(
                                color: AppTheme.accentPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppTheme.accentPrimary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink();

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 32),
                    actionButton,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    actionButton,
                  ],
                );
              }
            },
          ),
        );

        return RepaintBoundary(
          child: reducedMotion
              ? rowWidget
              : rowWidget
                  .animate(delay: (index * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0),
        );
      },
    );
  }
}
