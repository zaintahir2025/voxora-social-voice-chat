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
        const VSectionTitle(icon: Icons.radio, title: 'Rooms'),
        // Create room form
        TextField(
          controller: _titleC,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Room title'),
        ),
        const SizedBox(height: 10),
        TextField(controller: _topicC, decoration: const InputDecoration(hintText: 'Topic')),
        const SizedBox(height: 10),
        TextField(controller: _capC, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Capacity')),
        const SizedBox(height: 10),
        TextField(controller: _descC, maxLines: 2, decoration: const InputDecoration(hintText: 'Description')),
        const SizedBox(height: 10),
        VGradientButton(
          label: 'Start room',
          icon: Icons.add,
          onTap: _titleC.text.trim().isEmpty ? null : () {
            app.createRoom(
              title: _titleC.text,
              topic: _topicC.text,
              description: _descC.text,
              capacity: int.tryParse(_capC.text) ?? 200,
            );
            _titleC.clear(); _descC.clear();
            setState(() {});
          },
        ),
        const SizedBox(height: 14),
        // Room list
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(room.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${host.fullName} / ${room.topic}', style: Theme.of(context).textTheme.bodySmall),
                  ])),
                  Text('$count/${room.capacity}', style: Theme.of(context).textTheme.bodySmall),
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
              Text(room.topic.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(room.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(room.description.isEmpty ? 'No room description yet.' : room.description,
                style: TextStyle(color: VoxoraColors.muted, height: 1.55)),
            ])),
            const SizedBox(width: 12),
            Column(children: [
              VSecondaryButton(label: 'Join', icon: Icons.phone, onTap: () => app.joinRoom(room)),
              const SizedBox(height: 8),
              VDangerButton(label: 'Leave', icon: Icons.phone_disabled, onTap: () => app.leaveRoom(room)),
            ]),
          ],
        ),
        const Divider(height: 32),

        VoiceConsole(room: room, userId: app.profile!.id, joined: myP != null),
        const SizedBox(height: 16),

        // Participants
        Wrap(
          spacing: 10, runSpacing: 10,
          children: participants.map((p) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: VoxoraColors.line),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.72),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                VAvatar(url: p.profile?.avatarUrl, size: 42),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.profile?.fullName ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(p.role, style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(width: 8),
                Icon(p.muted ? Icons.mic_off : Icons.mic, size: 16, color: VoxoraColors.muted),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Meeting tools
        _meetingTools(app, room, notes, myP),
        const SizedBox(height: 16),

        // Room games
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: VoxoraColors.line),
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.78), const Color(0xFFF1F4FF).withValues(alpha: 0.72)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Room games', style: TextStyle(fontWeight: FontWeight.w700)),
              VSecondaryButton(label: 'Open', onTap: () => app.setView(AppView.games)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: ['chess', 'ludo', 'cards'].map((g) =>
              OutlinedButton(
                onPressed: myP == null ? null : () => app.createGame(room.id, g),
                child: Text(g[0].toUpperCase() + g.substring(1)),
              ),
            ).toList()),
            const SizedBox(height: 8),
            if (roomGames.isEmpty)
              Text('No active game in this room.', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(spacing: 8, children: roomGames.map((g) => Chip(label: Text(g.title))).toList()),
          ]),
        ),
        const SizedBox(height: 16),

        // Chat
        Container(
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(color: VoxoraColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _chatC,
                  onChanged: (_) => setState(() {}),
                  enabled: myP != null,
                  decoration: InputDecoration(hintText: myP != null ? 'Write to the room' : 'Join to chat'),
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

  Widget _meetingTools(AppProvider app, Room room, List<MeetingNote> notes, RoomParticipant? myP) {
    final tabs = {'agenda': 'Agenda', 'decision': 'Decisions', 'action': 'Action items'};
    final visible = notes.where((n) => n.noteType == _meetingTab).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: VoxoraColors.line),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.78), const Color(0xFFF1F4FF).withValues(alpha: 0.72)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: [
          ...tabs.entries.map((e) => _meetingTabButton(e.key, e.value)),
          OutlinedButton.icon(
            onPressed: () async {
              final base = appPublicUrl.endsWith('/') ? appPublicUrl : '$appPublicUrl/';
              final url = '$base?room=${room.id}';
              await Clipboard.setData(ClipboardData(text: url));
              setState(() => _copiedMsg = 'Invite link copied.');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Invite'),
          ),
        ]),
        if (_copiedMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_copiedMsg, style: const TextStyle(color: VoxoraColors.primaryStrong, fontWeight: FontWeight.w800)),
        ],
        const SizedBox(height: 10),
        ...visible.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () => app.toggleMeetingNote(n),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: VoxoraColors.line),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.body,
                  style: TextStyle(decoration: n.isDone ? TextDecoration.lineThrough : null, color: n.isDone ? VoxoraColors.muted : null)),
                Text('${n.profile?.fullName ?? "Member"} / ${_formatTime(n.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
        )),
        if (visible.isEmpty) Text('No ${tabs[_meetingTab]?.toLowerCase()} yet.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _noteC,
            onChanged: (_) => setState(() {}),
            enabled: myP != null,
            decoration: InputDecoration(hintText: myP != null ? 'Add ${tabs[_meetingTab]?.toLowerCase()}' : 'Join to add notes'),
          )),
          const SizedBox(width: 8),
          VGradientIconButton(
            icon: Icons.send,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isActive ? VoxoraColors.primary : Colors.white,
          border: isActive ? null : Border.all(color: VoxoraColors.line),
        ),
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isActive ? Colors.white : VoxoraColors.text,
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
    return AnimatedBuilder(
      animation: _voice,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VoxoraColors.cyan.withValues(alpha: 0.28)),
            gradient: LinearGradient(colors: [VoxoraColors.cyan.withValues(alpha: 0.1), VoxoraColors.lime.withValues(alpha: 0.12)]),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _voice.enabled ? VoxoraColors.primary : const Color(0xFF252A3C),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_voice.enabled && !_voice.muted ? Icons.mic : Icons.mic_off, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _voice.enabled ? (_voice.muted ? 'Muted' : 'Mic live') : 'Voice idle',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ]),
              ),
              Text(_voice.status, style: Theme.of(context).textTheme.bodySmall),
              VGradientButton(
                label: _voice.enabled ? 'Stop voice' : 'Start voice',
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
              if (!widget.joined) Text('Join the room to speak.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
