import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../config/constants.dart';
import '../services/bot_service.dart';

/// A single local bot game (not synced to Supabase).
class BotGame {
  final String id;
  final String gameType;
  Map<String, dynamic> state;
  Map<String, dynamic> players;
  final DateTime createdAt;
  bool isActive;
  String? result; // e.g. "You win!", "Bot wins!", "Draw"

  BotGame({
    required this.id,
    required this.gameType,
    required this.state,
    required this.players,
    required this.createdAt,
    this.isActive = true,
    this.result,
  });
}

const _botId = 'bot';
const _botNames = {'bot': 'Computer', 'bot_1': 'Bot 1', 'bot_2': 'Bot 2', 'bot_3': 'Bot 3'};

class BotGameProvider extends ChangeNotifier {
  final List<BotGame> _games = [];
  List<BotGame> get games => _games;

  String? _selectedGameId;
  String? get selectedGameId => _selectedGameId;

  BotGame? get selectedGame =>
      _games.where((g) => g.id == _selectedGameId).firstOrNull;

  bool _botThinking = false;
  bool get botThinking => _botThinking;

  String profileName(dynamic id) {
    if (id == null || (id is String && id.isEmpty)) return 'Open seat';
    if (id is String && _botNames.containsKey(id)) return _botNames[id]!;
    return 'You';
  }

  void selectGame(String id) {
    _selectedGameId = id;
    notifyListeners();
  }

  // ── Chess ──────────────────────────────────────────────────
  void createChessGame({bool playAsWhite = true}) {
    final id = 'bot_chess_${DateTime.now().millisecondsSinceEpoch}';
    final game = BotGame(
      id: id,
      gameType: 'chess',
      state: {
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'moves': <String>[],
      },
      players: {
        'white': playAsWhite ? 'player' : _botId,
        'black': playAsWhite ? _botId : 'player',
      },
      createdAt: DateTime.now(),
    );
    _games.insert(0, game);
    _selectedGameId = id;
    notifyListeners();

    // If bot plays white, make the first move
    if (!playAsWhite) _scheduleBotChessMove(id);
  }

