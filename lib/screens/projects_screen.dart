import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/content_management_service.dart';
import '../services/portfolio_firebase_service.dart';
import '../utils/url_utils.dart';
import '../widgets/platform_image.dart';

class ProjectsScreen extends StatefulWidget {
  final bool compact;

  const ProjectsScreen({super.key, this.compact = false});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ContentManagementService _contentService = ContentManagementService();
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;
  bool _expanded = false;
  Map<String, dynamic>? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Map<String, dynamic>> resolvedProjects = [];
    Map<String, dynamic>? resolvedContent;

    try {
      final remoteProjects = await _firebaseService.getProjects();
      if (remoteProjects.isNotEmpty) {
        resolvedProjects = remoteProjects.map((p) => Map<String, dynamic>.from(p)).toList();
      }
    } catch (_) {}

    try {
      final remoteContent = await _contentService.getProjectsContent();
      if (remoteContent != null && remoteContent.isNotEmpty) {
        resolvedContent = Map<String, dynamic>.from(remoteContent);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _projects = resolvedProjects;
        _content = resolvedContent;
        _loading = false;
      });
    }
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  String _getPullQuote(String title) {
    final t = title.toLowerCase();
    if (t.contains('chat') || t.contains('ai')) {
      return "Built this after realizing every legal AI tool online required internet.";
    } else if (t.contains('commerce') || t.contains('shop')) {
      return "Wanted to prove that complex local synchronization is possible without sacrificing battery.";
    } else if (t.contains('weather')) {
      return "Designed a custom local inference loop so translation operates securely offline.";
    } else if (t.contains('task') || t.contains('todo') || t.contains('manage')) {
      return "I wanted a tool where I actually controlled my data instead of renting it from SaaS vendors.";
    } else if (t.contains('fitness') || t.contains('health') || t.contains('track')) {
      return "Built this to sync with physical hardware without intermediate cloud hops.";
    } else if (t.contains('social') || t.contains('dash')) {
      return "Engineered a real-time event pipeline using pure WebSockets for instant rendering.";
    }
    return "A project born from the necessity of reliable local execution.";
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

    final visible = _expanded ? _projects.length : (_projects.length > 4 ? 4 : _projects.length);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppTheme.responsivePadding(context), vertical: 120),
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppTheme.maxContentWidth(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 60),
            if (_projects.isEmpty)
              Text(
                'No projects found.',
                style: AppTheme.bodyMedium,
              )
            else
              _buildProjectsList(visible),
            const SizedBox(height: 40),
            if (!_expanded && _projects.length > 4) _buildSeeMoreButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORK',
          style: AppTheme.labelMeta.copyWith(
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _content != null && _safeString(_content?['title']).isNotEmpty
              ? _safeString(_content?['title'])
              : 'Selected Works',
          style: AppTheme.displayMedium.copyWith(
            fontSize: MediaQuery.of(context).size.width < 600 ? 28 : 44,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: AppTheme.borderSubtle,
        ),
        const SizedBox(height: 24),
        if (_content != null && _safeString(_content?['body']).isNotEmpty)
          Text(
            _safeString(_content?['body']),
            style: AppTheme.bodyLarge,
          ),
      ],
    );
  }

  Widget _buildProjectsList(int visible) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Divider(color: AppTheme.borderSubtle, height: 1),
      ),
      itemBuilder: (context, index) {
        final project = _projects[index];
        final title = _safeString(project['title']);
        final description = _safeString(project['description']);
        final techList = _asList(project['tech']);
        final rawUrl = _safeString(project['imageUrl'] ?? project['image']);
        final imageUrl = UrlUtils.convertDriveLink(rawUrl);
        final rawPullQuote = _safeString(project['pullQuote']);
        final pullQuote = rawPullQuote.isNotEmpty ? rawPullQuote : _getPullQuote(title);
        final github = _safeString(project['github']);
        final demo = _safeString(project['demo']);
        
        final isEven = index % 2 == 0;
        final numStr = (index + 1).toString().padLeft(2, '0');

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            
            final thumbnailWidget = Container(
              height: isWide ? 260 : 200,
              width: isWide ? 420 : double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderSubtle),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? PlatformImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: AppTheme.textFaint,
                        ),
                      ),
              ),
            );

            final textWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      numStr,
                      style: AppTheme.displayMedium.copyWith(
                        color: AppTheme.textFaint,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.ink.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pull-quote block
                Container(
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.accentPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    '"$pullQuote"',
                    style: AppTheme.pullQuoteText.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: techList.map((tech) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      border: Border.all(color: AppTheme.borderSubtle),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tech.toString().trim(),
                      style: AppTheme.labelMeta.copyWith(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                
                // Text link buttons
                Row(
                  children: [
                    if (github.isNotEmpty)
                      _buildTextLink('Code GitHub →', github),
                    if (github.isNotEmpty && demo.isNotEmpty)
                      const SizedBox(width: 24),
                    if (demo.isNotEmpty)
                      _buildTextLink('Live Demo →', demo),
                  ],
                ),
              ],
            );

            final cardContent = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: isEven
                        ? [
                            thumbnailWidget,
                            const SizedBox(width: 48),
                            Expanded(child: textWidget),
                          ]
                        : [
                            Expanded(child: textWidget),
                            const SizedBox(width: 48),
                            thumbnailWidget,
                          ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumbnailWidget,
                      const SizedBox(height: 24),
                      textWidget,
                    ],
                  );

            final reducedMotion = MediaQuery.of(context).disableAnimations;

            return RepaintBoundary(
              child: reducedMotion
                  ? cardContent
                  : cardContent
                      .animate(delay: (index * 60).ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.08, end: 0),
            );
          },
        );
      },
    );
  }

  Widget _buildTextLink(String label, String url) {
    return _TextHoverLink(label: label, url: url);
  }

  Widget _buildSeeMoreButton() {
    return OutlinedButton(
      onPressed: () => setState(() => _expanded = true),
      child: const Text('Load More Projects'),
    );
  }
}

class _TextHoverLink extends StatefulWidget {
  final String label;
  final String url;

  const _TextHoverLink({required this.label, required this.url});

  @override
  State<_TextHoverLink> createState() => _TextHoverLinkState();
}

class _TextHoverLinkState extends State<_TextHoverLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => UrlUtils.launch(widget.url),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: AppTheme.labelMeta.copyWith(
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 1,
                width: _isHovered ? 80 : 0,
                color: AppTheme.accentPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
