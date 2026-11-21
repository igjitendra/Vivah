# Reports & Export Specifications — व्यवहार (Vyavahaar)

> **Implementation**: `lib/src/features/reports/services/pdf_service.dart`, `lib/src/features/reports/services/csv_service.dart`  
> **UI Entry Point**: `lib/src/features/reports/presentation/reports_screen.dart` (`/reports`)  
> **Engines**: `pdf` + `printing` (Native vector A4 PDF) & `csv` (RFC-4180 serializer)  
> **Sole Application Framework**: Flutter + Dart  
> **Last Updated**: 2026-11-21  

---

## 1. Hindi PDF Reports Engine (`PdfService.dart`)

The PDF export engine generates high-resolution, print-ready vector A4 PDF documents with authentic Devanagari typography, structured margins, page numbers, and cultural headings completely offline.

### 1.1 Typography & Devanagari Font Embedding
- **Font**: Google Noto Sans Devanagari loaded via `PdfGoogleFonts.notoSansDevanagariRegular()` and `PdfGoogleFonts.notoSansDevanagariBold()`.
- **Devanagari Vector Shaping**: Direct vector font embedding guarantees that complex Hindi conjuncts, half-characters (*halant*), and vowel matras render cleanly without overlapping or broken glyphs.
- **Page Layout**: A4 size (`margin: EdgeInsets.all(24)`), multi-page table pagination, header branding, and timestamp.

### 1.2 The Standard PDF Reports
1. **Complete Ledger (संपूर्ण बही खाता)**: Full chronological record of all recorded family transactions.
2. **Received Ledger (कुल मिला बही)**: Only incoming gifts and shagun.
3. **Given Ledger (कुल दिया बही)**: Only outgoing gifts and shagun.
4. **Person-wise Report**: Filtered by relative/contact with personal exchange history.
5. **Event-wise Report**: Filtered by ceremonial event (*shadi, tilak, mundan*) with ceremony totals.

---

## 2. Financial Integrity Rules in Reports

1. **Strict Separation of Totals**:
   - **कुल मिला (Total Received)**: Highlighted in forest green (`AppColors.forestGreen`).
   - **कुल दिया (Total Given)**: Highlighted in terracotta (`AppColors.terracotta`).
   - *Under no circumstances are these subtracted or combined into a commercial net debt or profit/loss figure.*
2. **Exclusion of Gift Estimates**: Physical gift estimated values (`estimated_value_paise`) are listed in a designated items column and are **NEVER** added to the cash total.
3. **Exclusion of Planned / Cancelled Entries**: Only entries with `status = 'recorded'` are included in completed financial totals. Planned transactions (`status = 'planned'`) and cancelled entries (`status = 'cancelled'`) are excluded.

---

## 3. CSV Export Specification (`CsvService.dart`)

### 3.1 RFC-4180 Compliance & Field Escaping
- Implemented using the `csv` package with strict RFC-4180 compliance.
- Fields containing commas, quotation marks, or newlines are wrapped in double quotes.
- Internal double quotes are escaped as `""`.

### 3.2 UTF-8 BOM (`\uFEFF`) Encoding for Microsoft Excel
When opening CSV files containing Hindi Devanagari text in Microsoft Excel on Windows or mobile devices, Excel defaults to ANSI encoding unless a UTF-8 Byte Order Mark is present.
- `CsvService` prepends the 3-byte UTF-8 BOM `\uFEFF` (`List<int>.from([0xEF, 0xBB, 0xBF])`) to the file content.
- This guarantees that Hindi names (e.g. "रमेश कुमार", "मामा जी", "शादी", "चाँदी का सिक्का") open cleanly in Excel without displaying corrupted symbols or question marks.

### 3.3 CSV Column Structure
```csv
"क्रमांक","प्रकार (मिला/दिया)","दिनांक","राशि (₹)","व्यक्ति का नाम","रिश्ता","कार्यक्रम","सामान / भेंट","टिप्पणी"
"1","मिला","22/11/2026","1,100","सुरेश कुमार","मामा जी","अमित की शादी","चाँदी का सिक्का (1 संख्या)","शुभकामनाएं"
```
