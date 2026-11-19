import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_providers.dart';
import '../../core/models/paged.dart';
import '../../core/models/visit.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/theme.dart';
import 'visit_history_utils.dart';

/// Paginated visit history (DESIGN.md §4.4).
///
/// Pages are loaded through [visitsPageProvider] and kept alive by watching
/// every requested page, so the single [CustomScrollView] never nests another
/// scrollable. Pull-to-refresh resets the page chain and invalidates the
/// family, which also clears the repository-side state.
class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({super.key});

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> {
  final ScrollController _scrollController = ScrollController();

  int _requestedPages = 1;

  // Derived pagination facts exposed to [_onScroll]. They are refreshed on
  // every build, which is also when the provider states change.
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
    // Stop watching older pages first, so the family invalidation below does
    // not kick off requests that are dropped by the next frame anyway.
    setState(() => _requestedPages = 1);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.invalidate(visitsPageProvider);
    try {
      await ref.read(visitsPageProvider(1).future);
    } catch (_) {
      // The provider state is rendered by the error footer/state below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clock = ref.watch(branchClockProvider);

    final pages = <AsyncValue<Paged<Visit>>>[
      for (var page = 1; page <= _requestedPages; page++)
        ref.watch(visitsPageProvider(page)),
    ];
    final loadedPages = <Paged<Visit>>[
      for (final page in pages)
        if (page.hasValue) page.requireValue,
    ];
    final visits = dedupeVisits(loadedPages.expand((page) => page.items));
    final total = loadedPages.isEmpty ? 0 : loadedPages.first.total;

    final firstPage = pages.first;
    final lastPage = pages.last;
    final lastPageItems = lastPage.valueOrNull?.items;

    final hasMore = lastPageItems != null &&
        lastPageItems.isNotEmpty &&
        total > 0 &&
        visits.length < total;
    final maxPage = total <= 0 ? 1 : ((total + visitsPageSize - 1) ~/ visitsPageSize);

    _hasMore = hasMore;
    _lastPageLoading = lastPage.isLoading;
    _lastPageFailed = lastPage.hasError;
    _maxPage = maxPage;

    final initialLoading = firstPage.isLoading && !firstPage.hasValue;
    final initialError = firstPage.hasError && visits.isEmpty;
    final showList = visits.isNotEmpty;
    final refreshFailed = showList && firstPage.hasError;
    final loadingMore = showList && _requestedPages > 1 && lastPage.isLoading;
    final loadMoreFailed =
        showList && _requestedPages > 1 && lastPage.hasError;

    if (showList) {
      // Fill the viewport when the first page is shorter than the screen.
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
                  child: _VisitsHeader(
                    subtitle: loadedPages.isEmpty
                        ? 'История визитов'
                        : formatVisitsCount(total),
                  ),
                ),
              ),
              if (refreshFailed)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _RefreshErrorBanner(
                      onRetry: () => ref.invalidate(visitsPageProvider(1)),
                    ),
                  ),
                ),
              if (initialLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverList.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _VisitSkeletonCard(),
                    ),
                  ),
                )
              else if (initialError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _VisitsStateView(
                    icon: Icons.cloud_off_outlined,
                    accent: palette.red,
                    title: 'Не удалось загрузить посещения',
                    message: historyErrorText(firstPage.error),
                    actionLabel: 'Повторить',
                    onAction: () => ref.invalidate(visitsPageProvider(1)),
                  ),
                )
              else if (!showList)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _VisitsStateView(
                    icon: Icons.directions_walk_outlined,
                    accent: palette.violet,
                    title: 'Пока нет посещений',
                    message: 'Здесь появится история ваших визитов в студию.',
                    actionLabel: 'Обновить',
                    onAction: _refresh,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverList.builder(
                    itemCount: visits.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == visits.length - 1 ? 0 : 8,
                        ),
                        child: VisitCard(
                          visit: visits[index],
                          clock: clock,
                        ),
                      );
                    },
                  ),
                ),
              if (showList)
                SliverToBoxAdapter(
                  child: _VisitsFooter(
                    loading: loadingMore,
                    failed: loadMoreFailed,
                    onRetry: () =>
                        ref.invalidate(visitsPageProvider(_requestedPages)),
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

class _VisitsHeader extends StatelessWidget {
  const _VisitsHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Посещения', style: text.headlineLarge),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: text.bodyLarge?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

/// A single visit card: date, account/single chip, lesson, teachers, branch.
class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit, required this.clock});

  final Visit visit;
  final BranchClock clock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final railColor = visitStyleColor(visit) ?? palette.pink;
    final teachers = visitTeachers(visit);
    final branch = visitBranchName(visit);

    return Container(
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
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 12,
            bottom: 12,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: railColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 12, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      visitDateLabel(clock, visit),
                      style: text.bodySmall?.copyWith(
                        color: palette.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: _ServiceChip(label: visitServiceLabel(visit))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(visitTitle(visit), style: text.titleMedium),
                if (teachers != null) ...[
                  const SizedBox(height: 4),
                  _VisitMetaLine(icon: Icons.person_outline, text: teachers),
                ],
                if (branch != null) ...[
                  const SizedBox(height: 4),
                  _VisitMetaLine(icon: Icons.place_outlined, text: branch),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.pinkSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(
          color: palette.pinkDeep,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _VisitMetaLine extends StatelessWidget {
  const _VisitMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: palette.muted),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.muted,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitsFooter extends StatelessWidget {
  const _VisitsFooter({
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

class _VisitsStateView extends StatelessWidget {
  const _VisitsStateView({
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

class _VisitSkeletonCard extends StatelessWidget {
  const _VisitSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(width: 86, height: 10, color: palette.line),
          const SizedBox(height: 11),
          _SkeletonBar(width: 190, height: 14, color: palette.line),
          const SizedBox(height: 9),
          _SkeletonBar(width: 230, height: 10, color: palette.line),
          const SizedBox(height: 8),
          _SkeletonBar(width: 100, height: 10, color: palette.line),
        ],
      ),
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
