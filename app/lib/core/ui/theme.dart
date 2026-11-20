import 'package:material_ui/material_ui.dart';

enum AppThemeMode {
  light,
  dark,
  pink,
  system;

  String get storageValue => name;

  String get label => switch (this) {
        AppThemeMode.light => 'Светлая',
        AppThemeMode.dark => 'Тёмная',
        AppThemeMode.pink => 'Розовая',
        AppThemeMode.system => 'Системная',
      };

  String get description => switch (this) {
        AppThemeMode.light => 'Тёплый светлый фон и розовый акцент',
        AppThemeMode.dark => 'Графит и мягкий розово-фиолетовый свет',
        AppThemeMode.pink => 'Брендовая розовая тема клуба',
        AppThemeMode.system => 'Как в настройках Android',
      };

  static const selectable = [AppThemeMode.light, AppThemeMode.dark];

  static AppThemeMode normalize(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? AppThemeMode.dark : AppThemeMode.light;

  static AppThemeMode fromStorage(String? value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.light,
    );
  }
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.line,
    required this.pink,
    required this.pinkDeep,
    required this.pinkSoft,
    required this.violet,
    required this.violetSoft,
    required this.green,
    required this.red,
    required this.yellow,
    required this.scheduleBg,
    required this.navSurface,
    required this.accountGradient,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF8F5F8),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF18141D),
    ink2: Color(0xFF3F3949),
    muted: Color(0xFF8D8697),
    line: Color(0xFFECE7EF),
    pink: Color(0xFFC27BA0),
    pinkDeep: Color(0xFF9E5B7E),
    pinkSoft: Color(0xFFF6E7EF),
    violet: Color(0xFF6C5CE7),
    violetSoft: Color(0xFFEFEAFF),
    green: Color(0xFF3E9B63),
    red: Color(0xFFD8424F),
    yellow: Color(0xFFFFF1AE),
    scheduleBg: Color(0xFFF8F5F8),
    navSurface: Color(0xFFFFFFFF),
    accountGradient: [Color(0xFFF2D7E4), Color(0xFFE2B6CB), Color(0xFFD3A0BB)],
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0D0C11),
    surface: Color(0xFF17151D),
    ink: Color(0xFFF7F2F8),
    ink2: Color(0xFFCFC7D6),
    muted: Color(0xFF8F8799),
    line: Color(0xFF2A2633),
    pink: Color(0xFFE39BC2),
    pinkDeep: Color(0xFFF0B4D3),
    pinkSoft: Color(0xFF2B1C26),
    violet: Color(0xFFA99BFF),
    violetSoft: Color(0xFF241F3A),
    green: Color(0xFF6BC78D),
    red: Color(0xFFFF7A86),
    yellow: Color(0xFF3A3217),
    scheduleBg: Color(0xFF0D0C11),
    navSurface: Color(0xFF17151D),
    accountGradient: [Color(0xFF3A2531), Color(0xFF4A2D3D), Color(0xFF5A3548)],
  );

  static const pinkBrand = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFFBEFF5),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF2A1520),
    ink2: Color(0xFF5A3A49),
    muted: Color(0xFF9A7B8A),
    line: Color(0xFFF0DCE6),
    pink: Color(0xFFB85C86),
    pinkDeep: Color(0xFF8E3F63),
    pinkSoft: Color(0xFFF6DCE8),
    violet: Color(0xFF6C5CE7),
    violetSoft: Color(0xFFEFEAFF),
    green: Color(0xFF3E9B63),
    red: Color(0xFFD8424F),
    yellow: Color(0xFFFFF1AE),
    scheduleBg: Color(0xFFF6DCE8),
    navSurface: Color(0xFFFFFFFF),
    accountGradient: [Color(0xFFF2D7E4), Color(0xFFE2B6CB), Color(0xFFD3A0BB)],
  );

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color line;
  final Color pink;
  final Color pinkDeep;
  final Color pinkSoft;
  final Color violet;
  final Color violetSoft;
  final Color green;
  final Color red;
  final Color yellow;
  final Color scheduleBg;
  final Color navSurface;
  final List<Color> accountGradient;

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? line,
    Color? pink,
    Color? pinkDeep,
    Color? pinkSoft,
    Color? violet,
    Color? violetSoft,
    Color? green,
    Color? red,
    Color? yellow,
    Color? scheduleBg,
    Color? navSurface,
    List<Color>? accountGradient,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      pink: pink ?? this.pink,
      pinkDeep: pinkDeep ?? this.pinkDeep,
      pinkSoft: pinkSoft ?? this.pinkSoft,
      violet: violet ?? this.violet,
      violetSoft: violetSoft ?? this.violetSoft,
      green: green ?? this.green,
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
      scheduleBg: scheduleBg ?? this.scheduleBg,
      navSurface: navSurface ?? this.navSurface,
      accountGradient: accountGradient ?? this.accountGradient,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: blend(bg, other.bg),
      surface: blend(surface, other.surface),
      ink: blend(ink, other.ink),
      ink2: blend(ink2, other.ink2),
      muted: blend(muted, other.muted),
      line: blend(line, other.line),
      pink: blend(pink, other.pink),
      pinkDeep: blend(pinkDeep, other.pinkDeep),
      pinkSoft: blend(pinkSoft, other.pinkSoft),
      violet: blend(violet, other.violet),
      violetSoft: blend(violetSoft, other.violetSoft),
      green: blend(green, other.green),
      red: blend(red, other.red),
      yellow: blend(yellow, other.yellow),
      scheduleBg: blend(scheduleBg, other.scheduleBg),
      navSurface: blend(navSurface, other.navSurface),
      accountGradient: [
        for (var i = 0; i < accountGradient.length; i++)
          blend(
            accountGradient[i],
            other.accountGradient[i % other.accountGradient.length],
          ),
      ],
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light = _build(AppPalette.light);
  static ThemeData dark = _build(AppPalette.dark);
  static ThemeData pink = _build(AppPalette.pinkBrand);

  static ThemeData forMode(AppThemeMode mode, Brightness platformBrightness) {
    return switch (mode) {
      AppThemeMode.light => light,
      AppThemeMode.dark => dark,
      AppThemeMode.pink => pink,
      AppThemeMode.system =>
        platformBrightness == Brightness.dark ? dark : light,
    };
  }

  static ThemeData _build(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.pink,
      brightness: palette.brightness,
    ).copyWith(
      primary: palette.pinkDeep,
      onPrimary: isDark ? palette.ink : Colors.white,
      secondary: palette.violet,
      onSecondary: Colors.white,
      surface: palette.surface,
      onSurface: palette.ink,
      error: palette.red,
      onError: Colors.white,
    );

    final baseText = ThemeData(
      brightness: palette.brightness,
      useMaterial3: true,
    ).textTheme;

    final textTheme = baseText
        .copyWith(
          headlineLarge: TextStyle(
            fontSize: 27,
            height: 32 / 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.08,
            color: palette.ink,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            height: 24 / 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: palette.ink,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            height: 19 / 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: palette.ink,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: palette.ink2,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w500,
            color: palette.ink2,
          ),
          bodySmall: TextStyle(
            fontSize: 11.5,
            height: 16 / 11.5,
            fontWeight: FontWeight.w500,
            color: palette.muted,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
          labelSmall: TextStyle(
            fontSize: 9.5,
            height: 14 / 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: palette.muted,
          ),
        )
        .apply(
          fontFamily: 'Manrope',
          bodyColor: palette.ink,
          displayColor: palette.ink,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.bg,
      fontFamily: 'Manrope',
      textTheme: textTheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: palette.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: palette.navSurface,
        indicatorColor: palette.pinkSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.pinkDeep : palette.muted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? palette.pinkDeep : palette.muted,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: palette.line, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.ink,
          foregroundColor: palette.bg,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.line),
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.pinkDeep,
          minimumSize: const Size(44, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.pink, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
