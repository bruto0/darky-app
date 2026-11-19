import 'package:material_ui/material_ui.dart';

import '../../core/models/account.dart';
import '../../core/ui/theme.dart';
import 'account_presentation.dart';

/// A single membership card. The freeze CTA lives *inside* the card and is
/// rendered only for accounts where [Account.freezeAvailable] is true.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.onFreeze});

  final Account account;
  final VoidCallback? onFreeze;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final counters = accountCounters(account);
    final validUntil = validUntilLabel(account.validUntil);
    final freezeReason = freezeUnavailableReason(account);

    return Container(
      key: ValueKey('account-card-${account.id}'),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: accountGradientFor(account, palette),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'АБОНЕМЕНТ',
                      style: text.labelSmall?.copyWith(
                        color: palette.ink.withValues(alpha: 0.72),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accountTitle(account),
                      style: text.titleLarge?.copyWith(
                        color: palette.ink,
                        fontSize: 21,
                        height: 24 / 21,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(label: accountStatusLabel(account)),
            ],
          ),
          const SizedBox(height: 16),
          if (counters.length == 1 &&
              account.freezeDaysTotal <= 0 &&
              account.packets.isEmpty)
            _SingleCounter(counter: counters.first)
          else
            _CounterGrid(counters: counters),
          if (validUntil != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: palette.ink2.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    validUntil,
                    style: text.bodySmall?.copyWith(
                      color: palette.ink2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (account.freezeAvailable)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey('account-freeze-${account.id}'),
                onPressed: onFreeze,
                icon: Icon(Icons.ac_unit_rounded, size: 18, color: palette.ink),
                label: const Text('Заморозить'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.surface.withValues(alpha: 0.55),
                  foregroundColor: palette.ink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: text.labelLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else if (freezeReason != null)
            Row(
              children: [
                Icon(
                  Icons.ac_unit_rounded,
                  size: 15,
                  color: palette.ink2.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    freezeReason,
                    style: text.bodySmall?.copyWith(
                      color: palette.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A compact row for closed/inactive accounts in the archive section.
class ArchiveAccountRow extends StatelessWidget {
  const ArchiveAccountRow({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final validUntil = validUntilLabel(account.validUntil);
    final details = validUntil == null
        ? '${account.visitsLeft} / ${account.visitsTotal} занятий'
        : '${account.visitsLeft} / ${account.visitsTotal} занятий · '
              '$validUntil';

    return Container(
      key: ValueKey('archive-account-${account.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 19,
              color: palette.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountTitle(account),
                  style: text.titleMedium?.copyWith(color: palette.ink2),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(label: accountStatusLabel(account)),
        ],
      ),
    );
  }
}

class _CounterGrid extends StatelessWidget {
  const _CounterGrid({required this.counters});

  final List<AccountCounter> counters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: [
            for (var index = 0; index < counters.length; index++)
              SizedBox(
                width:
                    counters.length > 1 &&
                        counters.length.isOdd &&
                        index == counters.length - 1
                    ? constraints.maxWidth
                    : half,
                child: _Counter(counter: counters[index]),
              ),
          ],
        );
      },
    );
  }
}

class _SingleCounter extends StatelessWidget {
  const _SingleCounter({required this.counter});

  final AccountCounter counter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          counter.value,
          style: text.titleLarge?.copyWith(
            color: palette.ink,
            fontSize: 24,
            height: 1.05,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            counter.label,
            style: text.bodySmall?.copyWith(
              color: palette.ink2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.counter});

  final AccountCounter counter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          counter.value,
          style: text.titleLarge?.copyWith(
            color: palette.ink,
            fontSize: 21,
            height: 1.05,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          counter.label,
          style: text.bodySmall?.copyWith(
            color: palette.ink2.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: palette.ink,
          fontSize: 9,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
