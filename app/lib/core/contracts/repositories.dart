import '../models/account.dart';
import '../models/booking.dart';
import '../models/deposit.dart';
import '../models/paged.dart';
import '../models/schedule_item.dart';
import '../models/visit.dart';

abstract class AccountRepository {
  Future<List<Account>> loadAccounts();
}

abstract class ScheduleRepository {
  Future<List<ScheduleItem>> loadDay(DateTime day);
}

abstract class VisitsRepository {
  Future<Paged<Visit>> loadPage(int page);
}

abstract class PurchasesRepository {
  Future<Paged<Deposit>> loadPage(int page);
}

abstract class BookingsRepository {
  Future<List<Booking>> loadUpcoming();
}
