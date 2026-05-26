import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/models.dart';

enum AppView { feed, friends, messages, games, profile }

class AppProvider extends ChangeNotifier {
  static const _profileColumns =
      'id, email, full_name, handle, avatar_url, cover_url, bio, interests, status, created_at, updated_at';

  final SupabaseClient _sb = Supabase.instance.client;
  final Random _rng = Random();

  Session? _session;
  Profile? _profile;
  List<Profile> _profiles = [];
  List<Friendship> _friendships = [];
  List<ConversationSummary> _conversations = [];
  List<DirectMessage> _messages = [];
  List<SocialPost> _posts = [];
  List<PostComment> _comments = [];
  List<PostLike> _likes = [];
  List<PostShare> _shares = [];
  List<GameSession> _gameSessions = [];
  List<GamePlayer> _gamePlayers = [];
  List<GameInvite> _gameInvites = [];
  List<CallSession> _callSessions = [];

  AppView _view = AppView.feed;
  bool _loading = true;
  bool _darkMode = true;
  String _notice = '';
  String _dataError = '';
  String? _activeConversationId;
  String? _activeGameId;
  String? _viewedProfileId;
  String? _activeCallId;

  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshTimer;
  int _loadGeneration = 0;

  Session? get session => _session;
  Profile? get profile => _profile;
  List<Profile> get profiles => _profiles;
  List<Friendship> get friendships => _friendships;
  List<ConversationSummary> get conversations => _conversations;
  List<DirectMessage> get messages => _messages;
  List<SocialPost> get posts => _posts;
  List<PostComment> get comments => _comments;
  List<PostLike> get likes => _likes;
  List<PostShare> get shares => _shares;
  List<GameSession> get gameSessions => _gameSessions;
  List<GamePlayer> get gamePlayers => _gamePlayers;
  List<GameInvite> get gameInvites => _gameInvites;
  List<CallSession> get callSessions => _callSessions;
  AppView get view => _view;
  bool get loading => _loading;
  bool get darkMode => _darkMode;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;
  String get notice => _notice;
  String get dataError => _dataError;
  String? get activeCallId => _activeCallId;

  ConversationSummary? get activeConversation =>
      _conversations
          .where((item) => item.conversation.id == _activeConversationId)
          .firstOrNull ??
      _conversations.firstOrNull;

  List<DirectMessage> get messagesForActiveConversation {
    final id = activeConversation?.conversation.id;
    if (id == null) return const [];
    return _messages.where((message) => message.conversationId == id).toList();
  }

  GameSession? get activeGame =>
      _gameSessions.where((game) => game.id == _activeGameId).firstOrNull ??
      _gameSessions.firstOrNull;

  Profile? get viewedProfile =>
      _profiles
          .where((person) => person.id == (_viewedProfileId ?? _profile?.id))
          .firstOrNull ??
      _profile;

  List<Profile> get friends {
    final myId = _profile?.id;
    if (myId == null) return const [];
    final ids = _friendships
        .where((friendship) => friendship.status == 'accepted')
        .map(
          (friendship) => friendship.requesterId == myId
              ? friendship.addresseeId
              : friendship.requesterId,
        )
        .toSet();
    return _profiles.where((profile) => ids.contains(profile.id)).toList();
  }

  List<Friendship> get incomingRequests {
    final myId = _profile?.id;
    if (myId == null) return const [];
    return _friendships
        .where((item) => item.status == 'pending' && item.addresseeId == myId)
        .toList();
  }

  List<CallSession> get liveCalls => _callSessions
      .where((call) => call.status != 'ended' && call.status != 'missed')
      .toList();

