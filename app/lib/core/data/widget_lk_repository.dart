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
      {'filters': _auth(session)},
    );
    return _items(json, Account.fromJson);
  }

  Future<List<ScheduleItem>> schedule(Session session, DateTime day) async {
    final utcDay = DateTime.utc(day.year, day.month, day.day)
        .subtract(clock.offset);
    final seconds = utcDay.millisecondsSinceEpoch ~/ 1000;
    final json = await api.post(
      '${config.apiBasePath}/widget_schedule/list',
      {
        'branch_id': config.branchId,
        'range': {'from': seconds, 'to': seconds},
        'filters': {
          'branch_id': config.branchId,
          'groups': true,
          'individuals': true,
          'rents': true,
          'scale': 'day',
        },
      },
    );
    final items = _items(json, ScheduleItem.fromJson);
    return [
      for (final item in items)
        item.copyWith(
          isMine: item.clientId == session.clientId,
          teacherName: item.teacherName,
          changeText: item.changeText,
        ),
    ]..sort(_scheduleOrder);
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

  Future<List<Booking>> bookings(Session session) async {
    final json = await api.post(
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
    final json = await api.post(
      '${config.apiBasePath}/widget_client_lk/barcode',
      {
        ..._auth(session),
        'type': 2,
        'seconds': 5,
      },
    );
    final raw = json['barcode'] ?? json['image'] ?? json['png'];
    if (raw is! String || raw.isEmpty) return null;
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
    final raw = json['items'];
    if (raw is! List) return <T>[];
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
    final total = (json['total'] as num?)?.toInt() ?? items.length;
    return Paged(items: items, total: total, page: page);
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
