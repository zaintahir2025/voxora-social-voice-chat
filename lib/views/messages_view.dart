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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.chat_bubble_outline,
            title: 'Chat with friends',
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
          if (app.conversations.isEmpty)
            const Text('Start a chat from the Friends page.')
          else
            ...app.conversations.map((summary) {
              final currentUserId = app.profile?.id ?? '';
              final title = summary.titleFor(currentUserId);
              final others = summary.members
                  .where((m) => m.id != currentUserId)
                  .toList();
              final active =
                  app.activeConversation?.conversation.id ==
                  summary.conversation.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  selected: active,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: AvatarStack(members: others),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    summary.lastMessage?.body ??
                        '${summary.members.length} members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      secondary: UserAvatar(url: friend.avatarUrl),
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
    final liveCall = app.liveCalls
        .where((call) => call.conversationId == summary.conversation.id)
        .firstOrNull;

    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AvatarStack(members: others),
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
                          '${summary.members.length} members',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (liveCall != null)
                    FilledButton.icon(
                      onPressed: () => _openCall(app, liveCall),
                      icon: Icon(
                        liveCall.callType == 'video'
                            ? Icons.videocam
                            : Icons.call,
                      ),
                      label: const Text('Join'),
                    )
                  else ...[
                    ActionIconButton(
                      icon: Icons.call_outlined,
                      tooltip: 'Audio call',
                      onPressed: () => _startCall(app, summary, 'audio'),
                    ),
                    ActionIconButton(
                      icon: Icons.videocam_outlined,
                      tooltip: 'Video call',
                      onPressed: () => _startCall(app, summary, 'video'),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final sender = app.profileById(message.senderId);
                  return MessageBubble(
                    name: message.senderId == currentUserId
                        ? null
                        : sender?.fullName,
                    body: message.body,
                    createdAt: message.createdAt,
                    mine: message.senderId == currentUserId,
                  );
                },
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
      builder: (_) => _CallDialog(call: call),
    );
  }
}

class _CallDialog extends StatefulWidget {
  final CallSession call;

  const _CallDialog({required this.call});

  @override
  State<_CallDialog> createState() => _CallDialogState();
}

class _CallDialogState extends State<_CallDialog> {
  late final FriendCallController _controller;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _controller = FriendCallController(
      callId: widget.call.id,
      userId: app.profile!.id,
      video: widget.call.callType == 'video',
    );
    _controller.addListener(_refresh);
    _controller.start().then((_) => app.markCallActive(widget.call.id));
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final video = widget.call.callType == 'video';
    return AlertDialog(
      title: Row(
        children: [
          Icon(video ? Icons.videocam : Icons.call),
          const SizedBox(width: 10),
          Expanded(child: Text(video ? 'Video call' : 'Audio call')),
        ],
      ),
      content: SizedBox(
        width: 680,
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
                      width: 150,
                      height: 96,
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
