import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/core/app_theme.dart';

class WaveformBars extends StatefulWidget {
  final bool isPlaying;

  const WaveformBars({super.key, required this.isPlaying});

  @override
  State<WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant WaveformBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(12, (index) {
              final progress = _ctrl.value;
              final offset = (index / 12.0) * 2 * math.pi;
              final wave = widget.isPlaying
                  ? (math.sin(progress * 2 * math.pi + offset).abs() * 0.75 +
                        0.25)
                  : 0.2;
              final barHeight = 6.0 + (wave * 26.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? kAmber.withValues(alpha: 0.6 + (wave * 0.4))
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
