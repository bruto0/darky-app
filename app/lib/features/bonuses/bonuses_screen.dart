import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_providers.dart';
import '../../core/models/bonus.dart';
import '../../core/models/paged.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/plural.dart';
import '../../core/ui/theme.dart';
import 'bonus_history_utils.dart';

/// Bonus history ("Баллы") tab: current balance, then accrual/spending rows
/// grouped by month and sorted newest first.
class BonusesScreen extends ConsumerStatefulWidget {
  const BonusesScreen({super.key});

  @override
  ConsumerState<BonusesScreen> createState() => _BonusesScreenState();
}

class _BonusesScreenState extends ConsumerState<BonusesScreen> {
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
    _lastPageLoading = true;
    setState(() => _requestedPages += 1);
  }

  Future<void> _refresh() async {
    setState(() => _requestedPages = 1);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.invalidate(bonusesPageProvider);
    try {
      await ref.read(bonusesPageProvider(1).future);
    } catch (_) {
      // The provider state renders the error below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final clock = ref.watch(branchClockProvider);
    final session = ref.watch(sessionControllerProvider).valueOrNull;

    final pages = <AsyncValue<Paged<Bonus>>>[
      for (var page = 1; page <= _requestedPages; page++)
        ref.watch(bonusesPageProvider(page)),
    ];
    final loadedPages = <Paged<Bonus>>[
      for (final page in pages)
        if (page.hasValue) page.requireValue,
    ];
    final bonuses = sortBonusesNewestFirst(
      dedupeBonuses(loadedPages.expand((page) => page.items)),
    );
    final groups = groupBonusesByMonth(bonuses, clock);
    final total = loadedPages.isEmpty ? 0 : loadedPages.first.total;

    final firstPage = pages.first;
    final lastPage = pages.last;
    final lastPageItems = lastPage.valueOrNull?.items;
    final hasMore = lastPageItems != null &&
        lastPageItems.isNotEmpty &&
        total > 0 &&
        bonuses.length < total;
    final maxPage =
        total <= 0 ? 1 : ((total + bonusesPageSize - 1) ~/ bonusesPageSize);

    _hasMore = hasMore;
    _lastPageLoading = lastPage.isLoading;
    _lastPageFailed = lastPage.hasError;
    _maxPage = maxPage;

    final initialLoading = firstPage.isLoading && !firstPage.hasValue;
    final initialError = firstPage.hasError && bonuses.isEmpty;
    final showList = bonuses.isNotEmpty;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'БАЛЛЫ',
                        style: text.labelSmall?.copyWith(
                          color: palette.pinkDeep,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('Баллы', style: text.headlineLarge),
                      const SizedBox(height: 5),
                      Text(
                        'История начислений и списаний',
                        style: text.bodySmall?.copyWith(color: palette.muted),
                      ),
                      const SizedBox(height: 16),
                      _TotalBonusCard(
                        value: session?.profile.bonus ?? 0,
                      ),
                    ],
                  ),
                ),
              ),
              if (initialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (initialError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateCard(
                    title: 'Не удалось загрузить баллы',
                    message: 'Проверьте подключение и попробуйте ещё раз.',
                    action: 'Повторить',
                    onAction: _refresh,
                    icon: Icons.cloud_off_outlined,
                  ),
                )
              else if (!showList)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateCard(
                    title: 'Пока нет баллов',
                    message: 'Здесь появятся начисления и списания бонусных баллов.',
                    icon: Icons.stars_outlined,
                  ),
                )
              else ...[
                for (final group in groups) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        group.label,
                        style: text.labelSmall?.copyWith(
                          color: palette.muted,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: group.bonuses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 1),
                      itemBuilder: (context, index) => _BonusRow(
                        bonus: group.bonuses[index],
                        clock: clock,
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: loadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : loadMoreFailed
                            ? TextButton(
                                onPressed: _maybeLoadMore,
                                child: const Text('Повторить загрузку'),
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalBonusCard extends StatelessWidget {
  const _TotalBonusCard({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.ink, palette.pinkDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ВСЕГО БАЛЛОВ',
                  style: text.labelSmall?.copyWith(
                    color: palette.bg.withValues(alpha: 0.82),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: text.headlineMedium?.copyWith(
                    color: palette.bg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPoints(value),
                  style: text.bodySmall?.copyWith(
                    color: palette.bg.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.bg.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.star_rounded, color: palette.yellow, size: 28),
          ),
        ],
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  const _BonusRow({required this.bonus, required this.clock});

  final Bonus bonus;
  final BranchClock clock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final positive = bonus.signedAmount > 0;
    final amountColor = positive ? palette.green : palette.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              bonusRowDate(clock, bonus),
              style: text.bodySmall?.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bonusDescription(bonus),
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            bonusAmountLabel(bonus),
            style: text.bodyMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: palette.muted),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: text.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
