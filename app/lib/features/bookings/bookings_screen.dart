import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_providers.dart';
import '../../core/models/booking.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/theme.dart';
import 'bookings_card.dart';
import 'bookings_logic.dart';

/// Upcoming bookings ("Записи") tab.
///
/// The widget API (`widget_client_lk/schedule`) is read-only for the client,
/// so there is no native cancellation: the outline button opens a confirmation
/// sheet that leads to the club cabinet in the external browser.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({
    super.key,
    this.onOpenSchedule,
    this.launchExternalUrl,
  });

  /// Overrides the default `context.go('/home')` navigation in tests.
  final VoidCallback? onOpenSchedule;

  /// Overrides `url_launcher` in tests.
  final ExternalUrlLauncher? launchExternalUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final clock = ref.watch(branchClockProvider);
    final config = ref.watch(appConfigProvider);
    final bookings = ref.watch(bookingsProvider);
    final upcoming = bookings.valueOrNull == null
        ? null
        : upcomingBookings(bookings.value!, clock);

    final String subtitle;
    if (bookings.hasValue) {
      subtitle = bookingsCountLabel(upcoming?.length ?? 0);
    } else if (bookings.hasError) {
      subtitle = 'Не удалось загрузить записи';
    } else {
      subtitle = 'Загружаем записи…';
    }

    final cabinetUri = Uri.parse('${config.baseUrl}${config.widgetPath}');
    final openSchedule = onOpenSchedule ?? () => context.go('/home');

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          children: [
            Text('Записи', style: text.headlineLarge),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: text.bodyLarge?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 18),
            ..._content(
              context: context,
              ref: ref,
              bookings: bookings,
              upcoming: upcoming,
              clock: clock,
              cabinetUri: cabinetUri,
              openSchedule: openSchedule,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<List<Booking>> bookings,
    required List<Booking>? upcoming,
    required BranchClock clock,
    required Uri cabinetUri,
    required VoidCallback openSchedule,
  }) {
    if (bookings.hasError && !bookings.hasValue) {
      return [
        _ErrorState(
          message: bookingsErrorMessage(bookings.error),
          onRetry: () => ref.invalidate(bookingsProvider),
        ),
      ];
    }
    if (bookings.isLoading && !bookings.hasValue) {
      return const [_LoadingState()];
    }

    final list = upcoming ?? const <Booking>[];
    if (list.isEmpty) {
      return [
        _EmptyState(onOpenSchedule: openSchedule),
      ];
    }

    return [
      for (var index = 0; index < list.length; index++) ...[
        if (index > 0) const SizedBox(height: 10),
        BookingCard(
          booking: list[index],
          clock: clock,
          cabinetUri: cabinetUri,
          launchExternalUrl: launchExternalUrl,
        ),
      ],
      const SizedBox(height: 12),
      const _CancellationRule(),
    ];
  }
}

class _CancellationRule extends StatelessWidget {
  const _CancellationRule();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        'Отмена доступна не позднее чем за 30 минут до начала занятия.\n'
        'Запись на групповые занятия — в расписании.',
        textAlign: TextAlign.center,
        style: text.bodySmall,
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.pink,
            ),
          ),
          const SizedBox(height: 12),
          Text('Загружаем записи…', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_outlined, color: palette.red, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Не удалось загрузить записи',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: text.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpenSchedule});

  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.pinkSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              color: palette.pinkDeep,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Пока нет записей',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Выберите занятие в расписании — запись появится здесь.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpenSchedule,
            child: const Text('Открыть расписание'),
          ),
        ],
      ),
    );
  }
}
