import 'package:material_ui/material_ui.dart';

import '../../core/storage/session.dart';
import '../../core/ui/theme.dart';
import '../account/account_presentation.dart';
import '../account/app_menu.dart';

/// Home header: D'arky brand line, profile row with avatar/name/bonus, QR,
/// logout and the three-dot menu to the right of logout.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.profile,
    required this.onQr,
    required this.onLogout,
  });

  final ClientProfile profile;
  final VoidCallback onQr;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'D',
                style: text.titleMedium?.copyWith(
                  color: palette.bg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "D'arky",
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Личный кабинет',
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(profile: profile),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    profileDisplayName(profile),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      fontSize: 20,
                      height: 24 / 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _BonusChip(bonus: profile.bonus),
                      Text(
                        profileBranchLine(profile),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _HeaderAction(
              icon: Icons.qr_code_2_rounded,
              tooltip: 'Показать QR-код',
              background: palette.violetSoft,
              foreground: palette.violet,
              onTap: onQr,
            ),
            const SizedBox(width: 2),
            _HeaderAction(
              icon: Icons.logout_rounded,
              tooltip: 'Выйти',
              background: Colors.transparent,
              foreground: palette.ink2,
              onTap: onLogout,
            ),
            const AppMenuButton(),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final url = profile.photoUrl?.trim();
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [palette.violet, palette.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: palette.surface.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: url == null || url.isEmpty
          ? _ProfileInitials(profile: profile)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _ProfileInitials(profile: profile),
            ),
    );
  }
}

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Text(
        profileInitials(profile),
        style: text.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  const _BonusChip({required this.bonus});

  final int bonus;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Бонусы: $bonus',
      child: Container(
        key: const ValueKey('home-bonus-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: palette.pinkSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 12, color: palette.pinkDeep),
            const SizedBox(width: 3),
            Text(
              '$bonus',
              style: text.labelSmall?.copyWith(
                color: palette.pinkDeep,
                fontSize: 10,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}
