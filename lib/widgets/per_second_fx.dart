import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 每秒收入跳动：光环扩散、火花甩出，金额往上飘。
class PerSecondFx extends StatefulWidget {
  const PerSecondFx({
    super.key,
    required this.text,
    required this.burstText,
    required this.active,
    required this.tick,
    required this.color,
    required this.accent,
    this.fontSize = 40,
    this.compact = false,
  });

  final String text;
  final String burstText;
  final bool active;
  final int tick;
  final Color color;
  final Color accent;
  final double fontSize;
  final bool compact;

  @override
  State<PerSecondFx> createState() => _PerSecondFxState();
}

class _PerSecondFxState extends State<PerSecondFx>
    with TickerProviderStateMixin {
  late final AnimationController _burst;
  late final AnimationController _ambient;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduceMotion) {
      _syncAmbient();
      return;
    }
    _reduceMotion = reduce;
    _syncAmbient();
  }

  @override
  void didUpdateWidget(PerSecondFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAmbient();
    if (!_reduceMotion && widget.active && oldWidget.tick != widget.tick) {
      _burst.forward(from: 0);
    }
  }

  void _syncAmbient() {
    final shouldRun = widget.active && !_reduceMotion;
    if (shouldRun && !_ambient.isAnimating) {
      _ambient.repeat();
    } else if (!shouldRun && _ambient.isAnimating) {
      _ambient.stop();
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return _amountText(glow: 0);
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_burst, _ambient]),
      builder: (context, _) {
        final bursting = _burst.isAnimating;
        final burst = bursting ? _burst.value : 0.0;
        final scale = bursting ? 1 + 0.08 * math.sin(burst * math.pi) : 1.0;
        final height = widget.compact ? 52.0 : 74.0;
        return SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _EnergyPainter(
                    burst: burst,
                    orbit: _ambient.value,
                    active: widget.active,
                    accent: widget.accent,
                    compact: widget.compact,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.scale(
                  alignment: Alignment.centerLeft,
                  scale: scale,
                  child: _amountText(glow: bursting ? 1 - burst : 0.35),
                ),
              ),
              if (bursting)
                for (var index = 0; index < (widget.compact ? 2 : 3); index++)
                  _floatingGain(index, burst),
            ],
          ),
        );
      },
    );
  }

  Widget _amountText({required double glow}) {
    final style = TextStyle(
      color: widget.color,
      fontSize: widget.fontSize,
      height: 1.1,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: widget.active
          ? [
              Shadow(
                color: widget.accent.withValues(alpha: 0.85 * glow.clamp(0, 1)),
                blurRadius: widget.compact ? 10 : 16,
              ),
            ]
          : null,
    );
    final text = Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: style,
    );
    if (!widget.active || _reduceMotion) {
      return text;
    }
    final shift = _ambient.value;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-1.2 + shift * 2.4, -0.2),
          end: Alignment(-0.2 + shift * 2.4, 0.6),
          colors: [widget.color, Colors.white, widget.accent, widget.color],
        ).createShader(bounds);
      },
      child: text,
    );
  }

  Widget _floatingGain(int index, double burst) {
    final rise = (widget.compact ? 22.0 : 40.0) + index * 8;
    final drift = math.sin((index + 1) * 1.8) * (widget.compact ? 8 : 16);
    final opacity = (1 - Curves.easeIn.transform(burst)).clamp(0.0, 1.0);
    return Positioned(
      left:
          (widget.compact ? 8.0 : 18.0) +
          index * (widget.compact ? 48 : 86) +
          drift * burst,
      bottom: 6 + rise * burst,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Text(
            widget.burstText,
            style: TextStyle(
              color: widget.accent,
              fontSize: widget.compact ? 11 : 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: [
                Shadow(
                  color: widget.accent.withValues(alpha: 0.9),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnergyPainter extends CustomPainter {
  const _EnergyPainter({
    required this.burst,
    required this.orbit,
    required this.active,
    required this.accent,
    required this.compact,
  });

  final double burst;
  final double orbit;
  final bool active;
  final Color accent;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) {
      return;
    }
    final center = Offset(compact ? 28 : 46, size.height * 0.62);
    final spin = orbit * math.pi * 2;
    for (var index = 0; index < 3; index++) {
      final angle = spin + index * math.pi * 2 / 3;
      final radius = compact ? 16.0 : 22.0;
      final point =
          center + Offset(math.cos(angle), math.sin(angle) * 0.72) * radius;
      canvas.drawCircle(
        point,
        compact ? 2.2 : 3,
        Paint()..color = accent.withValues(alpha: 0.55),
      );
    }
    if (burst <= 0) {
      return;
    }
    final fade = 1 - burst;
    for (var ring = 0; ring < 2; ring++) {
      final progress = (burst + ring * 0.22).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        (compact ? 10 : 14) + progress * (compact ? 28 : 52),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (compact ? 1.4 : 2.2) * (1 - progress)
          ..color = accent.withValues(alpha: 0.75 * (1 - progress)),
      );
    }
    const sparks = 8;
    for (var index = 0; index < sparks; index++) {
      final angle = spin + index / sparks * math.pi * 2;
      final distance = (compact ? 8 : 12) + burst * (compact ? 34 : 62);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final head = center + direction * distance;
      final tail = center + direction * distance * 0.72;
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = compact ? 1.2 : 1.8
          ..color = Colors.white.withValues(alpha: 0.9 * fade),
      );
      canvas.drawCircle(
        head,
        (compact ? 1.6 : 2.4) * fade + 0.4,
        Paint()..color = accent.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter oldDelegate) {
    return oldDelegate.burst != burst ||
        oldDelegate.orbit != orbit ||
        oldDelegate.active != active ||
        oldDelegate.accent != accent ||
        oldDelegate.compact != compact;
  }
}
