import 'dart:convert';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../models/account.dart';
import '../models/booking.dart';
import '../models/deposit.dart';
import '../models/paged.dart';
import '../models/schedule_item.dart';
import '../models/visit.dart';
import '../network/api_client.dart';
import '../network/api_failure.dart';
import '../storage/session.dart';
import '../time/branch_clock.dart';

/// Client-side widget API. Every request is signed by `client_id` + `secret`;
/// the public schedule additionally carries the branch id.
class WidgetLkRepository {
  WidgetLkRepository({
    required this.api,
    required this.config,
    required this.clock,
  });

  final ApiClient api;
  final AppConfig config;
  final BranchClock clock;

  Future<List<Account>> accounts(Session session) async {
    final json = await api.post(
      '${config.apiBasePath}/widget_client_lk/accounts',
      {'filters': {..._auth(session), 'closedAccountsShown': true}},
    );
    return _items(json, Account.fromJson);
  }

  Future<List<ScheduleItem>> schedule(Session session, DateTime day) async {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    final seconds = utcDay.millisecondsSinceEpoch ~/ 1000;
    final json = await api.post(
      '${config.apiBasePath}/widget_schedule/list',
      _scheduleBody(seconds),
    );
    final items = _items(json, ScheduleItem.fromJson);
    final extras = await _loadScheduleExtras(seconds);
    return [
      for (final item in items)
        _sanitizeScheduleItem(_applyExtras(item, extras), session),
    ]..sort(_scheduleOrder);
  }

  Map<String, dynamic> _scheduleBody(int seconds) {
    return {
      'branch_id': config.branchId,
      'range': {'from': seconds, 'to': seconds},
      'filters': {
        'branch_id': config.branchId,
        'groups': true,
        'individuals': true,
        'rents': true,
        'hall_id': null,
        'style_id': null,
        'teacher_id': null,
        'age': null,
        'scale': 'day',
      },
    };
  }

  Future<_ScheduleExtras> _loadScheduleExtras(int seconds) async {
    final stickers = <String, String>{};
    final colors = <String, String>{};
    final changes = <String, String>{};
    final substitutes = <String, List<String>>{};
    await Future.wait<void>([
      api
          .post(
            '${config.apiBasePath}/widget_schedule/stickers',
            _scheduleBody(seconds),
          )
          .then((json) {
        for (final item in _rawItems(json)) {
          final id = _scheduleId(item);
          if (id == null) continue;
          final name = item['name']?.toString();
          final color = item['color']?.toString();
          if (name != null && name.isNotEmpty) stickers[id] = name;
          if (color != null && color.isNotEmpty) colors[id] = color;
        }
      }).catchError((_) {}),
      api
          .post(
            '${config.apiBasePath}/widget_schedule/changes',
            _scheduleBody(seconds),
          )
          .then((json) {
        for (final item in _rawItems(json)) {
          final id = _scheduleId(item);
          if (id == null) continue;
          final teacher = _personName(
            item['teacher'] is Map ? item['teacher'] as Map : const {},
          );
          final source = _personName(
            item['sourceTeacher'] is Map
                ? item['sourceTeacher'] as Map
                : const {},
          );
          final annotation = item['annotation']?.toString();
          if (teacher != null) {
            substitutes.putIfAbsent(id, () => <String>[]).add(teacher);
          }
          final text = teacher != null
              ? 'Замена: $teacher${source != null ? ' (вместо $source)' : ''}'
              : annotation;
          if (text != null && text.isNotEmpty) changes[id] = text;
        }
      }).catchError((_) {}),
    ]);
    return _ScheduleExtras(
      stickers: stickers,
      stickerColors: colors,
      changes: changes,
      substitutes: substitutes,
    );
  }

  ScheduleItem _applyExtras(ScheduleItem item, _ScheduleExtras extras) {
    return item.copyWith(
      stickerName: extras.stickers[item.id],
      stickerColor: extras.stickerColors[item.id],
      changeText: extras.changes[item.id],
      substituteTeacherNames: extras.substitutes[item.id],
    );
  }

  ScheduleItem _sanitizeScheduleItem(ScheduleItem item, Session session) {
    final mine = item.clientId == session.clientId;
    if (item.isIndividual && !mine) {
      return item.sanitizedForeign().copyWith(isMine: false);
    }
    return item.copyWith(isMine: mine);
  }

