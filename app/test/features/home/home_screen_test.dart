import 'dart:async';

import 'package:dance/app/providers.dart';
import 'package:dance/core/contracts/fakes.dart';
import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/account.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/storage/session.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/core/ui/theme_controller.dart';
import 'package:dance/features/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Session _session() {
  return Session(
    clientId: 255,
    secret: 'demo',
    profile: const ClientProfile(
      id: 255,
      firstName: 'Анна',
      lastName: 'Смирнова',
      branchName: 'Главный',
      bonus: 0,
    ),
    createdAt: DateTime.utc(2026, 11, 19),
  );
}

Account _profileAccount() {
  return Account(
    id: 514,
    typeName: 'ПРОФИ',
    statusName: 'Активен',
    visitsLeft: 20,
    visitsTotal: 24,
    freezeDaysLeft: 21,
    freezeDaysTotal: 21,
    freezeEnable: true,
    closed: false,
    freeze: false,
    validUntil: DateTime(2027, 2, 7),
    entity: 'groupAccount',
    packets: const [AccountPacket(value: 21, days: 21, minimumDays: 1)],
  );
}

Account _standardAccount() {
  return Account(
    id: 10,
    typeName: 'Стандарт',
    statusName: 'Активен',
    visitsLeft: 3,
    visitsTotal: 5,
    freezeDaysLeft: 0,
    freezeDaysTotal: 0,
    freezeEnable: false,
    closed: false,
    freeze: false,
    validUntil: DateTime(2026, 12, 2),
    entity: 'individualAccount',
  );
}

Account _closedAccount() {
  return Account(
    id: 99,
    typeName: 'Стандарт',
    statusName: 'Закрыт',
    visitsLeft: 0,
    visitsTotal: 5,
    freezeDaysLeft: 0,
    freezeDaysTotal: 0,
    freezeEnable: false,
    closed: true,
    freeze: false,
    validUntil: DateTime(2025, 12, 2),
    entity: 'individualAccount',
    active: false,
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<Account> accounts = const [],
  bool fail = false,
  Size size = const Size(430, 1600),
  double textScale = 1,
  Future<List<Account>>? pendingAccounts,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(session: _session()),
        ),
        if (fail)
          accountsProvider.overrideWith(
            (ref) => Future<List<Account>>.error(const NetworkFailure()),
          )
        else
          accountsProvider.overrideWith(
            (ref) => pendingAccounts ?? Future<List<Account>>.value(accounts),
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home renders D\'arky header, profile and active accounts', (
    tester,
  ) async {
    await _pumpHome(tester, accounts: [_profileAccount(), _standardAccount()]);

    expect(find.text("D'arky"), findsOneWidget);
    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.text('АС'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-bonus-chip')), findsOneWidget);
    expect(find.text('Абонемент профи'), findsOneWidget);
    expect(find.text('Абонемент стандарт'), findsOneWidget);
    expect(find.text('20 / 24'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Заморозить'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);

    expect(find.byTooltip('Показать QR-код'), findsNothing);
    expect(find.byTooltip('Выйти'), findsOneWidget);
    expect(find.byTooltip('Ещё'), findsOneWidget);
    expect(find.text('Расписание'), findsOneWidget);
  });

  testWidgets('home fits a 360 dp screen at 1.3 text scale', (tester) async {
    await _pumpHome(
      tester,
      accounts: [_profileAccount(), _standardAccount()],
      size: const Size(360, 1600),
      textScale: 1.3,
    );

    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Заморозить'), findsOneWidget);
  });

  testWidgets('closed accounts move to the compact archive section', (
    tester,
  ) async {
    await _pumpHome(tester, accounts: [_profileAccount(), _closedAccount()]);

    expect(find.text('Архив'), findsOneWidget);
    expect(find.byKey(const ValueKey('archive-account-99')), findsOneWidget);
    expect(find.text('ЗАКРЫТ'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);
  });

  testWidgets('three-dot menu opens theme and about popover', (tester) async {
    await _pumpHome(tester, accounts: [_profileAccount()]);

    await tester.tap(find.byTooltip('Ещё'));
    await tester.pumpAndSettle();

    expect(find.text('Тема оформления'), findsOneWidget);
    expect(find.text('О приложении'), findsOneWidget);
    expect(find.text("D'arky 1.0.0"), findsOneWidget);
    expect(find.text('Android 15+'), findsOneWidget);

    await tester.tap(find.text('Тема оформления'));
    await tester.pumpAndSettle();

    expect(find.text('Оформление применится сразу'), findsOneWidget);
    for (final mode in AppThemeMode.values) {
      expect(find.text(mode.label), findsOneWidget);
    }

    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(find.text('Оформление применится сразу'), findsNothing);

    await tester.tap(find.byTooltip('Ещё'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('О приложении'));
    await tester.pumpAndSettle();
    expect(find.text('Мобильный кабинет клуба'), findsOneWidget);
    expect(find.text('Android 15+'), findsOneWidget);
    expect(find.text('Закрыть'), findsOneWidget);

    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('Мобильный кабинет клуба'), findsNothing);
  });

  testWidgets('logout asks for confirmation and can be cancelled', (
    tester,
  ) async {
    await _pumpHome(tester, accounts: [_profileAccount()]);

    await tester.tap(find.byTooltip('Выйти'));
    await tester.pumpAndSettle();
    expect(find.text('Выйти из кабинета?'), findsOneWidget);

    await tester.tap(find.text('Остаться'));
    await tester.pumpAndSettle();
    expect(find.text('Выйти из кабинета?'), findsNothing);
    expect(find.text('Анна Смирнова'), findsOneWidget);
  });

  testWidgets('confirming logout clears the session', (tester) async {
    await _pumpHome(tester, accounts: [_profileAccount()]);

    await tester.tap(find.byTooltip('Выйти'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Выйти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Выйти из кабинета?'), findsNothing);
    expect(find.text('Анна Смирнова'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('freeze explains the club cabinet and offers an external link', (
    tester,
  ) async {
    await _pumpHome(tester, accounts: [_profileAccount()]);

    await tester.tap(find.byKey(const ValueKey('account-freeze-514')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Заморозка оформляется в личном кабинете клуба'),
      findsOneWidget,
    );
    expect(find.text('Открыть кабинет клуба'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Открыть кабинет клуба'), findsNothing);
  });

  testWidgets('accounts loading state shows skeletons until data arrives', (
    tester,
  ) async {
    final completer = Completer<List<Account>>();
    await _pumpHome(tester, pendingAccounts: completer.future);

    expect(find.text('Загружаем абонементы…'), findsOneWidget);
    expect(find.text('Абонемент профи'), findsNothing);

    completer.complete([_profileAccount()]);
    await tester.pumpAndSettle();
    expect(find.text('Абонемент профи'), findsOneWidget);
    expect(find.text('Загружаем абонементы…'), findsNothing);
  });

  testWidgets('empty accounts show a designed empty state', (tester) async {
    await _pumpHome(tester, accounts: const []);

    expect(find.text('Абонементов пока нет'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);
  });

  testWidgets('accounts error shows a retry state', (tester) async {
    await _pumpHome(tester, fail: true);

    final errorCard = find.byKey(const ValueKey('accounts-error'));
    expect(errorCard, findsOneWidget);
    expect(find.text('Не удалось загрузить абонементы'), findsOneWidget);
    expect(
      find.descendant(
        of: errorCard,
        matching: find.text('Нет соединения с интернетом'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: errorCard, matching: find.text('Повторить')),
      findsOneWidget,
    );
  });
}
