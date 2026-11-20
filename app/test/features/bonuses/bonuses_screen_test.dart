import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/bonus.dart';
import 'package:dance/core/models/paged.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/bonuses/bonuses_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  final items = [
    Bonus(
      id: '20',
      type: 1,
      typeText: 'начисление баллов',
      sumWithSign: 450,
      createdAt: DateTime.utc(2026, 11, 14, 5),
      description: 'за покупку абонемента',
      clientBonus: 450,
    ),
    Bonus(
      id: '49',
      type: 3,
      typeText: 'обнуление баллов',
      sumWithSign: -900,
      createdAt: DateTime.utc(2026, 10, 15, 5),
      clientBonus: 0,
    ),
  ];

  testWidgets('renders balance and history grouped by month', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bonusesPageProvider.overrideWith(
            (ref, page) async => Paged(
              items: page == 1 ? items : const <Bonus>[],
              total: items.length,
              page: page,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BonusesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Баллы'), findsOneWidget);
    expect(find.text('ВСЕГО БАЛЛОВ'), findsOneWidget);
    expect(find.text('0 баллов'), findsNothing);
    expect(find.text('НОЯБРЬ 2026'), findsOneWidget);
    expect(find.text('ОКТЯБРЬ 2026'), findsOneWidget);
    expect(
      find.text('Начисление за покупку абонемента'),
      findsOneWidget,
    );
    expect(find.text('Обнуление баллов'), findsOneWidget);
    expect(find.text('+450'), findsOneWidget);
    expect(find.text('−900'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state without bonus operations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bonusesPageProvider.overrideWith(
            (ref, page) async => Paged<Bonus>(
              items: const [],
              total: 0,
              page: page,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BonusesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пока нет баллов'), findsOneWidget);
  });
}
