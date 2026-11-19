import 'dart:convert';
import 'dart:typed_data';

import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/account/qr_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lK3W4QAAAABJRU5ErkJggg==',
);

Future<void> _pumpQrSheet(
  WidgetTester tester, {
  required Future<Uint8List?> Function() load,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [barcodeProvider.overrideWith((ref) => load())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    showQrSheet(context, clientName: 'Анна Смирнова'),
                child: const Text('Открыть QR'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Открыть QR'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('QR sheet shows the barcode, name and entrance hint', (
    tester,
  ) async {
    await _pumpQrSheet(tester, load: () async => _png);

    expect(find.text('QR-код'), findsOneWidget);
    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.text('Покажите на входе'), findsOneWidget);
    expect(find.byKey(const ValueKey('qr-barcode-image')), findsOneWidget);
  });

  testWidgets('QR sheet handles a barcode loading error with retry', (
    tester,
  ) async {
    await _pumpQrSheet(
      tester,
      load: () => Future<Uint8List?>.error(const NetworkFailure()),
    );

    expect(find.text('Не удалось получить код'), findsOneWidget);
    expect(find.text('Нет соединения с интернетом'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
