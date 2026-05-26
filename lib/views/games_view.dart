import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/bot_game_provider.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _chessStatus(board),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AspectRatio(
              aspectRatio: 1,
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
    return InkWell(
      onTap: () => _tapSquare(app, bot, board, square),
      child: Container(
        color: selected
            ? VoxoraColors.amber
            : legal
            ? VoxoraColors.green.withValues(alpha: 0.55)
            : dark
            ? const Color(0xFF769656)
            : const Color(0xFFEEEED2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (legal)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              piece == null ? '' : _piece(piece),
              style: TextStyle(
                fontSize: 34,
                color: piece?.color == chess_lib.Color.WHITE
                    ? Colors.white
                    : Colors.black,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
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

class _LudoBoard extends StatelessWidget {
  final GameSession? friendGame;
  final BotGame? botGame;

  const _LudoBoard({this.friendGame, this.botGame});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final bot = context.watch<BotGameProvider>();
    final state = botGame?.state ?? friendGame!.state;
    final players =
        botGame?.players ??
        {
          for (final player in app.playersForGame(friendGame!.id))
            player.seat: player.userId,
        };
    final colors = List<String>.from(
      state['activeColors'] as List? ?? ludoColorNames.take(4),
    );
    final turn = state['turn'] as String? ?? colors.first;
    final dice = state['dice'] as int?;
    final winner = state['winner'] as String?;
    final mySeat = botGame == null
        ? app.myPlayerForGame(friendGame!.id)?.seat
        : colors.firstWhere(
            (color) => players[color] == BotGameProvider.playerId,
            orElse: () => '',
          );

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
              onPressed: winner != null || mySeat != turn || dice != null
                  ? null
                  : () {
                      if (botGame == null) {
                        app.rollLudoDice(friendGame!);
                      } else {
                        bot.rollLudoDice(botGame!.id);
                      }
                    },
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Roll'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LudoGrid(colors: colors),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final tokens = List<int>.from(
              (state['tokens'] as Map)[color] as List? ?? [0, 0, 0, 0],
            );
            final lane = _laneColor(color);
            return SizedBox(
              width: 230,
              child: AppCard(
                color: lane.withValues(alpha: 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      color.toUpperCase(),
                      style: TextStyle(
                        color: lane,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _playerLabel(app, bot, players[color]),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(4, (index) {
                        final movable =
                            mySeat == color &&
                            color == turn &&
                            dice != null &&
                            winner == null &&
                            _canMove(tokens[index], dice);
                        return InkWell(
                          onTap: movable
                              ? () {
                                  if (botGame == null) {
                                    app.moveLudoToken(friendGame!, index);
                                  } else {
                                    bot.moveLudoToken(
                                      botGame!.id,
                                      color,
                                      index,
                                    );
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(30),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lane,
                              boxShadow: movable
                                  ? [
                                      BoxShadow(
                                        color: lane.withValues(alpha: 0.55),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                              border: Border.all(
                                color: Colors.white,
                                width: movable ? 3 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tokens[index].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (mySeat == color && dice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Highlighted pieces can move.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _canMove(int position, int dice) {
    return position < 56 &&
        (position > 0 || dice == 6) &&
        position + dice <= 56;
  }

  String _playerLabel(AppProvider app, BotGameProvider bot, dynamic id) {
    if (botGame != null) return bot.profileName(id);
    return app.profileById(id as String?)?.fullName ?? 'Open seat';
  }

  Color _laneColor(String color) {
    return Color(ludoBoardColors[color] ?? 0xFF64748B);
  }
}

class _LudoGrid extends StatelessWidget {
  final List<String> colors;

  const _LudoGrid({required this.colors});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _LudoPainter(colors)),
    );
  }
}

class _LudoPainter extends CustomPainter {
  final List<String> colors;

  _LudoPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final paint = Paint()..style = PaintingStyle.fill;
    final lanes = {
      'red': Rect.fromLTWH(0, 0, cell * 6, cell * 6),
      'blue': Rect.fromLTWH(cell * 9, 0, cell * 6, cell * 6),
      'green': Rect.fromLTWH(0, cell * 9, cell * 6, cell * 6),
      'yellow': Rect.fromLTWH(cell * 9, cell * 9, cell * 6, cell * 6),
    };
    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      paint,
    );
    for (final entry in lanes.entries) {
      paint.color = Color(
        ludoBoardColors[entry.key]!,
      ).withValues(alpha: colors.contains(entry.key) ? 0.88 : 0.16);
      canvas.drawRect(entry.value, paint);
      paint.color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(entry.value.center, cell * 1.7, paint);
    }
    paint.color = const Color(0xFFE5E7EB);
    for (var i = 0; i <= 15; i++) {
      canvas.drawLine(
        Offset(i * cell, 0),
        Offset(i * cell, size.height),
        paint,
      );
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), paint);
    }
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF111827).withValues(alpha: 0.18);
    canvas.drawLine(
      Offset(cell * 7.5, cell),
      Offset(cell * 7.5, cell * 14),
      pathPaint,
    );
    canvas.drawLine(
      Offset(cell, cell * 7.5),
      Offset(cell * 14, cell * 7.5),
      pathPaint,
    );
    paint.color = const Color(0xFF111827);
    final center = Path()
      ..moveTo(cell * 6, cell * 6)
      ..lineTo(cell * 9, cell * 6)
      ..lineTo(cell * 9, cell * 9)
      ..lineTo(cell * 6, cell * 9)
      ..close();
    canvas.drawPath(center, paint);
  }

  @override
  bool shouldRepaint(covariant _LudoPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _Dice3D extends StatelessWidget {
  final int? value;

  const _Dice3D({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Text(
        value?.toString() ?? '-',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
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
    final mySeat = botGame == null
        ? app.myPlayerForGame(friendGame!.id)?.seat
        : BotGameProvider.playerId;
    final myHand = List<String>.from(hands[mySeat] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CountChip(
              icon: Icons.replay,
              label: 'Round ${state['round'] ?? 1}',
            ),
            if (botGame == null)
              FilledButton.icon(
                onPressed:
                    app.profile?.id == friendGame!.hostId && order.isEmpty
                    ? () => app.dealCards(friendGame!)
                    : null,
                icon: const Icon(Icons.style_outlined),
                label: const Text('Deal'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: (order.isEmpty ? ['p1', 'p2'] : order).map((seat) {
            final played = table[seat] as String?;
            return AppCard(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SizedBox(
                width: 140,
                child: Column(
                  children: [
                    Text(
                      _seatName(app, bot, seat),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    CountChip(
                      icon: Icons.emoji_events_outlined,
                      label: '${scores[seat] ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    _PlayingCard(card: played, back: played == null),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text('Your hand', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (myHand.isEmpty)
          Text(
            'Cards appear here after the host deals.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: myHand.map((card) {
              final canPlay = botGame == null
                  ? friendGame!.currentSeat == mySeat
                  : table[BotGameProvider.playerId] == null && !bot.botThinking;
              return InkWell(
                onTap: canPlay
                    ? () {
                        if (botGame == null) {
                          app.playCard(friendGame!, card);
                        } else {
                          bot.playCard(botGame!.id, card);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: _PlayingCard(card: card),
              );
            }).toList(),
          ),
      ],
    );
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

class _PlayingCard extends StatelessWidget {
  final String? card;
  final bool back;

  const _PlayingCard({this.card, this.back = false});

  @override
  Widget build(BuildContext context) {
    final red = card != null && (card!.endsWith('H') || card!.endsWith('D'));
    final suit = card == null ? '' : card!.substring(card!.length - 1);
    final rank = card == null ? '' : card!.substring(0, card!.length - 1);
    return Container(
      width: 72,
      height: 104,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: back ? const Color(0xFF1D4ED8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4)),
        ],
      ),
      child: back
          ? const Center(child: Icon(Icons.auto_awesome, color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    color: red ? Colors.red : Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _suit(suit),
                  style: TextStyle(
                    color: red ? Colors.red : Colors.black,
                    fontSize: 24,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    rank,
                    style: TextStyle(
                      color: red ? Colors.red : Colors.black,
                      fontWeight: FontWeight.w900,
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
        'A piece leaves base only on a six.',
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
        'Use sixes to bring new pieces out.',
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
