import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../services/bot_service.dart';
import '../services/ludo_rules.dart';

class BotGame {
  final String id;
  final String gameType;
  final DateTime createdAt;
  Map<String, dynamic> state;
  Map<String, dynamic> players;
  bool isActive;
  String? result;

  BotGame({
    required this.id,
    required this.gameType,
    required this.createdAt,
    required this.state,
    required this.players,
    this.isActive = true,
    this.result,
  });
}

class BotGameProvider extends ChangeNotifier {
  static const playerId = 'player';

  final _rng = Random();
  final List<BotGame> _games = [];
  String? _selectedGameId;
  bool _botThinking = false;

  List<BotGame> get games => _games;
  String? get selectedGameId => _selectedGameId;
  bool get botThinking => _botThinking;

  BotGame? get selectedGame =>
      _games.where((game) => game.id == _selectedGameId).firstOrNull;

  String profileName(dynamic id) {
    if (id == playerId) return 'You';
    if (id is String && id.startsWith('bot')) {
      final suffix = id == 'bot' ? '' : ' ${id.split('_').last}';
      return 'Computer$suffix';
    }
    return 'Open seat';
  }

  void selectGame(String id) {
    _selectedGameId = id;
    notifyListeners();
  }

  void deleteGame(String id) {
    _games.removeWhere((game) => game.id == id);
    if (_selectedGameId == id) {
      _selectedGameId = _games.isEmpty ? null : _games.first.id;
    }
    notifyListeners();
  }

  void createChessGame({bool playAsWhite = true}) {
    final id = 'bot_chess_${DateTime.now().millisecondsSinceEpoch}';
    final game = BotGame(
      id: id,
      gameType: 'chess',
      createdAt: DateTime.now(),
      state: {
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'moves': <String>[],
      },
      players: {
        'white': playAsWhite ? playerId : 'bot',
        'black': playAsWhite ? 'bot' : playerId,
      },
    );
    _addGame(game);
    if (!playAsWhite) _scheduleBotChessMove(id);
  }

  void makeChessMove(String gameId, String from, String to) {
    final game = _find(gameId);
    if (game == null || !game.isActive || _botThinking) return;
    final board = chess_lib.Chess.fromFEN(game.state['fen'] as String);
    final moved = board.move({'from': from, 'to': to, 'promotion': 'q'});
    if (!moved) return;

    final moves = List<String>.from(game.state['moves'] as List? ?? []);
    moves.add(
      board.history.isEmpty ? '$from-$to' : board.history.last.toString(),
    );
    game.state = {'fen': board.fen, 'moves': moves};
    _checkChessResult(game, board);
    notifyListeners();
    if (game.isActive) _scheduleBotChessMove(gameId);
  }

