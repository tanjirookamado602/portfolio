import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TypingAnimation extends StatefulWidget {
  final List<String> texts;
  final TextStyle? textStyle;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Duration deleteSpeed;

  const TypingAnimation({
    super.key,
    required this.texts,
    this.textStyle,
    this.typingSpeed = const Duration(milliseconds: 40),
    this.pauseDuration = const Duration(milliseconds: 2000),
    this.deleteSpeed = const Duration(milliseconds: 20),
  });

  @override
  State<TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cursorAnimation;

  int _currentTextIndex = 0;
  int _currentCharIndex = 0;
  bool _isDeleting = false;
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _cursorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _startTyping();
  }

  void _startTyping() {
    if (widget.texts.isEmpty) return;

    Future.delayed(widget.typingSpeed, () {
      if (!mounted) return;

      setState(() {
        if (!_isDeleting) {
          if (_currentCharIndex < widget.texts[_currentTextIndex].length) {
            _displayText = widget.texts[_currentTextIndex]
                .substring(0, _currentCharIndex + 1);
            _currentCharIndex++;
          } else {
            // Finished typing, wait then start deleting
            Future.delayed(widget.pauseDuration, () {
              if (mounted) {
                setState(() => _isDeleting = true);
                _startTyping();
              }
            });
            return;
          }
        } else {
          if (_currentCharIndex > 0) {
            _currentCharIndex--;
            _displayText =
                widget.texts[_currentTextIndex].substring(0, _currentCharIndex);
          } else {
            // Finished deleting, move to next text
            _isDeleting = false;
            _currentTextIndex = (_currentTextIndex + 1) % widget.texts.length;
          }
        }
      });

      _startTyping();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cursorAnimation,
      builder: (context, child) {
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _displayText,
                style: widget.textStyle ?? AppTheme.displayMedium,
              ),
              TextSpan(
                text: '█',
                style: (widget.textStyle ?? AppTheme.displayMedium).copyWith(
                  color: AppTheme.accentPrimary.withOpacity(_cursorAnimation.value > 0.5 ? 1 : 0),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
