import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/deposit.dart';
import 'package:dance/core/models/paged.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/purchases/purchases_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  testWidgets('renders operations grouped by month', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final deposits = [
      Deposit(
        id: '3001',
        typeText: 'оплата группового абонемента',
        createdAt: DateTime.utc(2026, 11, 10, 5),
        paymentText: 'Картой',
        targetNumber: 514,
        sumWithSign: '+10 350 ₽',
      ),
      Deposit(
        id: '3002',
        typeText: 'пополнение счета',
        createdAt: DateTime.utc(2026, 9, 29, 5),
        sum: 11500,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          depositsPageProvider.overrideWith(
            (ref, page) async => Paged(
              items: page == 1 ? deposits : const <Deposit>[],
              total: deposits.length,
              page: page,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PurchasesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Покупки'), findsOneWidget);
    expect(find.text('2 операции · оплата и пополнения'), findsOneWidget);
    expect(find.text('НОЯБРЬ 2026'), findsOneWidget);
    expect(find.text('СЕНТЯБРЬ 2026'), findsOneWidget);
    expect(find.text('Оплата группового абонемента'), findsOneWidget);
    expect(find.text('Картой · абонемент № 514'), findsOneWidget);
    expect(find.text('10\u00A0350 ₽'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when there are no purchases', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          depositsPageProvider.overrideWith(
            (ref, page) async => Paged<Deposit>(
              items: const [],
              total: 0,
              page: page,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PurchasesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 операций · оплата и пополнения'), findsOneWidget);
    expect(find.text('Покупок пока нет'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
