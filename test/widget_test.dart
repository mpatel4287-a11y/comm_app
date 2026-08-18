import 'package:flutter_test/flutter_test.dart';
import 'package:comm_app/models/member_model.dart';

void main() {
  group('MemberModel Unit Tests', () {
    test('calculateAge calculates correct age from birthdate', () {
      final now = DateTime.now();
      final birthYear = now.year - 25;
      final birthDateStr = '15/06/$birthYear';
      
      final age = MemberModel.calculateAge(birthDateStr);
      // Depending on whether June 15 has passed this year:
      final expectedAge = (now.month > 6 || (now.month == 6 && now.day >= 15)) ? 25 : 24;
      expect(age, equals(expectedAge));
    });

    test('calculateAge returns 0 for empty or invalid string', () {
      expect(MemberModel.calculateAge(''), equals(0));
      expect(MemberModel.calculateAge('invalid-date'), equals(0));
    });

    test('generateMid produces valid pattern F-XXX-SXX-XXX', () {
      final mid = MemberModel.generateMid('01', '01');
      expect(mid.startsWith('F-'), isTrue);
      expect(mid.contains('-S01-'), isTrue);
      expect(mid.length, equals(13));
    });

    test('empty member model contains sensible default properties', () {
      final empty = MemberModel.empty();
      expect(empty.id, isEmpty);
      expect(empty.fullName, isEmpty);
      expect(empty.isActive, isTrue);
      expect(empty.role, equals('member'));
    });
  });
}
