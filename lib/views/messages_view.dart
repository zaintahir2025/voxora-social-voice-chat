import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});
  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final _msgC = TextEditingController();
  final _searchC = TextEditingController();
  final _groupMsgC = TextEditingController();
  String _search = '';
  bool _showGroupBuilder = false;
  final Set<String> _groupMemberIds = <String>{};
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgC.dispose();
    _searchC.dispose();
    _groupMsgC.dispose();
    _scrollCtrl.dispose();
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
          SizedBox(width: 360, child: _list(app)),
          const SizedBox(width: 18),
          Expanded(child: _panel(app)),
        ],
      );
    }
    return Column(
      children: [_list(app), const SizedBox(height: 18), _panel(app)],
    );
  }

  Widget _list(AppProvider app) {
    final candidates = app.profiles
        .where(
          (p) =>
              p.id != app.profile?.id &&
              '${p.fullName} ${p.handle}'.toLowerCase().contains(
                _search.toLowerCase(),
              ),
        )
        .toList();

    return VPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSectionTitle(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            trailing: VSecondaryButton(
              label: _showGroupBuilder ? 'Cancel' : 'New Group',
              icon: _showGroupBuilder ? Icons.close : Icons.group_add_outlined,
              onTap: () =>
                  setState(() => _showGroupBuilder = !_showGroupBuilder),
            ),
          ),
          if (_showGroupBuilder) ...[
            _groupComposer(app),
            const SizedBox(height: 12),
          ],
          // Search bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: VoxoraColors.surfaceLight,
              border: Border.all(color: VoxoraColors.line),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: VoxoraColors.muted,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchC,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(
                      color: VoxoraColors.text,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search people...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (_search.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchC.clear();
                      setState(() => _search = '');
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: VoxoraColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_search.isNotEmpty)
            ...candidates.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: VListRow(
                  onTap: () => app.startConversation(p),
                  child: Row(
                    children: [
                      VAvatar(url: p.avatarUrl, size: 40, showOnline: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: VoxoraColors.text,
                              ),
                            ),
                            Text(
                              '@${p.handle}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: VoxoraColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (app.conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No conversations yet.\nSearch for someone to start chatting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: VoxoraColors.muted, fontSize: 13),
                ),
              ),
            )
          else
            ...app.conversations.map((conv) {
              final others = conv.members
                  .where((m) => m.id != app.profile?.id)
                  .toList();
              final isActive = app.activeConversation?.id == conv.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: VListRow(
                  isActive: isActive,
                  onTap: () => app.selectConversation(conv.id),
                  child: Row(
                    children: [
                      VAvatarStack(members: others),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: VoxoraColors.text,
                              ),
                            ),
                            Text(
                              conv.lastMessage,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _groupComposer(AppProvider app) {
    final people = app.profiles.where((p) => p.id != app.profile?.id).toList();
    final selected = people
        .where((p) => _groupMemberIds.contains(p.id))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VoxoraTheme.accentGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Group Chat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (selected.isEmpty)
            Text(
              'Select at least 2 people.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selected
                  .map(
                    (person) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: VoxoraColors.primary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: VoxoraColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            person.fullName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: VoxoraColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(
                              () => _groupMemberIds.remove(person.id),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: VoxoraColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: people.map((person) {
                  final checked = _groupMemberIds.contains(person.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (checked) {
                          _groupMemberIds.remove(person.id);
                        } else {
                          _groupMemberIds.add(person.id);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: checked
                            ? VoxoraColors.primary.withValues(alpha: 0.1)
                            : VoxoraColors.surface,
                        border: Border.all(
                          color: checked
                              ? VoxoraColors.primary.withValues(alpha: 0.3)
                              : VoxoraColors.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          VAvatar(url: person.avatarUrl, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: VoxoraColors.text,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '@${person.handle}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: VoxoraColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            checked
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: checked
                                ? VoxoraColors.primary
                                : VoxoraColors.muted,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _groupMsgC,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: VoxoraColors.text),
            decoration: const InputDecoration(
              hintText: 'First message (optional)',
              prefixIcon: Icon(
                Icons.message,
                size: 18,
                color: VoxoraColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          VGradientButton(
            label: 'Create Group',
            icon: Icons.group_add,
            fullWidth: true,
            onTap: _groupMemberIds.length < 2
                ? null
                : () async {
                    await app.createConversation(
                      _groupMemberIds.toList(),
                      firstMessage: _groupMsgC.text,
                    );
                    if (!mounted) return;
                    setState(() {
                      _groupMemberIds.clear();
                      _groupMsgC.clear();
                      _showGroupBuilder = false;
                      _search = '';
                      _searchC.clear();
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _panel(AppProvider app) {
    final conv = app.activeConversation;
    if (conv == null) {
      return VPanel(
        child: const VEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'No conversation',
          body: 'Search for someone to start chatting.',
        ),
      );
    }
    final messages = app.directMessages
        .where((m) => m.conversationId == conv.id)
        .toList();
    final others = conv.members.where((m) => m.id != app.profile?.id).toList();
    return VPanel(
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: VoxoraColors.line)),
              ),
              child: Row(
                children: [
                  VAvatarStack(members: others),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Row(
                          children: [
                            const VPulseDot(
                              color: VoxoraColors.online,
                              size: 6,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${conv.members.length} members',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 14),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final sender = conv.members
                      .where((m) => m.id == msg.senderId)
                      .firstOrNull;
                  return VMessageBubble(
                    name: msg.senderId == app.profile?.id
                        ? null
                        : sender?.fullName,
                    body: msg.body,
                    time: msg.createdAt,
                    isMine: msg.senderId == app.profile?.id,
                  );
                },
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: VoxoraColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgC,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: VoxoraColors.text,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: VoxoraColors.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: VoxoraColors.line,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: VoxoraColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: VoxoraColors.surfaceLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  VGradientIconButton(
                    icon: Icons.send,
                    onTap: _msgC.text.trim().isEmpty
                        ? null
                        : () {
                            final body = _msgC.text;
                            _msgC.clear();
                            setState(() {});
                            app.sendDirectMessage(conv.id, body);
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
}
