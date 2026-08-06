import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class SkillBadge extends StatefulWidget {
  final String title;
  final String? description;
  final String? icon;
  final double proficiency;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;

  const SkillBadge({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.proficiency = 0.0,
    this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<SkillBadge> createState() => _SkillBadgeState();
}

class _SkillBadgeState extends State<SkillBadge>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.proficiency,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    // Start the fill animation after a small delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // Map skill names to icons
  IconData _getSkillIcon(String title) {
    final t = title.toLowerCase().trim();
    if (t.contains('flutter')) return Icons.phone_android;
    if (t.contains('dart')) return Icons.code;
    if (t.contains('firebase')) return Icons.cloud;
    if (t.contains('sqlite')) return Icons.storage;
    if (t.contains('bloc')) return Icons.account_tree;
    if (t.contains('provider')) return Icons.settings_input_component;
    if (t.contains('riverpod')) return Icons.water_drop;
    if (t.contains('rest') || t.contains('api')) return Icons.api;
    if (t.contains('git')) return Icons.merge_type;
    if (t.contains('html') || t.contains('css') || t.contains('javascript')) return Icons.language;
    if (t.contains('react')) return Icons.web;
    if (t.contains('python')) return Icons.terminal;
    if (t.contains('java')) return Icons.coffee;
    if (t.contains('swift')) return Icons.apple;
    if (t.contains('kotlin')) return Icons.android;
    if (t.contains('figma') || t.contains('design')) return Icons.design_services;
    if (t.contains('docker')) return Icons.inventory_2;
    if (t.contains('aws') || t.contains('cloud')) return Icons.cloud_circle;
    if (t.contains('sql') || t.contains('database')) return Icons.dns;
    if (t.contains('node')) return Icons.hub;
    if (t.contains('llm') || t.contains('ai') || t.contains('ml')) return Icons.psychology;
    if (t.contains('getx')) return Icons.flash_on;
    if (t.contains('mvvm') || t.contains('mvc') || t.contains('architecture')) return Icons.architecture;
    return Icons.code;
  }

  @override
  Widget build(BuildContext context) {
    final skillColor = widget.color ?? AppTheme.accentPrimary;
    final percent = (widget.proficiency * 100).toInt();

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          transform: _isHovering
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.bgSurface
                : AppTheme.bgPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovering
                  ? skillColor.withOpacity(0.3)
                  : AppTheme.borderSubtle.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: skillColor.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Circular progress ring
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 52,
                    height: 52,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: _progressAnimation.value,
                        progressColor: skillColor,
                        trackColor: AppTheme.borderSubtle.withOpacity(0.4),
                        strokeWidth: 3.5,
                        isHovering: _isHovering,
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTheme.labelMeta.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isHovering
                                ? skillColor
                                : AppTheme.ink.withOpacity(0.7),
                          ),
                          child: Text('$percent%'),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Skill name + icon
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: 15,
                        color: _isHovering
                            ? AppTheme.ink
                            : AppTheme.ink.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      child: Text(widget.title),
                    ),
                  ],
                ),
              ),
              // Icon on the right
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isHovering
                      ? skillColor.withOpacity(0.1)
                      : AppTheme.bgSurface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getSkillIcon(widget.title),
                  size: 20,
                  color: _isHovering
                      ? skillColor
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the circular progress ring
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;
  final bool isHovering;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.isHovering,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovering ? strokeWidth + 0.5 : strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Draw a small dot at the end of the progress arc
    if (progress > 0.02) {
      final endAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final dotPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, isHovering ? 3.5 : 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isHovering != isHovering;
  }
}
