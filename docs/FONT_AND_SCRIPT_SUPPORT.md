# Multilingual Font and Script Support Guide — व्यवहार (Vyavahaar)

> **Typography Mandate**: 100% offline bundling; zero missing glyph boxes; correct conjunct ligature shaping across all Indian writing systems.  
> **Last Updated**: 2026-11-23  

---

## 1. Primary Typography & Script Coverage Architecture

Vyavahaar employs a dual-primary typography system aligned with the **InlitX/streak** design language and authentic Indian typographic design:

1. **Hindi & Indic Scripts — Poppins**:
   - Designed by Indian Type Foundry (ITF) and Google Fonts.
   - Bundled weights: Regular (400), Medium (500), SemiBold (600), Bold (700), and ExtraBold (800) in `assets/fonts/Poppins-*.ttf`.
   - Offers natural Devanagari letter proportions, open counters, and high legibility for mobile and desktop screens.

2. **English & Latin Script — Figtree**:
   - Clean, geometric sans-serif typeface matching the InlitX/streak core aesthetic.
   - Bundled weights: Light (300), Regular (400), Medium (500), SemiBold (600), Bold (700), ExtraBold (800), and Black (900) in `assets/fonts/Figtree-*.ttf`.

3. **Dynamic Locale-Aware Font Resolution**:
   - `AppTheme.fromPalette(palette, locale: activeLocale)` dynamically sets `primaryFamily = isEnglish ? 'Figtree' : 'Poppins'`.
   - `fontFamilyFallback: const ['Poppins', 'Figtree', 'NotoSansDevanagari', 'sans-serif']` ensures that if mixed scripts are encountered, glyphs render seamlessly without tofu blocks.

| Script Name | ISO 15924 | Covered Scheduled Languages | Primary Font Asset | Fallback Chain |
| :--- | :--- | :--- | :--- | :--- |
| **Devanagari** | `Deva` | Hindi, Bodo, Dogri, Konkani, Maithili, Marathi, Nepali, Sanskrit, Kashmiri/Sindhi (Deva) | `Poppins` | `NotoSansDevanagari`, `Figtree`, `sans-serif` |
| **Latin** | `Latn` | English | `Figtree` | `Poppins`, `NotoSansDevanagari`, `sans-serif` |
| **Bengali-Assamese**| `Beng` | Assamese, Bengali, Manipuri (Bengali script) | `NotoSansBengali` | `Poppins`, `Roboto` |
| **Gujarati** | `Gujr` | Gujarati | `NotoSansGujarati` | `Poppins`, `Roboto` |
| **Gurmukhi** | `Guru` | Punjabi | `NotoSansGurmukhi` | `Poppins`, `Roboto` |
| **Kannada** | `Knda` | Kannada | `NotoSansKannada` | `Poppins`, `Roboto` |
| **Malayalam** | `Mlym` | Malayalam | `NotoSansMalayalam` | `Poppins`, `Roboto` |
| **Meitei Mayek** | `Mtei` | Manipuri (Meitei) | `NotoSansMeeteiMayek` | `Poppins`, `Roboto` |
| **Odia** | `Orya` | Odia | `NotoSansOriya` | `Poppins`, `Roboto` |
| **Ol Chiki** | `Olck` | Santali | `NotoSansOlChiki` | `Poppins`, `Roboto` |
| **Perso-Arabic** | `Arab` | Urdu, Kashmiri (Arabic), Sindhi (Arabic) | `NotoNastaliqUrdu` | `NotoSansArabic`, `Poppins` |
| **Tamil** | `Taml` | Tamil | `NotoSansTamil` | `Poppins`, `Roboto` |
| **Telugu** | `Telu` | Telugu | `NotoSansTelugu` | `Poppins`, `Roboto` |

---

## 2. Indic Script Rendering Rules

1. **Matra & Vowel Positioning**: Indic scripts place dependent vowels before, after, above, or below consonant bases. Text containers must provide adequate vertical line height (`lineSpacingMultiplier: 1.15` to `1.35`) to prevent clipping top matras or bottom halants/nuktas.
2. **Conjunct Ligatures (*Yuktakshars*)**: Full OpenType shaping engines (`HarfBuzz` in Flutter engine) must remain unhindered. Zero custom manual string slicing across Indic grapheme clusters.
3. **Perso-Arabic Nastaliq Rendering**: Urdu and Kashmiri Arabic require cascading baseline height adjustments (`lineSpacingMultiplier: 1.35`) and explicit RTL directionality.

---

## 3. PDF Font Embedding Strategy

In PDF generation (`pdf` package in Flutter):
- The PDF format requires physical embedding of TrueType (`.ttf`) font binaries containing the required Unicode cmap table.
- `PdfService` selects the embedded TTF font based on `currentLanguageSpec.primaryFontFamily` so that exported PDFs in Bengali, Gujarati, Tamil, etc., render with correct ligatures and zero tofu boxes.

---

## 4. Binary Size Optimization

To maintain compact installer footprints (< 35 MB on Android and desktop):
- Use variable fonts or single medium-weight TrueType subsets where multiple static weights (`Thin`, `Light`, `Black`) are unnecessary.
- Never duplicate identical Latin glyph ranges across separate font files.
