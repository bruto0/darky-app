import 'package:dance/core/config/app_config.dart';
import 'package:dance/core/models/account.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/account/account_card.dart';
import 'package:dance/features/account/account_presentation.dart';
import 'package:dance/features/account/freeze_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppPalette.light.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('freezable card shows a full-width freeze CTA and no pay CTA', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(AccountCard(account: _profileAccount(), onFreeze: () => taps++)),
    );

    expect(find.text('Абонемент профи'), findsOneWidget);
    expect(find.text('20 / 24'), findsOneWidget);
    expect(find.text('21 / 21'), findsOneWidget);
    expect(find.text('Дней заморозки'), findsNothing);
    expect(find.text('дней заморозки'), findsOneWidget);
    expect(find.text('Действует до 7 февраля 2027'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);

    final button = find.widgetWithText(FilledButton, 'Заморозить');
    expect(button, findsOneWidget);

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('account-card-514')),
    );
    final buttonRect = tester.getRect(button);
    expect(buttonRect.width, greaterThan(cardRect.width - 60));

    await tester.tap(button);
    expect(taps, 1);
  });

  testWidgets('card without freeze has an explanation and no pay CTA', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(AccountCard(account: _standardAccount())));

    expect(find.text('Абонемент стандарт'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Заморозить'), findsNothing);
    expect(find.text('Заморозка не предусмотрена тарифом'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);
  });

  test('freeze copy follows account state without inventing an action', () {
    expect(freezeUnavailableReason(_profileAccount()), isNull);

    final standard = _standardAccount();
    expect(
      freezeUnavailableReason(standard),
      'Заморозка не предусмотрена тарифом',
    );

    final frozen = Account(
      id: 11,
      typeName: 'ПРОФИ',
      visitsLeft: 5,
      visitsTotal: 10,
      freezeDaysLeft: 5,
      freezeDaysTotal: 10,
      freezeEnable: true,
      closed: false,
      freeze: true,
    );
    expect(freezeUnavailableReason(frozen), 'Абонемент заморожен');
    expect(frozen.freezeAvailable, isFalse);
  });

  test('freeze link points to the club widget cabinet', () {
    expect(
      freezeCabinetUri(AppConfig.defaults).toString(),
      'https://4621c03198bd6735334088.impulsemini.ru/widget/2',
    );
  });
}
