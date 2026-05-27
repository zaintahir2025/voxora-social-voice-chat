import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/models.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.gradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              borderColor ??
              (dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.74)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(height: 1.05),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final bool online;
  final String? seed;

  const UserAvatar({
    super.key,
    this.url,
    this.size = 42,
    this.online = false,
    this.seed,
  });

  String get _fallbackUrl {
    final s = Uri.encodeComponent(seed ?? 'voxora');
    return 'https://api.dicebear.com/9.x/lorelei/png?seed=$s&backgroundColor=ff5a5f,00a699,ffb400,ff4b4b,f97316';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveUrl = url == null || url!.isEmpty ? _fallbackUrl : url!;
    
    final avatar = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all((size * 0.045).clamp(1.5, 3.0)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary,
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            effectiveUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.person, color: scheme.primary),
            ),
          ),
        ),
      ),
    );

    if (!online) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: BoxDecoration(
              color: VoxoraColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: VoxoraColors.green.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AvatarStack extends StatelessWidget {
  final List<Profile> members;
  final double size;

  const AvatarStack({super.key, required this.members, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    if (visible.isEmpty) return UserAvatar(size: size);
    return SizedBox(
      width: size + (visible.length - 1) * (size * 0.58),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * size * 0.58,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: UserAvatar(url: visible[i].avatarUrl, size: size, seed: visible[i].handle),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: SizedBox(
        height: 260,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String? name;
  final String body;
  final String createdAt;
  final bool mine;
  final String? receipt;

  const MessageBubble({
    super.key,
    this.name,
    required this.body,
    required this.createdAt,
    required this.mine,
    this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = _time(createdAt);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(mine ? 8 : 2),
            bottomRight: Radius.circular(mine ? 2 : 8),
          ),
          border: mine
              ? null
              : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null) ...[
              Text(
                name!,
                style: TextStyle(
                  color: mine ? Colors.white : scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              body,
              style: TextStyle(
                color: mine ? Colors.white : scheme.onSurface,
                height: 1.35,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: mine ? Colors.white70 : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (mine && (receipt?.isNotEmpty ?? false)) ...[
                    const SizedBox(width: 7),
                    Icon(
                      receipt == 'Sent' ? Icons.done : Icons.done_all,
                      size: 13,
                      color: mine ? Colors.white70 : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      receipt!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mine ? Colors.white70 : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _time(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class CountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const CountChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effective = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effective.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effective.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: effective),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Color.alphaBlend(
                effective.withValues(alpha: 0.18),
                scheme.onSurface,
              ),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class UserStatusChip extends StatelessWidget {
  final String status;

  const UserStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    return CountChip(
      icon: normalized == 'online'
          ? Icons.circle
          : normalized == 'away'
          ? Icons.schedule
          : Icons.circle_outlined,
      label: switch (normalized) {
        'online' => 'Online',
        'away' => 'Away',
        _ => 'Offline',
      },
      color: switch (normalized) {
        'online' => VoxoraColors.green,
        'away' => VoxoraColors.amber,
        _ => VoxoraColors.slate,
      },
    );
  }
}

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: (color ?? scheme.primary).withValues(alpha: 0.09),
          foregroundColor: color ?? scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
