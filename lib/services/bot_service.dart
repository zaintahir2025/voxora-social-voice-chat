import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import '../config/constants.dart';

// ═══════════════════════════════════════════════════════════════
//  Chess Bot — Negamax with Alpha-Beta Pruning
// ═══════════════════════════════════════════════════════════════

class ChessBot {
  static const _pieceVal = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 20000,
  };

  // Piece-square tables (from white's view, index 0 = a8)
  static const _pawnPst = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    50,
    50,
    50,
    50,
    50,
    50,
    50,
    50,
    10,
    10,
    20,
    30,
    30,
    20,
    10,
    10,
    5,
    5,
    10,
    25,
    25,
    10,
    5,
    5,
    0,
    0,
    0,
    20,
    20,
    0,
    0,
    0,
    5,
    -5,
    -10,
    0,
    0,
    -10,
    -5,
    5,
    5,
    10,
    10,
    -20,
    -20,
    10,
    10,
    5,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];
  static const _knightPst = [
    -50,
    -40,
    -30,
    -30,
    -30,
    -30,
    -40,
    -50,
    -40,
    -20,
    0,
    0,
    0,
    0,
    -20,
    -40,
    -30,
    0,
    10,
    15,
    15,
    10,
    0,
    -30,
    -30,
    5,
    15,
    20,
    20,
    15,
    5,
    -30,
    -30,
    0,
    15,
    20,
    20,
    15,
    0,
    -30,
    -30,
    5,
    10,
    15,
    15,
    10,
    5,
    -30,
    -40,
    -20,
    0,
    5,
    5,
    0,
    -20,
    -40,
    -50,
    -40,
    -30,
    -30,
    -30,
    -30,
    -40,
    -50,
  ];
  static const _bishopPst = [
    -20,
    -10,
    -10,
    -10,
    -10,
    -10,
    -10,
    -20,
    -10,
    0,
    0,
    0,
    0,
    0,
    0,
    -10,
    -10,
    0,
    10,
    10,
    10,
    10,
    0,
    -10,
    -10,
    5,
    5,
    10,
    10,
    5,
    5,
    -10,
    -10,
    0,
    5,
    10,
    10,
    5,
    0,
    -10,
    -10,
    5,
    5,
    5,
    5,
    5,
    5,
    -10,
    -10,
    5,
    0,
    0,
    0,
    0,
    5,
    -10,
    -20,
    -10,
    -10,
    -10,
    -10,
    -10,
    -10,
    -20,
  ];
  static const _rookPst = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    5,
    10,
    10,
    10,
    10,
    10,
    10,
    5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    -5,
    0,
    0,
    0,
    0,
    0,
    0,
    -5,
    0,
    0,
    0,
    5,
    5,
    0,
    0,
    0,
  ];
  static const _queenPst = [
    -20,
    -10,
    -10,
    -5,
    -5,
    -10,
    -10,
    -20,
    -10,
    0,
    0,
    0,
    0,
    0,
    0,
    -10,
    -10,
    0,
    5,
    5,
    5,
    5,
    0,
    -10,
    -5,
    0,
    5,
    5,
    5,
    5,
    0,
    -5,
    0,
    0,
    5,
    5,
    5,
    5,
    0,
    -5,
    -10,
    5,
    5,
    5,
    5,
    5,
    0,
    -10,
    -10,
    0,
    5,
    0,
    0,
    0,
    0,
    -10,
    -20,
    -10,
    -10,
    -5,
    -5,
    -10,
    -10,
    -20,
  ];
  static const _kingMidPst = [
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -30,
    -40,
    -40,
    -50,
    -50,
    -40,
    -40,
    -30,
    -20,
    -30,
    -30,
    -40,
    -40,
    -30,
    -30,
    -20,
    -10,
    -20,
    -20,
    -20,
    -20,
    -20,
    -20,
    -10,
    20,
    20,
    0,
    0,
    0,
    0,
    20,
    20,
    20,
    30,
    10,
    0,
    0,
    10,
    30,
    20,
  ];

  static const _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const _ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];

  /// Returns the best move in SAN notation, or null if game is over.
  static String? getBestMove(String fen, {int depth = 3}) {
    final chess = chess_lib.Chess.fromFEN(fen);
    if (chess.game_over) return null;

    final moves = chess.moves();
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;

    // Shuffle to add variety when moves have equal score
    final rng = Random();
    final shuffled = List<String>.from(moves)..shuffle(rng);

    String bestMove = shuffled.first;
    int bestScore = -999999;

    for (final move in shuffled) {
      chess.move(move);
      final score = -_negamax(chess, depth - 1, -999999, 999999);
      chess.undo();
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  static int _negamax(chess_lib.Chess chess, int depth, int alpha, int beta) {
    if (chess.game_over) {
      if (chess.in_checkmate) return -90000 - depth; // losing = very bad
      return 0; // draw
    }
    if (depth == 0) return _evaluate(chess);

    int best = -999999;
    for (final move in chess.moves()) {
      chess.move(move);
      final score = -_negamax(chess, depth - 1, -beta, -alpha);
      chess.undo();
      best = max(best, score);
      alpha = max(alpha, score);
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Evaluate position from the perspective of the side to move.
  static int _evaluate(chess_lib.Chess chess) {
    int score = 0;
    for (final f in _files) {
      for (final r in _ranks) {
        final sq = '$f$r';
        final piece = chess.get(sq);
        if (piece == null) continue;
        final type = piece.type.toString().toLowerCase();
        final matVal = _pieceVal[type] ?? 0;
        final posVal = _posBonus(
          type,
          sq,
          piece.color == chess_lib.Color.WHITE,
        );
        if (piece.color == chess_lib.Color.WHITE) {
          score += matVal + posVal;
        } else {
          score -= matVal + posVal;
        }
      }
    }
    // Check bonus
    if (chess.in_check) score -= 50;
    return chess.turn == chess_lib.Color.WHITE ? score : -score;
  }

  static int _posBonus(String type, String sq, bool isWhite) {
    final fileIdx = sq.codeUnitAt(0) - 97; // 'a' = 0
    final rankIdx = int.parse(sq[1]) - 1; // rank 1 = 0
    final whiteIdx = (7 - rankIdx) * 8 + fileIdx;
    final idx = isWhite ? whiteIdx : (rankIdx * 8 + fileIdx);
    switch (type) {
      case 'p':
        return _pawnPst[idx];
      case 'n':
        return _knightPst[idx];
      case 'b':
        return _bishopPst[idx];
      case 'r':
        return _rookPst[idx];
      case 'q':
        return _queenPst[idx];
      case 'k':
        return _kingMidPst[idx];
      default:
        return 0;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Ludo Bot — Heuristic Token Selection
// ═══════════════════════════════════════════════════════════════

class LudoBot {
  /// Choose which token (0-3) to move given the dice roll.
  /// Returns -1 if no valid move.
  static int chooseToken(
    List<int> tokens,
    int dice,
    List<int> opponentPositions,
  ) {
    // Score each token option
    int bestIdx = -1;
    int bestScore = -1;

    for (int i = 0; i < 4; i++) {
      final pos = tokens[i];
      if (pos >= 56) continue; // already home
      if (pos == 0 && dice != 6) continue; // can't leave base without 6
      if (pos + dice > 56) continue; // must land exactly on home
      final newPos = pos + dice;

      int score = 10; // base score for any valid move

      // Leaving base is good
      if (pos == 0 && dice == 6) score += 40;

      // Reaching home exactly is great
      if (newPos == 56) score += 100;

      // Advancing tokens near home is good
      if (newPos > 40) score += 30;

      // Prefer advancing the most advanced token (push to finish)
      score += newPos;

      // Capturing (if opponent has token at same position)
      if (opponentPositions.contains(newPos) && newPos > 0 && newPos < 56) {
        score += 60;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }

    // Fallback: move any movable token
    if (bestIdx == -1) {
      for (int i = 0; i < 4; i++) {
        if (tokens[i] < 56 &&
            (tokens[i] > 0 || dice == 6) &&
            tokens[i] + dice <= 56) {
          return i;
        }
      }
    }
    return bestIdx;
  }
}

// ═══════════════════════════════════════════════════════════════
//  Cards Bot — Strategic Card Selection
// ═══════════════════════════════════════════════════════════════

class CardsBot {
  /// Choose which card to play from the hand.
  static String? chooseCard(
    List<String> hand,
    Map<String, dynamic> table,
    List<String> order,
  ) {
    if (hand.isEmpty) return null;

    // Get cards already played on the table
    final playedCards = <String>[];
    for (final id in order) {
      if (table[id] != null) playedCards.add(table[id] as String);
    }

    if (playedCards.isEmpty) {
      // Going first: play mid-range card
      final sorted = _sortByRank(hand);
      return sorted[sorted.length ~/ 2];
    }

    // Find the current highest card on the table
    final highestPlayed = _highestRank(playedCards);

    // Try to win with the lowest card that beats the current highest
    final sorted = _sortByRank(hand);
    for (final card in sorted) {
      if (_rankValue(card) > _rankValue(highestPlayed)) {
        return card; // lowest winning card
      }
    }

    // Can't win — play the lowest card
    return sorted.first;
  }

  static int _rankValue(String card) {
    final rank = card.replaceAll(RegExp(r'[SHDC]'), '');
    return cardRanks.indexOf(rank);
  }

  static List<String> _sortByRank(List<String> cards) {
    final copy = List<String>.from(cards);
    copy.sort((a, b) => _rankValue(a).compareTo(_rankValue(b)));
    return copy;
  }

  static String _highestRank(List<String> cards) {
    return cards.reduce((a, b) => _rankValue(a) >= _rankValue(b) ? a : b);
  }
}
