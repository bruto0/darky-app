import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/paged.dart';
import 'package:dance/core/models/visit.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/visits/visits_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  testWidgets('renders the first page of visits', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final visits = [
      Visit(
        id: '2001',
        title: 'Бачата Dominican flow',
        visitedAt: DateTime.utc(2026, 11, 17, 18, 30),
        byAccount: true,
        serviceNumber: 514,
        teacherNames: const ['Кальдерон Диего', 'Губина Наталья'],
        branchName: 'Главный',
        styleColor: 'C27BA0',
      ),
      Visit(
        id: '2002',
        title: 'Малый зал',
        visitedAt: DateTime.utc(2026, 11, 16, 10),
        byAccount: false,
        branchName: 'Главный',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsPageProvider.overrideWith(
            (ref, page) async => Paged(
              items: page == 1 ? visits : const <Visit>[],
              total: visits.length,
              page: page,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const VisitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Посещения'), findsOneWidget);
    expect(find.text('2 посещения'), findsOneWidget);
    // 18:30 UTC is the next day in the UTC+7 branch.
    expect(find.text('18.11.2026'), findsOneWidget);
    expect(find.text('Абонемент № 514'), findsOneWidget);
    expect(find.text('Разовое занятие'), findsOneWidget);
    expect(find.text('Бачата Dominican flow'), findsOneWidget);
    expect(find.text('Главный'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when there are no visits', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsPageProvider.overrideWith(
            (ref, page) async => Paged<Visit>(
              items: const [],
              total: 0,
              page: page,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const VisitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 посещений'), findsOneWidget);
    expect(find.text('Пока нет посещений'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads the next page on scroll and drops page-boundary duplicates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Visit fakeVisit(int index) {
      return Visit(
        id: 'visit-$index',
        title: 'Визит $index',
        visitedAt: DateTime.utc(2026, 11, 17, 10),
        byAccount: true,
        serviceNumber: 514,
        branchName: 'Главный',
      );
    }

    final firstPage = [for (var index = 0; index < 20; index++) fakeVisit(index)];
    final secondPage = [
      fakeVisit(19), // duplicate on the page boundary
      for (var index = 20; index < 25; index++) fakeVisit(index),
    ];
    final requestedPages = <int>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsPageProvider.overrideWith((ref, page) async {
            requestedPages.add(page);
            final items = switch (page) {
              1 => firstPage,
              2 => secondPage,
              _ => const <Visit>[],
            };
            return Paged(items: items, total: 25, page: page);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const VisitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(requestedPages, contains(2));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
    await tester.pumpAndSettle();

    expect(find.text('25 посещений'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
