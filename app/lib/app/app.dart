import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/ui/theme.dart';
import '../core/ui/theme_controller.dart';
import 'providers.dart';
import 'router.dart';

class DarkyApp extends ConsumerWidget {
  const DarkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final session = ref.watch(sessionControllerProvider);

    final theme = mode == AppThemeMode.pink ? AppTheme.pink : AppTheme.light;
    final darkTheme = AppTheme.dark;
    final themeMode = mode == AppThemeMode.pink
        ? ThemeMode.light
        : mode == AppThemeMode.dark
            ? ThemeMode.dark
            : mode == AppThemeMode.system
                ? ThemeMode.system
                : ThemeMode.light;

    return session.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "D'arky",
        theme: darkTheme,
        home: const _BootScreen(),
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [Locale('ru', 'RU')],
        localizationsDelegates: _delegates,
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "D'arky",
        theme: darkTheme,
        home: _BootError(
          onRetry: () => ref.invalidate(sessionControllerProvider),
        ),
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [Locale('ru', 'RU')],
        localizationsDelegates: _delegates,
      ),
      data: (_) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: "D'arky",
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        themeAnimationDuration: const Duration(milliseconds: 220),
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [Locale('ru', 'RU')],
        localizationsDelegates: _delegates,
      ),
    );
  }

  static const _delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A090E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandMark(),
            SizedBox(height: 18),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFC27BA0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0A090E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandMark(),
              const SizedBox(height: 18),
              Text(
                'Не удалось открыть приложение',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Проверьте соединение и попробуйте снова.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: const Color(0xFFB9B1C4),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Text(
        'D',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0A090E),
        ),
      ),
    );
  }
}
