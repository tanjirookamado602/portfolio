import 'dart:async';
import 'package:flutter/material.dart';

/// Simple entrance animation for sections: fades in and slides up.
class SectionEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const SectionEntrance({super.key, required this.child, this.delayMs = 80});

  @override
  State<SectionEntrance> createState() => _SectionEntranceState();
}

class _SectionEntranceState extends State<SectionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // small delayed entrance for a nicer stagger
    Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
