# Indian Multilingual Localization & Internationalization Architecture — व्यवहार (Vyavahaar)

> **App Name**: व्यवहार (Vyavahaar)  
> **Tagline**: रिश्तों का हिसाब, हमेशा याद।  
> **Target Scope**: Complete native user experience in all 22 Scheduled Languages of India + English fallback, extensible to regional dialects.  
> **Offline Policy**: 100% offline; zero runtime network downloads; zero external translation APIs.  
> **Last Updated**: 2026-11-21  

---

## 1. Localization Philosophy & Objectives

In India, personal ledgers and family gift exchanges (*neota, bhat, shadi-vivah, mundan, griha pravesh*) are deeply cultural and emotional practices. An app that forces English or standard Hindi onto families across Tamil Nadu, West Bengal, Punjab, or Assam violates user trust.

Vyavahaar is architected from day one as a **truly multilingual Indian product**:
1. **Zero Translation Coupling to Data**: Database records store canonical machine-readable tokens (`given`, `received`, `planned`, `recorded`, `cancelled`). Translated strings exist solely in presentation layers. Changing the UI language never modifies or corrupts historical family records.
2. **First-Class Scheduled Languages**: All 22 languages listed in the Eighth Schedule of the Constitution of India are first-class citizens in the language registry.
3. **Extensible Architecture**: Regional dialects and unlisted languages (Bhojpuri, Rajasthani, Tulu, Khasi, Garo, Mizo, etc.) can be registered dynamically via `LanguageRegistry.registerLanguage()` without rewriting widgets or refactoring core models.
4. **Authentic Cultural Terminology**: Translations must reflect regional cultural practices (e.g. *बही-खाता*, *হিসাব*, *ఖాతా*, *கணக்கு*, *حساب*) without commercial banking loan jargon (*debt, credit, dues*).
5. **Full Offline Autonomy**: All fonts, localization catalogs, and formatting rules are bundled locally. Language switching operates instantly in airplane mode.

---

## 2. Supported Language Hierarchy

```
Language Architecture
├── English (en-IN) [Development & Fallback]
└── 22 Scheduled Indian Languages (Eighth Schedule of the Constitution)
    ├── Indo-Aryan: as, bn, doi, gu, hi, ks (Arab/Deva), kok, mai, mr, ne, or, pa, sa, sd (Arab/Deva), ur
    ├── Dravidian: kn, ml, ta, te
    ├── Tibeto-Burman: brx, mni (Mtei/Beng)
    └── Austroasiatic (Munda): sat (Olck)
└── Extensible Regional Dialects (bho, raj, tcy, kha, grt, lus, etc.)
```

---

## 3. Technology Stack & Workflow

- **Framework Infrastructure**: `flutter_localizations`, `intl` v0.19.0.
- **Resource Format**: Application Resource Bundle (`.arb`) files with ICU message formatting and pluralization syntax.
- **Config**: `l10n.yaml` pointing to template `app_en.arb` with synthetic package generation.
- **State Management**: Riverpod `localeProvider` backed by `SettingsRepository` (persisting `preferred_locale_tag` in SQLite `app_settings` table).
- **Runtime Switching**: Instant UI rebuild without application restart or device reboot.

---

## 4. Script and Directionality Handling

### 4.1 Right-to-Left (RTL) Scripts
Urdu (`ur`), Kashmiri in Perso-Arabic (`ks-Arab`), and Sindhi in Perso-Arabic (`sd-Arab`) are right-to-left scripts.
- Flutter's `Directionality` widget ensures start/end padding, flex direction, back buttons, and cursor movements automatically reverse.
- **Mixed Directionality**: Rupee amounts (`₹1,100`), phone numbers (`9876543210`), and Gregorian dates (`2026-11-22`) within Urdu text maintain correct logical order without reversing digits.

### 4.2 Script Subtags
Where an Indian language utilizes multiple scripts, BCP 47 script subtags are strictly declared:
- `ks-Arab-IN` (Kashmiri in Perso-Arabic) vs `ks-Deva-IN` (Kashmiri in Devanagari)
- `sd-Arab-IN` (Sindhi in Perso-Arabic) vs `sd-Deva-IN` (Sindhi in Devanagari)
- `mni-Mtei-IN` (Manipuri in Meitei Mayek) vs `mni-Beng-IN` (Manipuri in Bengali script)
- `sat-Olck-IN` (Santali in Ol Chiki script)

---

## 5. Multilingual Currency, Number, and Date Formatting

1. **Integer Paise Invariance**: Currency is calculated strictly in 64-bit integer paise. Formatted strings are created strictly at the presentation boundary via `LocaleFormatter.formatPaise(paise, locale)`.
2. **Indian Number Grouping**: Lakhs (`₹1,00,000`) and Crores (`₹1,00,00,000`) grouping conventions are preserved.
3. **Calendar Dates**: Formatted via locale-aware `DateFormat('d MMMM yyyy', localeTag)`.

---

## 6. Unicode-Safe Multilingual Search

The application supports real-time searching across people, families, events, and gift items in all Indian scripts:
- **NFC Normalization**: All input is compared using Unicode canonical decomposition/composition to prevent duplicate glyph mismatches.
- **Diacritic & Matra Preservation**: Combining vowel signs (*matras*, *nuktas*, *viramas*) are preserved to prevent altering Hindi/Indic root words.
- **Prefix & Substring Matching**: Implemented in `UnicodeSearchUtils.matches()`.