  String? _scheduleId(Map<String, dynamic> item) {
    final schedule = item['schedule'];
    if (schedule is Map) {
      final id = schedule['id'];
      if (id != null) return id.toString();
    }
    final id = item['schedule_id'] ?? item['scheduleId'];
    return id?.toString();
  }

  List<Map<String, dynamic>> _rawItems(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  String? _personName(Map person) {
    final last = (person['lastName'] ?? '').toString().trim();
    final first = (person['name'] ?? '').toString().trim();
    final parts = [first, last].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  Future<Paged<Visit>> visits(
    Session session,
    int page, {
    int pageSize = 20,
  }) async {
    final json = await api.post(
      '${config.apiBasePath}/widget_client_lk/visits',
      {
        'limit': pageSize,
        'page': page,
        'sort': {'visit_date': 'desc', 'created': 'desc'},
        'filters': _auth(session),
      },
    );
    return _paged(json, page, Visit.fromJson);
  }

  Future<Paged<Deposit>> deposits(
    Session session,
    int page, {
    int pageSize = 20,
  }) async {
    final json = await api.post(
      '${config.apiBasePath}/widget_client_lk/deposits',
      {
        'limit': pageSize,
        'page': page,
        'sort': {'created': 'desc'},
        'filters': {
          ..._auth(session),
          'type': [11, 12, 13],
        },
      },
    );
    return _paged(json, page, Deposit.fromJson);
  }

  Future<List<Booking>> bookings(Session session) async {    final json = await api.post(
      '${config.apiBasePath}/widget_client_lk/schedule',
      {
        'filters': _auth(session),
        'sort': {
          'regular': 'desc',
          'dateBegin': 'desc',
          'date': 'desc',
          'minutesBegin': 'desc',
        },
      },
    );
    return _items(json, Booking.fromJson);
  }

  Future<Uint8List?> barcode(Session session) async {
    final bytes = await api.postBytes(
      '${config.apiBasePath}/widget_client_lk/barcode',
      {
        ..._auth(session),
        'type': 2,
        'seconds': 5,
      },
    );
    if (bytes.isEmpty) return null;
    // Some tenants return the PNG itself, others a JSON/base64 envelope.
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return bytes;
    }
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.isEmpty) return null;
    String raw;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        raw = (decoded['barcode'] ?? decoded['image'] ?? decoded['png'] ?? '')
            .toString();
      } else {
        raw = decoded.toString();
      }
    } on FormatException {
      raw = text;
    }
    if (raw.isEmpty) return null;
    final normalized = raw.contains(',') ? raw.split(',').last : raw;
    try {
      return base64Decode(normalized);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> _auth(Session session) => {
        'client_id': session.clientId,
        'secret': session.secret,
      };

  List<T> _items<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    _validate(json);
    final raw = json['items'];
    if (raw is! List) {
      throw const ParseFailure('В ответе клуба нет списка items');
    }
    return [
      for (final item in raw)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ];
  }

  Paged<T> _paged<T>(
    Map<String, dynamic> json,
    int page,
    T Function(Map<String, dynamic>) parse,
  ) {
    final items = _items(json, parse);
    final total = (json['total'] as num?)?.toInt();
    if (total == null) {
      throw const ParseFailure('В ответе клуба нет total');
    }
    return Paged(items: items, total: total, page: page);
  }

  void _validate(Map<String, dynamic> json) {
    final message = (json['message'] ?? json['error'] ?? json['detail'])
        ?.toString();
    final failed = json['success'] == false;
    if (message == null && !failed) return;
    final lower = (message ?? '').toLowerCase();
    if (lower.contains('validatesecret') ||
        lower.contains('logicexception') ||
        lower.contains('доступ') ||
        lower.contains('сесси') ||
        lower.contains('auth')) {
      throw const UnauthorizedFailure();
    }
    throw VendorFailure(message ?? 'Клуб отклонил запрос');
  }

  int _scheduleOrder(ScheduleItem a, ScheduleItem b) {
    final time = (a.minutesBegin ?? 1 << 30)
        .compareTo(b.minutesBegin ?? 1 << 30);
    if (time != 0) return time;
    final type = a.type.compareTo(b.type);
    if (type != 0) return type;
    return a.title.compareTo(b.title);
  }
}

class _ScheduleExtras {
  const _ScheduleExtras({
    required this.stickers,
    required this.stickerColors,
    required this.changes,
    required this.substitutes,
  });

  final Map<String, String> stickers;
  final Map<String, String> stickerColors;
  final Map<String, String> changes;
  final Map<String, List<String>> substitutes;
}
