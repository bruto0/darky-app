import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/ui/theme.dart';
import 'theme_dialog.dart';

enum AppMenuAction { theme, about }

/// The `⋮` menu that sits to the right of logout in the home header.
class AppMenuButton extends ConsumerWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final config = ref.watch(appConfigProvider);

    return PopupMenuButton<AppMenuAction>(
      key: const ValueKey('home-app-menu'),
      tooltip: 'Ещё',
      icon: Icon(Icons.more_vert_rounded, size: 22, color: palette.ink),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 252, maxWidth: 300),
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      offset: const Offset(-8, 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.line),
      ),
      onSelected: (action) {
        switch (action) {
          case AppMenuAction.theme:
            showThemeDialog(context);
            break;
          case AppMenuAction.about:
            showAboutAppDialog(context, config);
            break;
        }
      },
      itemBuilder: (menuContext) => [
        PopupMenuItem<AppMenuAction>(
          value: AppMenuAction.theme,
          height: 54,
          child: Row(
            children: [
              _MenuIcon(
                icon: Icons.palette_outlined,
                background: palette.pinkSoft,
                foreground: palette.pinkDeep,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Тема оформления',
                  style: text.bodyLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: palette.muted),
            ],
          ),
        ),
        PopupMenuItem<AppMenuAction>(
          value: AppMenuAction.about,
          height: 54,
          child: Row(
            children: [
              _MenuIcon(
                icon: Icons.info_outline_rounded,
                background: palette.violetSoft,
                foreground: palette.violet,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'О приложении',
                  style: text.bodyLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<AppMenuAction>(
          enabled: false,
          height: 48,
          child: Row(
            children: [
              Text(
                "D'arky ${config.appVersion}",
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
              const Spacer(),
              Text(
                'Android 15+',
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: foreground),
    );
  }
}

Future<void> showAboutAppDialog(BuildContext context, AppConfig config) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) => _AboutAppDialog(config: config),
  );
}

Future<void> _openClubLink(BuildContext context, String url) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть браузер')),
    );
  }
}

class _AboutAppDialog extends StatelessWidget {
  const _AboutAppDialog({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: palette.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.ink,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'D',
                      style: text.titleLarge?.copyWith(color: palette.bg),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("D'arky", style: text.titleLarge),
                        Text(
                          'Мобильный кабинет клуба',
                          style: text.bodySmall?.copyWith(color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Абонементы, расписание, посещения и записи D\'arky Dance '
                'в одном приложении.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 16),
              _AboutRow(label: 'Версия', value: config.appVersion),
              _AboutRow(label: 'Платформа', value: 'Android 15+'),
              _AboutRow(
                label: 'Клуб',
                value: config.origin,
                onTap: () => _openClubLink(context, config.origin),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final valueWidget = Text(
      value,
      textAlign: TextAlign.end,
      style: text.bodySmall?.copyWith(
        color: onTap == null ? palette.ink2 : palette.pinkDeep,
        fontWeight: FontWeight.w700,
        decoration: onTap == null ? null : TextDecoration.underline,
        decorationColor: palette.pinkDeep,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: palette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: onTap == null
                ? valueWidget
                : Semantics(
                    button: true,
                    link: true,
                    label: 'Открыть $value в браузере',
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: valueWidget,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
