import 'package:dance/core/models/schedule_item.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Fixed branch clock: 2026-11-19 12:00 in the club (UTC+7).
BranchClock fixedClock({DateTime? utcNow}) {
  return BranchClock(
    offset: const Duration(hours: 7),
    now: () => utcNow ?? DateTime.utc(2026, 11, 19, 5),
  );
}

ScheduleItem scheduleItem({
  String id = '1',
  int type = 0,
  String title = 'Занятие',
  String? hallName = 'Большой зал',
  String? teacherName,
  List<String> mainTeacherNames = const [],
  List<String> substituteTeacherNames = const [],
  int? clientId,
  String? clientName,
  String? clientDisplayName,
  int? clientBonus,
  DateTime? startsAt,
  DateTime? endsAt,
  bool isMine = false,
  int? minutesBegin,
  int? minutesEnd,
  String? styleName,
  String? groupLevel,
  String? stickerName,
  String? stickerColor,
  String? changeText,
  String? typeTitle,
}) {
  return ScheduleItem(
    id: id,
    type: type,
    title: title,
    hallName: hallName,
    teacherName: teacherName,
    mainTeacherNames: mainTeacherNames,
    substituteTeacherNames: substituteTeacherNames,
    clientId: clientId,
    clientName: clientName,
    clientDisplayName: clientDisplayName,
    clientBonus: clientBonus,
    startsAt: startsAt,
    endsAt: endsAt,
    isMine: isMine,
    minutesBegin: minutesBegin,
    minutesEnd: minutesEnd,
    styleName: styleName,
    groupLevel: groupLevel,
    stickerName: stickerName,
    stickerColor: stickerColor,
    changeText: changeText,
    typeTitle: typeTitle,
  );
}

Widget testApp(Widget child, {bool dark = false}) {
  return MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(
      backgroundColor: dark ? AppPalette.dark.bg : AppPalette.light.bg,
      body: child,
    ),
  );
}
