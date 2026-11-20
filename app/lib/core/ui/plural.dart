String pluralRu(int value, String one, String few, String many) {
  final n = value.abs();
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

String formatPoints(int value) =>
    '$value ${pluralRu(value, 'балл', 'балла', 'баллов')}';