  void makeChessMove(String gameId, String from, String to) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null || !game.isActive) return;

    final fen = game.state['fen'] as String;
    final moves = List<String>.from(game.state['moves'] as List? ?? []);
    final chess = chess_lib.Chess.fromFEN(fen);

    final moved = chess.move({'from': from, 'to': to, 'promotion': 'q'});
    if (!moved) return;

    moves.add(chess.history.last.toString());
    game.state = {'fen': chess.fen, 'moves': moves};

    _checkChessResult(game, chess);
    notifyListeners();

    // Schedule bot reply
    if (game.isActive) _scheduleBotChessMove(gameId);
  }

  void _scheduleBotChessMove(String gameId) {
    _botThinking = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 600), () {
      final game = _games.where((g) => g.id == gameId).firstOrNull;
      if (game == null || !game.isActive) {
        _botThinking = false;
        notifyListeners();
        return;
      }

      final fen = game.state['fen'] as String;
      final chess = chess_lib.Chess.fromFEN(fen);

      // Check if it's bot's turn
      final isWhite = chess.turn == chess_lib.Color.WHITE;
      final botColor = game.players['white'] == _botId ? 'white' : 'black';
      final isBotTurn = (isWhite && botColor == 'white') || (!isWhite && botColor == 'black');

      if (!isBotTurn || chess.game_over) {
        _botThinking = false;
        notifyListeners();
        return;
      }

      final bestMove = ChessBot.getBestMove(fen, depth: 3);
      if (bestMove == null) {
        _botThinking = false;
        notifyListeners();
        return;
      }

      final moves = List<String>.from(game.state['moves'] as List? ?? []);
      chess.move(bestMove);
      moves.add(bestMove);
      game.state = {'fen': chess.fen, 'moves': moves};
      _checkChessResult(game, chess);
      _botThinking = false;
      notifyListeners();
    });
  }

  void _checkChessResult(BotGame game, chess_lib.Chess chess) {
    if (!chess.game_over) return;
    game.isActive = false;
    if (chess.in_checkmate) {
      // The side whose turn it is has been checkmated
      final loser = chess.turn == chess_lib.Color.WHITE ? 'white' : 'black';
      final loserIsBot = game.players[loser] == _botId;
      game.result = loserIsBot ? '🎉 You win by checkmate!' : '😞 Computer wins by checkmate.';
    } else if (chess.in_stalemate) {
      game.result = '🤝 Stalemate — Draw.';
    } else if (chess.in_draw) {
      game.result = '🤝 Draw.';
    }
  }

  // ── Ludo ───────────────────────────────────────────────────
  void createLudoGame({String playerColor = 'red'}) {
    final id = 'bot_ludo_${DateTime.now().millisecondsSinceEpoch}';
    final players = <String, dynamic>{};
    for (final c in ludoColorNames) {
      players[c] = c == playerColor ? 'player' : 'bot_${ludoColorNames.indexOf(c)}';
    }
    final game = BotGame(
      id: id,
      gameType: 'ludo',
      state: {
        'turn': 'red',
        'dice': null,
        'tokens': {
          'red': [0, 0, 0, 0],
          'blue': [0, 0, 0, 0],
          'green': [0, 0, 0, 0],
          'yellow': [0, 0, 0, 0],
        },
        'winner': null,
      },
      players: players,
      createdAt: DateTime.now(),
    );
    _games.insert(0, game);
    _selectedGameId = id;
    notifyListeners();

    // If bot goes first, start bot turn
    if (playerColor != 'red') _scheduleBotLudoTurn(id);
  }

  void rollLudoDice(String gameId) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null || !game.isActive) return;
    final state = game.state;
    if (state['dice'] != null || state['winner'] != null) return;

    final dice = Random().nextInt(6) + 1;
    game.state = {...state, 'dice': dice};
    notifyListeners();

    // Check if player has any valid moves
    final turn = state['turn'] as String;
    final tokens = List<int>.from((state['tokens'] as Map)[turn] as List);
    final hasMove = tokens.any((t) => t < 56 && (t > 0 || dice == 6));
    if (!hasMove) {
      // Skip turn
      Future.delayed(const Duration(milliseconds: 500), () {
        _advanceLudoTurn(gameId);
      });
    }
  }

  void moveLudoToken(String gameId, String color, int tokenIdx) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null || !game.isActive) return;
    final state = Map<String, dynamic>.from(game.state);
    final dice = state['dice'] as int?;
    if (dice == null) return;

    final allTokens = Map<String, dynamic>.from(state['tokens'] as Map);
    final colorTokens = List<int>.from(allTokens[color] as List);
    if (colorTokens[tokenIdx] >= 56) return;
    if (colorTokens[tokenIdx] == 0 && dice != 6) return;

    colorTokens[tokenIdx] = (colorTokens[tokenIdx] + dice).clamp(0, 56);
    allTokens[color] = colorTokens;
    state['tokens'] = allTokens;
    state['dice'] = null;

    // Check winner
    if (colorTokens.every((t) => t >= 56)) {
      state['winner'] = color;
      game.isActive = false;
      final isPlayer = game.players[color] == 'player';
      game.result = isPlayer ? '🎉 You win!' : '🤖 ${color[0].toUpperCase()}${color.substring(1)} bot wins!';
    }

    game.state = state;
    notifyListeners();

    if (game.isActive && state['winner'] == null) {
      _advanceLudoTurn(gameId);
    }
  }

  void _advanceLudoTurn(String gameId) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null || !game.isActive) return;

    final state = Map<String, dynamic>.from(game.state);
    final currentTurn = state['turn'] as String;
    final idx = ludoColorNames.indexOf(currentTurn);
    final nextColor = ludoColorNames[(idx + 1) % 4];
    state['turn'] = nextColor;
    state['dice'] = null;
    game.state = state;
    notifyListeners();

    // If next turn is a bot, schedule bot move
    if (game.players[nextColor] != 'player') {
      _scheduleBotLudoTurn(gameId);
    }
  }

  void _scheduleBotLudoTurn(String gameId) {
    _botThinking = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      final game = _games.where((g) => g.id == gameId).firstOrNull;
      if (game == null || !game.isActive) {
        _botThinking = false;
        notifyListeners();
        return;
      }

      final state = Map<String, dynamic>.from(game.state);
      final turn = state['turn'] as String;
      if (game.players[turn] == 'player') {
        _botThinking = false;
        notifyListeners();
        return;
      }

      // Roll dice
      final dice = Random().nextInt(6) + 1;
      final allTokens = state['tokens'] as Map<String, dynamic>;
      final myTokens = List<int>.from(allTokens[turn] as List);

      // Gather opponent positions
      final opponentPos = <int>[];
      for (final c in ludoColorNames) {
        if (c != turn) {
          opponentPos.addAll(List<int>.from(allTokens[c] as List).where((p) => p > 0 && p < 56));
        }
      }

      final tokenIdx = LudoBot.chooseToken(myTokens, dice, opponentPos);

      if (tokenIdx >= 0) {
        myTokens[tokenIdx] = (myTokens[tokenIdx] + dice).clamp(0, 56);
        final newAllTokens = Map<String, dynamic>.from(allTokens);
        newAllTokens[turn] = myTokens;
        state['tokens'] = newAllTokens;

        if (myTokens.every((t) => t >= 56)) {
          state['winner'] = turn;
          game.isActive = false;
          game.result = '🤖 ${turn[0].toUpperCase()}${turn.substring(1)} bot wins!';
        }
      }

      game.state = state;
      _botThinking = false;
      notifyListeners();

      if (game.isActive) {
        _advanceLudoTurn(gameId);
      }
    });
  }

  // ── Cards ──────────────────────────────────────────────────
  void createCardsGame({int botCount = 1}) {
    final id = 'bot_cards_${DateTime.now().millisecondsSinceEpoch}';
    final order = <String>['player'];
    for (int i = 0; i < botCount.clamp(1, 3); i++) {
      order.add('bot_$i');
    }

    // Deal initial hands
    final deck = _shuffledDeck();
    final hands = <String, dynamic>{};
    for (final pid in order) {
      hands[pid] = deck.take(5).toList();
      deck.removeRange(0, 5.clamp(0, deck.length));
    }

    final game = BotGame(
      id: id,
      gameType: 'cards',
      state: {
        'deck': deck,
        'hands': hands,
        'table': <String, dynamic>{},
        'scores': <String, dynamic>{},
        'round': 1,
        'order': order,
      },
      players: {'order': order},
      createdAt: DateTime.now(),
    );
    _games.insert(0, game);
    _selectedGameId = id;
    notifyListeners();
  }

  void playCard(String gameId, String card) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null || !game.isActive) return;
    final state = Map<String, dynamic>.from(game.state);
    final hands = Map<String, dynamic>.from(state['hands'] as Map);
    final table = Map<String, dynamic>.from(state['table'] as Map);
    final myHand = List<String>.from(hands['player'] as List? ?? []);

    if (table['player'] != null || !myHand.contains(card)) return;

    myHand.remove(card);
    hands['player'] = myHand;
    table['player'] = card;
    state['hands'] = hands;
    state['table'] = table;
    game.state = state;
    notifyListeners();

    // Trigger bot plays
    _scheduleBotCardPlays(gameId);
  }

  void _scheduleBotCardPlays(String gameId) {
    _botThinking = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      final game = _games.where((g) => g.id == gameId).firstOrNull;
      if (game == null || !game.isActive) {
        _botThinking = false;
        notifyListeners();
        return;
      }

      final state = Map<String, dynamic>.from(game.state);
      final hands = Map<String, dynamic>.from(state['hands'] as Map);
      final table = Map<String, dynamic>.from(state['table'] as Map);
      final order = List<String>.from(state['order'] as List);

      // Each bot plays
      for (final pid in order) {
        if (pid == 'player' || table[pid] != null) continue;
        final botHand = List<String>.from(hands[pid] as List? ?? []);
        if (botHand.isEmpty) continue;
        final chosen = CardsBot.chooseCard(botHand, table, order);
        if (chosen != null) {
          botHand.remove(chosen);
          hands[pid] = botHand;
          table[pid] = chosen;
        }
      }

      state['hands'] = hands;
      state['table'] = table;
      game.state = state;
      _botThinking = false;
      notifyListeners();

      // Check if all played — auto-settle after delay
      if (order.every((id) => table[id] != null)) {
        Future.delayed(const Duration(seconds: 1), () => _settleCardRound(gameId));
      }
    });
  }

  void _settleCardRound(String gameId) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null) return;

    final state = Map<String, dynamic>.from(game.state);
    final table = Map<String, dynamic>.from(state['table'] as Map);
    final scores = Map<String, dynamic>.from(state['scores'] as Map);
    final order = List<String>.from(state['order'] as List);
    final round = (state['round'] as int? ?? 1);

    // Find winner of this round (highest rank)
    final entries = order.map((id) => MapEntry(id, table[id] as String?)).where((e) => e.value != null).toList();
    if (entries.isEmpty) return;
    entries.sort((a, b) =>
        cardRanks.indexOf(b.value!.replaceAll(RegExp(r'[SHDC]'), '')) -
        cardRanks.indexOf(a.value!.replaceAll(RegExp(r'[SHDC]'), '')));
    final winner = entries.first.key;
    scores[winner] = ((scores[winner] as int?) ?? 0) + 1;

    state['scores'] = scores;
    state['table'] = <String, dynamic>{};
    state['round'] = round + 1;
    game.state = state;

    // Check if any hand is empty (game over)
    final hands = state['hands'] as Map<String, dynamic>;
    final allEmpty = order.every((id) => (hands[id] as List?)?.isEmpty ?? true);
    if (allEmpty) {
      game.isActive = false;
      final playerScore = (scores['player'] as int?) ?? 0;
      final maxBotScore = order.where((id) => id != 'player').map((id) => (scores[id] as int?) ?? 0).fold<int>(0, max);
      if (playerScore > maxBotScore) {
        game.result = '🎉 You win with $playerScore points!';
      } else if (playerScore == maxBotScore) {
        game.result = '🤝 Tie at $playerScore points!';
      } else {
        game.result = '🤖 Bot wins with $maxBotScore points!';
      }
    }

    notifyListeners();
  }

  void dealCards(String gameId) {
    final game = _games.where((g) => g.id == gameId).firstOrNull;
    if (game == null || !game.isActive) return;
    final state = Map<String, dynamic>.from(game.state);
    final order = List<String>.from(state['order'] as List);
    final scores = Map<String, dynamic>.from(state['scores'] as Map);
    final round = (state['round'] as int? ?? 1);

    final deck = _shuffledDeck();
    final hands = <String, dynamic>{};
    for (final pid in order) {
      hands[pid] = deck.take(5).toList();
      deck.removeRange(0, 5.clamp(0, deck.length));
    }

    game.state = {
      'deck': deck,
      'hands': hands,
      'table': <String, dynamic>{},
      'scores': scores,
      'round': round,
      'order': order,
    };
    notifyListeners();
  }

  void deleteGame(String gameId) {
    _games.removeWhere((g) => g.id == gameId);
    if (_selectedGameId == gameId) {
      _selectedGameId = _games.isNotEmpty ? _games.first.id : null;
    }
    notifyListeners();
  }

  List<String> _shuffledDeck() {
    final deck = [for (final s in cardSuits) for (final r in cardRanks) '$r$s'];
    deck.shuffle(Random());
    return deck;
  }
}