  void init() {
    _session = _sb.auth.currentSession;
    if (_session == null) {
      _loading = false;
    } else {
      unawaited(loadAppData(_session!.user.id));
      _subscribeRealtime(_session!.user.id);
    }
    _authSub = _sb.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      if (_session == null) {
        _clearSession();
        _loading = false;
        _unsubscribeRealtime();
        notifyListeners();
      } else {
        _loading = true;
        notifyListeners();
        unawaited(loadAppData(_session!.user.id));
        _subscribeRealtime(_session!.user.id);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _refreshTimer?.cancel();
    _unsubscribeRealtime();
    super.dispose();
  }

  void setView(AppView view) {
    _view = view;
    notifyListeners();
  }

  void toggleTheme() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void clearNotice() {
    _notice = '';
    notifyListeners();
  }

  void viewProfile(String userId) {
    _viewedProfileId = userId;
    _view = AppView.profile;
    notifyListeners();
  }

  void selectConversation(String id) {
    _activeConversationId = id;
    _view = AppView.messages;
    notifyListeners();
  }

  void selectGame(String id) {
    _activeGameId = id;
    _view = AppView.games;
    notifyListeners();
  }

  void _showNotice(String message) {
    _notice = message;
    notifyListeners();
  }

  Future<void> loadAppData(String userId, {bool showLoader = true}) async {
    final generation = ++_loadGeneration;
    if (showLoader) {
      _loading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait<dynamic>([
        _fetchOrCreateProfile(userId),
        _sb
            .from('profiles')
            .select(_profileColumns)
            .order('created_at')
            .limit(300),
        _sb
            .from('friendships')
            .select()
            .or('requester_id.eq.$userId,addressee_id.eq.$userId')
            .order('created_at', ascending: false)
            .limit(500),
        _sb
            .from('posts')
            .select()
            .order('created_at', ascending: false)
            .limit(200),
        _sb.from('post_comments').select().order('created_at').limit(800),
        _sb.from('post_likes').select().limit(2000),
        _sb.from('post_shares').select().limit(1000),
        _sb
            .from('game_sessions')
            .select()
            .order('created_at', ascending: false)
            .limit(100),
        _sb.from('game_players').select().limit(400),
        _sb
            .from('game_invites')
            .select()
            .or('invited_by.eq.$userId,invited_user_id.eq.$userId')
            .order('created_at', ascending: false)
            .limit(200),
      ]).timeout(const Duration(seconds: 12));

      if (generation != _loadGeneration) return;

      final mine = Map<String, dynamic>.from(
        results[0] as Map<String, dynamic>,
      );
      mine['email'] ??= _session?.user.email;
      _profile = Profile.fromJson(mine);
      _profiles = (results[1] as List)
          .map((item) => Profile.fromJson(item))
          .toList();
      _friendships = (results[2] as List)
          .map((item) => Friendship.fromJson(item))
          .toList();
      _posts = (results[3] as List)
          .map((item) => SocialPost.fromJson(item))
          .toList();
      _comments = (results[4] as List)
          .map((item) => PostComment.fromJson(item))
          .toList();
      _likes = (results[5] as List)
          .map((item) => PostLike.fromJson(item))
          .toList();
      _shares = (results[6] as List)
          .map((item) => PostShare.fromJson(item))
          .toList();
      _gameSessions = (results[7] as List)
          .map((item) => GameSession.fromJson(item))
          .toList();
      _gamePlayers = (results[8] as List)
          .map((item) => GamePlayer.fromJson(item))
          .toList();
      _gameInvites = (results[9] as List)
          .map((item) => GameInvite.fromJson(item))
          .toList();

      await _loadConversations(userId);
      await _loadCalls();

      _activeConversationId ??= _conversations.firstOrNull?.conversation.id;
      if (_activeConversationId != null &&
          !_conversations.any(
            (item) => item.conversation.id == _activeConversationId,
          )) {
        _activeConversationId = _conversations.firstOrNull?.conversation.id;
      }
      _activeGameId ??= _gameSessions.firstOrNull?.id;
      if (_activeGameId != null &&
          !_gameSessions.any((game) => game.id == _activeGameId)) {
        _activeGameId = _gameSessions.firstOrNull?.id;
      }
      _viewedProfileId ??= _profile?.id;
      _dataError = '';
    } catch (error) {
      if (generation == _loadGeneration) {
        _dataError = _friendlyError(error);
        _notice = _dataError;
      }
    } finally {
      if (generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> _fetchOrCreateProfile(String userId) async {
    try {
      return await _sb
          .from('profiles')
          .select(_profileColumns)
          .eq('id', userId)
          .single();
    } catch (_) {
      final user = _session?.user;
      final email = user?.email ?? '';
      final metadata = user?.userMetadata ?? const <String, dynamic>{};
      final fullName = (metadata['full_name'] as String?)?.trim();
      final handle = _cleanHandle(
        (metadata['handle'] as String?) ?? email.split('@').first,
      );
      return await _sb
          .from('profiles')
          .insert({
            'id': userId,
            'email': email,
            'full_name': fullName == null || fullName.length < 2
                ? 'Voxora Member'
                : fullName,
            'handle': handle.length < 3
                ? 'member-${userId.substring(0, 6)}'
                : handle,
          })
          .select(_profileColumns)
          .single();
    }
  }

  Future<void> _loadConversations(String userId) async {
    final mine = await _sb
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', userId)
        .order('joined_at', ascending: false)
        .limit(120);
    final ids = (mine as List)
        .map((item) => item['conversation_id'] as String)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      _conversations = [];
      _messages = [];
      return;
    }

    final results = await Future.wait<dynamic>([
      _sb
          .from('conversations')
          .select()
          .inFilter('id', ids)
          .order('updated_at', ascending: false),
      _sb
          .from('conversation_members')
          .select()
          .inFilter('conversation_id', ids),
      _sb
          .from('messages')
          .select()
          .inFilter('conversation_id', ids)
          .order('created_at')
          .limit(1000),
    ]);

    final conversationRows = (results[0] as List)
        .map((item) => Conversation.fromJson(item))
        .toList();
    final memberRows = (results[1] as List)
        .map((item) => ConversationMember.fromJson(item))
        .toList();
    _messages = (results[2] as List)
        .map((item) => DirectMessage.fromJson(item))
        .toList();

    _conversations = conversationRows.map((conversation) {
      final memberIds = memberRows
          .where((member) => member.conversationId == conversation.id)
          .map((member) => member.userId)
          .toSet();
      final members = _profiles
          .where((person) => memberIds.contains(person.id))
          .toList();
      final last = _messages
          .where((message) => message.conversationId == conversation.id)
          .lastOrNull;
      return ConversationSummary(
        conversation: conversation,
        members: members,
        lastMessage: last,
      );
    }).toList();
  }

  Future<void> _loadCalls() async {
    final ids = _conversations.map((item) => item.conversation.id).toList();
    if (ids.isEmpty) {
      _callSessions = [];
      return;
    }
    final rows = await _sb
        .from('call_sessions')
        .select()
        .inFilter('conversation_id', ids)
        .order('created_at', ascending: false)
        .limit(50);
    _callSessions = (rows as List)
        .map((item) => CallSession.fromJson(item))
        .toList();
  }

  void _subscribeRealtime(String userId) {
    _unsubscribeRealtime();
    var channel = _sb.channel('voxora-social-$userId');
    for (final table in [
      'profiles',
      'friendships',
      'conversations',
      'conversation_members',
      'messages',
      'posts',
      'post_comments',
      'post_likes',
      'post_shares',
      'game_sessions',
      'game_players',
      'game_invites',
      'call_sessions',
      'call_participants',
      'call_signals',
    ]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleRefresh(),
      );
    }
    _realtimeChannel = channel.subscribe();
  }

  void _unsubscribeRealtime() {
    unawaited(_realtimeChannel?.unsubscribe() ?? Future<void>.value());
    _realtimeChannel = null;
  }

  void _scheduleRefresh() {
    final userId = _session?.user.id;
    if (userId == null) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 650), () {
      unawaited(loadAppData(userId, showLoader: false));
    });
  }

