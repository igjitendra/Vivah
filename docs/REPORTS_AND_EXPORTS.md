# Reports & Export Specifications — व्यवहार (Vyavahaar)

> **Implementation**: `src/services/PdfService.ts`, `src/services/CsvService.ts`  
> **UI Entry Point**: `app/reports/index.tsx`  
> **Engine**: `expo-print` (HTML to PDF) & `expo-file-system`  
> **Last Updated**: 2026-11-21

---

## 1. Hindi PDF Reports Engine (`PdfService.ts`)

The PDF export engine generates high-resolution, print-ready A4 PDF documents with authentic Devanagari typography, structured margins, page numbers, and cultural headings.

### 1.1 Typography & Devanagari Font Embedding
- **Font**: Google Noto Sans Devanagari (`@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;600;700;800&display=swap');`).
- **Devanagari Shaping**: CSS ensures proper complex conjunct rendering, half-characters (*halant*), and vowel matras without overlapping or missing glyphs.
- **Page Layout**: A4 size (`margin: 15mm 15mm 20mm 15mm`), automatic page breaks on tables, and footer page numbering (`व्यवहार • पृष्ठ counter(page) / counter(pages)`).

### 1.2 The 6 Standard PDF Reports

| Report Name | Scope & Content | Key Filters Applied |
| :--- | :--- | :--- |
| **1. Complete Ledger (संपूर्ण बही खाता)** | Full historical record of all completed family transactions. | `status = 'recorded' AND deleted_at IS NULL` |
| **2. Person-wise Report (व्यक्ति-वार विवरण)** | Complete relationship history with a single relative or friend. | Filtered by `person_id`; separates Mila and Diya totals. |
| **3. Event-wise Report (कार्यक्रम-वार विवरण)** | Complete gift and shagun ledger for a specific function (e.g. wedding).| Filtered by `event_id`; lists all incoming/outgoing items. |
| **4. Year-wise Report (वर्ष-वार सारांश)** | Annual social expenditure and gift summary. | Filtered by calendar year (`strftime('%Y', event_date)`). |
| **5. Gift/Item Report (भेंट व सामान विवरण)** | Inventory of all physical gifts received or given. | Joins `entry_items`; excludes cash amounts. |
| **6. Custom Date Range Report** | User-selected From Date and To Date transactions. | `event_date >= :from AND event_date <= :to` |

---

## 2. Financial Integrity Rules in Reports

1. **Separation of Totals**: Every report features two independent summary banners:
   - **कुल मिला (Total Received)**: Highlighted in forest green (`#15803D`).
   - **कुल दिया (Total Given)**: Highlighted in crimson red (`#B91C1C`).
   - *Never combined into a net balance.*
2. **Exclusion of Gift Estimates**: If an item has an estimated value (e.g. "चाँदी का सिक्का - अनुमानित ₹2,000"), it is rendered in an italicized item column and **NEVER** added to the cash total.
3. **Exclusion of Planned / Cancelled Entries**: Only entries with `status = 'recorded'` appear in completed totals. Planned entries are either excluded or grouped into a separate designated "प्रस्तावित व्यवहार" table.

---

## 3. CSV Export Specification (`CsvService.ts`)

### 3.1 RFC-4180 Compliance & Field Escaping
- Fields containing commas, quotation marks, or newlines are wrapped in double quotes.
- Internal double quotes are escaped as `""`.

### 3.2 UTF-8 BOM (`\uFEFF`) Encoding for Microsoft Excel
When opening CSV files containing Hindi Devanagari text in Microsoft Excel on Windows or Android, Excel defaults to ANSI encoding unless a UTF-8 Byte Order Mark is present.
- `CsvService.wrapUtf8Bom()` prepends the 3-byte BOM `\uFEFF` to the file content.
- This guarantees that Hindi names (e.g. "रमेश कुमार", "मामा जी", "शादी") open cleanly in Excel without displaying corrupted symbols or question marks.

### 3.3 CSV Column Structure
```csv
"क्रमांक","प्रकार (मिला/दिया)","तिथि","राशि (₹)","व्यक्ति का नाम","गाँव/शहर","रिश्ता","फोन","कार्यक्रम","भेंट / सामान","टिप्पणी"
"1","मिला","22/11/2026","1,100","सुरेश कुमार","वाराणसी","मामा जी","9876543210","अमित की शादी","चाँदी का सिक्का (1 संख्या)","शुभकामनाएं"
```
