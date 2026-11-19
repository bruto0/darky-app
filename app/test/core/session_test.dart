import 'dart:convert';

import 'package:dance/core/storage/session.dart';
import 'package:dance/core/storage/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  const profile = ClientProfile(
    id: 255,
    firstName: 'Анна',
    lastName: 'Смирнова',
    middleName: 'Игоревна',
    branchName: "D'arky Dance",
  );
  final session = Session(
    clientId: 255,
    secret: 'demo-secret',
    profile: profile,
    createdAt: DateTime.utc(2026, 11, 19),
  );

  test('session JSON round-trip', () {
    final restored = Session.fromJson(
      jsonDecode(jsonEncode(session.toJson())) as Map<String, dynamic>,
    );
    expect(restored.clientId, 255);
    expect(restored.secret, 'demo-secret');
    expect(restored.profile.fullName, 'Смирнова Анна Игоревна');
    expect(restored.createdAt, DateTime.utc(2026, 11, 19));
  });

  test('secure store reads and writes the session', () async {
    final storage = MockSecureStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (_) async => jsonEncode(session.toJson()),
    );
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    final store = SecureSessionStore(storage: storage);
    final restored = await store.read();
    expect(restored?.clientId, 255);
    expect(restored?.profile.firstName, 'Анна');

    await store.write(session);
    verify(
      () => storage.write(
        key: 'darky.session.v1',
        value: any(named: 'value'),
      ),
    ).called(1);

    await store.clear();
    verify(() => storage.delete(key: 'darky.session.v1')).called(1);
  });
}
