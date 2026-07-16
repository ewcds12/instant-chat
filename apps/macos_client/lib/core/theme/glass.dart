import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class LiquidGradientBackground extends StatelessWidget {
  const LiquidGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RetroColors.canvasTop, RetroColors.canvasBottom],
        ),
      ),
      child: child,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = RetroMetrics.cornerLarge,
    this.tint = RetroColors.glass,
    this.borderColor = RetroColors.hairline,
    this.blurSigma = 22,
    this.shadows = const [
      BoxShadow(
        color: Color(0x140F172A),
        blurRadius: 30,
        offset: Offset(0, 16),
      ),
    ],
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;
  final Color borderColor;
  final double blurSigma;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadows,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
