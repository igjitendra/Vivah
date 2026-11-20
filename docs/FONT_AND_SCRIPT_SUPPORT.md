# Multilingual Font and Script Support Guide — व्यवहार (Vyavahaar)

> **Typography Mandate**: 100% offline bundling; zero missing glyph boxes; correct conjunct ligature shaping across all Indian writing systems.  
> **Last Updated**: 2026-11-21  

---

## 1. Script & Font Coverage Architecture

Vyavahaar uses the Google **Noto** ("No More Tofu") font family licensed under the **SIL Open Font License (OFL) v1.1**, permitting free commercial bundling, modification, and offline redistribution across all 5 target platforms.

| Script Name | ISO 15924 | Covered Scheduled Languages | Primary Font Asset | Fallback Chain |
| :--- | :--- | :--- | :--- | :--- |
| **Devanagari** | `Deva` | Hindi, Bodo, Dogri, Konkani, Maithili, Marathi, Nepali, Sanskrit, Kashmiri/Sindhi (Deva) | `NotoSansDevanagari` | `NotoSerifDevanagari`, `Roboto` |
| **Bengali-Assamese**| `Beng` | Assamese, Bengali, Manipuri (Bengali script) | `NotoSansBengali` | `NotoSerifBengali`, `Roboto` |
| **Gujarati** | `Gujr` | Gujarati | `NotoSansGujarati` | `NotoSerifGujarati`, `Roboto` |
| **Gurmukhi** | `Guru` | Punjabi | `NotoSansGurmukhi` | `NotoSerifGurmukhi`, `Roboto` |
| **Kannada** | `Knda` | Kannada | `NotoSansKannada` | `NotoSerifKannada`, `Roboto` |
| **Malayalam** | `Mlym` | Malayalam | `NotoSansMalayalam` | `NotoSerifMalayalam`, `Roboto` |
| **Meitei Mayek** | `Mtei` | Manipuri (Meitei) | `NotoSansMeeteiMayek` | `NotoSansBengali`, `Roboto` |
| **Odia** | `Orya` | Odia | `NotoSansOriya` | `NotoSerifOriya`, `Roboto` |
| **Ol Chiki** | `Olck` | Santali | `NotoSansOlChiki` | `Roboto` |
| **Perso-Arabic** | `Arab` | Urdu, Kashmiri (Arabic), Sindhi (Arabic) | `NotoNastaliqUrdu` | `NotoSansArabic`, `Roboto` |
| **Tamil** | `Taml` | Tamil | `NotoSansTamil` | `NotoSerifTamil`, `Roboto` |
| **Telugu** | `Telu` | Telugu | `NotoSansTelugu` | `NotoSerifTelugu`, `Roboto` |
| **Latin** | `Latn` | English | `Roboto` | `NotoSans` |

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
