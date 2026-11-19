import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_providers.dart';
import '../../core/models/account.dart';
import '../../core/network/api_failure.dart';
import '../../core/ui/theme.dart';
import '../account/account_card.dart';
import '../account/account_presentation.dart';
import '../account/freeze_sheet.dart';
import '../account/logout_sheet.dart';
import '../account/qr_sheet.dart';
import '../schedule/schedule_fab.dart';
import '../schedule/schedule_section.dart';
import 'home_header.dart';

/// Account/profile home. The whole page is one [CustomScrollView] owned by
/// Home; the schedule section (implemented in `features/schedule`) contributes
/// slivers to the same scroll view and never needs a nested scrollable.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final session = ref.watch(sessionControllerProvider).valueOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.pink,
              ),
            ),
          ),
        ),
      );
    }

    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                color: palette.pink,
                backgroundColor: palette.surface,
                onRefresh: () async {
                  ref.invalidate(accountsProvider);
                  try {
                    await ref.read(accountsProvider.future);
                  } catch (_) {
                    // The error state below already explains the failure.
                  }
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: HomeHeader(
                          profile: session.profile,
                          onQr: () => showQrSheet(
                            context,
                            clientName: profileDisplayName(session.profile),
                          ),
                          onLogout: () => _logout(context, ref),
                        ),
                      ),
                    ),
                    ..._accountSlivers(context, ref, accounts),
                    const ScheduleSection(bottomPadding: 96),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: ScheduleFab()),
          ],
        ),
      ),
    );
  }

  List<Widget> _accountSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Account>> accounts,
  ) {
    if (!accounts.hasValue && accounts.hasError) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _AccountsError(
              error: accounts.error!,
              onRetry: () => ref.invalidate(accountsProvider),
            ),
          ),
        ),
      ];
    }
    if (!accounts.hasValue) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _AccountsLoading()),
        ),
      ];
    }

    final data = accounts.value ?? const <Account>[];
    if (data.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _EmptyAccounts(
              onRefresh: () => ref.invalidate(accountsProvider),
            ),
          ),
        ),
      ];
    }

    final active = [
      for (final account in data)
        if (account.isActive) account,
    ];
    final archived = [
      for (final account in data)
        if (!account.isActive) account,
    ];
    final config = ref.read(appConfigProvider);

    return [
      if (active.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _NoActiveAccounts()),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final account = active[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == active.length - 1 ? 0 : 10,
                ),
                child: AccountCard(
                  account: account,
                  onFreeze: () => showFreezeSheet(
                    context,
                    account: account,
                    config: config,
                  ),
                ),
              );
            }, childCount: active.length),
          ),
        ),
      if (archived.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ArchiveSection(accounts: archived),
          ),
        ),
    ];
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showLogoutSheet(context);
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(sessionControllerProvider.notifier).logout();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выйти. Попробуйте снова.')),
      );
    }
  }
}

class _AccountsLoading extends StatelessWidget {
  const _AccountsLoading();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Загружаем абонементы',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonCard(height: 158, palette: palette),
          const SizedBox(height: 10),
          _SkeletonCard(height: 124, palette: palette),
          const SizedBox(height: 10),
          Text(
            'Загружаем абонементы…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height, required this.palette});

  final double height;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double blockHeight) {
      return Container(
        width: width,
        height: blockHeight,
        decoration: BoxDecoration(
          color: palette.line.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(74, 8),
          const SizedBox(height: 12),
          block(170, 17),
          const Spacer(),
          Row(
            children: [block(78, 18), const SizedBox(width: 24), block(78, 18)],
          ),
          const SizedBox(height: 8),
          block(128, 8),
        ],
      ),
    );
  }
}

class _AccountsError extends StatelessWidget {
  const _AccountsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('accounts-error'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.pinkSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 21,
                  color: palette.red,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Не удалось загрузить абонементы',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(_accountsErrorMessage(error), style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.violetSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 22,
              color: palette.violet,
            ),
          ),
          const SizedBox(height: 13),
          Text('Абонементов пока нет', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Когда клуб оформит абонемент, он появится здесь.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Обновить'),
          ),
        ],
      ),
    );
  }
}

class _NoActiveAccounts extends StatelessWidget {
  const _NoActiveAccounts();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Активных абонементов нет. Закрытые абонементы — в архиве.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveSection extends StatelessWidget {
  const _ArchiveSection({required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: palette.muted),
            const SizedBox(width: 7),
            Text(
              'Архив',
              style: text.titleMedium?.copyWith(color: palette.ink2),
            ),
            const Spacer(),
            Text('${accounts.length}', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < accounts.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == accounts.length - 1 ? 0 : 8,
            ),
            child: ArchiveAccountRow(account: accounts[index]),
          ),
      ],
    );
  }
}

String _accountsErrorMessage(Object error) {
  if (error is ApiFailure && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return 'Проверьте соединение и попробуйте снова.';
}
