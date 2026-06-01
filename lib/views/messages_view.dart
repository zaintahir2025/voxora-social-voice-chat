import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/call_service.dart';
import '../widgets/common_widgets.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final _message = TextEditingController();
  final _groupTitle = TextEditingController();
  final _firstMessage = TextEditingController();
  final Set<String> _selectedFriends = {};
  String _chatQuery = '';
  bool _creatingGroup = false;

  @override
  void dispose() {
    _message.dispose();
    _groupTitle.dispose();
    _firstMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final wide = MediaQuery.of(context).size.width >= 900;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: _conversationList(app)),
          const SizedBox(width: 14),
          Expanded(child: _chatPanel(app)),
        ],
      );
    }
    return Column(
      children: [
        _conversationList(app),
        const SizedBox(height: 14),
        _chatPanel(app),
      ],
    );
  }

  Widget _conversationList(AppProvider app) {
    final currentUserId = app.profile?.id ?? '';
    final query = _chatQuery.trim().toLowerCase();
    final conversations = app.chatConversations.where((summary) {
      final title = summary.titleFor(currentUserId).toLowerCase();
      final lastMessage = summary.lastMessage?.body.toLowerCase() ?? '';
      return query.isEmpty ||
          title.contains(query) ||
          lastMessage.contains(query);
    }).toList();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.forum_outlined,
            title: 'Chats',
            subtitle: conversations.isEmpty
                ? 'Your message inbox'
                : '${conversations.length} active chats',
            trailing: IconButton(
              tooltip: _creatingGroup ? 'Close group builder' : 'Create group',
              icon: Icon(
                _creatingGroup ? Icons.close : Icons.group_add_outlined,
              ),
              onPressed: () => setState(() => _creatingGroup = !_creatingGroup),
            ),
          ),
          if (_creatingGroup) ...[
            _groupBuilder(app),
            const SizedBox(height: 14),
          ],
          TextField(
            onChanged: (value) => setState(() => _chatQuery = value),
            decoration: const InputDecoration(
              hintText: 'Search chats',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (conversations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: _InlineEmpty(
                icon: Icons.chat_bubble_outline,
                title: query.isEmpty ? 'No chats yet' : 'No chats found',
                body: query.isEmpty
                    ? 'Message a friend first; empty contacts stay out of this inbox.'
                    : 'Try another name or message.',
              ),
            )
          else
            ...conversations.map((summary) {
              final title = summary.titleFor(currentUserId);
              final others = summary.members
                  .where((m) => m.id != currentUserId)
                  .toList();
              final active =
                  app.activeConversation?.conversation.id ==
                  summary.conversation.id;
              final unread = app.unreadCountForConversation(
                summary.conversation.id,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ConversationTile(
                  title: title,
                  subtitle: summary.lastMessage?.body ?? '',
                  active: active,
                  unread: unread,
                  avatar: AvatarStack(members: others, size: 42),
                  time: summary.lastMessage?.createdAt,
                  onTap: () => app.selectConversation(summary.conversation.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _groupBuilder(AppProvider app) {
    final friends = app.friends;
    return AppCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _groupTitle,
            decoration: const InputDecoration(
              labelText: 'Group name',
              prefixIcon: Icon(Icons.group_outlined),
            ),
          ),
          const SizedBox(height: 10),
          if (friends.isEmpty)
            Text(
              'Add friends before creating a group.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  children: friends.map((friend) {
                    final selected = _selectedFriends.contains(friend.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(friend.fullName),
                      subtitle: Text('@${friend.handle}'),
                      secondary: UserAvatar(
                        url: friend.avatarUrl,
                        online: app.isProfileOnline(friend),
                        seed: friend.handle,
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedFriends.add(friend.id);
                          } else {
                            _selectedFriends.remove(friend.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _firstMessage,
            decoration: const InputDecoration(
              labelText: 'First message',
              prefixIcon: Icon(Icons.message_outlined),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedFriends.length < 2
                  ? null
                  : () async {
                      await app.createConversation(
                        _selectedFriends.toList(),
                        title: _groupTitle.text,
                        firstMessage: _firstMessage.text,
                      );
                      if (!mounted) return;
                      setState(() {
                        _creatingGroup = false;
                        _selectedFriends.clear();
                        _groupTitle.clear();
                        _firstMessage.clear();
                      });
                    },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Create group'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatPanel(AppProvider app) {
    final summary = app.activeConversation;
    if (summary == null) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No conversation selected',
        body: 'Choose a friend or create a group.',
      );
    }
    final currentUserId = app.profile?.id ?? '';
    final title = summary.titleFor(currentUserId);
    final others = summary.members
        .where((member) => member.id != currentUserId)
        .toList();
    final messages = app.messagesForActiveConversation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<AppProvider>().markConversationRead(
          summary.conversation.id,
        ),
      );
    });
    final liveCall = app.liveCallForConversation(summary.conversation.id);
    final canCall = app.canStartCall(summary);
    final subtitle = summary.conversation.isGroup
        ? '${summary.members.length} members'
        : app.presenceLabel(others.firstOrNull);

    final availableHeight = MediaQuery.of(context).size.height - 180;
    final panelHeight = math.max(460.0, math.min(720.0, availableHeight));
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: panelHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AvatarStack(members: others, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (liveCall != null && app.canJoinCall(liveCall))
                    if (liveCall.status == 'ringing' &&
                        liveCall.callerId != currentUserId) ...[
                      IconButton.filled(
                        tooltip: 'Decline call',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                        onPressed: () => app.declineCall(liveCall),
                        icon: const Icon(Icons.call_end),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openCall(app, liveCall),
                        icon: Icon(
                          liveCall.callType == 'video'
                              ? Icons.videocam
                              : Icons.call,
                        ),
                        label: const Text('Answer'),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: () => _openCall(app, liveCall),
                        icon: Icon(
                          liveCall.callType == 'video'
                              ? Icons.videocam
                              : Icons.call,
                        ),
                        label: Text(
                          liveCall.status == 'ringing' ? 'Calling' : 'Join',
                        ),
                      )
                  else ...[
                    ActionIconButton(
                      icon: Icons.call_outlined,
                      tooltip: 'Audio call',
                      onPressed: canCall
                          ? () => _startCall(app, summary, 'audio')
                          : null,
                    ),
                    ActionIconButton(
                      icon: Icons.videocam_outlined,
                      tooltip: 'Video call',
                      onPressed: canCall
                          ? () => _startCall(app, summary, 'video')
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
                ),
                child: messages.isEmpty
                    ? const Center(
                        child: _InlineEmpty(
                          icon: Icons.waving_hand_outlined,
                          title: 'Say hello',
                          body: 'Send the first message to start this chat.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final sender = app.profileById(message.senderId);
                          return MessageBubble(
                            name:
                                summary.conversation.isGroup &&
                                    message.senderId != currentUserId
                                ? sender?.fullName
                                : null,
                            body: message.body,
                            createdAt: message.createdAt,
                            mine: message.senderId == currentUserId,
                            receipt: app.readReceiptForMessage(
                              message,
                              summary.members,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final body = _message.text;
                      _message.clear();
                      app.sendMessage(summary.conversation.id, body);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCall(
    AppProvider app,
    ConversationSummary conversation,
    String type,
  ) async {
    final call = await app.startCall(conversation, type);
    if (call != null && mounted) _openCall(app, call);
  }

  void _openCall(AppProvider app, CallSession call) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CallDialog(call: call),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final int unread;
  final Widget avatar;
  final String? time;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.unread,
    required this.avatar,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.24)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unread > 0
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (time != null)
                        Text(
                          _time(time!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0
                                ? scheme.onSurface
                                : scheme.onSurface.withValues(alpha: 0.58),
                            fontWeight: unread > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        _ChatUnreadBadge(count: unread),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: scheme.primary),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ChatUnreadBadge extends StatelessWidget {
  final int count;

  const _ChatUnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: scheme.onError,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class CallDialog extends StatefulWidget {
  final CallSession call;

  const CallDialog({super.key, required this.call});

  @override
  State<CallDialog> createState() => _CallDialogState();
}

class _CallDialogState extends State<CallDialog> {
  late final AppProvider _app;
  late final FriendCallController _controller;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppProvider>();
    _controller = FriendCallController(
      callId: widget.call.id,
      userId: _app.profile!.id,
      video: widget.call.callType == 'video',
    );
    _controller.addListener(_refresh);
    unawaited(_joinAndStart(_app));
  }

  Future<void> _joinAndStart(AppProvider app) async {
    await app.joinCall(widget.call);
    if (!mounted) return;
    await _controller.start();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    final liveCall = _app.callById(widget.call.id);
    if (!_ending &&
        liveCall != null &&
        liveCall.status != 'ended' &&
        liveCall.status != 'missed') {
      unawaited(_app.endCall(widget.call.id));
    }
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    if (!_ending && _controller.status == 'Waiting for friend') {
      _ending = true;
      unawaited(_app.endCall(widget.call.id));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final liveCall = app.callById(widget.call.id);
    if (liveCall == null ||
        liveCall.status == 'ended' ||
        liveCall.status == 'missed' ||
        !app.canJoinCall(liveCall)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
    final video = widget.call.callType == 'video';
    final dialogWidth = math.max(
      280.0,
      math.min(680.0, MediaQuery.of(context).size.width - 64),
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(video ? Icons.videocam : Icons.call),
          const SizedBox(width: 10),
          Expanded(child: Text(video ? 'Video call' : 'Audio call')),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (video)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.black,
                        child: RTCVideoView(
                          _controller.remoteRenderer,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        width: math.min(150.0, dialogWidth * 0.34),
                        height: math.min(96.0, dialogWidth * 0.22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: RTCVideoView(
                              _controller.localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 1,
                        height: 1,
                        child: Opacity(
                          opacity: 0,
                          child: RTCVideoView(_controller.remoteRenderer),
                        ),
                      ),
                      const Icon(Icons.graphic_eq, size: 54),
                      const SizedBox(height: 10),
                      Text(_controller.status),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                _controller.status,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton.filledTonal(
          tooltip: _controller.muted ? 'Unmute' : 'Mute',
          onPressed: _controller.toggleMute,
          icon: Icon(_controller.muted ? Icons.mic_off : Icons.mic),
        ),
        if (video)
          IconButton.filledTonal(
            tooltip: _controller.cameraOff
                ? 'Turn camera on'
                : 'Turn camera off',
            onPressed: _controller.toggleCamera,
            icon: Icon(
              _controller.cameraOff ? Icons.videocam_off : Icons.videocam,
            ),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            _ending = true;
            await _controller.stop();
            await app.endCall(widget.call.id);
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.call_end),
          label: const Text('End'),
        ),
      ],
    );
  }
}
