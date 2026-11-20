import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Абонемент',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_walk_outlined),
            selectedIcon: Icon(Icons.directions_walk),
            label: 'Посещения',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Покупки',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars),
            label: 'Баллы',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Записи',
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.ink,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'D',
                    style: text.titleMedium?.copyWith(
                      color: palette.bg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "D'arky",
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(eyebrow.toUpperCase(), style: text.labelSmall),
            const SizedBox(height: 6),
            Text(title, style: text.headlineLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: text.bodyLarge),
            const SizedBox(height: 22),
            child ?? const SizedBox.shrink(),
            const SizedBox(height: 18),
            _ContractCard(icon: icon),
          ],
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.violetSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 21, color: palette.violet),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Раздел в разработке', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Каркас, темы и контракты готовы. Экран собирается на следующем этапе.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
