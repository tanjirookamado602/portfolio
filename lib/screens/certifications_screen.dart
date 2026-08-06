import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/portfolio_firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/url_utils.dart';
import '../widgets/platform_image.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _showAll = false;
  String? _selectedCategory;

  List<String> get _categories {
    final cats = <String>{'All'};
    for (var item in _items) {
      if (item['category'] != null && item['category'].toString().isNotEmpty) {
        cats.add(item['category'].toString());
      }
    }
    return cats.toList();
  }

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
      final remoteItems = await _firebaseService.getCertifications();
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

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return _items;
    }
    return _items
        .where((item) =>
            item['category']?.toString().toLowerCase() ==
            _selectedCategory!.toLowerCase())
        .toList();
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
            if (_items.isNotEmpty) _buildCategoryFilter(),
            const SizedBox(height: 48),
            if (_items.isEmpty)
              Text(
                'No certifications found.',
                style: AppTheme.bodyMedium,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCertificationsGrid(),
                  if (_filteredItems.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
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
              ),
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
          'CREDENTIALS',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Certifications',
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

  Widget _buildCategoryFilter() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    final filterWidget = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category ||
            (_selectedCategory == null && category == 'All');

        return InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentPrimary : AppTheme.bgSurface,
              border: Border.all(
                color: isSelected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              category,
              style: AppTheme.labelMeta.copyWith(
                color: isSelected ? AppTheme.bgPrimary : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category ||
                  (_selectedCategory == null && category == 'All');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentPrimary : AppTheme.bgSurface,
                      border: Border.all(
                        color: isSelected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category,
                      style: AppTheme.labelMeta.copyWith(
                        color: isSelected ? AppTheme.bgPrimary : AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return filterWidget;
  }

  Widget _buildCertificationsGrid() {
    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    final itemCount = _showAll
        ? filteredItems.length
        : (filteredItems.length > 4 ? 4 : filteredItems.length);

    Widget buildCard(Map<String, dynamic> item) {
      final imageUrl = UrlUtils.convertDriveLink(item['imageUrl']);
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          border: Border.all(color: AppTheme.borderSubtle),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? PlatformImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.bgPrimary,
                          alignment: Alignment.center,
                          child: const Icon(Icons.school, color: AppTheme.textFaint, size: 40),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _asString(item['title'], 'Certificate'),
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _asString(item['issuer'], ''),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item['date'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _asString(item['date'], ''),
                        style: AppTheme.labelMeta.copyWith(
                          color: AppTheme.textFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final reducedMotion = MediaQuery.of(context).disableAnimations;

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 32,
          crossAxisSpacing: 32,
          childAspectRatio: 1.4,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final card = buildCard(filteredItems[index]);
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
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final card = buildCard(filteredItems[index]);
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
}
