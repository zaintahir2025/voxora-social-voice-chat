import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/models.dart';

enum AppView { rooms, messages, people, games, profile, admin }

class AppProvider extends ChangeNotifier {
  final SupabaseClient _sb = Supabase.instance.client;

  // Auth
  Session? _session;
  Session? get session => _session;

  // Data
  Profile? _profile;
  Profile? get profile => _profile;
  List<Profile> _profiles = [];
  List<Profile> get profiles => _profiles;
  List<Room> _rooms = [];
  List<Room> get rooms => _rooms;
  List<RoomParticipant> _participants = [];
  List<RoomParticipant> get participants => _participants;
  List<RoomMessage> _roomMessages = [];
  List<RoomMessage> get roomMessages => _roomMessages;
  List<MeetingNote> _meetingNotes = [];
  List<MeetingNote> get meetingNotes => _meetingNotes;
  List<GameSession> _gameSessions = [];
  List<GameSession> get gameSessions => _gameSessions;
  List<Friendship> _friendships = [];
  List<Friendship> get friendships => _friendships;
  List<ConversationSummary> _conversations = [];
  List<ConversationSummary> get conversations => _conversations;
  List<DirectMessage> _directMessages = [];
  List<DirectMessage> get directMessages => _directMessages;

  // UI state
  String? _activeRoomId;
  String? get activeRoomId => _activeRoomId;
  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;
  AppView _view = AppView.rooms;
  AppView get view => _view;
  bool _loading = true;
  bool get loading => _loading;
  String _notice = '';
  String get notice => _notice;

  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _realtimeChannel;

  // Derived
  Room? get activeRoom =>
      _rooms.where((r) => r.id == _activeRoomId).firstOrNull ?? _rooms.firstOrNull;
  ConversationSummary? get activeConversation =>
      _conversations.where((c) => c.id == _activeConversationId).firstOrNull ??
      _conversations.firstOrNull;
  List<RoomParticipant> get roomParticipants =>
      activeRoom == null ? [] : _participants.where((p) => p.roomId == activeRoom!.id).toList();
  RoomParticipant? get myParticipant =>
      _profile == null ? null : roomParticipants.where((p) => p.userId == _profile!.id).firstOrNull;
  List<RoomMessage> get messagesForRoom =>
      activeRoom == null ? [] : _roomMessages.where((m) => m.roomId == activeRoom!.id).toList();
  List<MeetingNote> get notesForRoom =>
      activeRoom == null ? [] : _meetingNotes.where((n) => n.roomId == activeRoom!.id).toList();
  List<Room> get liveRooms => _rooms.where((r) => r.isLive).toList();

