import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/models.dart';

enum AppView { rooms, messages, people, games, profile, admin }

class AppProvider extends ChangeNotifier {
  static const _profileColumns =
      'id, full_name, handle, avatar_url, cover_url, bio, interests, level, is_admin, created_at, updated_at';
  static const _profileFetchLimit = 200;
  static const _adminProfileFetchLimit = 500;
  static const _roomFetchLimit = 120;
  static const _participantFetchLimit = 1000;
  static const _roomMessageFetchLimit = 250;
  static const _meetingNoteFetchLimit = 120;
  static const _gameSessionFetchLimit = 80;
  static const _friendshipFetchLimit = 500;
  static const _conversationFetchLimit = 80;
  static const _directMessageFetchLimit = 300;
  static const _realtimeRefreshDelay = Duration(seconds: 2);
  static const _loadTimeout = Duration(seconds: 8);

  final SupabaseClient _sb = Supabase.instance.client;
  final Random _rng = Random();

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
  String _dataError = '';
  String get dataError => _dataError;

  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _appRealtimeChannel;
  RealtimeChannel? _scopedRealtimeChannel;
  Timer? _realtimeRefreshTimer;
  Timer? _postWriteRefreshTimer;
  int _loadGeneration = 0;
  int _loadFailureCount = 0;
  DateTime? _loadPausedUntil;
  String? _scopedRealtimeUserId;
  String? _scopedRealtimeRoomId;
  String? _scopedRealtimeConversationId;

  // Derived
  Room? get activeRoom =>
      _rooms.where((r) => r.id == _activeRoomId).firstOrNull ??
      _rooms.firstOrNull;
  ConversationSummary? get activeConversation =>
      _conversations.where((c) => c.id == _activeConversationId).firstOrNull ??
      _conversations.firstOrNull;
  List<RoomParticipant> get roomParticipants => activeRoom == null
      ? []
      : _participants.where((p) => p.roomId == activeRoom!.id).toList();
  RoomParticipant? get myParticipant => _profile == null
      ? null
      : roomParticipants.where((p) => p.userId == _profile!.id).firstOrNull;
  List<RoomMessage> get messagesForRoom => activeRoom == null
      ? []
      : _roomMessages.where((m) => m.roomId == activeRoom!.id).toList();
  List<MeetingNote> get notesForRoom => activeRoom == null
      ? []
      : _meetingNotes.where((n) => n.roomId == activeRoom!.id).toList();
  List<Room> get liveRooms => _rooms.where((r) => r.isLive).toList();

