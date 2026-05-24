import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class GamesView extends StatefulWidget {
  const GamesView({super.key});
  @override
  State<GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<GamesView> {
  String _roomId = '';
  String _selectedGameId = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    if (_roomId.isEmpty && app.activeRoom != null) _roomId = app.activeRoom!.id;
    final roomGames = app.gameSessions.where((g) => g.roomId == _roomId && g.isActive).toList();
    final selected = roomGames.where((g) => g.id == _selectedGameId).firstOrNull ?? roomGames.firstOrNull;
    final joined = app.participants.any((p) => p.roomId == _roomId && p.userId == app.profile?.id);
    final isWide = MediaQuery.of(context).size.width > 900;

    final sidebar = VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const VSectionTitle(icon: Icons.sports_esports_outlined, title: 'Games'),
      DropdownButtonFormField<String>(
        initialValue: app.liveRooms.any((r) => r.id == _roomId) ? _roomId : null,
        decoration: const InputDecoration(labelText: 'Room'),
        items: app.liveRooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.title))).toList(),
        onChanged: (v) => setState(() => _roomId = v ?? ''),
      ),
      const SizedBox(height: 14),
      ...['chess', 'ludo', 'cards'].map((g) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: !joined || _roomId.isEmpty ? null : () => app.createGame(_roomId, g),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: VoxoraColors.line), borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.94), const Color(0xFFF6F1FF).withValues(alpha: 0.88)]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_gameTitle(g), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(_gameSub(g), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      )),
      const SizedBox(height: 8),
      ...roomGames.map((g) => Padding(padding: const EdgeInsets.only(bottom: 8), child: VListRow(
        isActive: selected?.id == g.id, onTap: () => setState(() => _selectedGameId = g.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${g.gameType} / ${_fmtTime(g.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ))),
    ]));

    final stage = selected != null
        ? VPanel(child: _GameBoard(game: selected))
        : VPanel(child: const VEmptyState(icon: Icons.sports_esports_outlined, title: 'No game selected', body: 'Join a room and start a game.'));

    if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 360, child: sidebar), const SizedBox(width: 18), Expanded(child: stage)]);
    return Column(children: [sidebar, const SizedBox(height: 18), stage]);
  }

  String _gameTitle(String t) => {'chess': 'Chess', 'ludo': 'Ludo', 'cards': 'Cards'}[t] ?? t;
  String _gameSub(String t) => {'chess': 'Classic strategy', 'ludo': 'Race to home', 'cards': 'Fast rounds'}[t] ?? '';
  String _fmtTime(String iso) { try { final d = DateTime.parse(iso); return '${d.hour}:${d.minute.toString().padLeft(2, '0')}'; } catch (_) { return ''; } }
}

