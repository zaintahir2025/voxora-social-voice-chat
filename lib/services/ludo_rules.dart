import '../config/constants.dart';

const ludoFinishPosition = 56;
const ludoHomeLaneStart = 52;

class LudoMoveResult {
  final int target;
  final bool captured;
  final bool finished;

  const LudoMoveResult({
    required this.target,
    required this.captured,
    required this.finished,
  });
}

bool isLegalLudoMove(int position, int dice) {
  if (dice < 1 || dice > 6 || position >= ludoFinishPosition) return false;
  if (position <= 0) return dice == 6;
  return position + dice <= ludoFinishPosition;
}

int? ludoMoveTarget(int position, int dice) {
  if (!isLegalLudoMove(position, dice)) return null;
  return position <= 0 ? 1 : position + dice;
}

bool hasLegalLudoMove(List<int> tokens, int dice) {
  return tokens.any((position) => isLegalLudoMove(position, dice));
}

String nextLudoSeat(Map<String, dynamic> state, String current) {
  final colors = List<String>.from(
    state['activeColors'] as List? ?? ludoColorNames,
  );
  if (colors.isEmpty) return current;
  final index = colors.indexOf(current);
  if (index < 0) return colors.first;
  return colors[(index + 1) % colors.length];
}

int? ludoAbsoluteTrackIndex(String color, int position) {
  if (position <= 0 || position >= ludoHomeLaneStart) return null;
  final start = ludoStartOffsets[color] ?? 0;
  return (start + position - 1) % ludoTrackLength;
}

LudoMoveResult? applyLudoMove(
  Map<String, dynamic> state,
  String color,
  int tokenIndex,
  int dice,
) {
  final allTokens = Map<String, dynamic>.from(state['tokens'] as Map? ?? {});
  final tokens = List<int>.from(allTokens[color] as List? ?? [0, 0, 0, 0]);
  if (tokenIndex < 0 || tokenIndex >= tokens.length) return null;

  final target = ludoMoveTarget(tokens[tokenIndex], dice);
  if (target == null) return null;

  tokens[tokenIndex] = target;
  allTokens[color] = tokens;

  var captured = false;
  final landingTrackIndex = ludoAbsoluteTrackIndex(color, target);
  if (landingTrackIndex != null &&
      !ludoSafeTrackIndices.contains(landingTrackIndex)) {
    for (final entry in allTokens.entries.toList()) {
      final opponentColor = entry.key;
      if (opponentColor == color) continue;

      final opponentTokens = List<int>.from(entry.value as List? ?? []);
      var changed = false;
      for (var i = 0; i < opponentTokens.length; i++) {
        if (ludoAbsoluteTrackIndex(opponentColor, opponentTokens[i]) ==
            landingTrackIndex) {
          opponentTokens[i] = 0;
          changed = true;
          captured = true;
        }
      }
      if (changed) allTokens[opponentColor] = opponentTokens;
    }
  }

  state['tokens'] = allTokens;
  return LudoMoveResult(
    target: target,
    captured: captured,
    finished: tokens.every((position) => position >= ludoFinishPosition),
  );
}
