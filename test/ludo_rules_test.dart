import 'package:flutter_test/flutter_test.dart';
import 'package:voxora/services/ludo_rules.dart';

void main() {
  group('Ludo rules', () {
    test('requires a six to leave base and enters on the start square', () {
      expect(ludoMoveTarget(0, 5), isNull);
      expect(ludoMoveTarget(0, 6), 1);
    });

    test('requires an exact finish', () {
      expect(ludoMoveTarget(52, 4), 56);
      expect(ludoMoveTarget(53, 4), isNull);
      expect(isLegalLudoMove(56, 6), isFalse);
    });

    test('captures opponents on unsafe shared track squares', () {
      final state = {
        'activeColors': ['red', 'blue'],
        'tokens': {
          'red': [1, 0, 0, 0],
          'blue': [41, 0, 0, 0],
        },
      };

      final move = applyLudoMove(state, 'red', 0, 1);

      expect(move?.captured, isTrue);
      expect((state['tokens'] as Map)['red'], [2, 0, 0, 0]);
      expect((state['tokens'] as Map)['blue'], [0, 0, 0, 0]);
    });

    test('protects pieces on safe squares', () {
      final state = {
        'activeColors': ['red', 'blue'],
        'tokens': {
          'red': [3, 0, 0, 0],
          'blue': [48, 0, 0, 0],
        },
      };

      final move = applyLudoMove(state, 'red', 0, 6);

      expect(move?.captured, isFalse);
      expect((state['tokens'] as Map)['red'], [9, 0, 0, 0]);
      expect((state['tokens'] as Map)['blue'], [48, 0, 0, 0]);
    });

    test('advances through active colors', () {
      final state = {
        'activeColors': ['red', 'blue', 'yellow', 'green'],
      };

      expect(nextLudoSeat(state, 'red'), 'blue');
      expect(nextLudoSeat(state, 'green'), 'red');
    });
  });
}