class _GameBoard extends StatefulWidget {
  final GameSession game;
  const _GameBoard({required this.game});
  @override
  State<_GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<_GameBoard> {
  String? _selectedSquare;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.game.gameType.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          Text(widget.game.title, style: Theme.of(context).textTheme.headlineMedium),
        ]),
        VSecondaryButton(label: 'Join', onTap: () => app.joinGame(widget.game)),
      ]),
      const Divider(height: 28),
      if (widget.game.gameType == 'chess') _chessBoard(app),
      if (widget.game.gameType == 'ludo') _ludoBoard(app),
      if (widget.game.gameType == 'cards') _cardsTable(app),
    ]);
  }

  Widget _chessBoard(AppProvider app) {
    final state = widget.game.state;
    final fen = state['fen'] as String? ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    final moves = (state['moves'] as List?)?.cast<String>() ?? [];
    final players = widget.game.players;
    final c = chess_lib.Chess.fromFEN(fen);
    final myColor = players['white'] == app.profile?.id ? 'white' : players['black'] == app.profile?.id ? 'black' : null;
    final turnColor = c.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    final status = c.in_checkmate ? '${turnColor == 'white' ? 'Black' : 'White'} wins!' : c.in_draw ? 'Draw' : '$turnColor to move';
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    return Column(children: [
      _metaRow([Text('White: ${app.profileName(players['white'])}'), Text('Black: ${app.profileName(players['black'])}'), Text(status, style: const TextStyle(fontWeight: FontWeight.w700))]),
      const SizedBox(height: 12),
      AspectRatio(aspectRatio: 1, child: GridView.count(
        crossAxisCount: 8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: [for (final rank in ranks) for (final file in files) _chessSquare(c, '$file$rank', myColor, turnColor, app, fen, moves)],
      )),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: moves.reversed.take(12).map((m) => Chip(label: Text(m))).toList()),
    ]);
  }

  Widget _chessSquare(chess_lib.Chess c, String sq, String? myColor, String turnColor, AppProvider app, String fen, List<String> moves) {
    final fileIdx = sq.codeUnitAt(0) - 97;
    final rankIdx = 8 - int.parse(sq[1]);
    final isDark = (fileIdx + rankIdx) % 2 == 1;
    final piece = c.get(sq);
    final isSelected = _selectedSquare == sq;

    return GestureDetector(
      onTap: () {
        if (myColor == null || myColor != turnColor || c.game_over) return;
        if (_selectedSquare == null) {
          if (piece != null && piece.color == (myColor == 'white' ? chess_lib.Color.WHITE : chess_lib.Color.BLACK)) {
            setState(() => _selectedSquare = sq);
          }
          return;
        }
        final nc = chess_lib.Chess.fromFEN(fen);
        final moved = nc.move({'from': _selectedSquare!, 'to': sq, 'promotion': 'q'});
        if (moved) {
          app.updateGame(widget.game.id, {'state': {'fen': nc.fen, 'moves': [...moves, nc.history.last.toString()]}});
        } else if (piece != null && piece.color == (myColor == 'white' ? chess_lib.Color.WHITE : chess_lib.Color.BLACK)) {
          setState(() => _selectedSquare = sq);
          return;
        }
        setState(() => _selectedSquare = null);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? VoxoraColors.lime : isDark ? VoxoraColors.primary : const Color(0xFFF8F1DF),
        ),
        alignment: Alignment.center,
        child: Text(piece != null ? _pieceChar(piece) : '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark && !isSelected ? Colors.white : VoxoraColors.surfaceStrong)),
      ),
    );
  }

  String _pieceChar(chess_lib.Piece p) {
    const w = {'p': '\u2659', 'r': '\u2656', 'n': '\u2658', 'b': '\u2657', 'q': '\u2655', 'k': '\u2654'};
    const b = {'p': '\u265F', 'r': '\u265C', 'n': '\u265E', 'b': '\u265D', 'q': '\u265B', 'k': '\u265A'};
    final t = p.type.toString().toLowerCase();
    return p.color == chess_lib.Color.WHITE ? (w[t] ?? '') : (b[t] ?? '');
  }

  Widget _ludoBoard(AppProvider app) {
    final state = widget.game.state;
    final turn = state['turn'] as String? ?? 'red';
    final dice = state['dice'] as int?;
    final tokens = state['tokens'] as Map<String, dynamic>? ?? {};
    final winner = state['winner'] as String?;
    final players = widget.game.players;
    final myColor = ludoColorNames.firstWhere((c) => players[c] == app.profile?.id, orElse: () => '');
    final activeColors = ludoColorNames.where((c) => players[c] != null).toList();
    final canPlay = myColor == turn && winner == null;

    String nextTurn(String current) {
      final order = activeColors.isNotEmpty ? activeColors : ludoColorNames;
      final i = order.indexOf(current);
      return order[(i + 1) % order.length];
    }

    return Column(children: [
      _metaRow([
        Text(winner != null ? '$winner wins' : '$turn turn', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('Dice: ${dice ?? "-"}'),
        VGradientButton(label: 'Roll', onTap: !canPlay || dice != null ? null : () {
          final d = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
          app.updateGame(widget.game.id, {'state': {...state, 'dice': d}});
        }),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: ludoColorNames.map((color) {
        final colorTokens = (tokens[color] as List?)?.cast<int>() ?? [0, 0, 0, 0];
        final laneColors = {'red': VoxoraColors.coral, 'blue': VoxoraColors.cyan, 'green': const Color(0xFF20C997), 'yellow': const Color(0xFFF8C51C)};
        return Container(width: 200, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: VoxoraColors.line), borderRadius: BorderRadius.circular(8), color: Colors.white),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 5, decoration: BoxDecoration(color: laneColors[color], borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Text(color, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(app.profileName(players[color]), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: List.generate(4, (i) =>
              ElevatedButton(
                onPressed: myColor != color || dice == null ? null : () {
                  final newTokens = Map<String, dynamic>.from(tokens);
                  final ct = List<int>.from(colorTokens);
                  ct[i] = (ct[i] + dice).clamp(0, 56);
                  newTokens[color] = ct;
                  final w = ct.every((p) => p >= 56) ? color : winner;
                  app.updateGame(widget.game.id, {'state': {...state, 'tokens': newTokens, 'dice': null, 'turn': w != null ? turn : nextTurn(turn), 'winner': w}});
                },
                child: Text('T${i + 1}: ${colorTokens[i]}'),
              ),
            )),
          ]),
        );
      }).toList()),
    ]);
  }

  Widget _cardsTable(AppProvider app) {
    final state = widget.game.state;
    final deck = (state['deck'] as List?)?.cast<String>() ?? [];
    final hands = state['hands'] as Map<String, dynamic>? ?? {};
    final table = state['table'] as Map<String, dynamic>? ?? {};
    final scores = state['scores'] as Map<String, dynamic>? ?? {};
    final round = state['round'] as int? ?? 1;
    final order = (widget.game.players['order'] as List?)?.cast<String>() ?? [];
    final myHand = (hands[app.profile?.id] as List?)?.cast<String>() ?? [];
    final allPlayed = order.isNotEmpty && order.every((id) => table[id] != null);

    void deal() {
      final d = List<String>.from([for (final s in cardSuits) for (final r in cardRanks) '$r$s'])..shuffle();
      final h = <String, dynamic>{};
      for (final id in order) { h[id] = d.take(5).toList(); d.removeRange(0, 5.clamp(0, d.length)); }
      app.updateGame(widget.game.id, {'state': {'deck': d, 'hands': h, 'table': {}, 'scores': scores, 'round': round + 1}});
    }

    void settle() {
      final entries = order.map((id) => MapEntry(id, table[id] as String?)).where((e) => e.value != null).toList();
      if (entries.isEmpty) return;
      entries.sort((a, b) => cardRanks.indexOf(b.value!.replaceAll(RegExp(r'[SHDC]'), '')) - cardRanks.indexOf(a.value!.replaceAll(RegExp(r'[SHDC]'), '')));
      final w = entries.first.key;
      final s = Map<String, dynamic>.from(scores);
      s[w] = ((s[w] as int?) ?? 0) + 1;
      app.updateGame(widget.game.id, {'state': {...state, 'scores': s, 'table': {}, 'round': round + 1}});
    }

    return Column(children: [
      _metaRow([
        Text('Round $round', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('Deck: ${deck.length}'),
        VGradientButton(label: 'Deal', onTap: order.length < 2 ? null : deal),
        VSecondaryButton(label: 'Score', onTap: !allPlayed ? null : settle),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: order.map((id) => Container(
        width: 150, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: VoxoraColors.line), borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.profileName(id), style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('Score ${(scores[id] as int?) ?? 0}', style: Theme.of(context).textTheme.bodySmall),
          Text(table[id] != null ? 'Played ${table[id]}' : '${(hands[id] as List?)?.length ?? 0} cards', style: Theme.of(context).textTheme.bodySmall),
        ]),
      )).toList()),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: myHand.map((card) => OutlinedButton(
        onPressed: table[app.profile?.id] != null ? null : () {
          final h = Map<String, dynamic>.from(hands);
          h[app.profile!.id] = myHand.where((c) => c != card).toList();
          final t = Map<String, dynamic>.from(table);
          t[app.profile!.id] = card;
          app.updateGame(widget.game.id, {'state': {...state, 'hands': h, 'table': t}});
        },
        child: Text(card, style: const TextStyle(fontWeight: FontWeight.w800)),
      )).toList()),
    ]);
  }

  Widget _metaRow(List<Widget> children) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(border: Border.all(color: VoxoraColors.line), borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.78)),
    child: Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: children),
  );
}