  void _clearSession() {
    _profile = null;
    _profiles = [];
    _friendships = [];
    _conversations = [];
    _messages = [];
    _posts = [];
    _comments = [];
    _likes = [];
    _shares = [];
    _gameSessions = [];
    _gamePlayers = [];
    _gameInvites = [];
    _callSessions = [];
    _activeConversationId = null;
    _activeGameId = null;
    _viewedProfileId = null;
    _activeCallId = null;
    _notice = '';
    _dataError = '';
  }

  Future<void> refresh({bool showLoader = false}) async {
    final userId = _session?.user.id;
    if (userId == null) return;
    await loadAppData(userId, showLoader: showLoader);
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String handle,
    String bio = '',
    String interests = '',
  }) async {
    try {
      final cleanHandle = _cleanHandle(handle);
      if (fullName.trim().length < 2) return 'Enter your display name.';
      if (cleanHandle.length < 3) {
        return 'Choose a handle with at least 3 characters.';
      }
      await _sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'handle': cleanHandle,
          'bio': bio.trim(),
          'interests': interests
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .take(8)
              .join(','),
        },
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return _friendlyError(error);
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      return _friendlyError(error);
    }
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
    _session = null;
    _clearSession();
    _unsubscribeRealtime();
    _loading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String handle,
    required String bio,
    required List<String> interests,
  }) async {
    if (_profile == null) return;
    final cleanHandle = _cleanHandle(handle);
    if (fullName.trim().length < 2) {
      _showNotice('Enter your display name.');
      return;
    }
    if (cleanHandle.length < 3) {
      _showNotice('Choose a handle with at least 3 characters.');
      return;
    }
    try {
      await _sb
          .from('profiles')
          .update({
            'full_name': fullName.trim(),
            'handle': cleanHandle,
            'bio': bio.trim(),
            'interests': interests
                .where((item) => item.trim().isNotEmpty)
                .take(8)
                .toList(),
          })
          .eq('id', _profile!.id);
      await refresh();
      _showNotice('Profile updated.');
    } catch (error) {
      _showNotice(_friendlyError(error));
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    final url = await _uploadPublicImage(
      'avatars',
      bytes,
      filename,
      maxBytes: 5 * 1024 * 1024,
    );
    if (url == null || _profile == null) return;
    await _sb
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', _profile!.id);
    await refresh();
  }

  Future<void> uploadCover(Uint8List bytes, String filename) async {
    final url = await _uploadPublicImage(
      'covers',
      bytes,
      filename,
      maxBytes: 8 * 1024 * 1024,
    );
    if (url == null || _profile == null) return;
    await _sb
        .from('profiles')
        .update({'cover_url': url})
        .eq('id', _profile!.id);
    await refresh();
  }

  Future<void> createPost({
    required String caption,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    if (_profile == null) return;
    final url = await _uploadPublicImage(
      'post-images',
      imageBytes,
      filename,
      maxBytes: 15 * 1024 * 1024,
    );
    if (url == null) return;
    await _sb.from('posts').insert({
      'author_id': _profile!.id,
      'caption': caption.trim(),
      'image_url': url,
    });
    await refresh();
    _showNotice('Post published.');
  }

  Future<void> editPost(SocialPost post, String caption) async {
    if (_profile == null || post.authorId != _profile!.id) return;
    await _sb
        .from('posts')
        .update({'caption': caption.trim()})
        .eq('id', post.id);
    await refresh();
    _showNotice('Post updated.');
  }

  Future<void> deletePost(SocialPost post) async {
    if (_profile == null || post.authorId != _profile!.id) return;
    await _sb.from('posts').delete().eq('id', post.id);
    await refresh();
    _showNotice('Post removed.');
  }

  Future<void> toggleLike(SocialPost post) async {
    if (_profile == null) return;
    if (likedPost(post.id)) {
      await _sb
          .from('post_likes')
          .delete()
          .eq('post_id', post.id)
          .eq('user_id', _profile!.id);
    } else {
      await _sb.from('post_likes').insert({
        'post_id': post.id,
        'user_id': _profile!.id,
      });
    }
    await refresh();
  }

  Future<void> addComment(SocialPost post, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('post_comments').insert({
      'post_id': post.id,
      'author_id': _profile!.id,
      'body': body.trim(),
    });
    await refresh();
  }

  Future<void> deleteComment(PostComment comment) async {
    if (_profile == null) return;
    await _sb.from('post_comments').delete().eq('id', comment.id);
    await refresh();
  }

  Future<void> sharePost(SocialPost post) async {
    if (_profile == null) return;
    try {
      await _sb.from('post_shares').insert({
        'post_id': post.id,
        'user_id': _profile!.id,
      });
      await _sb.from('posts').insert({
        'author_id': _profile!.id,
        'caption': '',
        'shared_post_id': post.id,
      });
      await refresh();
      _showNotice('Post shared to your profile.');
    } catch (_) {
      _showNotice('You already shared this post.');
    }
  }

  bool likedPost(String postId) {
    final myId = _profile?.id;
    return myId != null &&
        _likes.any((like) => like.postId == postId && like.userId == myId);
  }

  int likeCount(String postId) =>
      _likes.where((like) => like.postId == postId).length;
  int shareCount(String postId) =>
      _shares.where((share) => share.postId == postId).length;

  List<PostComment> commentsForPost(String postId) =>
      _comments.where((comment) => comment.postId == postId).toList();

  Profile? profileById(String? id) {
    if (id == null) return null;
    return _profiles.where((profile) => profile.id == id).firstOrNull ??
        (_profile?.id == id ? _profile : null);
  }

  SocialPost? postById(String? id) {
    if (id == null) return null;
    return _posts.where((post) => post.id == id).firstOrNull;
  }

  Friendship? friendshipWith(String userId) {
    final myId = _profile?.id;
    if (myId == null) return null;
    return _friendships
        .where(
          (item) =>
              (item.requesterId == myId && item.addresseeId == userId) ||
              (item.requesterId == userId && item.addresseeId == myId),
        )
        .firstOrNull;
  }

  Future<void> requestFriend(Profile person) async {
    if (_profile == null || person.id == _profile!.id) return;
    if (friendshipWith(person.id) != null) {
      _showNotice('Friend request already exists.');
      return;
    }
    await _sb.from('friendships').insert({
      'requester_id': _profile!.id,
      'addressee_id': person.id,
      'status': 'pending',
    });
    await refresh();
    _showNotice('Friend request sent.');
  }

  Future<void> acceptFriend(Friendship friendship) async {
    await _sb
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendship.id);
    await refresh();
    _showNotice('Friend added.');
  }

  Future<void> removeFriend(Friendship friendship) async {
    await _sb.from('friendships').delete().eq('id', friendship.id);
    await refresh();
    _showNotice('Friend removed.');
  }

  Future<void> startConversation(Profile other) async {
    if (_profile == null || other.id == _profile!.id) return;
    final existing = _conversations.where((summary) {
      if (summary.conversation.isGroup || summary.members.length != 2) {
        return false;
      }
      return summary.members.any((member) => member.id == other.id);
    }).firstOrNull;
    if (existing != null) {
      selectConversation(existing.conversation.id);
      return;
    }
    await createConversation([other.id], isGroup: false);
  }

  Future<void> createConversation(
    List<String> memberIds, {
    bool isGroup = true,
    String? title,
    String? firstMessage,
  }) async {
    if (_profile == null) return;
    final members = memberIds
        .where((id) => id != _profile!.id)
        .toSet()
        .toList();
    if (members.isEmpty || (isGroup && members.length < 2)) {
      _showNotice(
        isGroup ? 'Choose at least two friends.' : 'Choose a friend.',
      );
      return;
    }
    final conversation = await _sb
        .from('conversations')
        .insert({
          'created_by': _profile!.id,
          'is_group': isGroup,
          'title': isGroup
              ? (title?.trim().isEmpty ?? true ? 'Group chat' : title!.trim())
              : null,
        })
        .select()
        .single();
    final conversationId = conversation['id'] as String;
    await _sb.from('conversation_members').insert([
      {'conversation_id': conversationId, 'user_id': _profile!.id},
      ...members.map(
        (id) => {'conversation_id': conversationId, 'user_id': id},
      ),
    ]);
    if (firstMessage != null && firstMessage.trim().isNotEmpty) {
      await _sb.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _profile!.id,
        'body': firstMessage.trim(),
      });
    }
    _activeConversationId = conversationId;
    _view = AppView.messages;
    await refresh();
  }

  Future<void> sendMessage(String conversationId, String body) async {
    if (_profile == null || body.trim().isEmpty) return;
    await _sb.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _profile!.id,
      'body': body.trim(),
    });
    await _sb
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
    await refresh();
  }

  Future<CallSession?> startCall(
    ConversationSummary conversation,
    String type,
  ) async {
    if (_profile == null) return null;
    final row = await _sb
        .from('call_sessions')
        .insert({
          'conversation_id': conversation.conversation.id,
          'caller_id': _profile!.id,
          'call_type': type,
          'status': 'ringing',
        })
        .select()
        .single();
    final call = CallSession.fromJson(row);
    await _sb
        .from('call_participants')
        .insert(
          conversation.members
              .map(
                (member) => {
                  'call_id': call.id,
                  'user_id': member.id,
                  'status': member.id == _profile!.id ? 'joined' : 'ringing',
                  if (member.id == _profile!.id)
                    'joined_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
    _activeCallId = call.id;
    await refresh();
    return call;
  }

  Future<void> markCallActive(String callId) async {
    await _sb
        .from('call_sessions')
        .update({'status': 'active'})
        .eq('id', callId);
    await refresh();
  }

  Future<void> endCall(String callId) async {
    await _sb
        .from('call_sessions')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId);
    if (_activeCallId == callId) _activeCallId = null;
    await refresh();
  }

  List<GamePlayer> playersForGame(String gameId) =>
      _gamePlayers.where((player) => player.gameId == gameId).toList();

  GamePlayer? myPlayerForGame(String gameId) {
    final myId = _profile?.id;
    if (myId == null) return null;
    return _gamePlayers
        .where((player) => player.gameId == gameId && player.userId == myId)
        .firstOrNull;
  }

  Future<void> createFriendGame(
    String gameType, {
    required int maxPlayers,
    List<String> inviteUserIds = const [],
  }) async {
    if (_profile == null) return;
    final inviteCode = _newInviteCode();
    final seat = _seatFor(gameType, 0);
    final gameRow = await _sb
        .from('game_sessions')
        .insert({
          'host_id': _profile!.id,
          'game_type': gameType,
          'mode': 'friends',
          'max_players': maxPlayers.clamp(2, 4),
          'invite_code': inviteCode,
          'status': maxPlayers == 1 ? 'active' : 'waiting',
          'current_seat': _firstSeat(gameType),
          'state': _initialGameState(gameType, maxPlayers),
        })
        .select()
        .single();
    final gameId = gameRow['id'] as String;
    await _sb.from('game_players').insert({
      'game_id': gameId,
      'user_id': _profile!.id,
      'seat': seat,
      'display_color': _displayColorFor(gameType, seat),
    });
    if (inviteUserIds.isNotEmpty) {
      await _sb
          .from('game_invites')
          .insert(
            inviteUserIds
                .map(
                  (id) => {
                    'game_id': gameId,
                    'invited_by': _profile!.id,
                    'invited_user_id': id,
                  },
                )
                .toList(),
          );
    }
    _activeGameId = gameId;
    _view = AppView.games;
    await refresh();
    _showNotice('Game code $inviteCode is ready.');
  }

  Future<void> joinGameByCode(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return;
    final rows = await _sb
        .from('game_sessions')
        .select()
        .eq('invite_code', clean)
        .limit(1);
    if ((rows as List).isEmpty) {
      _showNotice('No game found for that code.');
      return;
    }
    await joinFriendGame(GameSession.fromJson(rows.first));
  }

  Future<void> joinFriendGame(GameSession game) async {
    if (_profile == null) return;
    final players = playersForGame(game.id);
    if (players.any((player) => player.userId == _profile!.id)) {
      _activeGameId = game.id;
      notifyListeners();
      return;
    }
    if (players.length >= game.maxPlayers) {
      _showNotice('This game is full.');
      return;
    }
    final usedSeats = players.map((player) => player.seat).toSet();
    final seat = _seatsFor(
      game.gameType,
      game.maxPlayers,
    ).where((candidate) => !usedSeats.contains(candidate)).first;
    await _sb.from('game_players').insert({
      'game_id': game.id,
      'user_id': _profile!.id,
      'seat': seat,
      'display_color': _displayColorFor(game.gameType, seat),
    });
    if (players.length + 1 >= game.maxPlayers && game.status == 'waiting') {
      await _sb
          .from('game_sessions')
          .update({'status': 'active'})
          .eq('id', game.id);
    }
    await _sb
        .from('game_invites')
        .update({'status': 'accepted'})
        .eq('game_id', game.id)
        .eq('invited_user_id', _profile!.id);
    _activeGameId = game.id;
    await refresh();
  }

  Future<void> updateGame(GameSession game, Map<String, dynamic> patch) async {
    await _sb.from('game_sessions').update(patch).eq('id', game.id);
    await refresh();
  }

  Future<void> makeChessMove(GameSession game, String from, String to) async {
    final mine = myPlayerForGame(game.id);
    if (mine == null || game.status == 'finished') return;
    final board = chess_lib.Chess.fromFEN(game.state['fen'] as String);
    final turnSeat = board.turn == chess_lib.Color.WHITE ? 'white' : 'black';
    if (mine.seat != turnSeat) {
      _showNotice('Wait for your turn.');
      return;
    }
    final moved = board.move({'from': from, 'to': to, 'promotion': 'q'});
    if (!moved) return;
    final moves = List<String>.from(game.state['moves'] as List? ?? []);
    moves.add(
      board.history.isEmpty ? '$from-$to' : board.history.last.toString(),
    );
    final patch = {
      'state': {'fen': board.fen, 'moves': moves},
      'current_seat': board.turn == chess_lib.Color.WHITE ? 'white' : 'black',
      'status': board.game_over ? 'finished' : 'active',
    };
    await updateGame(game, patch);
  }

  Future<void> rollLudoDice(GameSession game) async {
    final mine = myPlayerForGame(game.id);
    if (mine == null || mine.seat != game.currentSeat) {
      _showNotice('Wait for your turn.');
      return;
    }
    final state = Map<String, dynamic>.from(game.state);
    if (state['dice'] != null || state['winner'] != null) return;
    final dice = _rng.nextInt(6) + 1;
    state['dice'] = dice;
    final tokens = _ludoTokens(state, mine.seat);
    if (!_hasLudoMove(tokens, dice)) {
      state['dice'] = null;
      await updateGame(game, {
        'state': state,
        'current_seat': _nextSeat(game.gameType, game.maxPlayers, mine.seat),
      });
      _showNotice('${mine.seat} rolled $dice with no legal move.');
      return;
    }
    await updateGame(game, {'state': state});
  }

  Future<void> moveLudoToken(GameSession game, int tokenIndex) async {
    final mine = myPlayerForGame(game.id);
    if (mine == null || mine.seat != game.currentSeat) return;
    final state = Map<String, dynamic>.from(game.state);
    final dice = state['dice'] as int?;
    if (dice == null) return;
    final tokensMap = Map<String, dynamic>.from(state['tokens'] as Map);
    final tokens = List<int>.from(tokensMap[mine.seat] as List);
    if (tokenIndex < 0 || tokenIndex >= tokens.length) return;
    final current = tokens[tokenIndex];
    if (current >= 56 || (current == 0 && dice != 6) || current + dice > 56) {
      _showNotice('That piece cannot move with this roll.');
      return;
    }
    tokens[tokenIndex] = current + dice;
    tokensMap[mine.seat] = tokens;
    state['tokens'] = tokensMap;
    state['dice'] = null;
    final winner = tokens.every((position) => position >= 56);
    if (winner) state['winner'] = mine.seat;
    await updateGame(game, {
      'state': state,
      'status': winner ? 'finished' : 'active',
      'current_seat': winner
          ? mine.seat
          : _nextSeat(game.gameType, game.maxPlayers, mine.seat),
      if (winner) 'winner_id': _profile!.id,
    });
  }

  Future<void> dealCards(GameSession game) async {
    final players = playersForGame(game.id);
    if (players.length < 2 || _profile?.id != game.hostId) return;
    final order = players.map((player) => player.seat).toList()..sort();
    final deck = _deck();
    final hands = <String, dynamic>{};
    for (final seat in order) {
      hands[seat] = deck.take(5).toList();
      deck.removeRange(0, min(5, deck.length));
    }
    await updateGame(game, {
      'status': 'active',
      'current_seat': order.first,
      'state': {
        'deck': deck,
        'hands': hands,
        'table': <String, dynamic>{},
        'scores': <String, dynamic>{},
        'round': 1,
        'order': order,
      },
    });
  }

  Future<void> playCard(GameSession game, String card) async {
    final mine = myPlayerForGame(game.id);
    if (mine == null || mine.seat != game.currentSeat) {
      _showNotice('Wait for your turn.');
      return;
    }
    final state = Map<String, dynamic>.from(game.state);
    final hands = Map<String, dynamic>.from(state['hands'] as Map? ?? {});
    final table = Map<String, dynamic>.from(state['table'] as Map? ?? {});
    final hand = List<String>.from(hands[mine.seat] as List? ?? []);
    if (!hand.contains(card) || table[mine.seat] != null) return;
    hand.remove(card);
    hands[mine.seat] = hand;
    table[mine.seat] = card;
    state['hands'] = hands;
    state['table'] = table;
    final order = List<String>.from(state['order'] as List? ?? []);
    final allPlayed =
        order.isNotEmpty && order.every((seat) => table[seat] != null);
    if (allPlayed) {
      _settleCardRound(state);
    }
    final nextSeat = allPlayed
        ? (state['order'] as List).first as String
        : _nextCardSeat(order, table, mine.seat);
    await updateGame(game, {
      'state': state,
      'current_seat': nextSeat,
      'status': _cardsFinished(state) ? 'finished' : 'active',
    });
  }

  String _nextCardSeat(
    List<String> order,
    Map<String, dynamic> table,
    String current,
  ) {
    if (order.isEmpty) return current;
    final start = order.indexOf(current);
    for (var i = 1; i <= order.length; i++) {
      final seat = order[(start + i) % order.length];
      if (table[seat] == null) return seat;
    }
    return order.first;
  }

  void _settleCardRound(Map<String, dynamic> state) {
    final table = Map<String, dynamic>.from(state['table'] as Map);
    final scores = Map<String, dynamic>.from(state['scores'] as Map? ?? {});
    final order = List<String>.from(state['order'] as List? ?? []);
    final played = order.where((seat) => table[seat] != null).toList();
    played.sort(
      (a, b) => _cardValue(table[b] as String) - _cardValue(table[a] as String),
    );
    if (played.isNotEmpty) {
      scores[played.first] = ((scores[played.first] as int?) ?? 0) + 1;
    }
    state['scores'] = scores;
    state['table'] = <String, dynamic>{};
    state['round'] = ((state['round'] as int?) ?? 1) + 1;
  }

  bool _cardsFinished(Map<String, dynamic> state) {
    final hands = Map<String, dynamic>.from(state['hands'] as Map? ?? {});
    final order = List<String>.from(state['order'] as List? ?? []);
    return order.isNotEmpty &&
        order.every((seat) => (hands[seat] as List? ?? const []).isEmpty);
  }

  List<int> _ludoTokens(Map<String, dynamic> state, String color) {
    final tokens = Map<String, dynamic>.from(state['tokens'] as Map? ?? {});
    return List<int>.from(tokens[color] as List? ?? [0, 0, 0, 0]);
  }

  bool _hasLudoMove(List<int> tokens, int dice) {
    return tokens.any(
      (position) =>
          position < 56 && (position > 0 || dice == 6) && position + dice <= 56,
    );
  }

  Map<String, dynamic> _initialGameState(String type, int maxPlayers) {
    if (type == 'chess') {
      return {
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'moves': <String>[],
      };
    }
    if (type == 'ludo') {
      final colors = ludoColorNames.take(maxPlayers.clamp(2, 4)).toList();
      return {
        'activeColors': colors,
        'turn': colors.first,
        'dice': null,
        'tokens': {
          for (final color in colors) color: [0, 0, 0, 0],
        },
        'winner': null,
      };
    }
    return {
      'deck': _deck(),
      'hands': <String, dynamic>{},
      'table': <String, dynamic>{},
      'scores': <String, dynamic>{},
      'round': 1,
      'order': <String>[],
    };
  }

  List<String> _deck() {
    final deck = [
      for (final suit in cardSuits)
        for (final rank in cardRanks) '$rank$suit',
    ]..shuffle(_rng);
    return deck;
  }

  int _cardValue(String card) =>
      cardRanks.indexOf(card.replaceAll(RegExp(r'[SHDC]'), ''));

  List<String> _seatsFor(String gameType, int maxPlayers) {
    if (gameType == 'chess') return const ['white', 'black'];
    if (gameType == 'ludo') {
      return ludoColorNames.take(maxPlayers.clamp(2, 4)).toList();
    }
    return List.generate(maxPlayers.clamp(2, 4), (index) => 'p${index + 1}');
  }

  String _seatFor(String gameType, int index) => _seatsFor(gameType, 4)[index];
  String _firstSeat(String gameType) =>
      gameType == 'cards' ? 'p1' : _seatFor(gameType, 0);

  String _nextSeat(String gameType, int maxPlayers, String current) {
    final seats = _seatsFor(gameType, maxPlayers);
    final index = seats.indexOf(current);
    return seats[(index + 1) % seats.length];
  }

  String? _displayColorFor(String gameType, String seat) {
    if (gameType == 'chess') return seat == 'white' ? '#F8FAFC' : '#111827';
    if (gameType == 'ludo') return seat;
    return null;
  }

  String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  Future<String?> _uploadPublicImage(
    String bucket,
    Uint8List bytes,
    String filename, {
    required int maxBytes,
  }) async {
    if (_profile == null) return null;
    final contentType = _imageContentType(filename);
    if (contentType == null) {
      _showNotice('Use a PNG, JPG, or WebP image.');
      return null;
    }
    if (bytes.length > maxBytes) {
      _showNotice('That image is too large.');
      return null;
    }
    final extension = _safeImageExtension(filename);
    final path =
        '${_profile!.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _sb.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
            cacheControl: '31536000',
          ),
        );
    return _sb.storage.from(bucket).getPublicUrl(path);
  }

  String? _imageContentType(String filename) {
    return switch (_safeImageExtension(filename)) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  String _safeImageExtension(String filename) {
    final extension = filename.split('.').last.trim().toLowerCase();
    return extension == 'jpeg' ? 'jpg' : extension;
  }

  String _cleanHandle(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) return 'The request timed out. Try again.';
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    return error.toString();
  }
}
