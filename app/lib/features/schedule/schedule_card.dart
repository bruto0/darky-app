import 'package:material_ui/material_ui.dart';

import '../../core/models/schedule_item.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/theme.dart';
import 'schedule_format.dart';

/// Whether an individual/rent item belongs to the signed-in client.
///
/// The repository already sets [ScheduleItem.isMine]; the raw `clientId`
/// comparison is kept as a second, session-independent guard.
bool isOwnScheduleItem(ScheduleItem item, int? clientId) {
  if (item.isMine) return true;
  return clientId != null && item.clientId == clientId;
}

/// Rail colour of a schedule card.
///
/// Own individual lessons get the violet "это моё" marker; groups and rent
/// use the brand accent.
Color scheduleRailColor(
  ScheduleItem item,
  AppPalette palette, {
  required bool isOwn,
}) {
  if (isOwn && item.isIndividual) return palette.violet;
  if (item.isRent) return palette.pink;
  return palette.pink;
}

/// A single lesson in the day list.
///
/// Privacy rules from DESIGN §5.3/§5.4 are enforced by construction: the
/// foreign individual/rent branches never receive the client name, teacher,
/// style or sticker, so those strings cannot leak into the widget tree.
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.item,
    required this.clock,
    this.clientId,
  });

  final ScheduleItem item;
  final BranchClock clock;

  /// Signed-in client id; combined with [ScheduleItem.isMine] to detect
  /// "own" individual lessons and rents.
  final int? clientId;

  bool get _isOwn => isOwnScheduleItem(item, clientId);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isOwn = _isOwn;
    final rail = scheduleRailColor(item, palette, isOwn: isOwn);

    final Widget card;
    if (item.isGroup) {
      card = _fullCard(
        context,
        palette: palette,
        rail: rail,
        title: _groupTitle(item),
        hall: item.hallName,
        mainTeachers: item.mainTeacherNames.isNotEmpty
            ? item.mainTeacherNames
            : [if (item.teacherName != null) item.teacherName!],
        substituteTeachers: item.substituteTeacherNames,
        changeText: _changeLabel(item),
        stickerName: item.stickerName,
        stickerColor: item.stickerColor,
        trailingIcon: Icons.groups_outlined,
      );
    } else if (item.isIndividual) {
      if (isOwn) {
        card = _fullCard(
          context,
          palette: palette,
          rail: rail,
          title: _ownTitle(item, fallback: 'Индивидуальное занятие'),
          teacher: item.teacherName,
          hall: item.hallName,
          trailingIcon: Icons.person_outline,
        );
      } else {
        card = _compactCard(
          context,
          palette: palette,
          rail: palette.muted.withValues(alpha: 0.35),
          kind: 'индив',
          kindColor: palette.ink2,
          hall: item.hallName,
        );
      }
    } else if (item.isRent) {
      card = _fullCard(
        context,
        palette: palette,
        rail: rail,
        title: _rentTitle(item),
        hall: item.hallName,
        stickerName: item.isSampoSticker ? null : item.stickerName,
        stickerColor: item.stickerColor,
        trailingIcon: Icons.meeting_room_outlined,
      );
    } else {
      // Unknown type: stay on the compact, privacy-safe side.
      card = _compactCard(
        context,
        palette: palette,
        rail: palette.muted.withValues(alpha: 0.35),
        kind: 'занятие',
        kindColor: palette.ink2,
        hall: item.hallName,
      );
    }

    return MergeSemantics(
      child: Container(
        key: ValueKey<String>('schedule_card_${item.id}'),
        child: card,
      ),
    );
  }

  String _groupTitle(ScheduleItem item) {
    final base = item.title.trim().isEmpty
        ? (item.styleName?.trim().isNotEmpty ?? false
            ? item.styleName!.trim()
            : 'Групповое занятие')
        : item.title.trim();
    final level = item.groupLevel?.trim();
    if (level == null || level.isEmpty) return base;
    if (base.toLowerCase().contains(level.toLowerCase())) return base;
    return '$base $level';
  }

  String _ownTitle(ScheduleItem item, {required String fallback}) {
    final name = item.clientName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final title = item.title.trim();
    return title.isEmpty || title == 'Занятие' ? fallback : title;
  }

  String _rentTitle(ScheduleItem item) {
    final prefix = item.isSampoSticker ? 'сампо' : 'аренда';
    final tenant = _nonEmpty(item.clientDisplayName) ??
        _nonEmpty(item.clientName);
    return tenant == null ? prefix : '$prefix $tenant';
  }

  String? _changeLabel(ScheduleItem item) {
    final raw = item.changeText?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.toLowerCase().startsWith('замена')) return raw;
    return 'Замена: $raw';
  }

  Widget _fullCard(
    BuildContext context, {
    required AppPalette palette,
    required Color rail,
    required String title,
    String? teacher,
    List<String> mainTeachers = const [],
    List<String> substituteTeachers = const [],
    String? hall,
    String? changeText,
    String? stickerName,
    String? stickerColor,
    String? kindLabel,
    IconData? trailingIcon,
  }) {
    final text = Theme.of(context).textTheme;
    final teacherText = _nonEmpty(teacher);
    final mainTeacherText = _nonEmpty(
      mainTeachers.where((name) => name.trim().isNotEmpty).join(', '),
    );
    final substituteText = _nonEmpty(
      substituteTeachers.where((name) => name.trim().isNotEmpty).join(', '),
    );
    final hallText = _nonEmpty(hall);
    final change = _nonEmpty(changeText);
    final substitution = substituteText == null
        ? change
        : (change ?? 'Замена: $substituteText');
    final sticker = _nonEmpty(stickerName);
    final kind = _nonEmpty(kindLabel);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timeColumn(context, palette: palette),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 13),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: rail, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                      ),
                      if (sticker != null) ...[
                        const SizedBox(width: 8),
                        _StickerChip(
                          label: sticker,
                          rawColor: stickerColor,
                          palette: palette,
                        ),
                      ],
                    ],
                  ),
                  if (kind != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      kind,
                      style: text.bodySmall?.copyWith(
                        color: palette.pinkDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (mainTeacherText != null) ...[
                    const SizedBox(height: 5),
                    _IconLine(
                      icon: Icons.people_outline,
                      color: palette.violet,
                      child: Text(
                        mainTeacherText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: palette.violet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (teacherText != null) ...[
                    const SizedBox(height: 5),
                    _IconLine(
                      icon: Icons.person_outline,
                      color: palette.violet,
                      child: Text(
                        teacherText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: palette.violet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (substitution != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      substitution,
                      style: text.bodySmall?.copyWith(
                        color: palette.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (hallText != null) ...[
                    const SizedBox(height: 5),
                    _IconLine(
                      icon: Icons.place_outlined,
                      color: palette.muted,
                      child: Text(
                        hallText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                trailingIcon,
                size: 20,
                color: palette.muted.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactCard(
    BuildContext context, {
    required AppPalette palette,
    required Color rail,
    required String kind,
    required Color kindColor,
    String? hall,
  }) {
    final text = Theme.of(context).textTheme;
    final hallText = _nonEmpty(hall);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: palette.line.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scheduleStartTime(item, clock),
                  style: text.titleMedium?.copyWith(
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (scheduleDurationText(item) case final duration?)
                  Text(duration, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: rail,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            kind,
            style: text.bodyMedium?.copyWith(
              color: kindColor,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          if (hallText != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hallText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeColumn(BuildContext context, {required AppPalette palette}) {
    final text = Theme.of(context).textTheme;
    final duration = scheduleDurationText(item);
    return SizedBox(
      width: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scheduleStartTime(item, clock),
            style: text.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (duration != null)
            Text(
              duration,
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
        ],
      ),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({
    required this.icon,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 5),
        Expanded(child: child),
      ],
    );
  }
}

class _StickerChip extends StatelessWidget {
  const _StickerChip({
    required this.label,
    required this.palette,
    this.rawColor,
  });

  final String label;
  final AppPalette palette;
  final String? rawColor;

  @override
  Widget build(BuildContext context) {
    final background = _background();
    final foreground = background == palette.yellow ? palette.ink : palette.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 9.5,
              letterSpacing: 0.7,
            ),
      ),
    );
  }

  Color _background() {
    final parsed = _parseHex(rawColor);
    if (parsed != null) return parsed;
    final name = label.toLowerCase();
    if (name.contains('сампо')) return palette.yellow;
    if (name.contains('индив')) return palette.violetSoft;
    return palette.pinkSoft;
  }

  static Color? _parseHex(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().replaceFirst('#', '');
    if (value.length != 6 && value.length != 8) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(value.length == 6 ? 0xFF000000 | parsed : parsed);
  }
}
