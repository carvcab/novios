import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'local_storage.dart';

class AppThemeColors {
  // ── Light mode ──
  static const lightBg = Color(0xFFFFF5F8);          // warm rose-white
  static const lightCard = Color(0xFFFFFFFF);         // pure white cards
  static const lightText = Color(0xFF1F1F1F);         // near-black for max readability
  static const lightTextSecondary = Color(0xFF5A5A5A); // medium grey for subtitles
  static const lightPrimary = Color(0xFFE8467C);      // vivid coral-pink
  static const lightSecondary = Color(0xFF9B6FE8);    // rich purple
  static const lightSurface = Color(0xFFFFFFFF);      // white surface
  static const lightSurfaceContainer = Color(0xFFF3E8EE); // warm tinted container
  static const lightInputBg = Color(0xFFF2EDF0);      // subtle warm grey input

  // ── Dark mode ──
  static const darkBg = Color(0xFF09090B);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkText = Color(0xFFF4F4F5);
  static const darkTextSecondary = Color(0xFFA1A1AA);
  static const darkPrimary = Color(0xFFFF6B95);
  static const darkSecondary = Color(0xFFB794F6);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkSurfaceContainer = Color(0xFF2A2530);
  static const darkInputBg = Color(0xFF252525);
}

class ThemeProvider with ChangeNotifier {
  String _fontFamily = 'Inter';
  bool _isDark = false;

  ThemeProvider() {
    _loadFromPrefs();
  }

  String get fontFamily => _fontFamily;
  bool get isDark => _isDark;

  void _loadFromPrefs() {
    try {
      _fontFamily = LocalStorage().getString('font_family') ?? 'Inter';
      _isDark = LocalStorage().getBool('is_dark_mode');
    } catch (_) {}
  }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    await LocalStorage().setBool('is_dark_mode', _isDark);
    notifyListeners();
  }

  Future<void> setDark(bool val) async {
    _isDark = val;
    await LocalStorage().setBool('is_dark_mode', val);
    notifyListeners();
  }

  Future<void> setFont(String font) async {
    _fontFamily = font;
    await LocalStorage().setString('font_family', font);
    notifyListeners();
  }

  TextStyle getTextStyle(TextStyle base) {
    switch (_fontFamily) {
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(textStyle: base);
      case 'Outfit':
        return GoogleFonts.outfit(textStyle: base);
      case 'Pacifico':
        return GoogleFonts.pacifico(textStyle: base);
      case 'Poppins':
        return GoogleFonts.poppins(textStyle: base);
      case 'Manrope':
        return GoogleFonts.manrope(textStyle: base);
      default:
        return GoogleFonts.inter(textStyle: base);
    }
  }

  ThemeData getThemeData() {
    final isDark = _isDark;
    final bg = isDark ? AppThemeColors.darkBg : AppThemeColors.lightBg;
    final card = isDark ? AppThemeColors.darkCard : AppThemeColors.lightCard;
    final text = isDark ? AppThemeColors.darkText : AppThemeColors.lightText;
    final textSecondary = isDark ? AppThemeColors.darkTextSecondary : AppThemeColors.lightTextSecondary;
    final primary = isDark ? AppThemeColors.darkPrimary : AppThemeColors.lightPrimary;
    final secondary = isDark ? AppThemeColors.darkSecondary : AppThemeColors.lightSecondary;
    final surface = isDark ? AppThemeColors.darkSurface : AppThemeColors.lightSurface;
    final surfaceContainer = isDark ? AppThemeColors.darkSurfaceContainer : AppThemeColors.lightSurfaceContainer;
    final inputBg = isDark ? AppThemeColors.darkInputBg : AppThemeColors.lightInputBg;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        // Explicit container colors — prevents M3 from generating bad ones
        surfaceContainerHighest: surfaceContainer,
        primaryContainer: isDark
            ? const Color(0xFF3D1929)
            : const Color(0xFFFFD9E5),  // soft pink for "my" chat bubbles
        onPrimaryContainer: isDark
            ? const Color(0xFFFFD1DC)
            : const Color(0xFF5C1230),  // dark burgundy text on pink bg
        secondaryContainer: isDark
            ? const Color(0xFF2E243D)
            : const Color(0xFFF0E4FF),
        onSecondaryContainer: isDark
            ? const Color(0xFFE9D8FF)
            : const Color(0xFF3B1870),
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: getTextStyle(TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: text,
        )),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: GoogleFonts.inter(fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: textSecondary.withValues(alpha: 0.6), fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 9),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1F1F1F),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: text.withValues(alpha: 0.08),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSecondary.withValues(alpha: 0.4);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.4);
          return textSecondary.withValues(alpha: 0.15);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.15),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
      ),
      listTileTheme: ListTileThemeData(
        textColor: text,
        iconColor: textSecondary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: text),
      ),
    );
  }
}
