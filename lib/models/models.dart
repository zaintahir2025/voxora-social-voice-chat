// All data models for Voxora, matching the Supabase schema.

class Profile {
  final String id;
  final String? email;
  final String fullName;
  final String handle;
  final String? avatarUrl;
  final String? coverUrl;
  final String bio;
  final List<String> interests;
  final int level;
  final bool isAdmin;
  final bool isBlocked;
  final String createdAt;

  Profile({
    required this.id,
    this.email,
    required this.fullName,
    required this.handle,
    this.avatarUrl,
    this.coverUrl,
    this.bio = '',
    this.interests = const [],
    this.level = 1,
    this.isAdmin = false,
    this.isBlocked = false,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    email: json['email'] as String?,
    fullName: json['full_name'] as String? ?? 'Voxora Member',
    handle: json['handle'] as String? ?? 'member',
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    bio: json['bio'] as String? ?? '',
    interests:
        (json['interests'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    level: json['level'] as int? ?? 1,
    isAdmin: json['is_admin'] as bool? ?? false,
    isBlocked: json['is_blocked'] as bool? ?? false,
    createdAt: json['created_at'] as String? ?? '',
  );
}

class Room {
  final String id;
  final String title;
  final String topic;
  final String description;
  final String hostId;
  final int capacity;
  final bool isLive;
  final bool isLocked;
  final String createdAt;
  final String? endedAt;

  Room({
    required this.id,
    required this.title,
    this.topic = 'General',
    this.description = '',
    required this.hostId,
    this.capacity = 200,
    this.isLive = true,
    this.isLocked = false,
    required this.createdAt,
    this.endedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] as String,
    title: json['title'] as String,
    topic: json['topic'] as String? ?? 'General',
    description: json['description'] as String? ?? '',
    hostId: json['host_id'] as String,
    capacity: json['capacity'] as int? ?? 200,
    isLive: json['is_live'] as bool? ?? true,
    isLocked: json['is_locked'] as bool? ?? false,
    createdAt: json['created_at'] as String? ?? '',
    endedAt: json['ended_at'] as String?,
  );
}

class RoomParticipant {
  final String roomId;
  final String userId;
  final String role;
  final bool muted;
  final bool speaking;
  final String joinedAt;
  final Profile? profile;

  RoomParticipant({
    required this.roomId,
    required this.userId,
    this.role = 'listener',
    this.muted = true,
    this.speaking = false,
    required this.joinedAt,
    this.profile,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    Profile? profile;
    final p = json['profiles'];
    if (p is Map<String, dynamic>) {
      profile = Profile.fromJson(p);
    } else if (p is List && p.isNotEmpty && p[0] is Map<String, dynamic>) {
      profile = Profile.fromJson(p[0] as Map<String, dynamic>);
    }
    return RoomParticipant(
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'listener',
      muted: json['muted'] as bool? ?? true,
      speaking: json['speaking'] as bool? ?? false,
      joinedAt: json['joined_at'] as String? ?? '',
      profile: profile,
    );
  }
}

class RoomMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String body;
  final String kind;
  final String createdAt;
  final Profile? profile;

  RoomMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.body,
    this.kind = 'chat',
    required this.createdAt,
    this.profile,
  });

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    Profile? profile;
    final p = json['profiles'];
    if (p is Map<String, dynamic>) {
      profile = Profile.fromJson(p);
    } else if (p is List && p.isNotEmpty && p[0] is Map<String, dynamic>) {
      profile = Profile.fromJson(p[0] as Map<String, dynamic>);
    }
    return RoomMessage(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      kind: json['kind'] as String? ?? 'chat',
      createdAt: json['created_at'] as String? ?? '',
      profile: profile,
    );
  }
}

class MeetingNote {
  final String id;
  final String roomId;
  final String authorId;
  final String noteType;
  final String body;
  final bool isDone;
  final String createdAt;
  final Profile? profile;

  MeetingNote({
    required this.id,
    required this.roomId,
    required this.authorId,
    required this.noteType,
    required this.body,
    this.isDone = false,
    required this.createdAt,
    this.profile,
  });

  factory MeetingNote.fromJson(Map<String, dynamic> json) {
    Profile? profile;
    final p = json['profiles'];
    if (p is Map<String, dynamic>) {
      profile = Profile.fromJson(p);
    } else if (p is List && p.isNotEmpty && p[0] is Map<String, dynamic>) {
      profile = Profile.fromJson(p[0] as Map<String, dynamic>);
    }
    return MeetingNote(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      authorId: json['author_id'] as String,
      noteType: json['note_type'] as String,
      body: json['body'] as String,
      isDone: json['is_done'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      profile: profile,
    );
  }
}

class GameSession {
  final String id;
  final String roomId;
  final String hostId;
  final String gameType;
  final String title;
  final Map<String, dynamic> players;
  final Map<String, dynamic> state;
  final bool isActive;
  final String createdAt;

  GameSession({
    required this.id,
    required this.roomId,
    required this.hostId,
    required this.gameType,
    required this.title,
    required this.players,
    required this.state,
    this.isActive = true,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
    id: json['id'] as String,
    roomId: json['room_id'] as String,
    hostId: json['host_id'] as String,
    gameType: json['game_type'] as String,
    title: json['title'] as String? ?? '',
    players: Map<String, dynamic>.from((json['players'] as Map?) ?? const {}),
    state: Map<String, dynamic>.from((json['state'] as Map?) ?? const {}),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] as String? ?? '',
  );
}

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final String createdAt;

  Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'] as String,
    requesterId: json['requester_id'] as String,
    addresseeId: json['addressee_id'] as String,
    status: json['status'] as String? ?? 'pending',
    createdAt: json['created_at'] as String? ?? '',
  );
}

class ConversationSummary {
  final String id;
  final String title;
  final List<Profile> members;
  final Profile? other;
  final String lastMessage;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.members,
    this.other,
    this.lastMessage = 'Conversation started',
  });
}

class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String createdAt;

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) => DirectMessage(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    body: json['body'] as String,
    createdAt: json['created_at'] as String? ?? '',
  );
}
