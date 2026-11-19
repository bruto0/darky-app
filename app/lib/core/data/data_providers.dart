import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../models/account.dart';
import '../models/booking.dart';
import '../models/deposit.dart';
import '../models/paged.dart';
import '../models/schedule_item.dart';
import '../models/visit.dart';
import '../storage/session.dart';
import 'widget_lk_repository.dart';

final widgetLkRepositoryProvider = Provider<WidgetLkRepository>((ref) {
  return WidgetLkRepository(
    api: ref.watch(apiClientProvider),
    config: ref.watch(appConfigProvider),
    clock: ref.watch(branchClockProvider),
  );
});

Session _session(Ref ref) {
  final session = ref.watch(sessionControllerProvider).valueOrNull;
  if (session == null) {
    throw StateError('Session is required for widget data');
  }
  return session;
}

final accountsProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  return ref.watch(widgetLkRepositoryProvider).accounts(_session(ref));
});

final scheduleDayProvider =
    FutureProvider.autoDispose.family<List<ScheduleItem>, DateTime>(
  (ref, day) {
    return ref.watch(widgetLkRepositoryProvider).schedule(_session(ref), day);
  },
);

final visitsPageProvider =
    FutureProvider.autoDispose.family<Paged<Visit>, int>((ref, page) {
  return ref.watch(widgetLkRepositoryProvider).visits(_session(ref), page);
});

final depositsPageProvider =
    FutureProvider.autoDispose.family<Paged<Deposit>, int>((ref, page) {
  return ref.watch(widgetLkRepositoryProvider).deposits(_session(ref), page);
});

final bookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  return ref.watch(widgetLkRepositoryProvider).bookings(_session(ref));
});

final barcodeProvider =
    FutureProvider.autoDispose<Uint8List?>((ref) async {
  return ref.watch(widgetLkRepositoryProvider).barcode(_session(ref));
});