  void init() {
    _session = _sb.auth.currentSession;
    _loading = false;
    if (_session != null) _onSessionReady();
    notifyListeners();
    _authSub = _sb.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      notifyListeners();
      if (_session != null) {
        _onSessionReady();
      } else {
        _profile = null;
        _realtimeChannel?.unsubscribe();
        notifyListeners();
      }
    });
  }

  void _onSessionReady() {
    final userId = _session!.user.id;
    loadAppData(userId);
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _sb
        .channel('voxora-db')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          callback: (_) => loadAppData(userId, showLoader: false),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ── Navigation ──
  void setView(AppView v) {
    _view = v;
    notifyListeners();
  }

  void selectRoom(String id) {
    _activeRoomId = id;
    notifyListeners();
  }

  void selectConversation(String id) {
    _activeConversationId = id;
    notifyListeners();
  }

  void clearNotice() {
    _notice = '';
    notifyListeners();
  }

  void _showNotice(String msg) {
    _notice = msg;
    notifyListeners();
  }

  // ── Data Loading ──
  Future<void> loadAppData(String userId, {bool showLoader = true}) async {
    if (showLoader) {
      _loading = true;
      notifyListeners();
    }

    final results = await Future.wait([
      _sb.from('profiles').select().eq('id', userId).single(),
      _sb.from('profiles').select().order('created_at', ascending: false),
      _sb.from('rooms').select().order('created_at', ascending: false),
      _sb.from('room_participants').select('*, profiles(*)'),
      _sb.from('room_messages').select('*, profiles(*)').order('created_at'),
      _sb.from('room_meeting_notes').select('*, profiles(*)').order('created_at'),
      _sb.from('game_sessions').select().order('created_at', ascending: false),
      _sb
          .from('friendships')
          .select()
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .order('created_at', ascending: false),
    ]);

    _profile = Profile.fromJson(results[0] as Map<String, dynamic>);
    _profiles = (results[1] as List).map((e) => Profile.fromJson(e)).toList();
    _rooms = (results[2] as List).map((e) => Room.fromJson(e)).toList();
    _participants = (results[3] as List).map((e) => RoomParticipant.fromJson(e)).toList();
    _roomMessages = (results[4] as List).map((e) => RoomMessage.fromJson(e)).toList();
    _meetingNotes = (results[5] as List).map((e) => MeetingNote.fromJson(e)).toList();
    _gameSessions = (results[6] as List).map((e) => GameSession.fromJson(e)).toList();
    _friendships = (results[7] as List).map((e) => Friendship.fromJson(e)).toList();

    await _loadConversations(userId);

    final invitedRoom = Uri.base.queryParameters['room'];
    if (_activeRoomId == null && invitedRoom != null && _rooms.any((r) => r.id == invitedRoom)) {
      _activeRoomId = invitedRoom;
    }
    if (_activeRoomId == null && _rooms.isNotEmpty) {
      _activeRoomId = _rooms.first.id;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadConversations(String userId) async {
    final mine = await _sb.from('conversation_members').select('conversation_id').eq('user_id', userId);
    final ids = (mine as List).map((r) => r['conversation_id'] as String).toSet().toList();
    if (ids.isEmpty) {
      _conversations = [];
      _directMessages = [];
      return;
    }

    final results = await Future.wait([
      _sb.from('conversation_members').select('conversation_id, user_id, profiles(*)').inFilter('conversation_id', ids),
      _sb.from('messages').select().inFilter('conversation_id', ids).order('created_at'),
    ]);

    final memberRows = results[0] as List;
    final allMessages = (results[1] as List).map((e) => DirectMessage.fromJson(e)).toList();
    _directMessages = allMessages;

    final summaries = <ConversationSummary>[];
    for (final id in ids) {
      final members = memberRows
          .where((r) => r['conversation_id'] == id)
          .map((r) {
            final p = r['profiles'];
            if (p is Map<String, dynamic>) return Profile.fromJson(p);
            if (p is List && p.isNotEmpty) return Profile.fromJson(p[0]);
            return null;
          })
          .whereType<Profile>()
          .toList();

      final others = members.where((m) => m.id != userId).toList();
      if (others.isEmpty) continue;

      final last = allMessages.where((m) => m.conversationId == id).lastOrNull;
      summaries.add(ConversationSummary(
        id: id,
        title: others.length == 1 ? others.first.fullName : others.map((m) => m.fullName).join(', '),
        members: members,
        other: others.first,
        lastMessage: last?.body ?? 'Conversation started',
      ));
    }

    summaries.sort((a, b) {
      final aLast = allMessages.where((m) => m.conversationId == a.id).lastOrNull?.createdAt ?? '';
      final bLast = allMessages.where((m) => m.conversationId == b.id).lastOrNull?.createdAt ?? '';
      return bLast.compareTo(aLast);
    });

    _conversations = summaries;
    if (_activeConversationId == null && summaries.isNotEmpty) {
      _activeConversationId = summaries.first.id;
    }
  }

  // ── Auth ──
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String handle,
    String bio = '',
    String interests = '',
  }) async {
    try {
      final cleanHandle = handle.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
      if (fullName.trim().length < 2) return 'Enter a display name.';
      if (cleanHandle.length < 3) return 'Choose a handle with at least 3 valid characters.';
      final res = await _sb.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'handle': cleanHandle,
          'bio': bio.trim(),
          'interests': interests,
        },
      );
      return res.user == null ? 'Sign up failed' : null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _sb.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
    _session = null;
    _profile = null;
    notifyListeners();
  }

  // ── Rooms ──
  Future<void> createRoom({
    required String title,
    String topic = 'General',
    String description = '',
    int capacity = 200,
  }) async {
    if (_profile == null) return;
    if (title.trim().isEmpty) {
      _showNotice('Add a room title first.');
      return;
    }
    final res = await _sb.from('rooms').insert({
      'title': title.trim(),
      'topic': topic.trim(),
      'description': description.trim(),
      'capacity': capacity.clamp(2, 500),
      'host_id': _profile!.id,
    }).select().single();

    _activeRoomId = res['id'];
    _view = AppView.rooms;
    _showNotice('Room is live.');
  }

  Future<void> joinRoom(Room room) async {
    if (_profile == null) return;
    if (room.isLocked || !room.isLive) {
      _showNotice('This room is not accepting new participants.');
      return;
    }
    final count = _participants.where((p) => p.roomId == room.id).length;
    if (count >= room.capacity) {
      _showNotice('This room has reached its configured size.');
      return;
    }
    await _sb.from('room_participants').upsert({
      'room_id': room.id,
      'user_id': _profile!.id,
      'role': room.hostId == _profile!.id ? 'host' : 'listener',
      'muted': room.hostId != _profile!.id,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
    _activeRoomId = room.id;
    notifyListeners();
  }

  Future<void> leaveRoom(Room room) async {
    if (_profile == null) return;
    await _sb.from('room_participants').delete().eq('room_id', room.id).eq('user_id', _profile!.id);
    if (room.hostId == _profile!.id) {
      await _sb.from('rooms').update({
        'is_live': false,
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', room.id);
    }
  }

  Future<void> sendRoomMessage(String roomId, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('room_messages').insert({
      'room_id': roomId,
      'sender_id': _profile!.id,
      'body': body.trim(),
    });
  }

  Future<void> addMeetingNote(String roomId, String noteType, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('room_meeting_notes').insert({
      'room_id': roomId,
      'author_id': _profile!.id,
      'note_type': noteType,
      'body': body.trim(),
    });
    _showNotice('Saved to the meeting room.');
  }

  Future<void> toggleMeetingNote(MeetingNote note) async {
    await _sb.from('room_meeting_notes').update({'is_done': !note.isDone}).eq('id', note.id);
  }

  // ── Messages ──
  Future<void> startConversation(Profile other) async {
    if (_profile == null || other.id == _profile!.id) return;
    final mine = await _sb.from('conversation_members').select('conversation_id').eq('user_id', _profile!.id);
    final ids = (mine as List).map((r) => r['conversation_id'] as String).toSet().toList();
    if (ids.isNotEmpty) {
      final members =
          await _sb.from('conversation_members').select('conversation_id, user_id').inFilter('conversation_id', ids);
      for (final id in ids) {
        final rows = (members as List).where((r) => r['conversation_id'] == id).toList();
        if (rows.length == 2 && rows.any((r) => r['user_id'] == other.id)) {
          _activeConversationId = id;
          _view = AppView.messages;
          notifyListeners();
          return;
        }
      }
    }
    await createConversation([other.id]);
  }

  Future<void> createConversation(List<String> memberIds, {String? firstMessage}) async {
    if (_profile == null) return;
    final clean = memberIds.where((id) => id != _profile!.id).toSet().toList();
    if (clean.isEmpty) {
      _showNotice('Choose at least one member.');
      return;
    }

    final conv = await _sb.from('conversations').insert({'created_by': _profile!.id}).select().single();
    final convId = conv['id'] as String;
    await _sb.from('conversation_members').insert([
      {'conversation_id': convId, 'user_id': _profile!.id},
      ...clean.map((id) => {'conversation_id': convId, 'user_id': id}),
    ]);

    if (firstMessage != null && firstMessage.trim().isNotEmpty) {
      await _sb.from('messages').insert({
        'conversation_id': convId,
        'sender_id': _profile!.id,
        'body': firstMessage.trim(),
      });
    }

    await _loadConversations(_profile!.id);
    _activeConversationId = convId;
    _view = AppView.messages;
    notifyListeners();
  }

  Future<void> sendDirectMessage(String conversationId, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _profile!.id,
      'body': body.trim(),
    });
  }

  // ── Friends ──
  Future<void> requestFriend(Profile person) async {
    if (_profile == null || person.id == _profile!.id) return;
    final existing = findFriendship(person.id);
    if (existing?.status == 'accepted') {
      _showNotice('You are already friends.');
      return;
    }
    if (existing?.status == 'pending') {
      _showNotice('Friend request is already pending.');
      return;
    }
    await _sb.from('friendships').insert({
      'requester_id': _profile!.id,
      'addressee_id': person.id,
      'status': 'pending',
    });
    _showNotice('Friend request sent.');
  }

  Future<void> acceptFriend(Friendship friendship) async {
    await _sb.from('friendships').update({'status': 'accepted'}).eq('id', friendship.id);
    _showNotice('Friend added.');
  }

  Friendship? findFriendship(String otherId) {
    if (_profile == null) return null;
    return _friendships.where((f) =>
        (f.requesterId == _profile!.id && f.addresseeId == otherId) ||
        (f.requesterId == otherId && f.addresseeId == _profile!.id)).firstOrNull;
  }

  // ── Profile ──
  Future<void> updateProfile({
    required String fullName,
    required String handle,
    required String bio,
    required List<String> interests,
  }) async {
    if (_profile == null) return;
    final cleanHandle = handle.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    if (fullName.trim().length < 2) {
      _showNotice('Enter a display name.');
      return;
    }
    if (cleanHandle.length < 3) {
      _showNotice('Choose a handle with at least 3 valid characters.');
      return;
    }
    try {
      await _sb.from('profiles').update({
        'full_name': fullName.trim(),
        'handle': cleanHandle,
        'bio': bio.trim(),
        'interests': interests.where((i) => i.isNotEmpty).take(8).toList(),
      }).eq('id', _profile!.id);
      _showNotice('Profile updated.');
    } catch (e) {
      _showNotice(e.toString());
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    if (_profile == null) return;
    final ext = filename.split('.').last;
    final path = '${_profile!.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _sb.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    final url = _sb.storage.from('avatars').getPublicUrl(path);
    await _sb.from('profiles').update({'avatar_url': url}).eq('id', _profile!.id);
  }

  Future<void> uploadCover(Uint8List bytes, String filename) async {
    if (_profile == null) return;
    final ext = filename.split('.').last;
    final path = '${_profile!.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _sb.storage.from('covers').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    final url = _sb.storage.from('covers').getPublicUrl(path);
    await _sb.from('profiles').update({'cover_url': url}).eq('id', _profile!.id);
  }

  // ── Games ──
  Future<void> createGame(String roomId, String gameType) async {
    if (_profile == null) return;
    final res = await _sb.from('game_sessions').insert({
      'room_id': roomId,
      'host_id': _profile!.id,
      'game_type': gameType,
      'title': _gameTitle(gameType),
      'players': {},
      'state': _initialGameState(gameType),
    }).select().single();
    final game = GameSession.fromJson(res);
    await joinGame(game);
    _view = AppView.games;
    notifyListeners();
  }

  Future<void> joinGame(GameSession game) async {
    if (_profile == null) return;
    final players = Map<String, dynamic>.from(game.players);
    if (game.gameType == 'chess') {
      if (players['white'] == null) {
        players['white'] = _profile!.id;
      } else if (players['black'] == null && players['white'] != _profile!.id) {
        players['black'] = _profile!.id;
      }
    } else if (game.gameType == 'ludo') {
      final freeColor = ludoColorNames.firstWhere((c) => players[c] == null, orElse: () => '');
      if (freeColor.isNotEmpty && !players.values.contains(_profile!.id)) {
        players[freeColor] = _profile!.id;
      }
    } else if (game.gameType == 'cards') {
      final order = (players['order'] as List<dynamic>?)?.cast<String>() ?? [];
      if (!order.contains(_profile!.id)) {
        players['order'] = [...order, _profile!.id];
      }
    }
    await _sb.from('game_sessions').update({'players': players}).eq('id', game.id);
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> patch) async {
    await _sb.from('game_sessions').update(patch).eq('id', gameId);
  }

  // ── Admin ──
  Future<void> toggleBlockUser(Profile user) async {
    await _sb.from('profiles').update({'is_blocked': !user.isBlocked}).eq('id', user.id);
    _showNotice('User status updated.');
  }

  Future<void> endRoom(Room room) async {
    await _sb.from('rooms').update({
      'is_live': false,
      'is_locked': true,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', room.id);
  }

  // ── Helpers ──
  String profileName(dynamic id) {
    if (id is! String || id.isEmpty) return 'Open seat';
    return _profiles.firstWhere((p) => p.id == id, orElse: () => Profile(id: '', fullName: 'Member', handle: '', createdAt: '')).fullName;
  }

  String _gameTitle(String type) => {'chess': 'Chess', 'ludo': 'Ludo', 'cards': 'Cards'}[type] ?? type;

  Map<String, dynamic> _initialGameState(String type) {
    if (type == 'chess') {
      return {'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', 'moves': []};
    }
    if (type == 'ludo') {
      return {
        'turn': 'red',
        'dice': null,
        'tokens': {
          'red': [0, 0, 0, 0],
          'blue': [0, 0, 0, 0],
          'green': [0, 0, 0, 0],
          'yellow': [0, 0, 0, 0],
        },
      };
    }
    return {
      'deck': _shuffled(_makeDeck()),
      'hands': {},
      'table': {},
      'scores': {},
      'round': 1,
    };
  }

  List<String> _makeDeck() => [
        for (final s in cardSuits)
          for (final r in cardRanks) '$r$s'
      ];

  List<String> _shuffled(List<String> items) {
    final copy = [...items];
    copy.shuffle();
    return copy;
  }
}
