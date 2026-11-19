import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_providers.dart';
import '../../core/models/deposit.dart';
import '../../core/models/paged.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/theme.dart';
import 'deposit_history_utils.dart';

/// Paginated purchases history grouped by month (DESIGN.md §4.5).
///
/// Pages are loaded through [depositsPageProvider]; the whole screen is one
/// [CustomScrollView] with no nested scrollables. Pull-to-refresh resets the
/// page chain and invalidates the family.
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final ScrollController _scrollController = ScrollController();

  int _requestedPages = 1;

  bool _hasMore = false;
  bool _lastPageLoading = false;
  bool _lastPageFailed = false;
  int _maxPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 360) return;
    _maybeLoadMore();
  }

  void _maybeLoadMore() {
    if (!_hasMore || _lastPageLoading || _lastPageFailed) return;
    if (_requestedPages >= _maxPage) return;
    // Block repeated scroll events between the setState and the next build.
    _lastPageLoading = true;
    setState(() => _requestedPages += 1);
  }

  Future<void> _refresh() async {
    setState(() => _requestedPages = 1);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.invalidate(depositsPageProvider);
    try {
      await ref.read(depositsPageProvider(1).future);
    } catch (_) {
      // The provider state is rendered by the error footer/state below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clock = ref.watch(branchClockProvider);

    final pages = <AsyncValue<Paged<Deposit>>>[
      for (var page = 1; page <= _requestedPages; page++)
        ref.watch(depositsPageProvider(page)),
    ];
    final loadedPages = <Paged<Deposit>>[
      for (final page in pages)
        if (page.hasValue) page.requireValue,
    ];
    final deposits = dedupeDeposits(loadedPages.expand((page) => page.items));
    final groups = groupDepositsByMonth(deposits, clock);
    final total = loadedPages.isEmpty ? 0 : loadedPages.first.total;

    final firstPage = pages.first;
    final lastPage = pages.last;
    final lastPageItems = lastPage.valueOrNull?.items;

    final hasMore = lastPageItems != null &&
        lastPageItems.isNotEmpty &&
        total > 0 &&
        deposits.length < total;
    final maxPage =
        total <= 0 ? 1 : ((total + depositsPageSize - 1) ~/ depositsPageSize);

    _hasMore = hasMore;
    _lastPageLoading = lastPage.isLoading;
    _lastPageFailed = lastPage.hasError;
    _maxPage = maxPage;

    final initialLoading = firstPage.isLoading && !firstPage.hasValue;
    final initialError = firstPage.hasError && deposits.isEmpty;
    final showList = deposits.isNotEmpty;
    final refreshFailed = showList && firstPage.hasError;
    final loadingMore = showList && _requestedPages > 1 && lastPage.isLoading;
    final loadMoreFailed =
        showList && _requestedPages > 1 && lastPage.hasError;

    if (showList) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_hasMore || _lastPageLoading || _lastPageFailed) return;
        if (_requestedPages >= _maxPage) return;
        if (!_scrollController.hasClients) return;
        if (_scrollController.position.extentAfter < 320) _maybeLoadMore();
      });
    }

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.pinkDeep,
          backgroundColor: palette.surface,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _PurchasesHeader(
                    subtitle: loadedPages.isEmpty
                        ? 'Оплата и пополнения'
                        : formatPurchasesSubtitle(total),
                  ),
                ),
              ),
              if (refreshFailed)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _RefreshErrorBanner(
                      onRetry: () => ref.invalidate(depositsPageProvider(1)),
                    ),
                  ),
                ),
              if (initialLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverList.builder(
                    itemCount: 2,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _PurchasesSkeletonSection(),
                    ),
                  ),
                )
              else if (initialError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _PurchasesStateView(
                    icon: Icons.cloud_off_outlined,
                    accent: palette.red,
                    title: 'Не удалось загрузить покупки',
                    message: historyErrorText(firstPage.error),
                    actionLabel: 'Повторить',
                    onAction: () => ref.invalidate(depositsPageProvider(1)),
                  ),
                )
              else if (!showList)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _PurchasesStateView(
                    icon: Icons.shopping_bag_outlined,
                    accent: palette.violet,
                    title: 'Покупок пока нет',
                    message:
                        'Здесь появятся оплаты и пополнения счёта в студии.',
                    actionLabel: 'Обновить',
                    onAction: _refresh,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) => _DepositMonthSection(
                      group: groups[index],
                      clock: clock,
                    ),
                  ),
                ),
              if (showList)
                SliverToBoxAdapter(
                  child: _PurchasesFooter(
                    loading: loadingMore,
                    failed: loadMoreFailed,
                    onRetry: () =>
                        ref.invalidate(depositsPageProvider(_requestedPages)),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchasesHeader extends StatelessWidget {
  const _PurchasesHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Покупки', style: text.headlineLarge),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: text.bodyLarge?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class _DepositMonthSection extends StatelessWidget {
  const _DepositMonthSection({required this.group, required this.clock});

  final DepositMonthGroup group;
  final BranchClock clock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(
            group.label,
            style: text.bodySmall?.copyWith(
              color: palette.muted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: palette.line),
            boxShadow: [
              BoxShadow(
                color: palette.ink.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var index = 0; index < group.deposits.length; index++) ...[
                if (index > 0)
                  Divider(height: 1, thickness: 1, color: palette.line),
                _DepositRow(deposit: group.deposits[index], clock: clock),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DepositRow extends StatelessWidget {
  const _DepositRow({required this.deposit, required this.clock});

  final Deposit deposit;
  final BranchClock clock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final paymentLine = depositPaymentLine(deposit);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              depositRowDate(clock, deposit),
              style: text.bodySmall?.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(depositTitle(deposit), style: text.titleMedium),
                if (paymentLine != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    paymentLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: palette.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            depositAmountLabel(deposit),
            style: text.titleMedium?.copyWith(
              color: palette.green,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchasesFooter extends StatelessWidget {
  const _PurchasesFooter({
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    if (loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: palette.pinkDeep,
              ),
            ),
            const SizedBox(width: 10),
            Text('Загружаем ещё', style: text.bodySmall),
          ],
        ),
      );
    }
    if (failed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            Text(
              'Не удалось загрузить ещё',
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: palette.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Не удалось обновить. Показаны прежние данные.',
              style: text.bodySmall?.copyWith(color: palette.ink2),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _PurchasesStateView extends StatelessWidget {
  const _PurchasesStateView({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _PurchasesSkeletonSection extends StatelessWidget {
  const _PurchasesSkeletonSection();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBar(width: 110, height: 10, color: palette.line),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: palette.line),
          ),
          child: Column(
            children: [
              for (var row = 0; row < 3; row++) ...[
                if (row > 0) const SizedBox(height: 18),
                Row(
                  children: [
                    _SkeletonBar(width: 34, height: 10, color: palette.line),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SkeletonBar(
                        width: double.infinity,
                        height: 12,
                        color: palette.line,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _SkeletonBar(width: 66, height: 12, color: palette.line),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
