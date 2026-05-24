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
        decoration: const InputDecoration(labelText: 'Select Room', prefixIcon: Icon(Icons.radio, size: 18, color: VoxoraColors.muted)),
        dropdownColor: VoxoraColors.surface,
        style: const TextStyle(color: VoxoraColors.text),
        items: app.liveRooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.title))).toList(),
        onChanged: (v) => setState(() => _roomId = v ?? ''),
      ),
      const SizedBox(height: 16),
      Text('NEW GAME', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 10),
      ...['chess', 'ludo', 'cards'].map((g) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _GameTypeCard(
          type: g,
          enabled: joined && _roomId.isNotEmpty,
          onTap: () => app.createGame(_roomId, g),
        ),
      )),
      const SizedBox(height: 12),
      if (roomGames.isNotEmpty) ...[
        Text('ACTIVE GAMES', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        ...roomGames.map((g) => Padding(padding: const EdgeInsets.only(bottom: 8), child: VListRow(
          isActive: selected?.id == g.id, onTap: () => setState(() => _selectedGameId = g.id),
          child: Row(children: [
            Icon(_gameIcon(g.gameType), size: 18, color: VoxoraColors.lime),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text)),
              Text('${g.gameType} · ${_fmtTime(g.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
        ))),
      ] else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('No active games in this room.', style: Theme.of(context).textTheme.bodySmall),
        ),
    ]));

    final stage = selected != null
        ? VPanel(child: _GameBoard(game: selected))
        : VPanel(child: const VEmptyState(icon: Icons.sports_esports_outlined, title: 'No game selected', body: 'Join a room and start a game from the sidebar.'));

    if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 360, child: sidebar), const SizedBox(width: 18), Expanded(child: stage)]);
    return Column(children: [sidebar, const SizedBox(height: 18), stage]);
  }

  IconData _gameIcon(String t) => {'chess': Icons.grid_on, 'ludo': Icons.casino, 'cards': Icons.style}[t] ?? Icons.sports_esports;
  String _fmtTime(String iso) { try { final d = DateTime.parse(iso); return '${d.hour}:${d.minute.toString().padLeft(2, '0')}'; } catch (_) { return ''; } }
}

class _GameTypeCard extends StatefulWidget {
  final String type;
  final bool enabled;
  final VoidCallback onTap;
  const _GameTypeCard({required this.type, required this.enabled, required this.onTap});
  @override
  State<_GameTypeCard> createState() => _GameTypeCardState();
}

