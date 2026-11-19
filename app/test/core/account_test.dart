import 'dart:convert';
import 'dart:io';

import 'package:dance/core/models/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('freeze is available only for the eligible account', () {
    final json = jsonDecode(
      File('test/fixtures/accounts.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final accounts = [
      for (final item in json['items'] as List)
        Account.fromJson(Map<String, dynamic>.from(item as Map)),
    ];

    expect(accounts, hasLength(2));
    expect(accounts[0].typeName, 'ПРОФИ');
    expect(accounts[0].freezeAvailable, isTrue);
    expect(accounts[0].freezeDaysLeft, 21);
    expect(accounts[0].packets.single.days, 21);

    expect(accounts[1].typeName, 'Стандарт');
    expect(accounts[1].freezeAvailable, isFalse);
    expect(accounts[1].packets, isEmpty);
  });

  test('freeze days are derived from the freeze packet', () {
    final account = Account.fromJson({
      'id': 514,
      'typeName': 'ПРОФИ',
      'closed': false,
      'freeze': false,
      'packets': [
        {'value': 5, 'days': 21, 'min': '1'},
      ],
    });

    expect(account.freezeDaysLeft, 21);
    expect(account.freezeDaysTotal, 21);
    expect(account.freezeAvailable, isTrue);
  });

  test('frozen, closed and zero-day accounts are not freezable', () {
    const base = {
      'id': 1,
      'typeName': 'ПРОФИ',
      'freezeDaysLeft': 5,
      'freezeDaysTotal': 5,
      'freezeEnable': true,
      'closed': false,
      'freeze': false,
    };

    expect(Account.fromJson(base).freezeAvailable, isTrue);
    expect(
      Account.fromJson({...base, 'freeze': true}).freezeAvailable,
      isFalse,
    );
    expect(
      Account.fromJson({...base, 'closed': true}).freezeAvailable,
      isFalse,
    );
    expect(
      Account.fromJson({...base, 'freezeDaysLeft': 0}).freezeAvailable,
      isFalse,
    );
    expect(
      Account.fromJson({...base, 'freezeEnable': false}).freezeAvailable,
      isFalse,
    );
  });
}
