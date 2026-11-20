import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/booking.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/theme.dart';
import 'bookings_logic.dart';

/// Opens a URL in the external browser. Injected in tests to avoid the
/// platform channel.
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternally(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Upcoming booking card: date badge, type, hall, branch, time and weekday.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.clock,
    required this.cabinetUri,
    this.launchExternalUrl,
  });

  final Booking booking;
  final BranchClock clock;
  final Uri cabinetUri;
  final ExternalUrlLauncher? launchExternalUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final start = bookingStart(clock, booking);
    final caption = bookingCaption(booking).toUpperCase();
    final title = bookingTitle(booking);
    final branch = bookingBranch(booking);
    final showCaption = caption != title.toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (start != null) ...[
                _DateBadge(date: start),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCaption) ...[
                      Text(
                        caption,
                        style: text.labelSmall?.copyWith(
                          color: palette.pinkDeep,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      title,
                      style: text.titleLarge?.copyWith(
                        fontSize: 19,
                        height: 1.15,
                      ),
                    ),
                    if (branch != null) ...[
                      const SizedBox(height: 4),
                      Text(branch, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(_typeIcon, size: 20, color: palette.muted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: palette.muted,
              ),
              const SizedBox(width: 7),
              Text(
                bookingTimeRange(clock, booking),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (start != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '· ${clock.weekdayFull(start)}',
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (booking.isRent)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Для отмены свяжитесь с администратором',
                textAlign: TextAlign.right,
                style: text.bodySmall?.copyWith(
                  color: palette.ink2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: () {
                showBookingCancellationSheet(
                  context,
                  booking: booking,
                  clock: clock,
                  cabinetUri: cabinetUri,
                  launchExternalUrl: launchExternalUrl,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.red,
                side: BorderSide(color: palette.red.withValues(alpha: 0.5)),
                minimumSize: const Size(44, 46),
                textStyle: text.labelLarge?.copyWith(
                  color: palette.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Отменить запись'),
            ),
        ],
      ),
    );
  }

  IconData get _typeIcon {
    if (booking.isRent) return Icons.home_outlined;
    if (booking.isIndividual) return Icons.person_outline;
    return Icons.groups_outlined;
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: palette.pinkSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.day}',
            style: text.titleLarge?.copyWith(
              color: palette.pinkDeep,
              fontSize: 22,
              height: 1.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            bookingMonthShort(date),
            style: text.labelSmall?.copyWith(
              color: palette.pinkDeep,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Informational sheet shown by "Отменить запись".
///
/// The widget API does not expose a confirmed cancellation endpoint
/// (`widget_client_lk/schedule` is read-only for the client), so the sheet
/// explains the club-cabinet flow and opens it in the external browser.
Future<void> showBookingCancellationSheet(
  BuildContext context, {
  required Booking booking,
  required BranchClock clock,
  required Uri cabinetUri,
  ExternalUrlLauncher? launchExternalUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    builder: (sheetContext) {
      return _CancellationSheet(
        booking: booking,
        clock: clock,
        cabinetUri: cabinetUri,
        launchExternalUrl: launchExternalUrl,
      );
    },
  );
}

class _CancellationSheet extends StatelessWidget {
  const _CancellationSheet({
    required this.booking,
    required this.clock,
    required this.cabinetUri,
    this.launchExternalUrl,
  });

  final Booking booking;
  final BranchClock clock;
  final Uri cabinetUri;
  final ExternalUrlLauncher? launchExternalUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final start = bookingStart(clock, booking);
    final summary = [
      bookingCaption(booking),
      if (start != null) bookingDateBadge(start),
      bookingTimeRange(clock, booking),
    ].join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Отмена записи', style: text.titleLarge),
          const SizedBox(height: 8),
          Text(summary, style: text.bodyMedium?.copyWith(color: palette.muted)),
          const SizedBox(height: 12),
          Text(
            'В приложении отмена пока недоступна. Откройте личный кабинет '
            'клуба в браузере и выберите «Отменить запись».',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.pinkSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 17, color: palette.pinkDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Отмена доступна не позднее чем за 30 минут до начала '
                    'занятия.',
                    style: text.bodySmall?.copyWith(color: palette.ink2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _openCabinet(context),
            child: const Text('Открыть кабинет клуба'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCabinet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final launcher = launchExternalUrl ?? _launchExternally;
    Navigator.of(context).pop();
    var opened = false;
    try {
      opened = await launcher(cabinetUri);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось открыть браузер')),
      );
    }
  }
}
