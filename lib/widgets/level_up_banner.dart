// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';

class LevelUpBanner extends StatefulWidget {
  final int newLevel;
  final String skillName;
  final String skillEmoji;
  final Color skillColor;
  final double newProgress;
  final VoidCallback onDismiss;

  const LevelUpBanner({
    super.key,
    required this.newLevel,
    required this.skillName,
    required this.skillEmoji,
    required this.skillColor,
    required this.newProgress,
    required this.onDismiss,
  });

  static void show(
    OverlayState overlay, {
    required int newLevel,
    required String skillName,
    required String skillEmoji,
    required Color skillColor,
    required double newProgress,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => LevelUpBanner(
        newLevel: newLevel,
        skillName: skillName,
        skillEmoji: skillEmoji,
        skillColor: skillColor,
        newProgress: newProgress,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<LevelUpBanner> createState() => _LevelUpBannerState();
}

class _LevelUpBannerState extends State<LevelUpBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 0.0–0.075 (300ms): slide in easeOut
    // 0.075–0.925 (3400ms): visible
    // 0.925–1.0 (300ms): slide out easeIn
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 7.5,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 85.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -1),
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 7.5,
      ),
    ]).animate(_controller);

    // 0.075–0.25 (700ms): ring animates from 1.0 down to newProgress
    _ringAnimation = Tween<double>(
      begin: 1.0,
      end: widget.newProgress,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.075, 0.25, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final goldColor =
        isDark ? const Color(0xFFFFD700) : const Color(0xFFB8860B);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: IgnorePointer(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Color.lerp(Theme.of(context).colorScheme.surface, widget.skillColor, 0.2) ?? Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface,
                        ]
                      : [
                          Color.lerp(Theme.of(context).colorScheme.surface, widget.skillColor, 0.1) ?? Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.skillColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.skillColor.withOpacity(isDark ? 0.4 : 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    widget.skillEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Level ${widget.newLevel}!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: goldColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: goldColor,
                            ),
                          ],
                        ),
                        Text(
                          widget.skillName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _ringAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _RingPainter(
                            progress: _ringAnimation.value,
                            color: widget.skillColor,
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            strokeWidth: 4,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.newLevel}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                          ),
                        );
                      },
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

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
