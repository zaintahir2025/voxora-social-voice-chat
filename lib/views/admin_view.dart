import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width > 900;

    final usersPanel = VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const VSectionTitle(icon: Icons.people_outline, title: 'Users'),
      ...app.profiles.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: VPersonRow(
          person: p,
          action: p.isBlocked ? 'Unblock' : 'Block',
          onAction: () => app.toggleBlockUser(p),
          blocked: p.isBlocked,
        ),
      )),
    ]));

    final roomsPanel = VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const VSectionTitle(icon: Icons.radio, title: 'Rooms'),
      ...app.rooms.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: VoxoraColors.line),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.74),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(r.isLive ? 'Live' : 'Ended', style: Theme.of(context).textTheme.bodySmall),
            ]),
            if (r.isLive) VDangerButton(label: 'End', onTap: () => app.endRoom(r)),
          ]),
        ),
      )),
    ]));

    if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: usersPanel), const SizedBox(width: 18), Expanded(child: roomsPanel)]);
    return Column(children: [usersPanel, const SizedBox(height: 18), roomsPanel]);
  }
}
