import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/ui/theme.dart';
import '../../core/ui/theme_controller.dart';

/// Designed 2x2 theme chooser from the three-dot menu. Every tap applies the
/// theme immediately through [themeControllerProvider]; "Готово" only closes.
Future<void> showThemeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) => const ThemeDialog(),
  );
}

class ThemeDialog extends ConsumerWidget {
  const ThemeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final selected = ref.watch(themeControllerProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: palette.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Тема оформления', style: text.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.bg,
                      minimumSize: const Size(40, 40),
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: palette.ink2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Оформление применится сразу',
                style: text.bodySmall?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final mode in AppThemeMode.selectable)
                        SizedBox(
                          width: cardWidth,
                          child: _ThemeCard(
                            mode: mode,
                            selected: mode == selected,
                            onTap: () => ref
                                .read(themeControllerProvider.notifier)
                                .setMode(mode),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Готово'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Тема ${mode.label}',
      child: InkWell(
        key: ValueKey('theme-card-${mode.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? palette.pinkSoft.withValues(alpha: 0.55)
                : palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.pink : palette.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemePreview(mode: mode),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mode.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontSize: 13.5,
                        color: selected ? palette.pinkDeep : palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('theme-check-${mode.name}'),
                      size: 18,
                      color: palette.pinkDeep,
                    )
                  else
                    Text(
                      _themeTag(mode),
                      style: text.bodySmall?.copyWith(color: palette.muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _themeTag(AppThemeMode mode) => switch (mode) {
  AppThemeMode.light => 'Свет',
  AppThemeMode.dark => 'Графит',
  AppThemeMode.pink => 'Бренд',
  AppThemeMode.system => 'Авто',
};

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode});

  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        height: 72,
        child: switch (mode) {
          AppThemeMode.light => _PreviewBody(palette: AppPalette.light),
          AppThemeMode.dark => _PreviewBody(palette: AppPalette.dark),
          AppThemeMode.pink => _PreviewBody(palette: AppPalette.pinkBrand),
          AppThemeMode.system => const Row(
            children: [
              Expanded(child: _PreviewBody(palette: AppPalette.light)),
              Expanded(child: _PreviewBody(palette: AppPalette.dark)),
            ],
          ),
        },
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget line({required double height, double? widthFactor}) {
      final line = Container(
        height: height,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(2),
        ),
      );
      if (widthFactor == null) return line;
      return FractionallySizedBox(widthFactor: widthFactor, child: line);
    }

    return Container(
      color: palette.bg,
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: palette.violet,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.accountGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 6),
          line(height: 5),
          const SizedBox(height: 3),
          line(height: 4, widthFactor: 0.58),
        ],
      ),
    );
  }
}
