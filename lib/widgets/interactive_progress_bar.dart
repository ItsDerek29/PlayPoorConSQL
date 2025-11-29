import 'package:flutter/material.dart';
import '../utils/duration_formatter.dart';


class InteractiveProgressBar extends StatefulWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final Color progressColor;
  final Function(Duration) onSeek;

  const InteractiveProgressBar({
    Key? key,
    required this.progress,
    required this.position,
    required this.duration,
    required this.progressColor,
    required this.onSeek,
  }) : super(key: key);

  @override
  _InteractiveProgressBarState createState() => _InteractiveProgressBarState();
}

class _InteractiveProgressBarState extends State<InteractiveProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final progress = _isDragging ? _dragValue : widget.progress;

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.progressColor.withOpacity(0.8),
            inactiveTrackColor: Colors.white24,
            thumbColor: widget.progressColor,
            overlayColor: widget.progressColor.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 2.0,
          ),
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onHorizontalDragUpdate: (details) {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final double width = box.size.width;
                final double dx = details.localPosition.dx;
                final double newProgress = (dx / width).clamp(0.0, 1.0);
                setState(() {
                  _dragValue = newProgress;
                });
              }
            },
            onHorizontalDragEnd: (_) {
              final Duration newPosition = Duration(
                milliseconds: (widget.duration.inMilliseconds * _dragValue).round(),
              );
              widget.onSeek(newPosition);
              setState(() {
                _isDragging = false;
              });
            },
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                setState(() {
                  _isDragging = true;
                  _dragValue = value;
                });
                final Duration newPosition = Duration(
                  milliseconds: (widget.duration.inMilliseconds * value).round(),
                );
                widget.onSeek(newPosition);
                setState(() {
                  _isDragging = false;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DurationFormatter.format(_isDragging 
                  ? Duration(milliseconds: (widget.duration.inMilliseconds * _dragValue).round())
                  : widget.position),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                DurationFormatter.format(widget.duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
