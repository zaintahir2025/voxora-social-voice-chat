import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import '../config/constants.dart';

class ChessBot {
  static const _pieceValue = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 20000,
  };

  static String? getBestMove(String fen, {int depth = 3}) {
    final board = chess_lib.Chess.fromFEN(fen);
    if (board.game_over) return null;
    final moves = List<String>.from(board.moves())..shuffle(Random());
    if (moves.isEmpty) return null;

    var bestMove = moves.first;
    var bestScore = -999999;
    for (final move in moves) {
      board.move(move);
      final score = -_negamax(board, depth - 1, -1000000, 1000000);
      board.undo();
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  static int _negamax(chess_lib.Chess board, int depth, int alpha, int beta) {
    if (board.game_over) {
      if (board.in_checkmate) return -90000 - depth;
      return 0;
    }
    if (depth == 0) return _evaluate(board);

    var best = -999999;
    for (final move in board.moves()) {
      board.move(move);
      final score = -_negamax(board, depth - 1, -beta, -alpha);
      board.undo();
      best = max(best, score);
      alpha = max(alpha, score);
      if (alpha >= beta) break;
    }
    return best;
  }

  static int _evaluate(chess_lib.Chess board) {
    var score = 0;
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];
    for (final file in files) {
      for (final rank in ranks) {
        final piece = board.get('$file$rank');
        if (piece == null) continue;
        final value = _pieceValue[piece.type.toString().toLowerCase()] ?? 0;
        if (piece.color == chess_lib.Color.WHITE) {
          score += value;
        } else {
          score -= value;
        }
      }
    }
    if (board.in_check) score -= 40;
    return board.turn == chess_lib.Color.WHITE ? score : -score;
  }
}

class LudoBot {
  static int chooseToken(
    List<int> tokens,
    int dice,
    List<int> opponentPositions,
  ) {
    var bestIndex = -1;
    var bestScore = -1;
    for (var i = 0; i < tokens.length; i++) {
      final position = tokens[i];
      if (position >= 56) continue;
      if (position == 0 && dice != 6) continue;
      if (position + dice > 56) continue;

      final next = position + dice;
      var score = 10 + next;
      if (position == 0 && dice == 6) score += 45;
      if (next == 56) score += 100;
      if (next > 42) score += 35;
      if (opponentPositions.contains(next) && next < 56) score += 70;

      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex;
  }
}

class CardsBot {
  static String? chooseCard(
    List<String> hand,
    Map<String, dynamic> table,
    List<String> order,
  ) {
    if (hand.isEmpty) return null;
    final sorted = List<String>.from(hand)
      ..sort((a, b) => _rankValue(a).compareTo(_rankValue(b)));
    final played = order.map((id) => table[id]).whereType<String>().toList();
    if (played.isEmpty) return sorted[sorted.length ~/ 2];

    final highest = played.reduce(
      (a, b) => _rankValue(a) >= _rankValue(b) ? a : b,
    );
    for (final card in sorted) {
      if (_rankValue(card) > _rankValue(highest)) return card;
    }
    return sorted.first;
  }

  static int _rankValue(String card) {
    final rank = card.replaceAll(RegExp(r'[SHDC]'), '');
    return cardRanks.indexOf(rank);
  }
}