class _GameTypeCardState extends State<_GameTypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final info = {
      'chess': ('Chess', 'Classic strategy • 2 players', Icons.grid_on, VoxoraColors.lime),
      'ludo': ('Ludo', 'Race to home • 2-4 players', Icons.casino, VoxoraColors.primary),
      'cards': ('Cards', 'Quick rounds • 2+ players', Icons.style, VoxoraColors.cyan),
    };
    final data = info[widget.type]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _hovered && widget.enabled ? data.$4.withValues(alpha: 0.5) : VoxoraColors.line),
            borderRadius: BorderRadius.circular(12),
            color: _hovered && widget.enabled ? data.$4.withValues(alpha: 0.08) : VoxoraColors.surfaceLight,
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: data.$4.withValues(alpha: 0.15),
              ),
              child: Icon(data.$3, size: 20, color: data.$4),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.$1, style: const TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text)),
              Text(data.$2, style: Theme.of(context).textTheme.bodySmall),
            ])),
            if (widget.enabled) Icon(Icons.add_circle_outline, size: 18, color: data.$4),
          ]),
        ),
      ),
    );
  }
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
          VStatusBadge(label: widget.game.gameType.toUpperCase(), color: VoxoraColors.lime, icon: Icons.sports_esports),
          const SizedBox(height: 8),
          Text(widget.game.title, style: Theme.of(context).textTheme.headlineMedium),
        ]),
        VSecondaryButton(label: 'Join Game', icon: Icons.login, onTap: () => app.joinGame(widget.game)),
      ]),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 16),
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
      _metaRow([
        _playerTag('White', app.profileName(players['white']), VoxoraColors.text),
        const Text(' vs ', style: TextStyle(color: VoxoraColors.muted)),
        _playerTag('Black', app.profileName(players['black']), VoxoraColors.muted),
        const SizedBox(width: 12),
        VStatusBadge(label: status, color: c.in_checkmate ? VoxoraColors.danger : VoxoraColors.cyan),
      ]),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AspectRatio(aspectRatio: 1, child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VoxoraColors.line, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: GridView.count(
            crossAxisCount: 8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: [for (final rank in ranks) for (final file in files) _chessSquare(c, '$file$rank', myColor, turnColor, app, fen, moves)],
          ),
        )),
      ),
      const SizedBox(height: 14),
      if (moves.isNotEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: moves.reversed.take(12).map((m) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: VoxoraColors.surfaceLight,
              border: Border.all(color: VoxoraColors.line),
            ),
            child: Text(m, style: const TextStyle(fontSize: 12, color: VoxoraColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ).toList()),
    ]);
  }

  Widget _playerTag(String role, String name, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: role == 'White' ? Colors.white : VoxoraColors.surfaceStrong,
          border: Border.all(color: VoxoraColors.line),
        ),
      ),
      const SizedBox(width: 6),
      Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
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
          color: isSelected
              ? VoxoraColors.lime.withValues(alpha: 0.6)
              : isDark ? const Color(0xFF3D5A80) : const Color(0xFF1A2332),
        ),
        alignment: Alignment.center,
        child: Text(
          piece != null ? _pieceChar(piece) : '',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: piece != null && piece.color == chess_lib.Color.WHITE
                ? Colors.white
                : const Color(0xFFFFD166),
          ),
        ),
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

    final laneColors = {
      'red': VoxoraColors.primary,
      'blue': VoxoraColors.cyan,
      'green': VoxoraColors.success,
      'yellow': VoxoraColors.lime,
    };

    return Column(children: [
      _metaRow([
        VStatusBadge(
          label: winner != null ? '$winner wins!' : '$turn\'s turn',
          color: laneColors[winner ?? turn] ?? VoxoraColors.muted,
          icon: winner != null ? Icons.emoji_events : Icons.circle,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: VoxoraColors.surfaceLight,
            border: Border.all(color: VoxoraColors.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.casino, size: 18, color: VoxoraColors.lime),
            const SizedBox(width: 6),
            Text(dice != null ? '$dice' : '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: VoxoraColors.text)),
          ]),
        ),
        const SizedBox(width: 8),
        VGradientButton(label: 'Roll Dice', icon: Icons.casino, onTap: !canPlay || dice != null ? null : () {
          final d = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
          app.updateGame(widget.game.id, {'state': {...state, 'dice': d}});
        }),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 14, runSpacing: 14, children: ludoColorNames.map((color) {
        final colorTokens = (tokens[color] as List?)?.cast<int>() ?? [0, 0, 0, 0];
        final playerColor = laneColors[color]!;
        final isMyTurn = myColor == color && canPlay;
        return Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isMyTurn ? playerColor.withValues(alpha: 0.5) : VoxoraColors.line),
            borderRadius: BorderRadius.circular(14),
            color: VoxoraColors.surfaceLight,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 4, decoration: BoxDecoration(color: playerColor, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 10),
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: playerColor)),
              const SizedBox(width: 8),
              Text(color[0].toUpperCase() + color.substring(1), style: TextStyle(fontWeight: FontWeight.w800, color: playerColor)),
            ]),
            Text(app.profileName(players[color]), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: List.generate(4, (i) {
              final pos = colorTokens[i];
              final finished = pos >= 56;
              return GestureDetector(
                onTap: myColor != color || dice == null ? null : () {
                  final newTokens = Map<String, dynamic>.from(tokens);
                  final ct = List<int>.from(colorTokens);
                  ct[i] = (ct[i] + dice).clamp(0, 56);
                  newTokens[color] = ct;
                  final w = ct.every((p) => p >= 56) ? color : winner;
                  app.updateGame(widget.game.id, {'state': {...state, 'tokens': newTokens, 'dice': null, 'turn': w != null ? turn : nextTurn(turn), 'winner': w}});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: finished ? playerColor.withValues(alpha: 0.2) : VoxoraColors.surface,
                    border: Border.all(color: finished ? playerColor.withValues(alpha: 0.4) : VoxoraColors.line),
                  ),
                  child: Column(children: [
                    Text('T${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: playerColor)),
                    Text('$pos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: finished ? playerColor : VoxoraColors.text)),
                  ]),
                ),
              );
            })),
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
        VStatusBadge(label: 'Round $round', color: VoxoraColors.lime, icon: Icons.replay),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: VoxoraColors.surfaceLight,
            border: Border.all(color: VoxoraColors.line),
          ),
          child: Text('Deck: ${deck.length}', style: const TextStyle(fontSize: 12, color: VoxoraColors.muted, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        VGradientButton(label: 'Deal', icon: Icons.style, onTap: order.length < 2 ? null : deal),
        const SizedBox(width: 8),
        VSecondaryButton(label: 'Score Round', icon: Icons.check, onTap: !allPlayed ? null : settle),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, children: order.map((id) {
        final score = (scores[id] as int?) ?? 0;
        final played = table[id] as String?;
        final cardCount = (hands[id] as List?)?.length ?? 0;
        return Container(
          width: 160, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: played != null ? VoxoraColors.success.withValues(alpha: 0.3) : VoxoraColors.line),
            borderRadius: BorderRadius.circular(12),
            color: VoxoraColors.surfaceLight,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.profileName(id), style: const TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.emoji_events, size: 14, color: VoxoraColors.lime),
              const SizedBox(width: 4),
              Text('$score', style: const TextStyle(fontWeight: FontWeight.w800, color: VoxoraColors.lime)),
            ]),
            const SizedBox(height: 4),
            Text(played != null ? 'Played: $played' : '$cardCount cards',
              style: TextStyle(fontSize: 12, color: played != null ? VoxoraColors.success : VoxoraColors.muted)),
          ]),
        );
      }).toList()),
      const SizedBox(height: 16),
      if (myHand.isNotEmpty) ...[
        Text('YOUR HAND', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: myHand.map((card) {
          final suit = card.replaceAll(RegExp(r'[^SHDC]'), '');
          final isRed = suit == 'H' || suit == 'D';
          return GestureDetector(
            onTap: table[app.profile?.id] != null ? null : () {
              final h = Map<String, dynamic>.from(hands);
              h[app.profile!.id] = myHand.where((c) => c != card).toList();
              final t = Map<String, dynamic>.from(table);
              t[app.profile!.id] = card;
              app.updateGame(widget.game.id, {'state': {...state, 'hands': h, 'table': t}});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: VoxoraColors.surface,
                border: Border.all(color: isRed ? VoxoraColors.primary.withValues(alpha: 0.4) : VoxoraColors.line),
              ),
              child: Text(card, style: TextStyle(fontWeight: FontWeight.w800, color: isRed ? VoxoraColors.primary : VoxoraColors.text)),
            ),
          );
        }).toList()),
      ],
    ]);
  }

  Widget _metaRow(List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: VoxoraColors.line),
      borderRadius: BorderRadius.circular(12),
      color: VoxoraColors.surfaceLight,
    ),
    child: Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: children),
  );
}
