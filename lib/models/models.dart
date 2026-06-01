class Profile {
  final String id;
  final String? email;
  final String fullName;
  final String handle;
  final String? avatarUrl;
  final String? coverUrl;
  final String bio;
  final List<String> interests;
  final String status;
  final String createdAt;
  final String updatedAt;

  const Profile({
    required this.id,
    this.email,
    required this.fullName,
    required this.handle,
    this.avatarUrl,
    this.coverUrl,
    this.bio = '',
    this.interests = const [],
    this.status = 'offline',
    required this.createdAt,
    required this.updatedAt,
  });

  Profile copyWith({String? status, String? updatedAt}) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName,
      handle: handle,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      interests: interests,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        const [],
    status: json['status'] as String? ?? 'offline',
    createdAt: json['created_at'] as String? ?? '',
    updatedAt:
        json['updated_at'] as String? ?? json['created_at'] as String? ?? '',
  );
}

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final String createdAt;

  const Friendship({
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

class Conversation {
  final String id;
  final String? title;
  final bool isGroup;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const Conversation({
    required this.id,
    this.title,
    required this.isGroup,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String?,
    isGroup: json['is_group'] as bool? ?? false,
    createdBy: json['created_by'] as String,
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );
}

class ConversationMember {
  final String conversationId;
  final String userId;
  final String joinedAt;

  const ConversationMember({
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) =>
      ConversationMember(
        conversationId: json['conversation_id'] as String,
        userId: json['user_id'] as String,
        joinedAt: json['joined_at'] as String? ?? '',
      );
}

class ConversationSummary {
  final Conversation conversation;
  final List<Profile> members;
  final DirectMessage? lastMessage;

  const ConversationSummary({
    required this.conversation,
    required this.members,
    this.lastMessage,
  });

  String titleFor(String currentUserId) {
    if (conversation.isGroup) {
      final clean = conversation.title?.trim();
      return clean == null || clean.isEmpty ? 'Group chat' : clean;
    }
    final other = members
        .where((member) => member.id != currentUserId)
        .firstOrNull;
    return other?.fullName ?? 'Conversation';
  }
}

class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String createdAt;

  const DirectMessage({
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

class MessageRead {
  final String messageId;
  final String userId;
  final String readAt;

  const MessageRead({
    required this.messageId,
    required this.userId,
    required this.readAt,
  });

  factory MessageRead.fromJson(Map<String, dynamic> json) => MessageRead(
    messageId: json['message_id'] as String,
    userId: json['user_id'] as String,
    readAt: json['read_at'] as String? ?? '',
  );
}

class SocialPost {
  final String id;
  final String authorId;
  final String caption;
  final String? imageUrl;
  final String? sharedPostId;
  final String createdAt;
  final String updatedAt;

  const SocialPost({
    required this.id,
    required this.authorId,
    required this.caption,
    this.imageUrl,
    this.sharedPostId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    caption: json['caption'] as String? ?? '',
    imageUrl: json['image_url'] as String?,
    sharedPostId: json['shared_post_id'] as String?,
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );
}

class PostComment {
  final String id;
  final String postId;
  final String? parentCommentId;
  final String authorId;
  final String body;
  final String createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String,
    postId: json['post_id'] as String,
    parentCommentId: json['parent_comment_id'] as String?,
    authorId: json['author_id'] as String,
    body: json['body'] as String,
    createdAt: json['created_at'] as String? ?? '',
  );
}

class PostLike {
  final String postId;
  final String userId;

  const PostLike({required this.postId, required this.userId});

  factory PostLike.fromJson(Map<String, dynamic> json) => PostLike(
    postId: json['post_id'] as String,
    userId: json['user_id'] as String,
  );
}

class PostShare {
  final String id;
  final String postId;
  final String userId;

  const PostShare({
    required this.id,
    required this.postId,
    required this.userId,
  });

  factory PostShare.fromJson(Map<String, dynamic> json) => PostShare(
    id: json['id'] as String,
    postId: json['post_id'] as String,
    userId: json['user_id'] as String,
  );
}

class GameSession {
  final String id;
  final String hostId;
  final String gameType;
  final String mode;
  final int maxPlayers;
  final String inviteCode;
  final String status;
  final String? currentSeat;
  final Map<String, dynamic> state;
  final String? winnerId;
  final String createdAt;

  const GameSession({
    required this.id,
    required this.hostId,
    required this.gameType,
    required this.mode,
    required this.maxPlayers,
    required this.inviteCode,
    required this.status,
    this.currentSeat,
    required this.state,
    this.winnerId,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
    id: json['id'] as String,
    hostId: json['host_id'] as String,
    gameType: json['game_type'] as String,
    mode: json['mode'] as String? ?? 'friends',
    maxPlayers: json['max_players'] as int? ?? 2,
    inviteCode: json['invite_code'] as String? ?? '',
    status: json['status'] as String? ?? 'waiting',
    currentSeat: json['current_seat'] as String?,
    state: Map<String, dynamic>.from((json['state'] as Map?) ?? const {}),
    winnerId: json['winner_id'] as String?,
    createdAt: json['created_at'] as String? ?? '',
  );
}

class GamePlayer {
  final String gameId;
  final String userId;
  final String seat;
  final String? displayColor;

  const GamePlayer({
    required this.gameId,
    required this.userId,
    required this.seat,
    this.displayColor,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) => GamePlayer(
    gameId: json['game_id'] as String,
    userId: json['user_id'] as String,
    seat: json['seat'] as String,
    displayColor: json['display_color'] as String?,
  );
}

class GameInvite {
  final String id;
  final String gameId;
  final String invitedBy;
  final String invitedUserId;
  final String status;

  const GameInvite({
    required this.id,
    required this.gameId,
    required this.invitedBy,
    required this.invitedUserId,
    required this.status,
  });

  factory GameInvite.fromJson(Map<String, dynamic> json) => GameInvite(
    id: json['id'] as String,
    gameId: json['game_id'] as String,
    invitedBy: json['invited_by'] as String,
    invitedUserId: json['invited_user_id'] as String,
    status: json['status'] as String? ?? 'pending',
  );
}

class CallSession {
  final String id;
  final String conversationId;
  final String callerId;
  final String callType;
  final String status;
  final String createdAt;

  const CallSession({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.callType,
    required this.status,
    required this.createdAt,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    callerId: json['caller_id'] as String,
    callType: json['call_type'] as String,
    status: json['status'] as String? ?? 'ringing',
    createdAt: json['created_at'] as String? ?? '',
  );

  CallSession copyWith({String? status}) {
    return CallSession(
      id: id,
      conversationId: conversationId,
      callerId: callerId,
      callType: callType,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class CallParticipant {
  final String callId;
  final String userId;
  final String status;
  final String? joinedAt;

  const CallParticipant({
    required this.callId,
    required this.userId,
    required this.status,
    this.joinedAt,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) =>
      CallParticipant(
        callId: json['call_id'] as String,
        userId: json['user_id'] as String,
        status: json['status'] as String? ?? 'ringing',
        joinedAt: json['joined_at'] as String?,
      );
}
