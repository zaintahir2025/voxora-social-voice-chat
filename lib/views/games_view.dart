import 'dart:math';

import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/bot_game_provider.dart';
import '../services/ludo_rules.dart';
import '../widgets/common_widgets.dart';

class GamesView extends StatefulWidget {
  const GamesView({super.key});

  @override
  State<GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<GamesView> {
  final _joinCode = TextEditingController();
  String? _selectedBotId;

  @override
  void dispose() {
    _joinCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bot = context.watch<BotGameProvider>();
    final wide = MediaQuery.of(context).size.width >= 980;
    final selectedBot = _selectedBotId == null
        ? null
        : bot.games.where((game) => game.id == _selectedBotId).firstOrNull;

    final sidebar = _sidebar(app, bot);
    final board = selectedBot != null
        ? _GameStage.bot(game: selectedBot)
        : _GameStage.friend(game: app.activeGame);

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: sidebar),
          const SizedBox(width: 14),
          Expanded(child: board),
        ],
      );
    }
    return Column(children: [sidebar, const SizedBox(height: 14), board]);
  }

  Widget _sidebar(AppProvider app, BotGameProvider bot) {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                icon: Icons.sports_esports_outlined,
                title: 'Gaming pages',
                subtitle: 'Start with friends or computer.',
              ),
              ...['chess', 'ludo', 'cards'].map(
                (type) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GameStartTile(
                    type: type,
                    onTap: () => _startGame(type),
                  ),
                ),
              ),
              const Divider(height: 24),
              TextField(
                controller: _joinCode,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Join friend game code',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => app.joinGameByCode(_joinCode.text),
                  icon: const Icon(Icons.login),
                  label: const Text('Join game'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                icon: Icons.group_outlined,
                title: 'Friend games',
              ),
              if (app.gameSessions.isEmpty)
                Text(
                  'No friend games yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...app.gameSessions.map((game) {
                  final players = app.playersForGame(game.id);
                  return ListTile(
                    selected:
                        app.activeGame?.id == game.id && _selectedBotId == null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(_gameIcon(game.gameType)),
                    title: Text(
                      '${gameTitles[game.gameType]} - ${game.status}',
                    ),
                    subtitle: Text(
                      'Code ${game.inviteCode} - ${players.length}/${game.maxPlayers} players',
                    ),
                    onTap: () {
                      setState(() => _selectedBotId = null);
                      app.selectGame(game.id);
                    },
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                icon: Icons.smart_toy_outlined,
                title: 'Computer games',
              ),
              if (bot.games.isEmpty)
                Text(
                  'Computer games stay on this device.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...bot.games.map((game) {
                  return ListTile(
                    selected: _selectedBotId == game.id,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(_gameIcon(game.gameType)),
                    title: Text('${gameTitles[game.gameType]} vs computer'),
                    subtitle: Text(
                      game.result ??
                          (game.isActive ? 'In progress' : 'Finished'),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete game',
                      icon: const Icon(Icons.close),
                      onPressed: () => bot.deleteGame(game.id),
                    ),
                    onTap: () {
                      bot.selectGame(game.id);
                      setState(() => _selectedBotId = game.id);
                    },
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startGame(String type) async {
    final app = context.read<AppProvider>();
    final bot = context.read<BotGameProvider>();
    final setup = await showDialog<_GameSetup>(
      context: context,
      builder: (_) => _GameSetupDialog(type: type),
    );
    if (setup == null) return;

    if (setup.mode == _GameMode.computer) {
      if (type == 'chess') {
        bot.createChessGame(playAsWhite: setup.playAsWhite);
      } else if (type == 'ludo') {
        bot.createLudoGame(playerCount: setup.playerCount);
      } else {
        bot.createCardsGame(playerCount: setup.playerCount);
      }
      setState(() => _selectedBotId = bot.selectedGameId);
      return;
    }

    await app.createFriendGame(
      type,
      maxPlayers: setup.playerCount,
      inviteUserIds: setup.inviteUserIds,
    );
    setState(() => _selectedBotId = null);
  }

  IconData _gameIcon(String type) {
    return switch (type) {
      'chess' => Icons.grid_on_outlined,
      'ludo' => Icons.casino_outlined,
      'cards' => Icons.style_outlined,
      _ => Icons.sports_esports_outlined,
    };
  }
}

class _GameStartTile extends StatelessWidget {
  final String type;
  final VoidCallback onTap;

  const _GameStartTile({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (type) {
      'chess' => scheme.primary,
      'ludo' => VoxoraColors.green,
      'cards' => VoxoraColors.orange,
      _ => scheme.primary,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              type == 'chess'
                  ? Icons.grid_on_outlined
                  : type == 'ludo'
                  ? Icons.casino_outlined
                  : Icons.style_outlined,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameTitles[type]!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    _subtitle(type),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _subtitle(String type) {
    return switch (type) {
      'chess' => '2 players - legal move guide',
      'ludo' => '2-4 players - colored board and dice',
      'cards' => '2-4 players - high card rounds',
      _ => '',
    };
  }
}

enum _GameMode { computer, friends }

class _GameSetup {
  final _GameMode mode;
  final int playerCount;
  final bool playAsWhite;
  final List<String> inviteUserIds;

  const _GameSetup({
    required this.mode,
    required this.playerCount,
    required this.playAsWhite,
    required this.inviteUserIds,
  });
}

class _GameSetupDialog extends StatefulWidget {
  final String type;

  const _GameSetupDialog({required this.type});

  @override
  State<_GameSetupDialog> createState() => _GameSetupDialogState();
}

class _GameSetupDialogState extends State<_GameSetupDialog> {
  _GameMode _mode = _GameMode.computer;
  int _players = 2;
  bool _playAsWhite = true;
  final Set<String> _invites = {};

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final needsCount = widget.type != 'chess';
    return AlertDialog(
      title: Text('Start ${gameTitles[widget.type]}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<_GameMode>(
                segments: const [
                  ButtonSegment(
                    value: _GameMode.computer,
                    icon: Icon(Icons.smart_toy_outlined),
                    label: Text('Computer'),
                  ),
                  ButtonSegment(
                    value: _GameMode.friends,
                    icon: Icon(Icons.people_outline),
                    label: Text('Friends'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.first),
              ),
              if (widget.type == 'chess') ...[
                const SizedBox(height: 14),
                SwitchListTile(
                  value: _playAsWhite,
                  title: const Text('Play as white'),
                  secondary: const Icon(Icons.circle_outlined),
                  onChanged: _mode == _GameMode.computer
                      ? (value) => setState(() => _playAsWhite = value)
                      : null,
                ),
              ],
              if (needsCount) ...[
                const SizedBox(height: 14),
                Text('Players', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                    ButtonSegment(value: 4, label: Text('4')),
                  ],
                  selected: {_players},
                  onSelectionChanged: (value) =>
                      setState(() => _players = value.first),
                ),
              ],
              if (_mode == _GameMode.friends) ...[
                const SizedBox(height: 16),
                Text(
                  'Invite friends',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (app.friends.isEmpty)
                  Text(
                    'You can still share the generated game code.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ...app.friends.map(
                    (friend) => CheckboxListTile(
                      value: _invites.contains(friend.id),
                      title: Text(friend.fullName),
                      subtitle: Text('@${friend.handle}'),
                      secondary: UserAvatar(url: friend.avatarUrl),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _invites.add(friend.id);
                          } else {
                            _invites.remove(friend.id);
                          }
                        });
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
          onPressed: () => Navigator.pop(
            context,
            _GameSetup(
              mode: _mode,
              playerCount: widget.type == 'chess' ? 2 : _players,
              playAsWhite: _playAsWhite,
              inviteUserIds: _invites.toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameStage extends StatelessWidget {
  final GameSession? friendGame;
  final BotGame? botGame;

  const _GameStage.friend({required GameSession? game})
    : friendGame = game,
      botGame = null;

  const _GameStage.bot({required BotGame game})
    : botGame = game,
      friendGame = null;

  @override
  Widget build(BuildContext context) {
    final gameType = botGame?.gameType ?? friendGame?.gameType;
    if (gameType == null) {
      return const EmptyState(
        icon: Icons.sports_esports_outlined,
        title: 'No game selected',
        body: 'Start a game with a computer or friends.',
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CountChip(
                icon: Icons.sports_esports_outlined,
                label: gameTitles[gameType] ?? gameType,
              ),
              const SizedBox(width: 8),
              CountChip(
                icon: botGame == null
                    ? Icons.people_outline
                    : Icons.smart_toy_outlined,
                label: botGame == null ? 'Friends' : 'Computer',
                color: botGame == null
                    ? VoxoraColors.teal
                    : VoxoraColors.orange,
              ),
              const Spacer(),
              ActionIconButton(
                icon: Icons.menu_book_outlined,
                tooltip: 'Rules and guide',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _GuideDialog(type: gameType),
                ),
              ),
              ActionIconButton(
                icon: Icons.school_outlined,
                tooltip: 'Tutorial',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _TutorialDialog(type: gameType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (botGame?.result != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CountChip(
                icon: Icons.emoji_events_outlined,
                label: botGame!.result!,
              ),
            ),
          if (friendGame != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText('Invite code: ${friendGame!.inviteCode}'),
            ),
          if (gameType == 'chess')
            _ChessBoard(friendGame: friendGame, botGame: botGame),
          if (gameType == 'ludo')
            _LudoBoard(friendGame: friendGame, botGame: botGame),
          if (gameType == 'cards')
            _CardsTable(friendGame: friendGame, botGame: botGame),
        ],
      ),
    );
  }
}

class _ChessBoard extends StatefulWidget {
  final GameSession? friendGame;
  final BotGame? botGame;

  const _ChessBoard({this.friendGame, this.botGame});

  @override
  State<_ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<_ChessBoard> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bot = context.watch<BotGameProvider>();
    final state = widget.botGame?.state ?? widget.friendGame!.state;
    final fen = state['fen'] as String;
    final board = chess_lib.Chess.fromFEN(fen);
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];
    final legalTargets = _selected == null
        ? const <String>{}
        : board
              .moves({'square': _selected, 'verbose': true})
              .whereType<Map>()
              .map((move) => move['to'].toString())
              .toSet();
    final moves = List<String>.from(state['moves'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CountChip(
              icon: Icons.flag_outlined,
              label: _chessStatus(board),
              color: board.turn == chess_lib.Color.WHITE
                  ? const Color(0xFF64748B)
                  : Colors.black,
            ),
            CountChip(
              icon: Icons.history,
              label: '${moves.length} moves',
              color: VoxoraColors.teal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2F2217), Color(0xFF7C4A24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFE8D9BE), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: GridView.count(
                    crossAxisCount: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final rank in ranks)
                        for (final file in files)
                          _square(app, bot, board, '$file$rank', legalTargets),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _square(
    AppProvider app,
    BotGameProvider bot,
    chess_lib.Chess board,
    String square,
    Set<String> legalTargets,
  ) {
    final piece = board.get(square);
    final file = square.codeUnitAt(0) - 97;
    final rank = 8 - int.parse(square[1]);
    final dark = (file + rank).isOdd;
    final selected = _selected == square;
    final legal = legalTargets.contains(square);
    final scheme = Theme.of(context).colorScheme;
    final pieceType = piece?.type.toString().toLowerCase();
    final squareColor = dark
        ? const Color(0xFF769656)
        : const Color(0xFFF0D9B5);
    final labelColor = dark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF305030).withValues(alpha: 0.78);
    return InkWell(
      onTap: () => _tapSquare(app, bot, board, square),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: squareColor,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: VoxoraColors.amber.withValues(alpha: 0.78),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: VoxoraColors.amber.withValues(alpha: 0.38),
                    border: Border.all(
                      color: VoxoraColors.amber.withValues(alpha: 0.9),
                      width: 3,
                    ),
                  ),
                ),
              ),
            if (legal)
              Container(
                width: piece == null ? 18 : 52,
                height: piece == null ? 18 : 52,
                decoration: BoxDecoration(
                  color: piece == null
                      ? scheme.onSurface.withValues(alpha: 0.22)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: piece == null
                      ? null
                      : Border.all(
                          color: VoxoraColors.green.withValues(alpha: 0.72),
                          width: 5,
                        ),
                ),
              ),
            if (pieceType != null)
              Padding(
                padding: const EdgeInsets.all(7),
                child: _ChessPiece(
                  type: pieceType,
                  isWhite: piece!.color == chess_lib.Color.WHITE,
                ),
              ),
            if (file == 0)
              Positioned(
                top: 4,
                left: 5,
                child: Text(
                  square[1],
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (rank == 7)
              Positioned(
                right: 5,
                bottom: 3,
                child: Text(
                  square[0],
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _tapSquare(
    AppProvider app,
    BotGameProvider bot,
    chess_lib.Chess board,
    String square,
  ) {
    if (board.game_over) return;
    final isBotGame = widget.botGame != null;
    final mySeat = isBotGame
        ? (widget.botGame!.players['white'] == BotGameProvider.playerId
              ? 'white'
              : 'black')
        : app.myPlayerForGame(widget.friendGame!.id)?.seat;
    final turn = board.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    if (mySeat != turn) return;
    final piece = board.get(square);
    if (_selected == null) {
      if (piece != null &&
          ((piece.color == chess_lib.Color.WHITE && mySeat == 'white') ||
              (piece.color == chess_lib.Color.BLACK && mySeat == 'black'))) {
        setState(() => _selected = square);
      }
      return;
    }
    final from = _selected!;
    final test = chess_lib.Chess.fromFEN(board.fen);
    final moved = test.move({'from': from, 'to': square, 'promotion': 'q'});
    if (moved) {
      if (isBotGame) {
        bot.makeChessMove(widget.botGame!.id, from, square);
      } else {
        app.makeChessMove(widget.friendGame!, from, square);
      }
      setState(() => _selected = null);
      return;
    }
    setState(() => _selected = piece == null ? null : square);
  }

  // ignore: unused_element
  String _piece(chess_lib.Piece piece) {
    const white = {'p': '♙', 'r': '♖', 'n': '♘', 'b': '♗', 'q': '♕', 'k': '♔'};
    const black = {'p': '♟', 'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚'};
    final type = piece.type.toString().toLowerCase();
    return piece.color == chess_lib.Color.WHITE ? white[type]! : black[type]!;
  }

  String _chessStatus(chess_lib.Chess board) {
    if (board.in_checkmate) return 'Checkmate';
    if (board.in_draw) return 'Draw';
    final turn = board.turn == chess_lib.Color.WHITE ? 'White' : 'Black';
    return board.in_check ? '$turn is in check' : '$turn to move';
  }
}

class _ChessPiece extends StatelessWidget {
  final String type;
  final bool isWhite;

  const _ChessPiece({required this.type, required this.isWhite});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChessPiecePainter(type: type, isWhite: isWhite),
      child: const SizedBox.expand(),
    );
  }
}

class _ChessPiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;

  const _ChessPiecePainter({required this.type, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas
      ..save()
      ..translate((size.width - size.shortestSide) / 2, 0)
      ..scale(scale);

    final fill = isWhite ? Colors.white : Colors.black;
    final side = isWhite ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final stroke = isWhite
        ? const Color(0xFF111827).withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.45);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: isWhite ? 0.34 : 0.44)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: isWhite
            ? [Colors.white, const Color(0xFFF8FAFC), const Color(0xFFE5E7EB)]
            : [const Color(0xFF020617), Colors.black, const Color(0xFF111827)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    final sidePaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = side;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = stroke;

    void drawPath(Path path) {
      canvas
        ..save()
        ..translate(0, 3)
        ..drawPath(path, shadow)
        ..restore()
        ..drawPath(path, fillPaint)
        ..drawPath(path, strokePaint);
    }

    void drawOval(Rect rect, {bool sideTone = false}) {
      canvas
        ..save()
        ..translate(0, 3)
        ..drawOval(rect, shadow)
        ..restore()
        ..drawOval(rect, sideTone ? sidePaint : fillPaint)
        ..drawOval(rect, strokePaint);
    }

    void drawRRect(RRect rect, {bool sideTone = false}) {
      canvas
        ..save()
        ..translate(0, 3)
        ..drawRRect(rect, shadow)
        ..restore()
        ..drawRRect(rect, sideTone ? sidePaint : fillPaint)
        ..drawRRect(rect, strokePaint);
    }

    _drawChessBase(canvas, fillPaint, sidePaint, strokePaint, shadow);

    switch (type) {
      case 'p':
        drawOval(const Rect.fromLTWH(34, 16, 32, 32));
        drawPath(
          Path()
            ..moveTo(50, 43)
            ..cubicTo(31, 46, 28, 66, 32, 72)
            ..lineTo(68, 72)
            ..cubicTo(72, 66, 69, 46, 50, 43)
            ..close(),
        );
        break;
      case 'r':
        drawPath(
          Path()
            ..moveTo(28, 20)
            ..lineTo(28, 35)
            ..lineTo(34, 35)
            ..lineTo(34, 28)
            ..lineTo(45, 28)
            ..lineTo(45, 35)
            ..lineTo(55, 35)
            ..lineTo(55, 28)
            ..lineTo(66, 28)
            ..lineTo(66, 35)
            ..lineTo(72, 35)
            ..lineTo(72, 20)
            ..close(),
        );
        drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(33, 35, 34, 37),
            const Radius.circular(4),
          ),
        );
        break;
      case 'n':
        drawPath(
          Path()
            ..moveTo(31, 72)
            ..cubicTo(34, 55, 39, 43, 49, 35)
            ..lineTo(44, 23)
            ..cubicTo(56, 24, 69, 31, 73, 44)
            ..lineTo(66, 47)
            ..lineTo(70, 57)
            ..cubicTo(58, 55, 48, 58, 43, 72)
            ..close(),
        );
        final eye = Paint()
          ..color = isWhite ? Colors.black : Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(const Offset(58, 39), 2.2, eye);
        break;
      case 'b':
        drawOval(const Rect.fromLTWH(40, 14, 20, 20));
        drawPath(
          Path()
            ..moveTo(50, 32)
            ..cubicTo(31, 43, 30, 63, 37, 73)
            ..lineTo(63, 73)
            ..cubicTo(70, 63, 69, 43, 50, 32)
            ..close(),
        );
        canvas.drawLine(
          const Offset(57, 38),
          const Offset(43, 58),
          strokePaint..strokeWidth = 2.2,
        );
        break;
      case 'q':
        drawPath(
          Path()
            ..moveTo(28, 42)
            ..lineTo(35, 24)
            ..lineTo(45, 40)
            ..lineTo(50, 19)
            ..lineTo(55, 40)
            ..lineTo(65, 24)
            ..lineTo(72, 42)
            ..lineTo(66, 70)
            ..lineTo(34, 70)
            ..close(),
        );
        for (final center in const [
          Offset(35, 22),
          Offset(50, 17),
          Offset(65, 22),
        ]) {
          canvas.drawCircle(center, 5, fillPaint);
          canvas.drawCircle(center, 5, strokePaint);
        }
        break;
      case 'k':
        final crossPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round
          ..color = fill;
        canvas
          ..drawLine(const Offset(50, 12), const Offset(50, 31), crossPaint)
          ..drawLine(const Offset(42, 20), const Offset(58, 20), crossPaint)
          ..drawLine(const Offset(50, 12), const Offset(50, 31), strokePaint)
          ..drawLine(const Offset(42, 20), const Offset(58, 20), strokePaint);
        drawPath(
          Path()
            ..moveTo(37, 32)
            ..cubicTo(34, 43, 35, 58, 42, 70)
            ..lineTo(58, 70)
            ..cubicTo(65, 58, 66, 43, 63, 32)
            ..cubicTo(56, 36, 44, 36, 37, 32)
            ..close(),
        );
        break;
    }

    canvas.restore();
  }

  void _drawChessBase(
    Canvas canvas,
    Paint fillPaint,
    Paint sidePaint,
    Paint strokePaint,
    Paint shadow,
  ) {
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 75, 64, 13),
      const Radius.circular(7),
    );
    final collar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 64, 44, 13),
      const Radius.circular(6),
    );
    canvas
      ..save()
      ..translate(0, 3)
      ..drawRRect(base, shadow)
      ..drawRRect(collar, shadow)
      ..restore()
      ..drawRRect(base, fillPaint)
      ..drawRRect(base, strokePaint)
      ..drawRRect(collar, sidePaint)
      ..drawRRect(collar, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ChessPiecePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isWhite != isWhite;
  }
}

const _ludoTrackCells = <Offset>[
  Offset(1, 6),
  Offset(2, 6),
  Offset(3, 6),
  Offset(4, 6),
  Offset(5, 6),
  Offset(6, 5),
  Offset(6, 4),
  Offset(6, 3),
  Offset(6, 2),
  Offset(6, 1),
  Offset(6, 0),
  Offset(7, 0),
  Offset(8, 0),
  Offset(8, 1),
  Offset(8, 2),
  Offset(8, 3),
  Offset(8, 4),
  Offset(8, 5),
  Offset(9, 6),
  Offset(10, 6),
  Offset(11, 6),
  Offset(12, 6),
  Offset(13, 6),
  Offset(14, 6),
  Offset(14, 7),
  Offset(14, 8),
  Offset(13, 8),
  Offset(12, 8),
  Offset(11, 8),
  Offset(10, 8),
  Offset(9, 8),
  Offset(8, 9),
  Offset(8, 10),
  Offset(8, 11),
  Offset(8, 12),
  Offset(8, 13),
  Offset(8, 14),
  Offset(7, 14),
  Offset(6, 14),
  Offset(6, 13),
  Offset(6, 12),
  Offset(6, 11),
  Offset(6, 10),
  Offset(6, 9),
  Offset(5, 8),
  Offset(4, 8),
  Offset(3, 8),
  Offset(2, 8),
  Offset(1, 8),
  Offset(0, 8),
  Offset(0, 7),
  Offset(0, 6),
];

const _ludoHomeLaneCells = <String, List<Offset>>{
  'red': [Offset(1, 7), Offset(2, 7), Offset(3, 7), Offset(4, 7), Offset(5, 7)],
  'blue': [
    Offset(7, 1),
    Offset(7, 2),
    Offset(7, 3),
    Offset(7, 4),
    Offset(7, 5),
  ],
  'yellow': [
    Offset(13, 7),
    Offset(12, 7),
    Offset(11, 7),
    Offset(10, 7),
    Offset(9, 7),
  ],
  'green': [
    Offset(7, 13),
    Offset(7, 12),
    Offset(7, 11),
    Offset(7, 10),
    Offset(7, 9),
  ],
};

const _ludoBaseSlots = <String, List<Offset>>{
  'red': [Offset(2, 2), Offset(4, 2), Offset(2, 4), Offset(4, 4)],
  'blue': [Offset(11, 2), Offset(13, 2), Offset(11, 4), Offset(13, 4)],
  'green': [Offset(2, 11), Offset(4, 11), Offset(2, 13), Offset(4, 13)],
  'yellow': [Offset(11, 11), Offset(13, 11), Offset(11, 13), Offset(13, 13)],
};

class _LudoBoard extends StatefulWidget {
  final GameSession? friendGame;
  final BotGame? botGame;

  const _LudoBoard({this.friendGame, this.botGame});

  @override
  State<_LudoBoard> createState() => _LudoBoardState();
}

class _LudoBoardState extends State<_LudoBoard> {
  Map<String, List<int>> _displayedTokens = {};
  Map<String, List<int>>? _queuedTarget;
  String? _gameKey;
  bool _animating = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bot = context.watch<BotGameProvider>();
    final state = widget.botGame?.state ?? widget.friendGame!.state;
    final players =
        widget.botGame?.players ??
        {
          for (final player in app.playersForGame(widget.friendGame!.id))
            player.seat: player.userId,
        };
    final colors = List<String>.from(
      state['activeColors'] as List? ?? ludoColorNames.take(4),
    );
    final stateTurn = state['turn'] as String?;
    final turn = widget.friendGame?.currentSeat ?? stateTurn ?? colors.first;
    final dice = state['dice'] as int?;
    final winner = state['winner'] as String?;
    final mySeat = widget.botGame == null
        ? app.myPlayerForGame(widget.friendGame!.id)?.seat
        : colors.firstWhere(
            (color) => players[color] == BotGameProvider.playerId,
            orElse: () => '',
          );
    final targetTokens = _tokensFromState(state, colors);
    _syncDisplayedTokens(targetTokens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CountChip(
              icon: Icons.flag_outlined,
              label: winner == null ? '$turn turn' : '$winner wins',
              color: _laneColor(turn),
            ),
            _Dice3D(value: dice),
            FilledButton.icon(
              onPressed:
                  winner != null || mySeat != turn || dice != null || _animating
                  ? null
                  : () {
                      if (widget.botGame == null) {
                        app.rollLudoDice(widget.friendGame!);
                      } else {
                        bot.rollLudoDice(widget.botGame!.id);
                      }
                    },
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Roll'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _LudoGrid(
              colors: colors,
              displayedTokens: _displayedTokens,
              targetTokens: targetTokens,
              turn: turn,
              dice: dice,
              mySeat: mySeat,
              winner: winner,
              animating: _animating,
              onTokenTap: (color, index) {
                if (widget.botGame == null) {
                  app.moveLudoToken(widget.friendGame!, index);
                } else {
                  bot.moveLudoToken(widget.botGame!.id, color, index);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final tokens = targetTokens[color] ?? [0, 0, 0, 0];
            final lane = _laneColor(color);
            return _LudoPlayerPill(
              colorName: color,
              lane: lane,
              label: _playerLabel(app, bot, players[color]),
              tokens: tokens,
              active: color == turn && winner == null,
              winner: winner == color,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _syncDisplayedTokens(Map<String, List<int>> targetTokens) {
    final currentKey = widget.botGame?.id ?? widget.friendGame?.id;
    if (_gameKey != currentKey || _displayedTokens.isEmpty) {
      _gameKey = currentKey;
      _displayedTokens = _copyTokens(targetTokens);
      _queuedTarget = null;
      _animating = false;
      return;
    }

    if (_tokensEqual(_displayedTokens, targetTokens)) return;
    if (_animating) {
      _queuedTarget = _copyTokens(targetTokens);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animateTo(_copyTokens(targetTokens));
    });
  }

  Future<void> _animateTo(Map<String, List<int>> targetTokens) async {
    if (_animating) {
      _queuedTarget = targetTokens;
      return;
    }

    _animating = true;
    if (mounted) setState(() {});

    var target = targetTokens;
    while (mounted) {
      var changed = false;
      setState(() {
        for (final entry in target.entries) {
          final displayed = _displayedTokens.putIfAbsent(
            entry.key,
            () => List<int>.filled(entry.value.length, 0),
          );
          for (var i = 0; i < entry.value.length; i++) {
            if (i >= displayed.length) {
              displayed.add(entry.value[i]);
              changed = true;
              continue;
            }
            final current = displayed[i];
            final destination = entry.value[i];
            if (current < destination) {
              displayed[i] = current + 1;
              changed = true;
            } else if (current > destination) {
              displayed[i] = destination;
              changed = true;
            }
          }
        }
      });

      if (!changed) {
        final queued = _queuedTarget;
        _queuedTarget = null;
        if (queued != null && !_tokensEqual(_displayedTokens, queued)) {
          target = queued;
          continue;
        }
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 130));
    }

    _animating = false;
    if (mounted) setState(() {});
  }

  Map<String, List<int>> _tokensFromState(
    Map<String, dynamic> state,
    List<String> colors,
  ) {
    final allTokens = Map<String, dynamic>.from(state['tokens'] as Map? ?? {});
    return {
      for (final color in colors)
        color: List<int>.from(allTokens[color] as List? ?? [0, 0, 0, 0]),
    };
  }

  Map<String, List<int>> _copyTokens(Map<String, List<int>> tokens) {
    return {
      for (final entry in tokens.entries) entry.key: [...entry.value],
    };
  }

  bool _tokensEqual(Map<String, List<int>> a, Map<String, List<int>> b) {
    if (a.length != b.length) return false;
    for (final entry in b.entries) {
      final left = a[entry.key];
      if (left == null || left.length != entry.value.length) return false;
      for (var i = 0; i < entry.value.length; i++) {
        if (left[i] != entry.value[i]) return false;
      }
    }
    return true;
  }

  String _playerLabel(AppProvider app, BotGameProvider bot, dynamic id) {
    if (widget.botGame != null) return bot.profileName(id);
    return app.profileById(id as String?)?.fullName ?? 'Open seat';
  }

  Color _laneColor(String color) {
    return Color(ludoBoardColors[color] ?? 0xFF64748B);
  }
}

class _LudoGrid extends StatelessWidget {
  final List<String> colors;
  final Map<String, List<int>> displayedTokens;
  final Map<String, List<int>> targetTokens;
  final String turn;
  final int? dice;
  final String? mySeat;
  final String? winner;
  final bool animating;
  final void Function(String color, int index) onTokenTap;

  const _LudoGrid({
    required this.colors,
    required this.displayedTokens,
    required this.targetTokens,
    required this.turn,
    required this.dice,
    required this.mySeat,
    required this.winner,
    required this.animating,
    required this.onTokenTap,
  });

  @override
  Widget build(BuildContext context) {
    final placements = <_LudoPiecePlacement>[];
    final centerCounts = <String, int>{};

    for (final color in colors) {
      final displayed = displayedTokens[color] ?? [0, 0, 0, 0];
      final target = targetTokens[color] ?? [0, 0, 0, 0];
      for (var index = 0; index < displayed.length; index++) {
        final position = displayed[index];
        final center = _ludoTokenCenter(color, index, position);
        final key = _ludoStackKey(center);
        centerCounts[key] = (centerCounts[key] ?? 0) + 1;
        final currentTarget = index < target.length ? target[index] : position;
        final movable =
            !animating &&
            mySeat == color &&
            color == turn &&
            dice != null &&
            winner == null &&
            _canMoveLudoPosition(currentTarget, dice!);
        placements.add(
          _LudoPiecePlacement(
            color: color,
            index: index,
            position: position,
            center: center,
            movable: movable,
          ),
        );
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          final cell = size / 15;
          final tokenSize = (cell * 0.72).clamp(20.0, 34.0).toDouble();
          final seen = <String, int>{};
          final tokenChildren = <Widget>[];

          for (final placement in placements) {
            final key = _ludoStackKey(placement.center);
            final stackIndex = seen[key] ?? 0;
            seen[key] = stackIndex + 1;
            final stackCount = centerCounts[key] ?? 1;
            final stackOffset = _ludoStackOffset(stackIndex, stackCount);
            final center = Offset(
              (placement.center.dx + stackOffset.dx) * cell,
              (placement.center.dy + stackOffset.dy) * cell,
            );

            tokenChildren.add(
              AnimatedPositioned(
                key: ValueKey('ludo-${placement.color}-${placement.index}'),
                duration: const Duration(milliseconds: 125),
                curve: Curves.easeInOutCubic,
                left: center.dx - tokenSize / 2,
                top: center.dy - tokenSize / 2,
                width: tokenSize,
                height: tokenSize,
                child: _LudoPiece(
                  colorName: placement.color,
                  index: placement.index,
                  position: placement.position,
                  movable: placement.movable,
                  onTap: placement.movable
                      ? () => onTokenTap(placement.color, placement.index)
                      : null,
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _LudoPainter(colors)),
              ),
              ...tokenChildren,
            ],
          );
        },
      ),
    );
  }
}

class _LudoPiecePlacement {
  final String color;
  final int index;
  final int position;
  final Offset center;
  final bool movable;

  const _LudoPiecePlacement({
    required this.color,
    required this.index,
    required this.position,
    required this.center,
    required this.movable,
  });
}

class _LudoPiece extends StatelessWidget {
  final String colorName;
  final int index;
  final int position;
  final bool movable;
  final VoidCallback? onTap;

  const _LudoPiece({
    required this.colorName,
    required this.index,
    required this.position,
    required this.movable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lane = Color(ludoBoardColors[colorName] ?? 0xFF64748B);
    final dark = Color.lerp(lane, Colors.black, 0.24)!;
    final piece = AnimatedScale(
      scale: movable ? 1.08 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              lane.withValues(alpha: 0.96),
              dark,
            ],
            stops: const [0, 0.35, 1],
          ),
          border: Border.all(
            color: movable
                ? Colors.white
                : Colors.white.withValues(alpha: 0.78),
            width: movable ? 3 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: lane.withValues(alpha: movable ? 0.58 : 0.3),
              blurRadius: movable ? 20 : 10,
              spreadRadius: movable ? 2 : 0,
            ),
            const BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message:
          '${_titleCase(colorName)} piece ${index + 1}, position $position',
      child: Semantics(
        button: onTap != null,
        label:
            '${_titleCase(colorName)} piece ${index + 1}, position $position',
        child: MouseRegion(
          cursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: piece,
            ),
          ),
        ),
      ),
    );
  }
}

class _LudoPlayerPill extends StatelessWidget {
  final String colorName;
  final Color lane;
  final String label;
  final List<int> tokens;
  final bool active;
  final bool winner;

  const _LudoPlayerPill({
    required this.colorName,
    required this.lane,
    required this.label,
    required this.tokens,
    required this.active,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    final finished = tokens.where((position) => position >= 56).length;
    return Container(
      width: 188,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lane.withValues(alpha: active ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: winner || active
              ? lane.withValues(alpha: 0.9)
              : lane.withValues(alpha: 0.26),
          width: winner || active ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: lane,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _titleCase(colorName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: lane, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$finished/4',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _LudoPainter extends CustomPainter {
  final List<String> colors;

  _LudoPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF111827).withValues(alpha: 0.16);

    paint.color = const Color(0xFFF8FAFC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      paint,
    );

    _drawBase(canvas, cell, 'red', const Rect.fromLTWH(0, 0, 6, 6));
    _drawBase(canvas, cell, 'blue', const Rect.fromLTWH(9, 0, 6, 6));
    _drawBase(canvas, cell, 'green', const Rect.fromLTWH(0, 9, 6, 6));
    _drawBase(canvas, cell, 'yellow', const Rect.fromLTWH(9, 9, 6, 6));

    for (final pathCell in _ludoTrackCells) {
      _drawCell(canvas, cell, pathCell, Colors.white, border);
    }

    for (final entry in _ludoHomeLaneCells.entries) {
      final active = colors.contains(entry.key);
      final lane = Color(ludoBoardColors[entry.key]!);
      for (final pathCell in entry.value) {
        _drawCell(
          canvas,
          cell,
          pathCell,
          lane.withValues(alpha: active ? 0.82 : 0.15),
          border,
        );
      }
    }

    _drawStarts(canvas, cell, border);
    _drawSafeSquares(canvas, cell);
    _drawCenter(canvas, cell);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5),
        const Radius.circular(8),
      ),
      border,
    );
  }

  void _drawBase(Canvas canvas, double cell, String color, Rect gridRect) {
    final lane = Color(ludoBoardColors[color]!);
    final active = colors.contains(color);
    final baseRect = Rect.fromLTWH(
      gridRect.left * cell,
      gridRect.top * cell,
      gridRect.width * cell,
      gridRect.height * cell,
    ).deflate(cell * 0.18);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = lane.withValues(alpha: active ? 0.9 : 0.14);

    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(cell * 0.35)),
      paint,
    );

    paint.color = Colors.white.withValues(alpha: active ? 0.92 : 0.5);
    final house = baseRect.deflate(cell * 1.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(house, Radius.circular(cell * 0.3)),
      paint,
    );

    final slots = _ludoBaseSlots[color] ?? const <Offset>[];
    for (final slot in slots) {
      final center = Offset(slot.dx * cell, slot.dy * cell);
      paint.color = lane.withValues(alpha: active ? 0.24 : 0.08);
      canvas.drawCircle(center, cell * 0.58, paint);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = lane.withValues(alpha: active ? 0.68 : 0.16);
      canvas.drawCircle(center, cell * 0.58, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  void _drawCell(
    Canvas canvas,
    double cell,
    Offset gridCell,
    Color color,
    Paint border,
  ) {
    final rect = Rect.fromLTWH(
      gridCell.dx * cell,
      gridCell.dy * cell,
      cell,
      cell,
    ).deflate(0.8);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.08)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.08)),
      border,
    );
  }

  void _drawStarts(Canvas canvas, double cell, Paint border) {
    for (final entry in ludoStartOffsets.entries) {
      final lane = Color(ludoBoardColors[entry.key]!);
      final pathCell = _ludoTrackCells[entry.value];
      _drawCell(
        canvas,
        cell,
        pathCell,
        lane.withValues(alpha: colors.contains(entry.key) ? 0.9 : 0.16),
        border,
      );

      final center = _cellCenter(pathCell);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = Colors.white.withValues(alpha: 0.86);
      final start = Path()
        ..moveTo((center.dx - 0.18) * cell, (center.dy - 0.24) * cell)
        ..lineTo((center.dx + 0.24) * cell, center.dy * cell)
        ..lineTo((center.dx - 0.18) * cell, (center.dy + 0.24) * cell)
        ..close();
      canvas.drawPath(start, paint);
    }
  }

  void _drawSafeSquares(Canvas canvas, double cell) {
    final startSquares = ludoStartOffsets.values.toSet();
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.82);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.88);

    for (final safeIndex in ludoSafeTrackIndices) {
      if (startSquares.contains(safeIndex)) continue;
      final center = _cellCenter(_ludoTrackCells[safeIndex]);
      final path = _starPath(Offset(center.dx * cell, center.dy * cell), cell);
      canvas.drawPath(path, paint);
      canvas.drawPath(path, stroke);
    }
  }

  void _drawCenter(Canvas canvas, double cell) {
    final centerRect = Rect.fromLTWH(cell * 6, cell * 6, cell * 3, cell * 3);
    final middle = centerRect.center;
    final triangles = {
      'red': [
        Offset(centerRect.left, centerRect.top),
        Offset(centerRect.left, centerRect.bottom),
      ],
      'blue': [
        Offset(centerRect.left, centerRect.top),
        Offset(centerRect.right, centerRect.top),
      ],
      'yellow': [
        Offset(centerRect.right, centerRect.top),
        Offset(centerRect.right, centerRect.bottom),
      ],
      'green': [
        Offset(centerRect.left, centerRect.bottom),
        Offset(centerRect.right, centerRect.bottom),
      ],
    };
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final entry in triangles.entries) {
      paint.color = Color(
        ludoBoardColors[entry.key]!,
      ).withValues(alpha: colors.contains(entry.key) ? 0.88 : 0.16);
      final path = Path()
        ..moveTo(middle.dx, middle.dy)
        ..lineTo(entry.value.first.dx, entry.value.first.dy)
        ..lineTo(entry.value.last.dx, entry.value.last.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LudoPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

bool _canMoveLudoPosition(int position, int dice) {
  return isLegalLudoMove(position, dice);
}

Offset _cellCenter(Offset cell) => Offset(cell.dx + 0.5, cell.dy + 0.5);

Offset _ludoTokenCenter(String color, int tokenIndex, int position) {
  if (position <= 0) {
    final slots = _ludoBaseSlots[color] ?? _ludoBaseSlots['red']!;
    return slots[tokenIndex % slots.length];
  }

  if (position >= 52) {
    final lane = _ludoHomeLaneCells[color] ?? _ludoHomeLaneCells['red']!;
    final laneIndex = (position - 52).clamp(0, lane.length - 1);
    return _cellCenter(lane[laneIndex]);
  }

  final start = ludoStartOffsets[color] ?? 0;
  final trackIndex = (start + position - 1) % _ludoTrackCells.length;
  return _cellCenter(_ludoTrackCells[trackIndex]);
}

Path _starPath(Offset center, double cell) {
  const points = 5;
  final outer = cell * 0.26;
  final inner = cell * 0.11;
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final angle = -1.5708 + i * pi / points;
    final radius = i.isEven ? outer : inner;
    final point = Offset(
      center.dx + cos(angle) * radius,
      center.dy + sin(angle) * radius,
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

String _ludoStackKey(Offset center) {
  return '${center.dx.toStringAsFixed(2)}:${center.dy.toStringAsFixed(2)}';
}

Offset _ludoStackOffset(int index, int count) {
  if (count <= 1) return Offset.zero;
  const offsets = [
    Offset(-0.16, -0.16),
    Offset(0.16, -0.16),
    Offset(-0.16, 0.16),
    Offset(0.16, 0.16),
  ];
  return offsets[index % offsets.length];
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

class _Dice3D extends StatelessWidget {
  final int? value;

  const _Dice3D({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFD1D5DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(4, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: value == null
            ? const Icon(
                Icons.casino_outlined,
                key: ValueKey('dice-empty'),
                color: Colors.black54,
              )
            : Stack(
                key: ValueKey('dice-$value'),
                children: [
                  for (final alignment in _dicePips(value!))
                    Align(
                      alignment: alignment,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  List<Alignment> _dicePips(int value) {
    const topLeft = Alignment(-0.56, -0.56);
    const topRight = Alignment(0.56, -0.56);
    const centerLeft = Alignment(-0.56, 0);
    const center = Alignment.center;
    const centerRight = Alignment(0.56, 0);
    const bottomLeft = Alignment(-0.56, 0.56);
    const bottomRight = Alignment(0.56, 0.56);

    return switch (value) {
      1 => const [center],
      2 => const [topLeft, bottomRight],
      3 => const [topLeft, center, bottomRight],
      4 => const [topLeft, topRight, bottomLeft, bottomRight],
      5 => const [topLeft, topRight, center, bottomLeft, bottomRight],
      _ => const [
        topLeft,
        centerLeft,
        bottomLeft,
        topRight,
        centerRight,
        bottomRight,
      ],
    };
  }
}

class _CardsTable extends StatelessWidget {
  final GameSession? friendGame;
  final BotGame? botGame;

  const _CardsTable({this.friendGame, this.botGame});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bot = context.watch<BotGameProvider>();
    final state = botGame?.state ?? friendGame!.state;
    final hands = Map<String, dynamic>.from(state['hands'] as Map? ?? {});
    final table = Map<String, dynamic>.from(state['table'] as Map? ?? {});
    final scores = Map<String, dynamic>.from(state['scores'] as Map? ?? {});
    final order = List<String>.from(state['order'] as List? ?? []);
    final deck = List<String>.from(state['deck'] as List? ?? []);
    final mySeat = botGame == null
        ? app.myPlayerForGame(friendGame!.id)?.seat
        : BotGameProvider.playerId;
    final myHand = List<String>.from(hands[mySeat] as List? ?? []);
    final displayOrder = order.isEmpty ? ['p1', 'p2'] : order;
    final playedCount = displayOrder
        .where((seat) => table[seat] is String)
        .length;
    final activeSeat =
        (botGame == null
            ? friendGame!.currentSeat
            : _activeBotSeat(order, table, bot.botThinking)) ??
        '';
    final winningSeat = _winningSeat(table, displayOrder);
    final canDeal =
        botGame == null &&
        app.profile?.id == friendGame!.hostId &&
        order.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CountChip(
              icon: Icons.replay,
              label: 'Round ${state['round'] ?? 1}',
            ),
            CountChip(
              icon: Icons.style_outlined,
              label: '${deck.length} in deck',
              color: VoxoraColors.orange,
            ),
            CountChip(
              icon: Icons.table_bar_outlined,
              label: '$playedCount/${displayOrder.length} played',
              color: VoxoraColors.teal,
            ),
            if (activeSeat.isNotEmpty)
              CountChip(
                icon: Icons.touch_app_outlined,
                label: '${_seatName(app, bot, activeSeat)} turn',
                color: VoxoraColors.green,
              ),
            if (botGame == null)
              FilledButton.icon(
                onPressed: canDeal ? () => app.dealCards(friendGame!) : null,
                icon: const Icon(Icons.style_outlined),
                label: const Text('Deal'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _CardTableFelt(
          deckCount: deck.length,
          playedCount: playedCount,
          seats: displayOrder
              .map(
                (seat) => _CardSeatState(
                  seat: seat,
                  name: _seatName(app, bot, seat),
                  score: (scores[seat] as int?) ?? 0,
                  handCount: (hands[seat] as List? ?? const []).length,
                  playedCard: table[seat] as String?,
                  active: activeSeat == seat && order.isNotEmpty,
                  leading: winningSeat == seat,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Your hand', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 10),
            CountChip(
              icon: Icons.back_hand_outlined,
              label: '${myHand.length} cards',
              color: VoxoraColors.orange,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (myHand.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              'Cards appear here after the host deals.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          _HandFan(
            cards: myHand,
            canPlayCard: (card) {
              return botGame == null
                  ? friendGame!.currentSeat == mySeat
                  : table[BotGameProvider.playerId] == null &&
                        !bot.botThinking &&
                        (botGame?.isActive ?? false);
            },
            onPlay: (card) {
              if (botGame == null) {
                app.playCard(friendGame!, card);
              } else {
                bot.playCard(botGame!.id, card);
              }
            },
          ),
      ],
    );
  }

  String _activeBotSeat(
    List<String> order,
    Map<String, dynamic> table,
    bool botThinking,
  ) {
    if (order.isEmpty) return '';
    if (table[BotGameProvider.playerId] == null) {
      return BotGameProvider.playerId;
    }
    if (botThinking) {
      return order.firstWhere(
        (seat) => seat != BotGameProvider.playerId && table[seat] == null,
        orElse: () => '',
      );
    }
    return '';
  }

  String? _winningSeat(Map<String, dynamic> table, List<String> order) {
    final played = order.where((seat) => table[seat] is String).toList();
    if (played.isEmpty) return null;
    played.sort(
      (a, b) => _cardRank(table[b] as String) - _cardRank(table[a] as String),
    );
    return played.first;
  }

  int _cardRank(String card) {
    return cardRanks.indexOf(card.replaceAll(RegExp(r'[SHDC]'), ''));
  }

  String _seatName(AppProvider app, BotGameProvider bot, String seat) {
    if (botGame != null) {
      return bot.profileName(
        seat == BotGameProvider.playerId
            ? seat
            : seat.replaceFirst('p', 'bot_'),
      );
    }
    final player = app
        .playersForGame(friendGame!.id)
        .where((p) => p.seat == seat)
        .firstOrNull;
    return app.profileById(player?.userId)?.fullName ?? seat.toUpperCase();
  }
}

class _CardSeatState {
  final String seat;
  final String name;
  final int score;
  final int handCount;
  final String? playedCard;
  final bool active;
  final bool leading;

  const _CardSeatState({
    required this.seat,
    required this.name,
    required this.score,
    required this.handCount,
    required this.playedCard,
    required this.active,
    required this.leading,
  });
}

class _CardTableFelt extends StatelessWidget {
  final int deckCount;
  final int playedCount;
  final List<_CardSeatState> seats;

  const _CardTableFelt({
    required this.deckCount,
    required this.playedCount,
    required this.seats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E5F49), Color(0xFF123B32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 620;
              final center = _TrickCenter(
                playedCount: playedCount,
                totalPlayers: seats.length,
                cards: seats
                    .where((seat) => seat.playedCard != null)
                    .map((seat) => seat.playedCard!)
                    .toList(),
              );
              final deck = _DeckPile(count: deckCount);
              if (narrow) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [deck, const SizedBox(width: 18), center],
                    ),
                    const SizedBox(height: 16),
                    _SeatWrap(seats: seats),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  deck,
                  const SizedBox(width: 18),
                  Expanded(child: center),
                  const SizedBox(width: 18),
                  SizedBox(width: 310, child: _SeatWrap(seats: seats)),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 10),
          Text(
            'Highest rank takes the round',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatWrap extends StatelessWidget {
  final List<_CardSeatState> seats;

  const _SeatWrap({required this.seats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: seats.map((seat) => _CardSeatPanel(seat: seat)).toList(),
    );
  }
}

class _CardSeatPanel extends StatelessWidget {
  final _CardSeatState seat;

  const _CardSeatPanel({required this.seat});

  @override
  Widget build(BuildContext context) {
    final accent = seat.leading
        ? VoxoraColors.amber
        : seat.active
        ? VoxoraColors.green
        : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: seat.active ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(
            alpha: seat.active || seat.leading ? 0.95 : 0.24,
          ),
          width: seat.active || seat.leading ? 1.6 : 1,
        ),
        boxShadow: seat.active
            ? [
                BoxShadow(
                  color: VoxoraColors.green.withValues(alpha: 0.28),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  seat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                seat.leading
                    ? Icons.emoji_events
                    : seat.active
                    ? Icons.circle
                    : Icons.circle_outlined,
                color: accent,
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'Score', value: '${seat.score}'),
              _MiniStat(label: 'Hand', value: '${seat.handCount}'),
            ],
          ),
          const SizedBox(height: 8),
          _PlayingCard(
            card: seat.playedCard,
            back: seat.playedCard == null,
            width: 58,
            height: 82,
            glow: seat.leading,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DeckPile extends StatelessWidget {
  final int count;

  const _DeckPile({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 5,
              top: i * 4,
              child: Transform.rotate(
                angle: (i - 1) * 0.045,
                child: _PlayingCard(
                  back: true,
                  width: 76,
                  height: 108,
                  elevated: i == 2,
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '$count left',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrickCenter extends StatelessWidget {
  final int playedCount;
  final int totalPlayers;
  final List<String> cards;

  const _TrickCenter({
    required this.playedCount,
    required this.totalPlayers,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Table',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 98,
            child: Center(
              child: cards.isEmpty
                  ? _EmptyTrickPile(
                      playedCount: playedCount,
                      totalPlayers: totalPlayers,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < cards.length; i++)
                          Transform.translate(
                            offset: Offset(
                              (i - (cards.length - 1) / 2) * 32,
                              0,
                            ),
                            child: Transform.rotate(
                              angle: (i - (cards.length - 1) / 2) * 0.08,
                              child: _PlayingCard(
                                card: cards[i],
                                width: 62,
                                height: 90,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrickPile extends StatelessWidget {
  final int playedCount;
  final int totalPlayers;

  const _EmptyTrickPile({
    required this.playedCount,
    required this.totalPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '$playedCount/$totalPlayers',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HandFan extends StatelessWidget {
  final List<String> cards;
  final bool Function(String card) canPlayCard;
  final void Function(String card) onPlay;

  const _HandFan({
    required this.cards,
    required this.canPlayCard,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final center = (cards.length - 1) / 2;
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        itemBuilder: (context, index) {
          final card = cards[index];
          final canPlay = canPlayCard(card);
          return Transform.translate(
            offset: Offset(0, (index - center).abs() * 2.5),
            child: Transform.rotate(
              angle: (index - center) * 0.035,
              child: _HandCardButton(
                card: card,
                canPlay: canPlay,
                onTap: canPlay ? () => onPlay(card) : null,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: cards.length,
      ),
    );
  }
}

class _HandCardButton extends StatefulWidget {
  final String card;
  final bool canPlay;
  final VoidCallback? onTap;

  const _HandCardButton({
    required this.card,
    required this.canPlay,
    required this.onTap,
  });

  @override
  State<_HandCardButton> createState() => _HandCardButtonState();
}

class _HandCardButtonState extends State<_HandCardButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && widget.canPlay ? 1.06 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: _hovered && widget.canPlay
                ? const Offset(0, -0.08)
                : Offset.zero,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: _PlayingCard(
              card: widget.card,
              width: 86,
              height: 124,
              glow: widget.canPlay,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayingCard extends StatelessWidget {
  final String? card;
  final bool back;
  final double width;
  final double height;
  final bool elevated;
  final bool glow;

  const _PlayingCard({
    this.card,
    this.back = false,
    this.width = 72,
    this.height = 104,
    this.elevated = true,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final red = card != null && (card!.endsWith('H') || card!.endsWith('D'));
    final suit = card == null ? '' : card!.substring(card!.length - 1);
    final rank = card == null ? '' : card!.substring(0, card!.length - 1);
    final suitLabel = _suit(suit);
    final suitColor = red ? const Color(0xFFE11D48) : Colors.black;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: glow ? VoxoraColors.amber : const Color(0xFFD1D5DB),
          width: glow ? 1.8 : 1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: (glow ? VoxoraColors.amber : Colors.black).withValues(
                    alpha: glow ? 0.32 : 0.26,
                  ),
                  blurRadius: glow ? 16 : 9,
                  offset: const Offset(2, 5),
                ),
              ]
            : null,
      ),
      child: back
          ? CustomPaint(
              painter: _CardBackPainter(),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: width * 0.28,
                ),
              ),
            )
          : Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: _CardCorner(
                    rank: rank,
                    suit: suit,
                    suitLabel: suitLabel,
                    color: suitColor,
                    size: width,
                  ),
                ),
                Center(
                  child: _CardSuitIcon(
                    suit: suit,
                    color: suitColor,
                    size: width * 0.38,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Transform.rotate(
                    angle: 3.14159,
                    child: _CardCorner(
                      rank: rank,
                      suit: suit,
                      suitLabel: suitLabel,
                      color: suitColor,
                      size: width,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _suit(String suit) {
    return switch (suit) {
      'S' => '♠',
      'H' => '♥',
      'D' => '♦',
      'C' => '♣',
      _ => '',
    };
  }
}

class _CardCorner extends StatelessWidget {
  final String rank;
  final String suit;
  final String suitLabel;
  final Color color;
  final double size;

  const _CardCorner({
    required this.rank,
    required this.suit,
    required this.suitLabel,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rank $suitLabel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rank,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.18,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 2),
          _CardSuitIcon(suit: suit, color: color, size: size * 0.16),
        ],
      ),
    );
  }
}

class _CardSuitIcon extends StatelessWidget {
  final String suit;
  final Color color;
  final double size;

  const _CardSuitIcon({
    required this.suit,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CardSuitPainter(suit: suit, color: color),
    );
  }
}

class _CardSuitPainter extends CustomPainter {
  final String suit;
  final Color color;

  const _CardSuitPainter({required this.suit, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color;
    final w = size.width;
    final h = size.height;

    switch (suit) {
      case 'H':
        final path = Path()
          ..moveTo(w * 0.5, h * 0.86)
          ..cubicTo(w * 0.08, h * 0.52, w * 0.06, h * 0.18, w * 0.3, h * 0.16)
          ..cubicTo(w * 0.42, h * 0.15, w * 0.49, h * 0.24, w * 0.5, h * 0.34)
          ..cubicTo(w * 0.51, h * 0.24, w * 0.58, h * 0.15, w * 0.7, h * 0.16)
          ..cubicTo(w * 0.94, h * 0.18, w * 0.92, h * 0.52, w * 0.5, h * 0.86)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'D':
        final path = Path()
          ..moveTo(w * 0.5, h * 0.08)
          ..lineTo(w * 0.86, h * 0.5)
          ..lineTo(w * 0.5, h * 0.92)
          ..lineTo(w * 0.14, h * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'C':
        canvas
          ..drawCircle(Offset(w * 0.36, h * 0.45), w * 0.21, paint)
          ..drawCircle(Offset(w * 0.64, h * 0.45), w * 0.21, paint)
          ..drawCircle(Offset(w * 0.5, h * 0.25), w * 0.21, paint);
        final stem = Path()
          ..moveTo(w * 0.5, h * 0.48)
          ..lineTo(w * 0.64, h * 0.88)
          ..lineTo(w * 0.36, h * 0.88)
          ..close();
        canvas.drawPath(stem, paint);
        break;
      default:
        final path = Path()
          ..moveTo(w * 0.5, h * 0.08)
          ..cubicTo(w * 0.08, h * 0.42, w * 0.06, h * 0.76, w * 0.32, h * 0.77)
          ..cubicTo(w * 0.43, h * 0.78, w * 0.49, h * 0.68, w * 0.5, h * 0.58)
          ..cubicTo(w * 0.51, h * 0.68, w * 0.57, h * 0.78, w * 0.68, h * 0.77)
          ..cubicTo(w * 0.94, h * 0.76, w * 0.92, h * 0.42, w * 0.5, h * 0.08)
          ..close();
        canvas.drawPath(path, paint);
        final stem = Path()
          ..moveTo(w * 0.5, h * 0.58)
          ..lineTo(w * 0.64, h * 0.92)
          ..lineTo(w * 0.36, h * 0.92)
          ..close();
        canvas.drawPath(stem, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardSuitPainter oldDelegate) {
    return oldDelegate.suit != suit || oldDelegate.color != color;
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF7C2D12)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      base,
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.18);
    for (var x = -size.height; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(7), const Radius.circular(6)),
      border,
    );
    canvas.drawCircle(
      rect.center,
      size.shortestSide * 0.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.52),
    );
  }

  @override
  bool shouldRepaint(covariant _CardBackPainter oldDelegate) {
    return false;
  }
}

class _GuideDialog extends StatelessWidget {
  final String type;

  const _GuideDialog({required this.type});

  @override
  Widget build(BuildContext context) {
    final rules = switch (type) {
      'chess' => [
        'Move one piece on your turn.',
        'Protect your king. Checkmate wins.',
        'Tap your piece to see legal destination squares.',
        'Pawns promote to queen automatically in this app.',
      ],
      'ludo' => [
        'Roll the dice on your color turn.',
        'A six moves a piece from base onto its start square.',
        'Landing on a rival outside safe squares sends that piece home.',
        'Sixes and captures give another turn; three sixes lose the turn.',
        'Reach 56 with all pieces to win.',
        'Glowing pieces are legal moves for the current dice.',
      ],
      'cards' => [
        'Each player receives five cards.',
        'Players play one card per round.',
        'Highest rank wins the round.',
        'Most won rounds after hands empty wins.',
      ],
      _ => <String>[],
    };
    return AlertDialog(
      title: Text('${gameTitles[type]} rules'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules
            .map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rule)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _TutorialDialog extends StatelessWidget {
  final String type;

  const _TutorialDialog({required this.type});

  @override
  Widget build(BuildContext context) {
    final steps = switch (type) {
      'chess' => [
        'Start by developing pawns and knights.',
        'Tap a piece and follow the green squares.',
        'If your king is checked, your move must remove the check.',
      ],
      'ludo' => [
        'Roll first, then choose one highlighted piece.',
        'Use sixes to bring new pieces out and keep pressure on rivals.',
        'Aim for the marked safe squares when an opponent is close.',
        'Near home, choose exact moves that reach 56.',
      ],
      'cards' => [
        'Play low cards when you cannot win.',
        'Play the lowest card that beats the table when you can win.',
        'Track scores after each round.',
      ],
      _ => <String>[],
    };
    return AlertDialog(
      title: Text('${gameTitles[type]} tutorial'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < steps.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(steps[i]),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Start playing'),
        ),
      ],
    );
  }
}
