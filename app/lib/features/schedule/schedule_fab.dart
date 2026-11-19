import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/data_providers.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/theme_controller.dart' show sharedPreferencesProvider;
import 'schedule_providers.dart';

/// Pure geometry of the draggable refresh FAB.
///
/// The circle always stays fully inside the safe area and inside the parent
/// box: `minX <= x <= maxX` and `minY <= y <= maxY`, where the max values also
/// subtract the FAB size. Keeping this as plain math makes the clamp testable
/// without pumping widgets.
class ScheduleFabGeometry {
  const ScheduleFabGeometry({
    required this.parentSize,
    required this.safePadding,
    this.size = 52,
    this.margin = 16,
    this.bottomReserve = 0,
  });

  final Size parentSize;
  final EdgeInsets safePadding;
  final double size;
  final double margin;

  /// Extra space kept free at the bottom (for example a bottom navigation bar
  /// when the FAB overlay covers the whole screen).
  final double bottomReserve;

  double get minX => safePadding.left + margin;

  double get maxX => math.max(
        minX,
        parentSize.width - safePadding.right - margin - size,
      );

  double get minY => safePadding.top + margin;

  double get maxY => math.max(
        minY,
        parentSize.height - safePadding.bottom - bottomReserve - margin - size,
      );

  Offset get defaultOffset => Offset(maxX, maxY);

  Offset clamp(Offset value) => Offset(
        value.dx.clamp(minX, maxX).toDouble(),
        value.dy.clamp(minY, maxY).toDouble(),
      );

  /// Resolves a stored normalized position (`0..1` on each axis) into pixels,
  /// clamped to the current parent size.
  Offset resolve(Offset normalized) {
    final dx = minX + normalized.dx.clamp(0.0, 1.0) * (maxX - minX);
    final dy = minY + normalized.dy.clamp(0.0, 1.0) * (maxY - minY);
    return clamp(Offset(dx, dy));
  }

  /// Converts a pixel offset to the normalized `0..1` form used in prefs.
  Offset normalize(Offset offset) {
    final clamped = clamp(offset);
    final dx = maxX == minX ? 0.0 : (clamped.dx - minX) / (maxX - minX);
    final dy = maxY == minY ? 0.0 : (clamped.dy - minY) / (maxY - minY);
    return Offset(dx, dy);
  }
}

/// Floating refresh button of the schedule.
///
/// This is a standalone overlay: the parent puts it in a `Stack` above the
/// home `CustomScrollView`, for example `Positioned.fill(child: ScheduleFab())`.
/// Tap reloads [scheduleDayProvider] for the day selected by
/// [scheduleSelectedDayProvider] (owned by `ScheduleSection`); drag moves the
/// button and clamps it fully into the safe area. The normalized position is
/// persisted with `shared_preferences`.
class ScheduleFab extends ConsumerStatefulWidget {
  const ScheduleFab({
    super.key,
    this.size = 52,
    this.margin = 16,
    this.bottomReserve = 0,
    this.storageKey = 'schedule_fab',
  });

  /// Key of the tappable circle (useful in widget tests).
  static const ValueKey<String> buttonKey = ValueKey('schedule_fab_button');

  /// Diameter of the circle, DESIGN §4.3: 52 dp.
  final double size;

  /// Minimum gap between the circle and the safe-area edges.
  final double margin;

  /// Additional bottom inset (bottom navigation bar when overlaying it).
  final double bottomReserve;

  /// Prefix of the two `shared_preferences` keys.
  final String storageKey;

  @override
  ConsumerState<ScheduleFab> createState() => _ScheduleFabState();
}

class _ScheduleFabState extends ConsumerState<ScheduleFab> {
  late Offset _normalized;
  Offset? _dragOffset;

  String get _xKey => '${widget.storageKey}_x';
  String get _yKey => '${widget.storageKey}_y';

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _normalized = Offset(
      _readAxis(prefs.getDouble(_xKey)),
      _readAxis(prefs.getDouble(_yKey)),
    );
  }

  static double _readAxis(double? value) =>
      (value ?? 1).clamp(0.0, 1.0).toDouble();

  void _refresh() {
    final day = ref.read(scheduleSelectedDayProvider);
    ref.invalidate(scheduleDayProvider(day));
    HapticFeedback.lightImpact();
  }

  void _resetPosition() {
    setState(() => _normalized = const Offset(1, 1));
    _persistPosition();
    HapticFeedback.selectionClick();
  }

  void _persistPosition() {
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setDouble(_xKey, _normalized.dx));
    unawaited(prefs.setDouble(_yKey, _normalized.dy));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final loading = ref
        .watch(scheduleDayProvider(ref.watch(scheduleSelectedDayProvider)))
        .isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentSize =
            constraints.hasBoundedWidth && constraints.hasBoundedHeight
                ? constraints.biggest
                : media.size;
        final geometry = ScheduleFabGeometry(
          parentSize: parentSize,
          safePadding: media.padding,
          size: widget.size,
          margin: widget.margin,
          bottomReserve: widget.bottomReserve,
        );
        final offset = geometry.resolve(_normalized);

        return Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: widget.size,
              height: widget.size,
              child: _buildButton(context, geometry, loading: loading),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(
    BuildContext context,
    ScheduleFabGeometry geometry, {
    required bool loading,
  }) {
    final palette = context.palette;
    return GestureDetector(
      key: ScheduleFab.buttonKey,
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : _refresh,
      onPanStart: (_) {
        _dragOffset = geometry.resolve(_normalized);
        HapticFeedback.selectionClick();
      },
      onPanUpdate: (details) {
        final anchor = _dragOffset ?? geometry.resolve(_normalized);
        final next = geometry.clamp(anchor + details.delta);
        _dragOffset = next;
        setState(() => _normalized = geometry.normalize(next));
      },
      onPanEnd: (_) {
        _dragOffset = null;
        _persistPosition();
        HapticFeedback.lightImpact();
      },
      child: Semantics(
        button: true,
        enabled: !loading,
        label: 'Обновить расписание',
        hint: loading
            ? 'Обновление…'
            : 'Тап — обновить день. Перетаскивание — переместить кнопку.',
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Сбросить позицию'):
              _resetPosition,
        },
        child: Container(
          decoration: BoxDecoration(
            color: palette.ink,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: palette.bg,
                    ),
                  )
                : Icon(Icons.refresh, size: 24, color: palette.bg),
          ),
        ),
      ),
    );
  }
}
