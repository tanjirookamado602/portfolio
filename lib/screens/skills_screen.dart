import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/portfolio_firebase_service.dart';
import '../widgets/skill_badge.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
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

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }

  String _asString(dynamic v, [String? fb]) {
    if (v == null) return fb ?? '';
    return _safeString(v);
  }

  Future<void> _loadContent() async {
    try {
      final remoteSkills = await _firebaseService.getSkills();
      if (mounted) {
        setState(() {
          _items = remoteSkills
              .map((e) =>
                  _normalizeSkillItem(Map<String, dynamic>.from(e)))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _normalizeSkillItem(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    out['name'] = _safeString(out['name']);
    out['category'] = _safeString(out['category']);

    try {
      var p = out['proficiency'];
      if (p == null && out.containsKey('percent')) {
        p = out['percent'];
      }
      double val = 0.0;
      if (p is num) {
        val = p.toDouble();
      } else if (p is String) {
        final parsed = double.tryParse(p);
        if (parsed != null) val = parsed;
      }
      if (val > 1.0) val = (val / 100.0).clamp(0.0, 1.0);
      out['proficiency'] = val.clamp(0.0, 1.0);
    } catch (_) {
      out['proficiency'] = 0.0;
    }

    return out;
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

  String _skillTitle(Map<String, dynamic> item) {
    final v = _asString(
        item['name'] ?? item['title'] ?? item['label'], 'Unnamed skill');
    return v.trim().isEmpty ? 'Unnamed skill' : v.trim();
  }

  // Map category names to icons
  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase().trim();
    if (c.contains('mobile')) return Icons.smartphone;
    if (c.contains('backend')) return Icons.dns;
    if (c.contains('state')) return Icons.account_tree;
    if (c.contains('web')) return Icons.language;
    if (c.contains('tool')) return Icons.build;
    if (c.contains('database')) return Icons.storage;
    if (c.contains('design')) return Icons.palette;
    if (c.contains('devops')) return Icons.cloud_sync;
    if (c.contains('ai') || c.contains('ml')) return Icons.psychology;
    return Icons.category;
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
        constraints:
            BoxConstraints(maxWidth: AppTheme.maxContentWidth(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 48),
            if (_items.isNotEmpty) _buildCategoryFilter(),
            const SizedBox(height: 48),
            if (_items.isEmpty)
              Text(
                'No skills found.',
                style: AppTheme.bodyMedium,
              )
            else
              _buildSkillsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILLS & EXPERTISE',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Technologies and tools',
          style: AppTheme.displayMedium.copyWith(
            fontSize: width < 600 ? 28 : 44,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: width < 600 ? 200 : 300,
          child: Text(
            'A curated overview of the technologies I work with daily to build production-ready applications.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );

    if (reducedMotion) return header;
    return header
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }

  Widget _buildCategoryFilter() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    Widget buildChip(String category) {
      final isSelected = _selectedCategory == category ||
          (_selectedCategory == null && category == 'All');

      return Padding(
        padding: EdgeInsets.only(right: isMobile ? 8 : 10),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentPrimary
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.borderSubtle,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category != 'All') ...[
                  Icon(
                    _getCategoryIcon(category),
                    size: 14,
                    color: isSelected
                        ? AppTheme.bgPrimary
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  category,
                  style: AppTheme.labelMeta.copyWith(
                    color: isSelected
                        ? AppTheme.bgPrimary
                        : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final chipList = _categories.map((c) => buildChip(c)).toList();

    Widget filterRow;
    if (isMobile) {
      filterRow = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chipList),
      );
    } else {
      filterRow = Wrap(
        spacing: 0,
        runSpacing: 10,
        children: chipList,
      );
    }

    if (reducedMotion) return filterRow;
    return filterRow
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms);
  }

  Widget _buildSkillsGrid() {
    final filteredItems = _filteredItems;
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final width = MediaQuery.of(context).size.width;

    // Determine column count based on screen width
    int crossAxisCount;
    if (width >= 1200) {
      crossAxisCount = 3;
    } else if (width >= 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final isSpecificCategory =
        _selectedCategory != null && _selectedCategory != 'All';

    if (isSpecificCategory) {
      // Show flat grid for specific category
      return _buildResponsiveGrid(
        items: filteredItems,
        crossAxisCount: crossAxisCount,
        reducedMotion: reducedMotion,
        startIndex: 0,
      );
    }

    // Group by category
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var item in filteredItems) {
      final cat = _asString(item['category'], 'Other');
      groups.putIfAbsent(cat, () => []).add(item);
    }

    int globalIdx = 0;
    final categoryWidgets = <Widget>[];

    groups.forEach((category, items) {
      if (items.isEmpty) return;

      final categoryHeader = Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category),
                size: 20,
                color: AppTheme.accentPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: AppTheme.labelMeta.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${items.length} ${items.length == 1 ? 'skill' : 'skills'}',
                    style: AppTheme.labelMeta.copyWith(
                      fontSize: 12,
                      color: AppTheme.textMuted.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              width: 60,
              color: AppTheme.borderSubtle.withOpacity(0.5),
            ),
          ],
        ),
      );

      Widget headerWidget;
      if (reducedMotion) {
        headerWidget = categoryHeader;
      } else {
        headerWidget = categoryHeader
            .animate(delay: (globalIdx * 60).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.03, end: 0, duration: 400.ms);
      }

      categoryWidgets.add(headerWidget);
      categoryWidgets.add(
        _buildResponsiveGrid(
          items: items,
          crossAxisCount: crossAxisCount,
          reducedMotion: reducedMotion,
          startIndex: globalIdx,
        ),
      );
      categoryWidgets.add(const SizedBox(height: 36));

      globalIdx += items.length;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryWidgets,
    );
  }

  Widget _buildResponsiveGrid({
    required List<Map<String, dynamic>> items,
    required int crossAxisCount,
    required bool reducedMotion,
    required int startIndex,
  }) {
    // Build rows manually for a clean grid
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += crossAxisCount) {
      final rowItems = <Widget>[];
      for (int j = 0; j < crossAxisCount; j++) {
        if (i + j < items.length) {
          final item = items[i + j];
          final proficiency = (item['proficiency'] ?? 0.0).toDouble();
          final badge = SkillBadge(
            title: _skillTitle(item),
            proficiency: proficiency,
          );

          Widget animatedBadge;
          if (reducedMotion) {
            animatedBadge = badge;
          } else {
            animatedBadge = RepaintBoundary(
              child: badge
                  .animate(delay: ((startIndex + i + j) * 60).ms)
                  .fadeIn(duration: 450.ms)
                  .slideY(begin: 0.06, end: 0, duration: 450.ms),
            );
          }

          rowItems.add(
            Expanded(child: Padding(
              padding: EdgeInsets.only(
                right: j < crossAxisCount - 1 ? 12 : 0,
              ),
              child: animatedBadge,
            )),
          );
        } else {
          // Empty spacer for incomplete rows
          rowItems.add(const Expanded(child: SizedBox()));
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowItems,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
