import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Short, finite motion. No timers, repeating animations, or app-state listeners.
abstract final class TrackerMotion {
  static const quick = Duration(milliseconds: 220);
  static const entrance = Duration(milliseconds: 320);
  static const amount = Duration(milliseconds: 400);
  static const shake = Duration(milliseconds: 360);
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}

class MotionEntrance extends StatefulWidget {
  const MotionEntrance({
    super.key,
    required this.child,
    this.replayKey,
    this.duration = TrackerMotion.entrance,
    this.distance = 14,
    this.fade = true,
  });
  final Widget child;
  final Object? replayKey;
  final Duration duration;
  final double distance;
  final bool fade;
  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TrackerMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MotionEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.replayKey != widget.replayKey) {
      if (TrackerMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: widget.fade ? _curve : const AlwaysStoppedAnimation<double>(1),
    child: AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.distance * (1 - _curve.value)),
        child: child,
      ),
    ),
  );
}

/// Keeps forms/search/scroll state in place. Only the selected page ticks.
/// One subtree transitions, so there are no duplicate GlobalKeys or HTTP calls.
class MotionTabs extends StatelessWidget {
  const MotionTabs({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => MotionEntrance(
    replayKey: index,
    duration: TrackerMotion.quick,
    distance: 8,
    fade: false,
    child: IndexedStack(
      index: index,
      children: [
        for (var i = 0; i < children.length; i++)
          TickerMode(
            enabled: i == index,
            child: RepaintBoundary(child: children[i]),
          ),
      ],
    ),
  );
}

class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: TrackerMotion.amount,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  double _from = 0;
  late double _to = widget.value;
  bool _started = false;
  double get _visible => _from + (_to - _from) * _curve.value;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep compatibility with Flutter 3.35.7, which has no TickerMode.valuesOf.
    // ignore: deprecated_member_use
    if (TrackerMotion.reduced(context) || !TickerMode.of(context)) {
      _controller.stop();
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) {
      return;
    }
    _from = _visible;
    _to = widget.value;
    // Keep compatibility with Flutter 3.35.7, which has no TickerMode.valuesOf.
    // ignore: deprecated_member_use
    if (TrackerMotion.reduced(context) || !TickerMode.of(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.format(widget.value),
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) =>
            Text(widget.format(_visible), style: widget.style),
      ),
    ),
  );
}

class ShakeFeedback extends StatefulWidget {
  const ShakeFeedback({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;
  @override
  State<ShakeFeedback> createState() => _ShakeFeedbackState();
}

class _ShakeFeedbackState extends State<ShakeFeedback>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: TrackerMotion.shake,
    value: 1,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TrackerMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ShakeFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger &&
        !TrackerMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = _controller.value;
      final offset = t == 1 ? 0.0 : math.sin(t * math.pi * 6) * 5 * (1 - t);
      return Transform.translate(offset: Offset(offset, 0), child: child);
    },
  );
}
