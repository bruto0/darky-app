import '../auth/auth_failure.dart';
import '../auth/auth_repository.dart';
import '../models/account.dart';
import '../models/booking.dart';
import '../models/deposit.dart';
import '../models/paged.dart';
import '../models/schedule_item.dart';
import '../models/visit.dart';
import '../storage/session.dart';
import 'repositories.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  Session? session;

  @override
  Future<Session?> restore() async => session;

  @override
  Future<Session> completeLogin(String phone) async {
    final current = session;
    if (current == null) {
      throw const AuthFailure('Нет тестовой сессии');
    }
    return current;
  }

  @override
  Future<Session> completeNativeLogin(String phone, String password) =>
      completeLogin(phone);

  @override
  Future<void> logout() async => session = null;
}

class FakeAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> loadAccounts() async => const [];
}

class FakeScheduleRepository implements ScheduleRepository {
  @override
  Future<List<ScheduleItem>> loadDay(DateTime day) async => const [];
}

class FakeVisitsRepository implements VisitsRepository {
  @override
  Future<Paged<Visit>> loadPage(int page) async =>
      Paged(items: const [], total: 0, page: page);
}

class FakePurchasesRepository implements PurchasesRepository {
  @override
  Future<Paged<Deposit>> loadPage(int page) async =>
      Paged(items: const [], total: 0, page: page);
}

class FakeBookingsRepository implements BookingsRepository {
  @override
  Future<List<Booking>> loadUpcoming() async => const [];
}
