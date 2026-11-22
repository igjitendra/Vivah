import 'package:flutter/material.dart';

/// Representation of a curated Color Palette for व्यवहार (Vyavahaar)
class ThemePalette {
  final String id;
  final String name;
  final String nameHindi;
  final bool isDark;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final List<Color> previewSwatches;

  const ThemePalette({
    required this.id,
    required this.name,
    required this.nameHindi,
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.previewSwatches,
  });

  // ==========================================
  // CURATED LIGHT THEMES
  // ==========================================
  static const ThemePalette porcelain = ThemePalette(
    id: 'porcelain',
    name: 'Porcelain',
    nameHindi: 'व्यवहार क्लासिक (टेराकोटा)',
    isDark: false,
    primary: Color(0xFFC05A2B), // Terracotta
    secondary: Color(0xFF1F3352), // Deep Navy
    background: Color(0xFFF4EFE7), // Warm Cream
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF1F3352),
    textSecondary: Color(0xFF64748B),
    previewSwatches: [
      Color(0xFFC05A2B),
      Color(0xFF1F3352),
      Color(0xFF15803D),
      Color(0xFFD97706),
      Color(0xFF2563EB),
    ],
  );

  static const ThemePalette lavender = ThemePalette(
    id: 'lavender',
    name: 'Lavender',
    nameHindi: 'लैवेंडर (जामुनी)',
    isDark: false,
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFF4C1D95),
    background: Color(0xFFF5F3FF),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFDDD6FE),
    textPrimary: Color(0xFF2E1065),
    textSecondary: Color(0xFF6D28D9),
    previewSwatches: [
      Color(0xFF7C3AED),
      Color(0xFF4C1D95),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
    ],
  );

  static const ThemePalette sky = ThemePalette(
    id: 'sky',
    name: 'Sky',
    nameHindi: 'आसमानी (Sky)',
    isDark: false,
    primary: Color(0xFF0284C7),
    secondary: Color(0xFF0C4A6E),
    background: Color(0xFFF0F9FF),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFBAE6FD),
    textPrimary: Color(0xFF082F49),
    textSecondary: Color(0xFF0369A1),
    previewSwatches: [
      Color(0xFF0284C7),
      Color(0xFF0C4A6E),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  );

  static const ThemePalette sakura = ThemePalette(
    id: 'sakura',
    name: 'Sakura',
    nameHindi: 'गुलाबी (Sakura)',
    isDark: false,
    primary: Color(0xFFE11D48),
    secondary: Color(0xFF881337),
    background: Color(0xFFFFF1F2),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFFECDD3),
    textPrimary: Color(0xFF4C0519),
    textSecondary: Color(0xFFBE123C),
    previewSwatches: [
      Color(0xFFE11D48),
      Color(0xFF881337),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF2563EB),
    ],
  );

  static const ThemePalette mint = ThemePalette(
    id: 'mint',
    name: 'Mint',
    nameHindi: 'पुदीना (Mint)',
    isDark: false,
    primary: Color(0xFF0D9488),
    secondary: Color(0xFF134E4A),
    background: Color(0xFFF0FDFA),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF99F6E4),
    textPrimary: Color(0xFF042F2E),
    textSecondary: Color(0xFF0F766E),
    previewSwatches: [
      Color(0xFF0D9488),
      Color(0xFF134E4A),
      Color(0xFFE11D48),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
    ],
  );

  static const ThemePalette linen = ThemePalette(
    id: 'linen',
    name: 'Linen',
    nameHindi: 'खादी (Linen)',
    isDark: false,
    primary: Color(0xFFD97706),
    secondary: Color(0xFF78350F),
    background: Color(0xFFFFFBEB),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFFDE68A),
    textPrimary: Color(0xFF451A03),
    textSecondary: Color(0xFFB45309),
    previewSwatches: [
      Color(0xFFD97706),
      Color(0xFF78350F),
      Color(0xFF16A34A),
      Color(0xFF2563EB),
      Color(0xFFDC2626),
    ],
  );

  static const ThemePalette paper = ThemePalette(
    id: 'paper',
    name: 'Paper',
    nameHindi: 'कागज़ (Paper)',
    isDark: false,
    primary: Color(0xFF854D0E),
    secondary: Color(0xFF3F2E1E),
    background: Color(0xFFFAF6F0),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE7DEC8),
    textPrimary: Color(0xFF2E2315),
    textSecondary: Color(0xFF71593C),
    previewSwatches: [
      Color(0xFF854D0E),
      Color(0xFF3F2E1E),
      Color(0xFF15803D),
      Color(0xFFB91C1C),
      Color(0xFF1D4ED8),
    ],
  );

  static const ThemePalette solarizedLight = ThemePalette(
    id: 'solarized_light',
    name: 'Solarized Light',
    nameHindi: 'सोलराइज़्ड लाइट',
    isDark: false,
    primary: Color(0xFF268BD2),
    secondary: Color(0xFF073642),
    background: Color(0xFFFDF6E3),
    surface: Color(0xFFEEE8D5),
    cardBorder: Color(0xFFD33682),
    textPrimary: Color(0xFF002B36),
    textSecondary: Color(0xFF586E75),
    previewSwatches: [
      Color(0xFF268BD2),
      Color(0xFF859900),
      Color(0xFFB58900),
      Color(0xFFCB4B16),
      Color(0xFF6C71C4),
    ],
  );

  // ==========================================
  // CURATED DARK THEMES
  // ==========================================
  static const ThemePalette midnightAurora = ThemePalette(
    id: 'midnight_aurora',
    name: 'Midnight Aurora',
    nameHindi: 'मिडनाइट ऑरोरा',
    isDark: true,
    primary: Color(0xFFA78BFA),
    secondary: Color(0xFFC084FC),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    cardBorder: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    previewSwatches: [
      Color(0xFFA78BFA),
      Color(0xFF38BDF8),
      Color(0xFF34D399),
      Color(0xFFF472B6),
      Color(0xFFFBBF24),
    ],
  );

  static const ThemePalette obsidian = ThemePalette(
    id: 'obsidian',
    name: 'Obsidian',
    nameHindi: 'ऑब्सिडियन (काला)',
    isDark: true,
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0284C7),
    background: Color(0xFF09090B),
    surface: Color(0xFF18181B),
    cardBorder: Color(0xFF27272A),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA1A1AA),
    previewSwatches: [
      Color(0xFF38BDF8),
      Color(0xFF22C55E),
      Color(0xFFEAB308),
      Color(0xFFF97316),
      Color(0xFFA855F7),
    ],
  );

  static const ThemePalette graphite = ThemePalette(
    id: 'graphite',
    name: 'Graphite',
    nameHindi: 'ग्रेफाइट',
    isDark: true,
    primary: Color(0xFF34D399),
    secondary: Color(0xFF059669),
    background: Color(0xFF121417),
    surface: Color(0xFF1E2229),
    cardBorder: Color(0xFF2C323D),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    previewSwatches: [
      Color(0xFF34D399),
      Color(0xFF60A5FA),
      Color(0xFFFBBF24),
      Color(0xFFF87171),
      Color(0xFFC084FC),
    ],
  );

  static const ThemePalette midnight = ThemePalette(
    id: 'midnight',
    name: 'Midnight',
    nameHindi: 'मिडनाइट ब्लू',
    isDark: true,
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF818CF8),
    background: Color(0xFF050B14),
    surface: Color(0xFF0B1728),
    cardBorder: Color(0xFF162A45),
    textPrimary: Color(0xFFE0F2FE),
    textSecondary: Color(0xFF7DD3FC),
    previewSwatches: [
      Color(0xFF38BDF8),
      Color(0xFF818CF8),
      Color(0xFF4ADE80),
      Color(0xFFFB923C),
      Color(0xFFF43F5E),
    ],
  );

  static const ThemePalette highContrast = ThemePalette(
    id: 'high_contrast',
    name: 'High Contrast',
    nameHindi: 'हाई कंट्रास्ट',
    isDark: true,
    primary: Color(0xFFFACC15),
    secondary: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    surface: Color(0xFF121212),
    cardBorder: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA3A3A3),
    previewSwatches: [
      Color(0xFFFACC15),
      Color(0xFFFFFFFF),
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
    ],
  );

  static const ThemePalette amberNight = ThemePalette(
    id: 'amber_night',
    name: 'Amber Night',
    nameHindi: 'एम्बर नाइट',
    isDark: true,
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFFD97706),
    background: Color(0xFF18130C),
    surface: Color(0xFF261D12),
    cardBorder: Color(0xFF3D2E1C),
    textPrimary: Color(0xFFFEF3C7),
    textSecondary: Color(0xFFD97706),
    previewSwatches: [
      Color(0xFFF59E0B),
      Color(0xFFF97316),
      Color(0xFF10B981),
      Color(0xFF38BDF8),
      Color(0xFFA855F7),
    ],
  );

  static const ThemePalette mocha = ThemePalette(
    id: 'mocha',
    name: 'Mocha',
    nameHindi: 'मोका (Mocha)',
    isDark: true,
    primary: Color(0xFFCBA6F7),
    secondary: Color(0xFFF38BA8),
    background: Color(0xFF1E1E2E),
    surface: Color(0xFF313244),
    cardBorder: Color(0xFF45475A),
    textPrimary: Color(0xFFCDD6F4),
    textSecondary: Color(0xFFA6ADC8),
    previewSwatches: [
      Color(0xFFCBA6F7),
      Color(0xFFF38BA8),
      Color(0xFFA6E3A1),
      Color(0xFF89B4FA),
      Color(0xFFFAB387),
    ],
  );

  static const ThemePalette neonCity = ThemePalette(
    id: 'neon_city',
    name: 'Neon City',
    nameHindi: 'नियॉन सिटी',
    isDark: true,
    primary: Color(0xFF22D3EE),
    secondary: Color(0xFFE879F9),
    background: Color(0xFF0D0221),
    surface: Color(0xFF1A0B36),
    cardBorder: Color(0xFF311463),
    textPrimary: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFC084FC),
    previewSwatches: [
      Color(0xFF22D3EE),
      Color(0xFFE879F9),
      Color(0xFF4ADE80),
      Color(0xFFFBBF24),
      Color(0xFFFF007F),
    ],
  );

  static const ThemePalette aurora = ThemePalette(
    id: 'aurora',
    name: 'Aurora',
    nameHindi: 'ऑरोरा (Aurora)',
    isDark: true,
    primary: Color(0xFF10B981),
    secondary: Color(0xFF2DD4BF),
    background: Color(0xFF06181C),
    surface: Color(0xFF0F292F),
    cardBorder: Color(0xFF173C44),
    textPrimary: Color(0xFFECFDF5),
    textSecondary: Color(0xFF6EE7B7),
    previewSwatches: [
      Color(0xFF10B981),
      Color(0xFF2DD4BF),
      Color(0xFF38BDF8),
      Color(0xFF818CF8),
      Color(0xFFF43F5E),
    ],
  );

  static const ThemePalette nord = ThemePalette(
    id: 'nord',
    name: 'Nord',
    nameHindi: 'नॉर्ड (Nord)',
    isDark: true,
    primary: Color(0xFF88C0D0),
    secondary: Color(0xFF81A1C1),
    background: Color(0xFF2E3440),
    surface: Color(0xFF3B4252),
    cardBorder: Color(0xFF4C566A),
    textPrimary: Color(0xFFECEFF4),
    textSecondary: Color(0xFFD8DEE9),
    previewSwatches: [
      Color(0xFF88C0D0),
      Color(0xFF81A1C1),
      Color(0xFFA3BE8C),
      Color(0xFFEBCB8B),
      Color(0xFFBF616A),
    ],
  );

  static const ThemePalette dracula = ThemePalette(
    id: 'dracula',
    name: 'Dracula',
    nameHindi: 'ड्रेकुला (Dracula)',
    isDark: true,
    primary: Color(0xFFBD93F9),
    secondary: Color(0xFFFF79C6),
    background: Color(0xFF282A36),
    surface: Color(0xFF383A59),
    cardBorder: Color(0xFF6272A4),
    textPrimary: Color(0xFFF8F8F2),
    textSecondary: Color(0xFF6272A4),
    previewSwatches: [
      Color(0xFFBD93F9),
      Color(0xFFFF79C6),
      Color(0xFF50FA7B),
      Color(0xFF8BE9FD),
      Color(0xFFFFB86C),
    ],
  );

  static const ThemePalette velvet = ThemePalette(
    id: 'velvet',
    name: 'Velvet',
    nameHindi: 'वेलवेट (Velvet)',
    isDark: true,
    primary: Color(0xFFF472B6),
    secondary: Color(0xFFA855F7),
    background: Color(0xFF180C17),
    surface: Color(0xFF281426),
    cardBorder: Color(0xFF3D1F3A),
    textPrimary: Color(0xFFFDF2F8),
    textSecondary: Color(0xFFF472B6),
    previewSwatches: [
      Color(0xFFF472B6),
      Color(0xFFA855F7),
      Color(0xFFC084FC),
      Color(0xFFFB7185),
      Color(0xFF38BDF8),
    ],
  );

  static const ThemePalette deepOcean = ThemePalette(
    id: 'deep_ocean',
    name: 'Deep Ocean',
    nameHindi: 'डीप ओशन',
    isDark: true,
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0284C7),
    background: Color(0xFF050F1A),
    surface: Color(0xFF0C1E33),
    cardBorder: Color(0xFF162E4C),
    textPrimary: Color(0xFFF0F9FF),
    textSecondary: Color(0xFF7DD3FC),
    previewSwatches: [
      Color(0xFF38BDF8),
      Color(0xFF0284C7),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
    ],
  );

  static const ThemePalette ember = ThemePalette(
    id: 'ember',
    name: 'Ember',
    nameHindi: 'एम्बर (Ember)',
    isDark: true,
    primary: Color(0xFFF97316),
    secondary: Color(0xFFEA580C),
    background: Color(0xFF140C08),
    surface: Color(0xFF24160F),
    cardBorder: Color(0xFF382318),
    textPrimary: Color(0xFFFFF7ED),
    textSecondary: Color(0xFFFB923C),
    previewSwatches: [
      Color(0xFFF97316),
      Color(0xFFEA580C),
      Color(0xFFEF4444),
      Color(0xFFFBBF24),
      Color(0xFFA855F7),
    ],
  );

  static const ThemePalette forest = ThemePalette(
    id: 'forest',
    name: 'Forest',
    nameHindi: 'वन (Forest)',
    isDark: true,
    primary: Color(0xFF34D399),
    secondary: Color(0xFF059669),
    background: Color(0xFF051B14),
    surface: Color(0xFF0A2E23),
    cardBorder: Color(0xFF144738),
    textPrimary: Color(0xFFECFDF5),
    textSecondary: Color(0xFF6EE7B7),
    previewSwatches: [
      Color(0xFF34D399),
      Color(0xFF10B981),
      Color(0xFFFBBF24),
      Color(0xFF60A5FA),
      Color(0xFFF43F5E),
    ],
  );

  static const ThemePalette sunset = ThemePalette(
    id: 'sunset',
    name: 'Sunset',
    nameHindi: 'सूर्यास्त (Sunset)',
    isDark: true,
    primary: Color(0xFFFB7185),
    secondary: Color(0xFFF43F5E),
    background: Color(0xFF1C0C18),
    surface: Color(0xFF2C1426),
    cardBorder: Color(0xFF482045),
    textPrimary: Color(0xFFFFF1F2),
    textSecondary: Color(0xFFFDA4AF),
    previewSwatches: [
      Color(0xFFFB7185),
      Color(0xFFF97316),
      Color(0xFFFBBF24),
      Color(0xFF38BDF8),
      Color(0xFFA855F7),
    ],
  );

  static const ThemePalette solarizedDark = ThemePalette(
    id: 'solarized_dark',
    name: 'Solarized Dark',
    nameHindi: 'सोलराइज़्ड डार्क',
    isDark: true,
    primary: Color(0xFF268BD2),
    secondary: Color(0xFF2AA198),
    background: Color(0xFF00212B),
    surface: Color(0xFF002B36),
    cardBorder: Color(0xFF073642),
    textPrimary: Color(0xFF93A1A1),
    textSecondary: Color(0xFF586E75),
    previewSwatches: [
      Color(0xFF268BD2),
      Color(0xFF2AA198),
      Color(0xFF859900),
      Color(0xFFB58900),
      Color(0xFFCB4B16),
    ],
  );

  static const List<ThemePalette> lightPalettes = [
    porcelain,
    lavender,
    sky,
    sakura,
    mint,
    linen,
    paper,
    solarizedLight,
  ];

  static const List<ThemePalette> darkPalettes = [
    midnightAurora,
    obsidian,
    graphite,
    midnight,
    highContrast,
    amberNight,
    mocha,
    neonCity,
    aurora,
    nord,
    dracula,
    velvet,
    deepOcean,
    ember,
    forest,
    sunset,
    solarizedDark,
  ];

  static ThemePalette getById(String id, {bool fallbackDark = false}) {
    for (final p in lightPalettes) {
      if (p.id == id) return p;
    }
    for (final p in darkPalettes) {
      if (p.id == id) return p;
    }
    return fallbackDark ? midnightAurora : porcelain;
  }
}
