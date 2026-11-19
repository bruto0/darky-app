import 'package:material_ui/material_ui.dart';

import '../../core/ui/theme.dart';

/// Confirmation sheet for the destructive session action. Returns `true` when
/// the user confirms logout.
Future<bool?> showLogoutSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _LogoutSheet(),
  );
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

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
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.pinkSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.logout_rounded, size: 22, color: palette.red),
          ),
          const SizedBox(height: 14),
          Text('Выйти из кабинета?', style: text.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Сессия и сохранённые данные будут очищены. Для входа снова '
            'понадобится телефон и пароль.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: palette.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Выйти'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Остаться'),
          ),
        ],
      ),
    );
  }
}