  void _scheduleBotChessMove(String gameId) {
    _botThinking = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 550), () {
      final game = _find(gameId);
      if (game == null || !game.isActive) {
        _botThinking = false;
        notifyListeners();
        return;
      }
      final board = chess_lib.Chess.fromFEN(game.state['fen'] as String);
      final botColor = game.players['white'] == 'bot' ? 'white' : 'black';
      final turn = board.turn == chess_lib.Color.WHITE ? 'white' : 'black';
      if (turn != botColor || board.game_over) {
        _botThinking = false;
        notifyListeners();
        return;
      }

      final bestMove = ChessBot.getBestMove(board.fen, depth: 3);
      if (bestMove != null) {
        board.move(bestMove);
        final moves = List<String>.from(game.state['moves'] as List? ?? []);
        moves.add(bestMove);
        game.state = {'fen': board.fen, 'moves': moves};
        _checkChessResult(game, board);
      }
      _botThinking = false;
      notifyListeners();
    });
  }

  void _checkChessResult(BotGame game, chess_lib.Chess board) {
    if (!board.game_over) return;
    game.isActive = false;
    if (board.in_checkmate) {
      final loser = board.turn == chess_lib.Color.WHITE ? 'white' : 'black';
      game.result = game.players[loser] == 'bot'
          ? 'You win by checkmate.'
          : 'Computer wins by checkmate.';
    } else {
      game.result = 'Draw.';
    }
  }

  void createLudoGame({int playerCount = 4, String playerColor = 'red'}) {
    final colors = ludoColorNames.take(playerCount.clamp(2, 4)).toList();
    final color = colors.contains(playerColor) ? playerColor : colors.first;
    final players = <String, dynamic>{};
    for (final lane in colors) {
      players[lane] = lane == color
          ? playerId
          : 'bot_${colors.indexOf(lane) + 1}';
    }
    final tokens = {
      for (final lane in colors) lane: [0, 0, 0, 0],
    };
    final id = 'bot_ludo_${DateTime.now().millisecondsSinceEpoch}';
    final game = BotGame(
      id: id,
      gameType: 'ludo',
      createdAt: DateTime.now(),
      state: {
        'activeColors': colors,
        'turn': colors.first,
        'dice': null,
        'sixStreak': 0,
        'tokens': tokens,
        'winner': null,
      },
      players: players,
    );
    _addGame(game);
    if (players[colors.first] != playerId) _scheduleBotLudoTurn(id);
  }

  void rollLudoDice(String gameId) {
    final game = _find(gameId);
    if (game == null || !game.isActive || _botThinking) return;
    final state = Map<String, dynamic>.from(game.state);
    final turn = state['turn'] as String;
    if (game.players[turn] != playerId || state['dice'] != null) return;

    final dice = _rng.nextInt(6) + 1;
    final sixStreak = dice == 6 ? ((state['sixStreak'] as int?) ?? 0) + 1 : 0;
    state['dice'] = dice;
    state['sixStreak'] = sixStreak;
    game.state = state;
    notifyListeners();

    if (dice == 6 && sixStreak >= 3) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _advanceLudoTurn(gameId),
      );
      return;
    }

    final tokens = _ludoTokens(state, turn);
    if (!hasLegalLudoMove(tokens, dice)) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _advanceLudoTurn(gameId),
      );
    }
  }

  void moveLudoToken(String gameId, String color, int tokenIndex) {
    final game = _find(gameId);
    if (game == null || !game.isActive || _botThinking) return;
    final state = Map<String, dynamic>.from(game.state);
    final dice = state['dice'] as int?;
    if (dice == null ||
        state['turn'] != color ||
        game.players[color] != playerId) {
      return;
    }
    final move = applyLudoMove(state, color, tokenIndex, dice);
    if (move == null) return;
    state['dice'] = null;

    game.state = state;
    _checkLudoWinner(game, color);
    notifyListeners();
    if (game.isActive) _finishLudoTurn(gameId, color, dice, move.captured);
  }

  void _scheduleBotLudoTurn(String gameId) {
    _botThinking = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      final game = _find(gameId);
      if (game == null || !game.isActive) {
        _botThinking = false;
        notifyListeners();
        return;
      }
      final state = Map<String, dynamic>.from(game.state);
      final turn = state['turn'] as String;
      if (game.players[turn] == playerId) {
        _botThinking = false;
        notifyListeners();
        return;
      }
      final dice = _rng.nextInt(6) + 1;
      final sixStreak = dice == 6 ? ((state['sixStreak'] as int?) ?? 0) + 1 : 0;
      state['dice'] = dice;
      state['sixStreak'] = sixStreak;
      if (dice == 6 && sixStreak >= 3) {
        game.state = state;
        _botThinking = false;
        notifyListeners();
        Future.delayed(
          const Duration(milliseconds: 450),
          () => _advanceLudoTurn(gameId),
        );
        return;
      }
      final allTokens = Map<String, dynamic>.from(state['tokens'] as Map);
      final mine = _ludoTokens(state, turn);
      final opponents = <int>[];
      for (final entry in allTokens.entries) {
        if (entry.key != turn) {
          for (final position in List<int>.from(entry.value as List)) {
            final trackIndex = ludoAbsoluteTrackIndex(entry.key, position);
            if (trackIndex != null) opponents.add(trackIndex);
          }
        }
      }
      final tokenIndex = LudoBot.chooseToken(
        mine,
        dice,
        opponents,
        color: turn,
      );
      final move = tokenIndex >= 0
          ? applyLudoMove(state, turn, tokenIndex, dice)
          : null;
      state['dice'] = null;

      game.state = state;
      _checkLudoWinner(game, turn);
      _botThinking = false;
      notifyListeners();
      if (game.isActive) {
        if (move != null) {
          _finishLudoTurn(gameId, turn, dice, move.captured);
        } else {
          _advanceLudoTurn(gameId);
        }
      }
    });
  }

  void _advanceLudoTurn(String gameId) {
    final game = _find(gameId);
    if (game == null || !game.isActive) return;
    final state = Map<String, dynamic>.from(game.state);
    final current = state['turn'] as String;
    state['turn'] = nextLudoSeat(state, current);
    state['dice'] = null;
    state['sixStreak'] = 0;
    game.state = state;
    notifyListeners();
    if (game.players[state['turn']] != playerId) _scheduleBotLudoTurn(gameId);
  }

  void _finishLudoTurn(String gameId, String color, int dice, bool captured) {
    final game = _find(gameId);
    if (game == null || !game.isActive) return;
    final state = Map<String, dynamic>.from(game.state);
    final keepsTurn = dice == 6 || captured;
    state['dice'] = null;
    state['turn'] = keepsTurn ? color : nextLudoSeat(state, color);
    if (!keepsTurn || dice != 6) state['sixStreak'] = 0;
    game.state = state;
    notifyListeners();
    if (keepsTurn && game.players[color] != playerId) {
      _scheduleBotLudoTurn(gameId);
    } else if (!keepsTurn && game.players[state['turn']] != playerId) {
      _scheduleBotLudoTurn(gameId);
    }
  }

  void _checkLudoWinner(BotGame game, String color) {
    final tokens = _ludoTokens(game.state, color);
    if (tokens.every((position) => position >= 56)) {
      game.isActive = false;
      game.state = {...game.state, 'winner': color};
      game.result = game.players[color] == playerId
          ? 'You win.'
          : '${color[0].toUpperCase()}${color.substring(1)} computer wins.';
    }
  }

  List<int> _ludoTokens(Map<String, dynamic> state, String color) {
    final tokens = Map<String, dynamic>.from(state['tokens'] as Map? ?? {});
    return List<int>.from(tokens[color] as List? ?? [0, 0, 0, 0]);
  }

  void createCardsGame({int playerCount = 2}) {
    final total = playerCount.clamp(2, 4);
    final order = <String>[playerId, for (var i = 1; i < total; i++) 'bot_$i'];
    final state = _newCardState(order);
    final id = 'bot_cards_${DateTime.now().millisecondsSinceEpoch}';
    _addGame(
      BotGame(
        id: id,
        gameType: 'cards',
        createdAt: DateTime.now(),
        state: state,
        players: {'order': order},
      ),
    );
  }

  void playCard(String gameId, String card) {
    final game = _find(gameId);
    if (game == null || !game.isActive || _botThinking) return;
    final state = Map<String, dynamic>.from(game.state);
    final hands = Map<String, dynamic>.from(state['hands'] as Map);
    final table = Map<String, dynamic>.from(state['table'] as Map);
    final hand = List<String>.from(hands[playerId] as List? ?? []);
    if (!hand.contains(card) || table[playerId] != null) return;
    hand.remove(card);
    hands[playerId] = hand;
    table[playerId] = card;
    state['hands'] = hands;
    state['table'] = table;
    game.state = state;
    notifyListeners();
    _scheduleBotCardPlays(gameId);
  }

  void _scheduleBotCardPlays(String gameId) {
    _botThinking = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 550), () {
      final game = _find(gameId);
      if (game == null || !game.isActive) {
        _botThinking = false;
        notifyListeners();
        return;
      }
      final state = Map<String, dynamic>.from(game.state);
      final hands = Map<String, dynamic>.from(state['hands'] as Map);
      final table = Map<String, dynamic>.from(state['table'] as Map);
      final order = List<String>.from(state['order'] as List);
      for (final id in order.where((id) => id != playerId)) {
        if (table[id] != null) continue;
        final hand = List<String>.from(hands[id] as List? ?? []);
        final card = CardsBot.chooseCard(hand, table, order);
        if (card == null) continue;
        hand.remove(card);
        hands[id] = hand;
        table[id] = card;
      }
      state['hands'] = hands;
      state['table'] = table;
      game.state = state;
      _botThinking = false;
      notifyListeners();
      if (order.every((id) => table[id] != null)) {
        Future.delayed(
          const Duration(milliseconds: 900),
          () => _settleCards(gameId),
        );
      }
    });
  }

  void _settleCards(String gameId) {
    final game = _find(gameId);
    if (game == null || !game.isActive) return;
    final state = Map<String, dynamic>.from(game.state);
    final table = Map<String, dynamic>.from(state['table'] as Map);
    final scores = Map<String, dynamic>.from(state['scores'] as Map);
    final order = List<String>.from(state['order'] as List);
    final played = order.where((id) => table[id] != null).toList();
    if (played.isEmpty) return;
    played.sort(
      (a, b) => _cardRank(table[b] as String) - _cardRank(table[a] as String),
    );
    final winner = played.first;
    scores[winner] = ((scores[winner] as int?) ?? 0) + 1;
    state['scores'] = scores;
    state['table'] = <String, dynamic>{};
    state['round'] = ((state['round'] as int?) ?? 1) + 1;
    game.state = state;

    final hands = Map<String, dynamic>.from(state['hands'] as Map);
    final done = order.every((id) => (hands[id] as List? ?? const []).isEmpty);
    if (done) {
      game.isActive = false;
      final playerScore = (scores[playerId] as int?) ?? 0;
      final bestBotScore = order
          .where((id) => id != playerId)
          .map((id) => (scores[id] as int?) ?? 0)
          .fold<int>(0, max);
      if (playerScore > bestBotScore) {
        game.result = 'You win with $playerScore points.';
      } else if (playerScore == bestBotScore) {
        game.result = 'Tie at $playerScore points.';
      } else {
        game.result = 'Computer wins with $bestBotScore points.';
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> _newCardState(List<String> order) {
    final deck = [
      for (final suit in cardSuits)
        for (final rank in cardRanks) '$rank$suit',
    ]..shuffle(_rng);
    final hands = <String, dynamic>{};
    for (final id in order) {
      hands[id] = deck.take(5).toList();
      deck.removeRange(0, min(5, deck.length));
    }
    return {
      'deck': deck,
      'hands': hands,
      'table': <String, dynamic>{},
      'scores': <String, dynamic>{},
      'round': 1,
      'order': order,
    };
  }

  int _cardRank(String card) {
    return cardRanks.indexOf(card.replaceAll(RegExp(r'[SHDC]'), ''));
  }

  BotGame? _find(String id) =>
      _games.where((game) => game.id == id).firstOrNull;

  void _addGame(BotGame game) {
    _games.insert(0, game);
    _selectedGameId = game.id;
    notifyListeners();
  }
}
