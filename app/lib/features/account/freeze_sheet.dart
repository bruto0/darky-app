import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/models/account.dart';
import '../../core/ui/theme.dart';
import 'account_presentation.dart';

/// The club cabinet URL used for the freeze scenario. The widget has no native
/// freeze endpoint, so the app deliberately delegates this flow to the web
/// cabinet instead of pretending a freeze API exists.
Uri freezeCabinetUri(AppConfig config) =>
    Uri.parse('${config.baseUrl}${config.widgetPath}');

Future<void> showFreezeSheet(
  BuildContext context, {
  required Account account,
  required AppConfig config,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _FreezeSheet(account: account, config: config),
  );
}

class _FreezeSheet extends StatelessWidget {
  const _FreezeSheet({required this.account, required this.config});

  final Account account;
  final AppConfig config;

  Future<void> _openCabinet(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final opened = await launchUrl(
        freezeCabinetUri(config),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Не удалось открыть браузер')),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Не удалось открыть браузер')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        22 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: palette.violetSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.ac_unit_rounded,
                  size: 22,
                  color: palette.violet,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Заморозка', style: text.titleLarge),
                    Text(
                      accountTitle(account),
                      style: text.bodySmall?.copyWith(color: palette.pinkDeep),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Заморозка оформляется в личном кабинете клуба. Приложение откроет '
            'страницу клуба в браузере — выберите «${accountTitle(account)}» '
            'и период заморозки.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: palette.pinkDeep,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.origin,
                    style: text.bodySmall?.copyWith(
                      color: palette.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _openCabinet(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Открыть кабинет клуба'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          Text(
            'Если в кабинете недоступна заморозка, обратитесь на ресепшен клуба.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
