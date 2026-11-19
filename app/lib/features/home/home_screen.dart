import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/theme_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return PlaceholderPage(
      eyebrow: 'Личный кабинет',
      title: 'Абонемент',
      subtitle: 'Здесь появятся профиль, два абонемента и расписание без вложенного скролла.',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          const _AccountPreview(),
          const SizedBox(height: 12),
          _ThemePreview(
            mode: mode,
            onSelected: (value) {
              ref.read(themeControllerProvider.notifier).setMode(value);
            },
          ),
        ],
      ),
    );
  }
}

class _AccountPreview extends StatelessWidget {
  const _AccountPreview();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.accountGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ПРОФИ',
                  style: text.labelSmall?.copyWith(
                    color: palette.ink,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Активен',
                  style: text.bodySmall?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '20 / 24',
            style: text.headlineLarge?.copyWith(
              color: palette.ink,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'занятий · заморозка 21 / 21',
            style: text.bodySmall?.copyWith(color: palette.ink2),
          ),
          const SizedBox(height: 12),
          Text(
            'до 7 февраля 2027',
            style: text.bodySmall?.copyWith(
              color: palette.ink2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode, required this.onSelected});

  final AppThemeMode mode;
  final ValueChanged<AppThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Тема оформления', style: text.titleMedium),
              ),
              Text(mode.label, style: text.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in AppThemeMode.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: value == mode,
                  onSelected: (_) => onSelected(value),
                  selectedColor: palette.pinkSoft,
                  backgroundColor: palette.bg,
                  side: BorderSide(
                    color: value == mode ? palette.pink : palette.line,
                  ),
                  labelStyle: text.bodySmall?.copyWith(
                    color: value == mode ? palette.pinkDeep : palette.ink2,
                    fontWeight: FontWeight.w700,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Временный переключатель этапа 1. В финале — меню из трёх точек справа от выхода.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
