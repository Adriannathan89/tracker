import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/models.dart';

void main() {
  test('reads decimal JSON and camelCase categories from backend', () {
    final r = TrackerRecord.fromJson({
      'id': 'r1',
      'title': 'Makan',
      'description': '',
      'amount': 12500.5,
      'type': 'expense',
      'createdAt': '2026-10-09T08:00:00Z',
      'isCommitted': false,
      'categories': [
        {'id': 'c', 'name': 'makanan', 'type': 'primary'},
      ],
    });
    expect(r.amount, 12500.5);
    expect(r.primary, 'makanan');
    expect(r.isCommitted, false);
  });
  test('record filters combine query, type, month and draft status', () {
    final committed = TrackerRecord.fromJson({
      'id': '1',
      'title': 'Gaji',
      'description': '',
      'amount': 10,
      'type': 'income',
      'createdAt': '2026-10-09T08:00:00Z',
      'isCommitted': true,
    });
    final draft = TrackerRecord.fromJson({
      'id': '2',
      'title': 'Makan',
      'description': '',
      'amount': 20,
      'type': 'expense',
      'createdAt': '2026-09-09T08:00:00Z',
      'isCommitted': false,
    });
    expect(
      filterRecords(
        [committed, draft],
        query: 'gAjI',
        month: DateTime(2026, 10),
        type: 'income',
      ),
      [committed],
    );
    expect(filterRecords([committed, draft], draftsOnly: true), [draft]);
  });
  test('money input rejects zero, signs, exponent and excess decimals', () {
    for (final value in ['0', '-12', '1e4', '12,345', 'NaN', '']) {
      expect(parseAmount(value), isNull, reason: value);
    }
    expect(parseAmount('12,50'), 12.5);
    expect(parseAmount('12500'), 12500);
  });
}