  void init() {
    _session = _sb.auth.currentSession;
    _loading = _session != null;
    if (_session != null) {
      _onSessionReady();
    }
    notifyListeners();
    _authSub = _sb.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      if (_session != null) {
        _loading = true;
        notifyListeners();
        _onSessionReady();
      } else {
        _clearSessionData();
        _loading = false;
        _realtimeRefreshTimer?.cancel();
        _postWriteRefreshTimer?.cancel();
        _unsubscribeRealtimeChannels();
        notifyListeners();
      }
    });
  }

  void _onSessionReady() {
    final userId = _session!.user.id;
    unawaited(loadAppData(userId));
    _realtimeRefreshTimer?.cancel();
    _postWriteRefreshTimer?.cancel();
    _unsubscribeRealtimeChannels();
    _appRealtimeChannel = _sb
        .channel('voxora-app-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requester_id',
            value: userId,
          ),
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'addressee_id',
            value: userId,
          ),
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _realtimeRefreshTimer?.cancel();
    _postWriteRefreshTimer?.cancel();
    _unsubscribeRealtimeChannels();
    super.dispose();
  }

  // ── Navigation ──
  void setView(AppView v) {
    if (v == AppView.admin && !(_profile?.isAdmin ?? false)) {
      _showNotice('Admin access is required for that area.');
      return;
    }
    _view = v;
    notifyListeners();
  }

  void selectRoom(String id) {
    _activeRoomId = id;
    _resubscribeScopedRealtime();
    notifyListeners();
  }

  void selectConversation(String id) {
    _activeConversationId = id;
    _resubscribeScopedRealtime();
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

  void _clearSessionData() {
    _profile = null;
    _profiles = [];
    _rooms = [];
    _participants = [];
    _roomMessages = [];
    _meetingNotes = [];
    _gameSessions = [];
    _friendships = [];
    _conversations = [];
    _directMessages = [];
    _activeRoomId = null;
    _activeConversationId = null;
    _notice = '';
    _dataError = '';
    _loadFailureCount = 0;
    _loadPausedUntil = null;
    _scopedRealtimeUserId = null;
    _scopedRealtimeRoomId = null;
    _scopedRealtimeConversationId = null;
  }

  void _unsubscribeRealtimeChannels() {
    unawaited(_appRealtimeChannel?.unsubscribe() ?? Future<void>.value());
    unawaited(_scopedRealtimeChannel?.unsubscribe() ?? Future<void>.value());
    _appRealtimeChannel = null;
    _scopedRealtimeChannel = null;
    _scopedRealtimeUserId = null;
    _scopedRealtimeRoomId = null;
    _scopedRealtimeConversationId = null;
  }

  void _resubscribeScopedRealtime([String? userId]) {
    final currentUserId = userId ?? _session?.user.id;
    if (currentUserId == null) {
      return;
    }

    final roomId = _activeRoomId;
    final conversationId = _activeConversationId;
    if (_scopedRealtimeUserId == currentUserId &&
        _scopedRealtimeRoomId == roomId &&
        _scopedRealtimeConversationId == conversationId) {
      return;
    }

    unawaited(_scopedRealtimeChannel?.unsubscribe() ?? Future<void>.value());
    _scopedRealtimeChannel = null;
    _scopedRealtimeUserId = currentUserId;
    _scopedRealtimeRoomId = roomId;
    _scopedRealtimeConversationId = conversationId;

    if (roomId == null && conversationId == null) {
      return;
    }

    var channel = _sb.channel(
      'voxora-scope-$currentUserId-${roomId ?? 'no-room'}-${conversationId ?? 'no-conversation'}',
    );

    if (roomId != null) {
      final roomFilter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      );
      channel = channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'room_participants',
            filter: roomFilter,
            callback: (_) => _scheduleRealtimeRefresh(currentUserId),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'room_messages',
            filter: roomFilter,
            callback: (_) => _scheduleRealtimeRefresh(currentUserId),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'room_meeting_notes',
            filter: roomFilter,
            callback: (_) => _scheduleRealtimeRefresh(currentUserId),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'game_sessions',
            filter: roomFilter,
            callback: (_) => _scheduleRealtimeRefresh(currentUserId),
          );
    }

    if (conversationId != null) {
      final conversationFilter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      );
      channel = channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversation_members',
            filter: conversationFilter,
            callback: (_) => _scheduleRealtimeRefresh(currentUserId),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: conversationFilter,
            callback: (_) => _scheduleRealtimeRefresh(currentUserId),
          );
    }

    _scopedRealtimeChannel = channel.subscribe();
  }

  void _scheduleRealtimeRefresh(String userId) {
    if (_session?.user.id != userId) {
      return;
    }
    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(_realtimeRefreshDelay, () {
      unawaited(loadAppData(userId, showLoader: false));
    });
  }

  void _schedulePostWriteRefresh() {
    final userId = _profile?.id ?? _session?.user.id;
    if (userId == null) {
      return;
    }
    _postWriteRefreshTimer?.cancel();
    _postWriteRefreshTimer = Timer(const Duration(milliseconds: 700), () {
      unawaited(loadAppData(userId, showLoader: false));
    });
  }

  bool _loadIsPaused() {
    final pausedUntil = _loadPausedUntil;
    return pausedUntil != null && DateTime.now().isBefore(pausedUntil);
  }

  void _recordLoadSuccess() {
    _loadFailureCount = 0;
    _loadPausedUntil = null;
  }

  void _recordLoadFailure() {
    _loadFailureCount += 1;
    if (_loadFailureCount < 2) {
      return;
    }

    final seconds = min(60, 5 * (1 << min(_loadFailureCount - 2, 4)));
    _loadPausedUntil = DateTime.now().add(Duration(seconds: seconds));
  }

  // ── Data Loading ──
  Future<void> loadAppData(String userId, {bool showLoader = true}) async {
    if (!showLoader && _loadIsPaused()) {
      return;
    }

    final generation = ++_loadGeneration;
    if (showLoader) {
      _loading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait<dynamic>([
        _fetchProfileWithRetry(userId),
        _sb
            .from('profiles')
            .select(_profileColumns)
            .order('created_at', ascending: false)
            .limit(_profileFetchLimit),
        _sb
            .from('rooms')
            .select()
            .order('created_at', ascending: false)
            .limit(_roomFetchLimit),
        _sb
            .from('room_participants')
            .select('*, profiles($_profileColumns)')
            .order('joined_at', ascending: false)
            .limit(_participantFetchLimit),
        _sb
            .from('room_messages')
            .select('*, profiles($_profileColumns)')
            .order('created_at', ascending: false)
            .limit(_roomMessageFetchLimit),
        _sb
            .from('room_meeting_notes')
            .select('*, profiles($_profileColumns)')
            .order('created_at', ascending: false)
            .limit(_meetingNoteFetchLimit),
        _sb
            .from('game_sessions')
            .select()
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(_gameSessionFetchLimit),
        _sb
            .from('friendships')
            .select()
            .or('requester_id.eq.$userId,addressee_id.eq.$userId')
            .order('created_at', ascending: false)
            .limit(_friendshipFetchLimit),
      ]).timeout(_loadTimeout);

      if (generation != _loadGeneration || _session?.user.id != userId) {
        return;
      }

      final myProfileJson = Map<String, dynamic>.from(
        results[0] as Map<String, dynamic>,
      );
      myProfileJson['email'] ??= _session?.user.email;
      _profile = Profile.fromJson(myProfileJson);
      _profiles = (results[1] as List).map((e) => Profile.fromJson(e)).toList();
      if (_profile?.isAdmin ?? false) {
        final adminRows = await _sb
            .rpc(
              'admin_list_profiles',
              params: {'result_limit': _adminProfileFetchLimit},
            )
            .timeout(_loadTimeout);
        if (generation != _loadGeneration || _session?.user.id != userId) {
          return;
        }
        _profiles = (adminRows as List)
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _rooms = (results[2] as List).map((e) => Room.fromJson(e)).toList();
      _participants = (results[3] as List)
          .map((e) => RoomParticipant.fromJson(e))
          .toList();
      _roomMessages = (results[4] as List)
          .map((e) => RoomMessage.fromJson(e))
          .toList()
          .reversed
          .toList();
      _meetingNotes = (results[5] as List)
          .map((e) => MeetingNote.fromJson(e))
          .toList()
          .reversed
          .toList();
      _gameSessions = (results[6] as List)
          .map((e) => GameSession.fromJson(e))
          .toList();
      _friendships = (results[7] as List)
          .map((e) => Friendship.fromJson(e))
          .toList();

      await _loadConversations(userId);

      final invitedRoom = Uri.base.queryParameters['room'];
      if (_activeRoomId != null &&
          !_rooms.any((r) => r.id == _activeRoomId && r.isLive)) {
        _activeRoomId = null;
      }
      if (_activeConversationId != null &&
          !_conversations.any((c) => c.id == _activeConversationId)) {
        _activeConversationId = null;
      }
      if (_activeRoomId == null &&
          invitedRoom != null &&
          _rooms.any((r) => r.id == invitedRoom)) {
        _activeRoomId = invitedRoom;
      }
      if (_activeRoomId == null && _rooms.isNotEmpty) {
        _activeRoomId = _rooms.first.id;
      }
      if (_activeConversationId == null && _conversations.isNotEmpty) {
        _activeConversationId = _conversations.first.id;
      }
      _resubscribeScopedRealtime(userId);
      _dataError = '';
      _recordLoadSuccess();
    } catch (error) {
      if (generation == _loadGeneration) {
        _recordLoadFailure();
        _dataError = 'Unable to load app data: ${_friendlyError(error)}';
        _notice = _dataError;
      }
    } finally {
      if (generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> _fetchProfileWithRetry(String userId) async {
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt += 1) {
      try {
        return await _sb
            .from('profiles')
            .select(_profileColumns)
            .eq('id', userId)
            .single();
      } catch (error) {
        lastError = error;
        await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('Profile was not created.');
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'Request timed out. The app is temporarily slowing refreshes.';
    }
    if (error is PostgrestException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _refresh({bool showLoader = false}) async {
    final userId = _profile?.id ?? _session?.user.id;
    if (userId == null) return;
    await loadAppData(userId, showLoader: showLoader);
  }

  Future<void> _loadConversations(String userId) async {
    final mine = await _sb
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', userId)
        .order('joined_at', ascending: false)
        .limit(_conversationFetchLimit);
    final ids = (mine as List)
        .map((r) => r['conversation_id'] as String)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      _conversations = [];
      _directMessages = [];
      return;
    }

    final results = await Future.wait([
      _sb
          .from('conversation_members')
          .select('conversation_id, user_id, profiles($_profileColumns)')
          .inFilter('conversation_id', ids),
      _sb
          .from('messages')
          .select()
          .inFilter('conversation_id', ids)
          .order('created_at', ascending: false)
          .limit(_directMessageFetchLimit),
    ]).timeout(_loadTimeout);

    final memberRows = results[0] as List;
    final allMessages = (results[1] as List)
        .map((e) => DirectMessage.fromJson(e))
        .toList()
        .reversed
        .toList();
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
      summaries.add(
        ConversationSummary(
          id: id,
          title: others.length == 1
              ? others.first.fullName
              : others.map((m) => m.fullName).join(', '),
          members: members,
          other: others.first,
          lastMessage: last?.body ?? 'Conversation started',
        ),
      );
    }

    summaries.sort((a, b) {
      final aLast =
          allMessages
              .where((m) => m.conversationId == a.id)
              .lastOrNull
              ?.createdAt ??
          '';
      final bLast =
          allMessages
              .where((m) => m.conversationId == b.id)
              .lastOrNull
              ?.createdAt ??
          '';
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
      final cleanHandle = handle.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9._-]'),
        '',
      );
      if (fullName.trim().length < 2) {
        return 'Enter a display name.';
      }
      if (cleanHandle.length < 3) {
        return 'Choose a handle with at least 3 valid characters.';
      }
      final res = await _sb.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'handle': cleanHandle,
          'bio': bio.trim(),
          'interests': interests
              .split(',')
              .map((interest) => interest.trim())
              .where((interest) => interest.isNotEmpty)
              .take(8)
              .join(','),
        },
      );
      return res.user == null ? 'Sign up failed' : null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _sb.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    try {
      await _sb.auth.signOut();
    } finally {
      _session = null;
      _loading = false;
      _loadGeneration += 1;
      _clearSessionData();
      _realtimeRefreshTimer?.cancel();
      _postWriteRefreshTimer?.cancel();
      await _appRealtimeChannel?.unsubscribe();
      await _scopedRealtimeChannel?.unsubscribe();
      _appRealtimeChannel = null;
      _scopedRealtimeChannel = null;
      notifyListeners();
    }
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
    final res = await _sb
        .from('rooms')
        .insert({
          'title': title.trim(),
          'topic': topic.trim(),
          'description': description.trim(),
          'capacity': capacity.clamp(2, 500),
          'host_id': _profile!.id,
        })
        .select()
        .single();

    _activeRoomId = res['id'];
    _view = AppView.rooms;
    await _refresh();
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
    await _refresh();
    notifyListeners();
  }

  Future<void> leaveRoom(Room room) async {
    if (_profile == null) return;
    await _sb
        .from('room_participants')
        .delete()
        .eq('room_id', room.id)
        .eq('user_id', _profile!.id);
    if (room.hostId == _profile!.id) {
      await _sb
          .from('rooms')
          .update({
            'is_live': false,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', room.id);
    }
    await _refresh();
  }

  Future<void> sendRoomMessage(String roomId, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('room_messages').insert({
      'room_id': roomId,
      'sender_id': _profile!.id,
      'body': body.trim(),
    });
    _schedulePostWriteRefresh();
  }

  Future<void> addMeetingNote(
    String roomId,
    String noteType,
    String body,
  ) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('room_meeting_notes').insert({
      'room_id': roomId,
      'author_id': _profile!.id,
      'note_type': noteType,
      'body': body.trim(),
    });
    _schedulePostWriteRefresh();
    _showNotice('Saved to the meeting room.');
  }

  Future<void> toggleMeetingNote(MeetingNote note) async {
    await _sb
        .from('room_meeting_notes')
        .update({'is_done': !note.isDone})
        .eq('id', note.id);
    _schedulePostWriteRefresh();
  }

  // ── Messages ──
  Future<void> startConversation(Profile other) async {
    if (_profile == null || other.id == _profile!.id) return;
    final mine = await _sb
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', _profile!.id)
        .order('joined_at', ascending: false)
        .limit(_conversationFetchLimit)
        .timeout(_loadTimeout);
    final ids = (mine as List)
        .map((r) => r['conversation_id'] as String)
        .toSet()
        .toList();
    if (ids.isNotEmpty) {
      final members = await _sb
          .from('conversation_members')
          .select('conversation_id, user_id')
          .inFilter('conversation_id', ids);
      for (final id in ids) {
        final rows = (members as List)
            .where((r) => r['conversation_id'] == id)
            .toList();
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

  Future<void> createConversation(
    List<String> memberIds, {
    String? firstMessage,
  }) async {
    if (_profile == null) return;
    final clean = memberIds.where((id) => id != _profile!.id).toSet().toList();
    if (clean.isEmpty) {
      _showNotice('Choose at least one member.');
      return;
    }

    final conv = await _sb
        .from('conversations')
        .insert({'created_by': _profile!.id})
        .select()
        .single();
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
    await _refresh();
    notifyListeners();
  }

  Future<void> sendDirectMessage(String conversationId, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _profile!.id,
      'body': body.trim(),
    });
    _schedulePostWriteRefresh();
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
    await _refresh();
    _showNotice('Friend request sent.');
  }

  Future<void> acceptFriend(Friendship friendship) async {
    await _sb
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendship.id);
    await _refresh();
    _showNotice('Friend added.');
  }

  Friendship? findFriendship(String otherId) {
    if (_profile == null) return null;
    return _friendships
        .where(
          (f) =>
              (f.requesterId == _profile!.id && f.addresseeId == otherId) ||
              (f.requesterId == otherId && f.addresseeId == _profile!.id),
        )
        .firstOrNull;
  }

  // ── Profile ──
  Future<void> updateProfile({
    required String fullName,
    required String handle,
    required String bio,
    required List<String> interests,
  }) async {
    if (_profile == null) return;
    final cleanHandle = handle.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '',
    );
    if (fullName.trim().length < 2) {
      _showNotice('Enter a display name.');
      return;
    }
    if (cleanHandle.length < 3) {
      _showNotice('Choose a handle with at least 3 valid characters.');
      return;
    }
    try {
      await _sb
          .from('profiles')
          .update({
            'full_name': fullName.trim(),
            'handle': cleanHandle,
            'bio': bio.trim(),
            'interests': interests.where((i) => i.isNotEmpty).take(8).toList(),
          })
          .eq('id', _profile!.id);
      await _refresh();
      _showNotice('Profile updated.');
    } catch (e) {
      _showNotice(e.toString());
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    if (_profile == null) return;
    final contentType = _imageContentType(filename);
    if (contentType == null) {
      _showNotice('Use a PNG, JPG, or WebP image.');
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      _showNotice('Avatar images must be 5 MB or smaller.');
      return;
    }
    final ext = _safeImageExtension(filename);
    final path =
        '${_profile!.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _sb.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
            cacheControl: '31536000',
          ),
        );
    final url = _sb.storage.from('avatars').getPublicUrl(path);
    await _sb
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', _profile!.id);
    await _refresh();
  }

  Future<void> uploadCover(Uint8List bytes, String filename) async {
    if (_profile == null) return;
    final contentType = _imageContentType(filename);
    if (contentType == null) {
      _showNotice('Use a PNG, JPG, or WebP image.');
      return;
    }
    if (bytes.length > 8 * 1024 * 1024) {
      _showNotice('Cover images must be 8 MB or smaller.');
      return;
    }
    final ext = _safeImageExtension(filename);
    final path =
        '${_profile!.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _sb.storage
        .from('covers')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
            cacheControl: '31536000',
          ),
        );
    final url = _sb.storage.from('covers').getPublicUrl(path);
    await _sb
        .from('profiles')
        .update({'cover_url': url})
        .eq('id', _profile!.id);
    await _refresh();
  }

  // ── Games ──
  Future<void> createGame(String roomId, String gameType) async {
    if (_profile == null) return;
    final res = await _sb
        .from('game_sessions')
        .insert({
          'room_id': roomId,
          'host_id': _profile!.id,
          'game_type': gameType,
          'title': _gameTitle(gameType),
          'players': {},
          'state': _initialGameState(gameType),
        })
        .select()
        .single();
    final game = GameSession.fromJson(res);
    await joinGame(game);
    _view = AppView.games;
    await _refresh();
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
      final freeColor = ludoColorNames.firstWhere(
        (c) => players[c] == null,
        orElse: () => '',
      );
      if (freeColor.isNotEmpty && !players.values.contains(_profile!.id)) {
        players[freeColor] = _profile!.id;
      }
    } else if (game.gameType == 'cards') {
      final order = (players['order'] as List<dynamic>?)?.cast<String>() ?? [];
      if (!order.contains(_profile!.id)) {
        players['order'] = [...order, _profile!.id];
      }
    }
    await _sb
        .from('game_sessions')
        .update({'players': players})
        .eq('id', game.id);
    _schedulePostWriteRefresh();
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> patch) async {
    await _sb.from('game_sessions').update(patch).eq('id', gameId);
    _schedulePostWriteRefresh();
  }

  Future<void> rollLudoDice(GameSession game) async {
    if (_profile == null || game.gameType != 'ludo') return;
    final players = Map<String, dynamic>.from(game.players);
    final state = Map<String, dynamic>.from(game.state);
    final turn = state['turn'] as String? ?? 'red';
    final myColor = ludoColorNames.firstWhere(
      (color) => players[color] == _profile!.id,
      orElse: () => '',
    );

    if (myColor.isEmpty) {
      _showNotice('Join this Ludo game before rolling.');
      return;
    }
    if (myColor != turn) {
      _showNotice('Wait for your turn.');
      return;
    }
    if (state['winner'] != null || state['dice'] != null) {
      return;
    }

    final dice = _rng.nextInt(6) + 1;
    final allTokens = _ludoTokens(state);
    final colorTokens = allTokens[turn] ?? _emptyLudoTokens();

    state['dice'] = dice;
    if (!_hasLegalLudoMove(colorTokens, dice)) {
      state['dice'] = null;
      state['turn'] = _nextActiveLudoColor(turn, players);
      _showNotice('$turn rolled $dice with no legal move. Turn skipped.');
    }

    await updateGame(game.id, {'state': state});
  }

  Future<void> moveLudoToken(
    GameSession game,
    String color,
    int tokenIndex,
  ) async {
    if (_profile == null || game.gameType != 'ludo') return;
    final players = Map<String, dynamic>.from(game.players);
    final state = Map<String, dynamic>.from(game.state);
    final turn = state['turn'] as String? ?? 'red';
    final dice = state['dice'] as int?;
    final myColor = ludoColorNames.firstWhere(
      (lane) => players[lane] == _profile!.id,
      orElse: () => '',
    );

    if (myColor != color ||
        color != turn ||
        dice == null ||
        state['winner'] != null) {
      return;
    }

    final allTokens = _ludoTokens(state);
    final colorTokens = List<int>.from(allTokens[color] ?? _emptyLudoTokens());
    if (tokenIndex < 0 ||
        tokenIndex >= colorTokens.length ||
        !_isLegalLudoMove(colorTokens[tokenIndex], dice)) {
      _showNotice('That token cannot move with this roll.');
      return;
    }

    colorTokens[tokenIndex] += dice;
    allTokens[color] = colorTokens;
    state['tokens'] = allTokens;
    state['dice'] = null;

    if (colorTokens.every((position) => position == 56)) {
      state['winner'] = color;
      await updateGame(game.id, {'state': state, 'is_active': false});
      return;
    }

    state['turn'] = _nextActiveLudoColor(turn, players);
    await updateGame(game.id, {'state': state});
  }

  // ── Admin ──
  Future<void> toggleBlockUser(Profile user) async {
    await _sb.rpc(
      'admin_set_user_blocked',
      params: {'target_user_id': user.id, 'blocked': !user.isBlocked},
    );
    await _refresh();
    _showNotice('User status updated.');
  }

  Future<void> endRoom(Room room) async {
    await _sb
        .from('rooms')
        .update({
          'is_live': false,
          'is_locked': true,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', room.id);
    await _refresh();
  }

  // ── Helpers ──
  String profileName(dynamic id) {
    if (id is! String || id.isEmpty) return 'Open seat';
    return _profiles
        .firstWhere(
          (p) => p.id == id,
          orElse: () =>
              Profile(id: '', fullName: 'Member', handle: '', createdAt: ''),
        )
        .fullName;
  }

  String _gameTitle(String type) =>
      {'chess': 'Chess', 'ludo': 'Ludo', 'cards': 'Cards'}[type] ?? type;

  Map<String, dynamic> _initialGameState(String type) {
    if (type == 'chess') {
      return {
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'moves': [],
      };
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
      for (final r in cardRanks) '$r$s',
  ];

  List<String> _shuffled(List<String> items) {
    final copy = [...items];
    copy.shuffle();
    return copy;
  }

  Map<String, List<int>> _ludoTokens(Map<String, dynamic> state) {
    final raw = state['tokens'] as Map<String, dynamic>? ?? {};
    return {
      for (final color in ludoColorNames)
        color:
            (raw[color] as List?)
                ?.map((value) => (value as num).toInt())
                .toList() ??
            _emptyLudoTokens(),
    };
  }

  List<int> _emptyLudoTokens() => [0, 0, 0, 0];

  bool _hasLegalLudoMove(List<int> tokens, int dice) {
    return tokens.any((position) => _isLegalLudoMove(position, dice));
  }

  bool _isLegalLudoMove(int position, int dice) {
    if (position >= 56) return false;
    if (position == 0 && dice != 6) return false;
    return position + dice <= 56;
  }

  String _nextActiveLudoColor(String current, Map<String, dynamic> players) {
    final order = ludoColorNames
        .where((color) => players[color] != null)
        .toList();
    final lanes = order.isEmpty ? ludoColorNames : order;
    final index = lanes.indexOf(current);
    if (index == -1) return lanes.first;
    return lanes[(index + 1) % lanes.length];
  }

  String? _imageContentType(String filename) {
    final ext = _safeImageExtension(filename);
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  String _safeImageExtension(String filename) {
    final ext = filename.split('.').last.trim().toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }
}
