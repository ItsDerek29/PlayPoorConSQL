import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Circular progress button widget that shows progress around a button
/// Used for play/pause, next, and previous buttons
class CircularProgressButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double size;
  final String? tooltip;

  const CircularProgressButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.progress = 0.0,
    this.progressColor = const Color(0xffda1cd2),
    this.backgroundColor = Colors.transparent,
    this.size = 60.0,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: CircularPercentIndicator(
        radius: size / 2,
        lineWidth: 3.0,
        percent: progress.clamp(0.0, 1.0),
        center: IconButton(
          icon: Icon(icon),
          iconSize: size * 0.5,
          color: Colors.white,
          onPressed: onPressed,
        ),
        progressColor: progressColor,
        backgroundColor: Colors.white24,
        circularStrokeCap: CircularStrokeCap.round,
        animation: true,
        animationDuration: 100,
      ),
    );
  }
}

