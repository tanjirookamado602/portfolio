import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final bool showParticles; // Ignored in Terminal Engineer theme

  const AnimatedBackground({
    super.key,
    required this.child,
    this.showParticles = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgPrimary,
      child: child,
    );
  }
}
