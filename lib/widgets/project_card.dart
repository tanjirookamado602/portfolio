import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import '../utils/url_utils.dart';
import 'platform_image.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final bool compact;

  const ProjectCard({
    super.key,
    required this.project,
    this.compact = false,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isHovered = false;

  bool get _isMobileProject {
    final tech = widget.project.tech.map((e) => e.toLowerCase()).toList();
    return tech.contains('flutter') ||
        tech.contains('android') ||
        tech.contains('ios');
  }

  bool get _isWebProject {
    final tech = widget.project.tech.map((e) => e.toLowerCase()).toList();
    return tech.contains('react') ||
        tech.contains('vue') ||
        tech.contains('web') ||
        tech.contains('html');
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isHovered ? AppTheme.accentPrimary : AppTheme.borderSubtle,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              _buildImageSection(widget.project),
              // Content Section
              Expanded(
                child: _buildContentSection(widget.project, widget.compact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(Project project) {
    final imageUrl = UrlUtils.convertDriveLink(project.image);
    final hasValidImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 1)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          hasValidImage
              ? PlatformImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                )
              : _buildPlaceholder(),

          // Overlay container to ensure text is readable
          Container(
            color: AppTheme.bgPrimary.withOpacity(0.4),
          ),

          // Monospace Category Tag
          if (!widget.compact)
            Positioned(
              top: 12,
              right: 12,
              child: _buildTypeBadge(),
            ),

          // Action buttons overlay
          if (!widget.compact)
            Positioned(
              bottom: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (project.github != null && project.github!.isNotEmpty)
                    _buildActionButton(
                      label: '[ CODE ]',
                      onPressed: () => _openUrl(project.github),
                    ),
                  if (project.github != null &&
                      project.github!.isNotEmpty &&
                      project.demo != null &&
                      project.demo!.isNotEmpty)
                    const SizedBox(width: 8),
                  if (project.demo != null && project.demo!.isNotEmpty)
                    _buildActionButton(
                      label: '[ DEMO ]',
                      isPrimary: true,
                      onPressed: () => _openUrl(project.demo),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.bgSurfaceElevated,
      child: const Center(
        child: Icon(
          Icons.terminal,
          size: 48,
          color: AppTheme.borderSubtle,
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    String label;

    if (_isMobileProject) {
      label = '[ MOBILE ]';
    } else if (_isWebProject) {
      label = '[ WEB ]';
    } else {
      label = '[ PROJECT ]';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.borderSubtle),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTheme.labelMeta,
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.accentPrimary.withOpacity(0.1) : AppTheme.bgSurface,
            border: Border.all(color: isPrimary ? AppTheme.accentPrimary : AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: AppTheme.labelMeta.copyWith(
              color: isPrimary ? AppTheme.accentPrimary : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(Project project, bool compact) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            project.title,
            style: AppTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            project.description,
            style: AppTheme.bodyMedium,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Tech stack
          if (!compact && project.tech.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.tech.take(3).map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderSubtle),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tech,
                    style: AppTheme.labelMeta.copyWith(fontSize: 11),
                  ),
                );
              }).toList(),
            ),

          if (!compact && project.tech.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${project.tech.length - 3} more',
                style: AppTheme.labelMeta,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
