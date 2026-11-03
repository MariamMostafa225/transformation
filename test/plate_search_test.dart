import 'package:flutter_test/flutter_test.dart';
import 'package:newapp/core/utils/plate_search.dart';

void main() {
  group('containsPlateQuery', () {
    test('matches a partial car number', () {
      expect(
        containsPlateQuery(
          query: '123',
          carNumber: '91234',
          letters: 'م ى د',
          companyName: 'الأنوار',
        ),
        isTrue,
      );
    });

    test('matches Arabic-Indic digits', () {
      expect(
        containsPlateQuery(
          query: '١٢٣',
          carNumber: '91234',
          letters: 'م ى د',
          companyName: 'الأنوار',
        ),
        isTrue,
      );
    });

    test('matches Arabic letters with normalized spaces and alef forms', () {
      expect(
        containsPlateQuery(
          query: 'م ي',
          carNumber: '963',
          letters: 'م ى د',
          companyName: 'الأنوار',
        ),
        isTrue,
      );
    });

    test('matches part of a company name', () {
      expect(
        containsPlateQuery(
          query: 'انوا',
          carNumber: '963',
          letters: 'ل ى د',
          companyName: 'الأنوار',
        ),
        isTrue,
      );
    });

    test('an empty query matches all cars', () {
      expect(
        containsPlateQuery(
          query: '  ',
          carNumber: '963',
          letters: 'ل ى د',
          companyName: 'الأنوار',
        ),
        isTrue,
      );
    });
  });
}
