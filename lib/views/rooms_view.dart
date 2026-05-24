import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/voice_room_service.dart';
import '../widgets/common_widgets.dart';

class RoomsView extends StatefulWidget {
  const RoomsView({super.key});
  @override
  State<RoomsView> createState() => _RoomsViewState();
}

class _RoomsViewState extends State<RoomsView> {
  final _titleC = TextEditingController();
  final _topicC = TextEditingController(text: 'General');
  final _capC = TextEditingController(text: '200');
  final _descC = TextEditingController();
  final _chatC = TextEditingController();
  String _meetingTab = 'agenda';
  final _noteC = TextEditingController();
  String _copiedMsg = '';
  bool _showCreateForm = false;

  @override
  void dispose() {
    _titleC.dispose(); _topicC.dispose(); _capC.dispose(); _descC.dispose();
    _chatC.dispose(); _noteC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: _roomList(app)),
          const SizedBox(width: 18),
          Expanded(child: _roomDetail(app)),
        ],
      );
    }
    return Column(children: [_roomList(app), const SizedBox(height: 18), _roomDetail(app)]);
  }

  Widget _roomList(AppProvider app) {
    return VPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VSectionTitle(
          icon: Icons.radio,
          title: 'Rooms',
          trailing: VSecondaryButton(
            label: _showCreateForm ? 'Close' : 'New',
            icon: _showCreateForm ? Icons.close : Icons.add,
            onTap: () => setState(() => _showCreateForm = !_showCreateForm),
          ),
        ),
        // Create room form
        if (_showCreateForm) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: VoxoraTheme.accentGlow,
            child: Column(children: [
              TextField(
                controller: _titleC,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: VoxoraColors.text),
                decoration: const InputDecoration(hintText: 'Room title', prefixIcon: Icon(Icons.title, size: 18, color: VoxoraColors.muted)),
              ),
              const SizedBox(height: 10),
              TextField(controller: _topicC, style: const TextStyle(color: VoxoraColors.text), decoration: const InputDecoration(hintText: 'Topic', prefixIcon: Icon(Icons.topic, size: 18, color: VoxoraColors.muted))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: _capC, keyboardType: TextInputType.number, style: const TextStyle(color: VoxoraColors.text), decoration: const InputDecoration(hintText: 'Capacity', prefixIcon: Icon(Icons.people, size: 18, color: VoxoraColors.muted)))),
              ]),
              const SizedBox(height: 10),
              TextField(controller: _descC, maxLines: 2, style: const TextStyle(color: VoxoraColors.text), decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description, size: 18, color: VoxoraColors.muted))),
              const SizedBox(height: 14),
              VGradientButton(
                label: 'Create room',
                icon: Icons.rocket_launch,
                fullWidth: true,
                onTap: _titleC.text.trim().isEmpty ? null : () {
                  app.createRoom(
                    title: _titleC.text,
                    topic: _topicC.text,
                    description: _descC.text,
                    capacity: int.tryParse(_capC.text) ?? 200,
                  );
                  _titleC.clear(); _descC.clear();
                  setState(() => _showCreateForm = false);
                },
              ),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        // Room list
        if (app.liveRooms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No live rooms yet. Create one!', style: TextStyle(color: VoxoraColors.muted, fontSize: 13))),
          )
        else
          ...app.liveRooms.map((room) {
            final host = app.profiles.firstWhere((p) => p.id == room.hostId,
                orElse: () => Profile(id: '', fullName: 'Host', handle: '', createdAt: ''));
            final count = app.participants.where((p) => p.roomId == room.id).length;
            final isActive = app.activeRoom?.id == room.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VListRow(
                isActive: isActive,
                onTap: () { app.selectRoom(room.id); app.joinRoom(room); },
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: room.isLive ? VoxoraColors.online : VoxoraColors.muted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(room.title, style: const TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text)),
                      const SizedBox(height: 2),
                      Text('${host.fullName} · ${room.topic}', style: Theme.of(context).textTheme.bodySmall),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: VoxoraColors.surfaceLight,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.people, size: 12, color: VoxoraColors.muted),
                        const SizedBox(width: 4),
                        Text('$count', style: const TextStyle(fontSize: 12, color: VoxoraColors.muted, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          }),
      ]),
    );
  }

  Widget _roomDetail(AppProvider app) {
    final room = app.activeRoom;
    if (room == null) {
      return VPanel(child: const VEmptyState(icon: Icons.radio, title: 'No active room', body: 'Create a room or join one from the list.'));
    }

    final participants = app.roomParticipants;
    final messages = app.messagesForRoom;
    final notes = app.notesForRoom;
    final myP = app.myParticipant;
    final roomGames = app.gameSessions.where((g) => g.roomId == room.id && g.isActive).toList();

    return VPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                VStatusBadge(label: room.topic, color: VoxoraColors.cyan, icon: Icons.topic),
                const SizedBox(width: 8),
                if (room.isLive) const VStatusBadge(label: 'LIVE', color: VoxoraColors.online, icon: Icons.fiber_manual_record),
              ]),
              const SizedBox(height: 10),
              Text(room.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(room.description.isEmpty ? 'No room description yet.' : room.description,
                style: TextStyle(color: VoxoraColors.muted, height: 1.55)),
            ])),
            const SizedBox(width: 12),
            Column(children: [
              VSecondaryButton(label: myP != null ? 'Joined' : 'Join', icon: Icons.login, onTap: myP != null ? null : () => app.joinRoom(room)),
              const SizedBox(height: 8),
              VDangerButton(label: 'Leave', icon: Icons.logout, onTap: () => app.leaveRoom(room)),
            ]),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),

        VoiceConsole(room: room, userId: app.profile!.id, joined: myP != null),
        const SizedBox(height: 20),

        // Participants
        Text('PARTICIPANTS · ${participants.length}', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: participants.map((p) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: VoxoraColors.line),
                borderRadius: BorderRadius.circular(12),
                color: VoxoraColors.surfaceLight,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                VAvatar(url: p.profile?.avatarUrl, size: 38, showOnline: !p.muted),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.profile?.fullName ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text, fontSize: 13)),
                  Row(children: [
                    VStatusBadge(
                      label: p.role,
                      color: p.role == 'host' ? VoxoraColors.lime : VoxoraColors.muted,
                    ),
                  ]),
                ]),
                const SizedBox(width: 8),
                Icon(p.muted ? Icons.mic_off : Icons.mic, size: 16, color: p.muted ? VoxoraColors.muted : VoxoraColors.online),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Meeting tools
        _meetingTools(app, room, notes, myP),
        const SizedBox(height: 20),

        // Room games
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: VoxoraColors.line),
            borderRadius: BorderRadius.circular(14),
            color: VoxoraColors.surfaceLight,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.sports_esports, size: 18, color: VoxoraColors.lime),
                const SizedBox(width: 8),
                const Text('Room Games', style: TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text)),
              ]),
              VSecondaryButton(label: 'View all', onTap: () => app.setView(AppView.games)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: ['chess', 'ludo', 'cards'].map((g) =>
              OutlinedButton.icon(
                onPressed: myP == null ? null : () => app.createGame(room.id, g),
                icon: Icon(_gameIcon(g), size: 16),
                label: Text(g[0].toUpperCase() + g.substring(1)),
              ),
            ).toList()),
            const SizedBox(height: 8),
            if (roomGames.isEmpty)
              Text('No active games.', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(spacing: 8, children: roomGames.map((g) => Chip(
                avatar: Icon(_gameIcon(g.gameType), size: 14, color: VoxoraColors.cyan),
                label: Text(g.title),
              )).toList()),
          ]),
        ),
        const SizedBox(height: 20),

        // Chat
        Container(
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(color: VoxoraColors.line),
            borderRadius: BorderRadius.circular(14),
            color: VoxoraColors.surfaceLight,
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: VoxoraColors.line)),
              ),
              child: Row(children: [
                const Icon(Icons.chat, size: 16, color: VoxoraColors.cyan),
                const SizedBox(width: 8),
                Text('Room Chat · ${messages.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text, fontSize: 13)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  return VMessageBubble(
                    name: m.profile?.fullName ?? 'Member',
                    body: m.body,
                    time: m.createdAt,
                    isMine: m.senderId == app.profile?.id,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: VoxoraColors.line)),
              ),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _chatC,
                  onChanged: (_) => setState(() {}),
                  enabled: myP != null,
                  style: const TextStyle(color: VoxoraColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: myP != null ? 'Type a message...' : 'Join room to chat',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: VoxoraColors.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: VoxoraColors.line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: VoxoraColors.primary)),
                    filled: true,
                    fillColor: VoxoraColors.surface,
                  ),
                )),
                const SizedBox(width: 8),
                VGradientIconButton(
                  icon: Icons.send,
                  onTap: myP == null || _chatC.text.trim().isEmpty ? null : () {
                    final body = _chatC.text;
                    _chatC.clear();
                    setState(() {});
                    app.sendRoomMessage(room.id, body);
                  },
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  IconData _gameIcon(String type) {
    switch (type) {
      case 'chess': return Icons.grid_on;
      case 'ludo': return Icons.casino;
      case 'cards': return Icons.style;
      default: return Icons.sports_esports;
    }
  }

  Widget _meetingTools(AppProvider app, Room room, List<MeetingNote> notes, RoomParticipant? myP) {
    final tabs = {'agenda': 'Agenda', 'decision': 'Decisions', 'action': 'Action Items'};
    final visible = notes.where((n) => n.noteType == _meetingTab).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: VoxoraColors.line),
        borderRadius: BorderRadius.circular(14),
        color: VoxoraColors.surfaceLight,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.description, size: 18, color: VoxoraColors.coral),
          const SizedBox(width: 8),
          const Text('Meeting Tools', style: TextStyle(fontWeight: FontWeight.w700, color: VoxoraColors.text)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...tabs.entries.map((e) => _meetingTabButton(e.key, e.value)),
          OutlinedButton.icon(
            onPressed: () async {
              final base = appPublicUrl.endsWith('/') ? appPublicUrl : '$appPublicUrl/';
              final url = '$base?room=${room.id}';
              await Clipboard.setData(ClipboardData(text: url));
              setState(() => _copiedMsg = 'Invite link copied!');
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _copiedMsg = '');
              });
            },
            icon: const Icon(Icons.link, size: 16),
            label: const Text('Invite'),
          ),
        ]),
        if (_copiedMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          VStatusBadge(label: _copiedMsg, color: VoxoraColors.success, icon: Icons.check_circle),
        ],
        const SizedBox(height: 12),
        ...visible.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => app.toggleMeetingNote(n),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: n.isDone ? VoxoraColors.success.withValues(alpha: 0.3) : VoxoraColors.line),
                borderRadius: BorderRadius.circular(10),
                color: n.isDone ? VoxoraColors.success.withValues(alpha: 0.08) : VoxoraColors.surface,
              ),
              child: Row(children: [
                Icon(n.isDone ? Icons.check_circle : Icons.circle_outlined, size: 18, color: n.isDone ? VoxoraColors.success : VoxoraColors.muted),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.body,
                    style: TextStyle(
                      color: n.isDone ? VoxoraColors.muted : VoxoraColors.text,
                      decoration: n.isDone ? TextDecoration.lineThrough : null,
                    )),
                  Text('${n.profile?.fullName ?? "Member"} · ${_formatTime(n.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                ])),
              ]),
            ),
          ),
        )),
        if (visible.isEmpty) Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('No ${tabs[_meetingTab]?.toLowerCase()} yet.', style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _noteC,
            onChanged: (_) => setState(() {}),
            enabled: myP != null,
            style: const TextStyle(color: VoxoraColors.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: myP != null ? 'Add ${tabs[_meetingTab]?.toLowerCase()}...' : 'Join to add notes',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          )),
          const SizedBox(width: 8),
          VGradientIconButton(
            icon: Icons.add,
            onTap: myP == null || _noteC.text.trim().isEmpty ? null : () {
              final body = _noteC.text;
              _noteC.clear();
              setState(() {});
              app.addMeetingNote(room.id, _meetingTab, body);
            },
          ),
        ]),
      ]),
    );
  }

  Widget _meetingTabButton(String key, String label) {
    final isActive = _meetingTab == key;
    return GestureDetector(
      onTap: () => setState(() => _meetingTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive ? const LinearGradient(colors: [VoxoraColors.primary, VoxoraColors.coral]) : null,
          color: isActive ? null : VoxoraColors.surface,
          border: isActive ? null : Border.all(color: VoxoraColors.line),
          boxShadow: isActive ? [BoxShadow(color: VoxoraColors.primary.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: isActive ? Colors.white : VoxoraColors.muted,
        )),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}

class VoiceConsole extends StatefulWidget {
  const VoiceConsole({
    super.key,
    required this.room,
    required this.userId,
    required this.joined,
  });

  final Room room;
  final String userId;
  final bool joined;

  @override
  State<VoiceConsole> createState() => _VoiceConsoleState();
}

class _VoiceConsoleState extends State<VoiceConsole> {
  late VoiceRoomController _voice;

  @override
  void initState() {
    super.initState();
    _voice = VoiceRoomController(roomId: widget.room.id, userId: widget.userId);
  }

  @override
  void didUpdateWidget(covariant VoiceConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id || oldWidget.userId != widget.userId) {
      _voice.dispose();
      _voice = VoiceRoomController(roomId: widget.room.id, userId: widget.userId);
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _voice,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _voice.enabled ? VoxoraColors.cyan.withValues(alpha: 0.4) : VoxoraColors.line),
            gradient: LinearGradient(
              colors: _voice.enabled
                  ? [VoxoraColors.cyan.withValues(alpha: 0.12), VoxoraColors.primary.withValues(alpha: 0.08)]
                  : [VoxoraColors.surfaceLight, VoxoraColors.surface],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.graphic_eq, size: 18, color: _voice.enabled ? VoxoraColors.cyan : VoxoraColors.muted),
                const SizedBox(width: 8),
                Text('Voice Channel', style: TextStyle(fontWeight: FontWeight.w700, color: _voice.enabled ? VoxoraColors.cyan : VoxoraColors.text)),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _voice.enabled
                          ? (_voice.muted ? VoxoraColors.lime.withValues(alpha: 0.15) : VoxoraColors.online.withValues(alpha: 0.15))
                          : VoxoraColors.surfaceLight,
                      border: Border.all(
                        color: _voice.enabled
                            ? (_voice.muted ? VoxoraColors.lime.withValues(alpha: 0.3) : VoxoraColors.online.withValues(alpha: 0.3))
                            : VoxoraColors.line,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _voice.enabled && !_voice.muted ? Icons.mic : Icons.mic_off,
                        size: 16,
                        color: _voice.enabled ? (_voice.muted ? VoxoraColors.lime : VoxoraColors.online) : VoxoraColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _voice.enabled ? (_voice.muted ? 'Muted' : 'Live') : 'Idle',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _voice.enabled ? (_voice.muted ? VoxoraColors.lime : VoxoraColors.online) : VoxoraColors.muted,
                        ),
                      ),
                    ]),
                  ),
                  Text(_voice.status, style: Theme.of(context).textTheme.bodySmall),
                  VGradientButton(
                    label: _voice.enabled ? 'Disconnect' : 'Connect',
                    icon: _voice.enabled ? Icons.call_end : Icons.call,
                    onTap: !widget.joined
                        ? null
                        : () {
                            if (_voice.enabled) {
                              _voice.stop();
                            } else {
                              _voice.start();
                            }
                          },
                  ),
                  VSecondaryButton(
                    label: _voice.muted ? 'Unmute' : 'Mute',
                    icon: _voice.muted ? Icons.mic : Icons.mic_off,
                    onTap: _voice.enabled ? _voice.toggleMute : null,
                  ),
                  if (!widget.joined)
                    const VStatusBadge(label: 'Join to speak', color: VoxoraColors.muted, icon: Icons.info_outline),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
