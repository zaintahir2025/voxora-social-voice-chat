import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/models.dart';

// ── Panel ──
class VPanel extends StatelessWidget {
  final Widget child;
  const VPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: VoxoraTheme.panelDecoration,
    child: child,
  );
}

// ── Section Title ──
class VSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const VSectionTitle({super.key, required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Icon(icon, size: 20, color: VoxoraColors.primary),
      const SizedBox(width: 10),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ]),
  );
}

// ── Empty State ──
class VEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const VEmptyState({super.key, required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 34, color: VoxoraColors.primary),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(body, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
    ])),
  );
}

// ── List Row ──
class VListRow extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final Widget child;
  const VListRow({super.key, this.isActive = false, this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? VoxoraColors.primary.withValues(alpha: 0.48) : VoxoraColors.line),
          borderRadius: BorderRadius.circular(8),
          gradient: isActive ? LinearGradient(colors: [VoxoraColors.primary.withValues(alpha: 0.12), VoxoraColors.cyan.withValues(alpha: 0.1)]) : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.88),
        ),
        child: child,
      ),
    ),
  );
}

// ── Person Row ──
class VPersonRow extends StatelessWidget {
  final Profile person;
  final String action;
  final VoidCallback? onAction;
  final bool blocked;
  const VPersonRow({super.key, required this.person, required this.action, this.onAction, this.blocked = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: VoxoraColors.line),
      borderRadius: BorderRadius.circular(8),
      color: blocked ? const Color(0xFFFFFBFA) : Colors.white.withValues(alpha: 0.88),
    ),
    child: Row(children: [
      VAvatar(url: person.avatarUrl, size: 42),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('@${person.handle}', style: Theme.of(context).textTheme.bodySmall),
      ])),
      VSecondaryButton(
        label: action,
        icon: blocked ? Icons.block : Icons.person_add_outlined,
        onTap: onAction,
      ),
    ]),
  );
}

// ── Avatar ──
class VAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final bool border;
  const VAvatar({super.key, this.url, this.size = 42, this.border = false});
  @override
  Widget build(BuildContext context) {
    Widget img;
    if (url != null && url!.isNotEmpty) {
      img = ClipOval(child: Image.network(url!, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback()));
    } else {
      img = _fallback();
    }
    if (border) {
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
        child: img,
      );
    }
    return img;
  }
  Widget _fallback() => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: VoxoraColors.primary.withValues(alpha: 0.15)),
    child: Icon(Icons.person, size: size * 0.5, color: VoxoraColors.primary),
  );
}

// ── Avatar Stack ──
class VAvatarStack extends StatelessWidget {
  final List<Profile> members;
  const VAvatarStack({super.key, required this.members});
  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    if (visible.isEmpty) return VAvatar(size: 42);
    return SizedBox(
      width: 42.0 + (visible.length - 1) * 24.0,
      height: 42,
      child: Stack(children: [
        for (var i = 0; i < visible.length; i++)
          Positioned(left: i * 24.0, child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: VAvatar(url: visible[i].avatarUrl, size: 38),
          )),
      ]),
    );
  }
}

// ── Message Bubble ──
class VMessageBubble extends StatelessWidget {
  final String? name;
  final String body;
  final String time;
  final bool isMine;
  const VMessageBubble({super.key, this.name, required this.body, required this.time, this.isMine = false});
  @override
  Widget build(BuildContext context) {
    String fmtTime;
    try { final d = DateTime.parse(time); fmtTime = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; } catch (_) { fmtTime = ''; }
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isMine ? null : Border.all(color: VoxoraColors.line),
          gradient: isMine ? const LinearGradient(colors: [VoxoraColors.primary, Color(0xFF274CFF)]) : null,
          color: isMine ? null : Colors.white.withValues(alpha: 0.84),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (name != null) Text(name!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isMine ? Colors.white : VoxoraColors.text)),
          Text(body, style: TextStyle(color: isMine ? Colors.white : VoxoraColors.text)),
          const SizedBox(height: 4),
          Text(fmtTime, style: TextStyle(fontSize: 11, color: isMine ? Colors.white70 : VoxoraColors.muted)),
        ]),
      ),
    );
  }
}

// ── Buttons ──
class VGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VGradientButton({super.key, required this.label, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: onTap != null ? const LinearGradient(colors: [VoxoraColors.primary, VoxoraColors.cyan]) : null,
        color: onTap == null ? VoxoraColors.muted.withValues(alpha: 0.3) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon!, size: 18, color: Colors.white), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    ),
  );
}

class VSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VSecondaryButton({super.key, required this.label, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VoxoraColors.line),
        color: Colors.white.withValues(alpha: 0.9),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon!, size: 16, color: VoxoraColors.text), const SizedBox(width: 6)],
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    ),
  );
}

class VDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VDangerButton({super.key, required this.label, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: VoxoraColors.danger),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon!, size: 16, color: Colors.white), const SizedBox(width: 6)],
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    ),
  );
}

class VGradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const VGradientIconButton({super.key, required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: onTap != null ? VoxoraColors.primary : VoxoraColors.muted.withValues(alpha: 0.3)),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}
