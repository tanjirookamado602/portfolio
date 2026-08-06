import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlowButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon; // Mostly ignored or handled simply
  final Color? glowColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;

  const GlowButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.glowColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // In Terminal mode, "GlowButton" is just an accented flat button
    final color = widget.backgroundColor ?? AppTheme.accentPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? color.withOpacity(0.1) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isHovered ? color : AppTheme.borderSubtle,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 18, color: _isHovered ? color : AppTheme.textMuted),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: AppTheme.labelMeta.copyWith(
                            color: _isHovered ? color : AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
