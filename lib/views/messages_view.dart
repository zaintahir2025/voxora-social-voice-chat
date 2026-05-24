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

  @override
  void dispose() {
    _msgC.dispose();
    _searchC.dispose();
    _groupMsgC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width > 900;
    if (isWide) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 360, child: _list(app)),
        const SizedBox(width: 18),
        Expanded(child: _panel(app)),
      ]);
    }
    return Column(children: [_list(app), const SizedBox(height: 18), _panel(app)]);
  }

  Widget _list(AppProvider app) {
    final candidates = app.profiles.where((p) =>
        p.id != app.profile?.id &&
        '${p.fullName} ${p.handle}'.toLowerCase().contains(_search.toLowerCase())).toList();

    return VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: VSectionTitle(icon: Icons.chat_bubble_outline, title: 'Messages')),
        VSecondaryButton(
          label: _showGroupBuilder ? 'Close' : 'New group',
          icon: _showGroupBuilder ? Icons.close : Icons.group_add_outlined,
          onTap: () => setState(() => _showGroupBuilder = !_showGroupBuilder),
        ),
      ]),
      if (_showGroupBuilder) ...[
        _groupComposer(app),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: VoxoraColors.line), borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Row(children: [
          const Icon(Icons.search, size: 18, color: VoxoraColors.muted),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _searchC, onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Find people', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      if (_search.isNotEmpty)
        ...candidates.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8),
          child: VPersonRow(person: p, action: 'Message', onAction: () => app.startConversation(p))))
      else
        ...app.conversations.map((conv) {
          final others = conv.members.where((m) => m.id != app.profile?.id).toList();
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: VListRow(
            isActive: app.activeConversation?.id == conv.id,
            onTap: () => app.selectConversation(conv.id),
            child: Row(children: [
              VAvatarStack(members: others), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(conv.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(conv.lastMessage, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ));
        }),
    ]));
  }

  Widget _groupComposer(AppProvider app) {
    final people = app.profiles.where((p) => p.id != app.profile?.id).toList();
    final selected = people.where((p) => _groupMemberIds.contains(p.id)).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: VoxoraColors.primary.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(colors: [
          VoxoraColors.primary.withValues(alpha: 0.08),
          VoxoraColors.cyan.withValues(alpha: 0.08),
        ]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create group', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (selected.isEmpty)
          Text('Choose at least two people.', style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((person) => Chip(
              visualDensity: VisualDensity.compact,
              label: Text(person.fullName),
              onDeleted: () => setState(() => _groupMemberIds.remove(person.id)),
            )).toList(),
          ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Column(children: people.map((person) {
              final checked = _groupMemberIds.contains(person.id);
              return CheckboxListTile(
                value: checked,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: VoxoraColors.primary,
                title: Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('@${person.handle}'),
                secondary: VAvatar(url: person.avatarUrl, size: 34),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _groupMemberIds.add(person.id);
                    } else {
                      _groupMemberIds.remove(person.id);
                    }
                  });
                },
              );
            }).toList()),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _groupMsgC,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'First message'),
        ),
        const SizedBox(height: 10),
        VGradientButton(
          label: 'Create group',
          icon: Icons.group_add_outlined,
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
      ]),
    );
  }

  Widget _panel(AppProvider app) {
    final conv = app.activeConversation;
    if (conv == null) return VPanel(child: const VEmptyState(icon: Icons.chat_bubble_outline, title: 'No conversation', body: 'Search for someone to chat.'));
    final messages = app.directMessages.where((m) => m.conversationId == conv.id).toList();
    final others = conv.members.where((m) => m.id != app.profile?.id).toList();
    return VPanel(child: SizedBox(height: 500, child: Column(children: [
      Container(
        padding: const EdgeInsets.only(bottom: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VoxoraColors.line))),
        child: Row(children: [
          VAvatarStack(members: others), const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(conv.title, style: Theme.of(context).textTheme.titleLarge),
            Text('${conv.members.length} members', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 14), itemCount: messages.length,
        itemBuilder: (_, i) {
          final msg = messages[i];
          final sender = conv.members.where((m) => m.id == msg.senderId).firstOrNull;
          return VMessageBubble(
            name: msg.senderId == app.profile?.id ? null : sender?.fullName,
            body: msg.body,
            time: msg.createdAt,
            isMine: msg.senderId == app.profile?.id,
          );
        },
      )),
      Row(children: [
        Expanded(child: TextField(
          controller: _msgC,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Type a message'),
        )),
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
      ]),
    ])));
  }
}
