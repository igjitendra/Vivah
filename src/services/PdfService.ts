import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { getDb, DEFAULT_HOUSEHOLD_ID } from '../database/db';
import { formatCurrency } from '../utils/currency';
import { formatHindiDate } from '../utils/date';
import type { Entry, EntryItem, Event, Person } from '../types';

export class PdfService {
  /**
   * Generates the shared HTML template with embedded Devanagari font & branding
   */
  private static getBaseHtml(title: string, subtitle: string, bodyContent: string): string {
    const today = new Date().toLocaleDateString('hi-IN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });

    return `
<!DOCTYPE html>
<html lang="hi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — व्यवहार</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;600;700;800&display=swap');

    @page {
      size: A4;
      margin: 15mm 15mm 20mm 15mm;
      @bottom-center {
        content: "व्यवहार • पृष्ठ " counter(page) " / " counter(pages);
        font-size: 9pt;
        color: #6B7280;
        font-family: 'Noto Sans Devanagari', sans-serif;
      }
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Noto Sans Devanagari', -apple-system, Roboto, 'Segoe UI', sans-serif;
      color: #1F2937;
      background-color: #FFFFFF;
      font-size: 11pt;
      line-height: 1.5;
      padding: 10px;
    }

    .header-table {
      width: 100%;
      border-bottom: 3px solid #1F3352;
      padding-bottom: 12px;
      margin-bottom: 20px;
    }

    .brand-title {
      font-size: 26pt;
      font-weight: 800;
      color: #1F3352;
      letter-spacing: 0.5px;
    }

    .brand-tagline {
      font-size: 10pt;
      color: #C05A2B;
      font-weight: 600;
      margin-top: 2px;
    }

    .report-meta {
      text-align: right;
      font-size: 10pt;
      color: #4B5563;
    }

    .report-title-box {
      background-color: #F4EFE7;
      border-left: 5px solid #C05A2B;
      padding: 12px 16px;
      margin-bottom: 20px;
      border-radius: 4px;
    }

    .report-title {
      font-size: 16pt;
      font-weight: 700;
      color: #1F3352;
    }

    .report-subtitle {
      font-size: 10.5pt;
      color: #4B5563;
      margin-top: 4px;
    }

    .summary-grid {
      display: table;
      width: 100%;
      margin-bottom: 24px;
      border-spacing: 10px;
    }

    .summary-card {
      display: table-cell;
      width: 33.33%;
      padding: 12px 14px;
      border-radius: 8px;
      border: 1px solid #E5E7EB;
      vertical-align: top;
    }

    .card-mila {
      background-color: #ECFDF5;
      border-color: #A7F3D0;
    }

    .card-diya {
      background-color: #FEF2F2;
      border-color: #FECACA;
    }

    .card-neutral {
      background-color: #F8FAFC;
      border-color: #E2E8F0;
    }

    .summary-label {
      font-size: 9.5pt;
      font-weight: 600;
      color: #4B5563;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .summary-value {
      font-size: 16pt;
      font-weight: 800;
      margin-top: 4px;
    }

    .val-mila { color: #16A34A; }
    .val-diya { color: #DC2626; }
    .val-neutral { color: #1F3352; }

    table.data-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
      font-size: 10pt;
      page-break-inside: auto;
    }

    table.data-table tr {
      page-break-inside: avoid;
      page-break-after: auto;
    }

    table.data-table th {
      background-color: #1F3352;
      color: #F4EFE7;
      text-align: left;
      padding: 9px 10px;
      font-weight: 700;
      font-size: 9.5pt;
      border: 1px solid #1F3352;
    }

    table.data-table td {
      padding: 8px 10px;
      border: 1px solid #E5E7EB;
      vertical-align: top;
    }

    table.data-table tr:nth-child(even) td {
      background-color: #F9FAFB;
    }

    .badge-mila {
      display: inline-block;
      background-color: #D1FAE5;
      color: #065F46;
      padding: 2px 8px;
      border-radius: 12px;
      font-weight: 700;
      font-size: 9pt;
    }

    .badge-diya {
      display: inline-block;
      background-color: #FEE2E2;
      color: #991B1B;
      padding: 2px 8px;
      border-radius: 12px;
      font-weight: 700;
      font-size: 9pt;
    }

    .badge-planned {
      display: inline-block;
      background-color: #FEF3C7;
      color: #92400E;
      padding: 2px 8px;
      border-radius: 12px;
      font-weight: 700;
      font-size: 9pt;
    }

    .footer {
      margin-top: 30px;
      padding-top: 10px;
      border-top: 1px dashed #CBD5E1;
      font-size: 8.5pt;
      color: #94A3B8;
      text-align: center;
    }

    .empty-state {
      text-align: center;
      padding: 40px;
      color: #6B7280;
      font-style: italic;
    }
  </style>
</head>
<body>
  <table class="header-table">
    <tr>
      <td>
        <div class="brand-title">व्यवहार</div>
        <div class="brand-tagline">रिश्तों का हिसाब, हमेशा याद।</div>
      </td>
      <td class="report-meta">
        <div><strong>दिनांक:</strong> ${today}</div>
        <div><strong>संस्करण:</strong> डिजिटल पारिवारिक बही खाता</div>
      </td>
    </tr>
  </table>

  <div class="report-title-box">
    <div class="report-title">${title}</div>
    <div class="report-subtitle">${subtitle}</div>
  </div>

  ${bodyContent}

  <div class="footer">
    यह रिपोर्ट व्यवहार (Vyavahaar) ऐप द्वारा जनरेट की गई है। समस्त डेटा केवल आपके डिवाइस पर सुरक्षित है।
  </div>
</body>
</html>
    `;
  }

  /**
   * 1. Complete व्यवहार report
   */
  static async generateFullReport(): Promise<string> {
    const db = getDb();
    const entries = db.getAllSync<Entry>(
      `SELECT e.*, p.name as person_name, p.village as person_village, ev.title as event_title, ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL AND e.status = 'recorded'
       ORDER BY e.created_at DESC`,
      DEFAULT_HOUSEHOLD_ID
    );

    let totalMila = 0;
    let totalDiya = 0;
    entries.forEach(e => {
      if (e.direction === 'mila') totalMila += e.cash_amount_paise;
      else if (e.direction === 'diya') totalDiya += e.cash_amount_paise;
    });

    const bodyContent = `
      <div class="summary-grid">
        <div class="summary-card card-mila">
          <div class="summary-label">कुल मिला (Received)</div>
          <div class="summary-value val-mila">${formatCurrency(totalMila)}</div>
        </div>
        <div class="summary-card card-diya">
          <div class="summary-label">कुल दिया (Given)</div>
          <div class="summary-value val-diya">${formatCurrency(totalDiya)}</div>
        </div>
        <div class="summary-card card-neutral">
          <div class="summary-label">कुल व्यवहार संख्या</div>
          <div class="summary-value val-neutral">${entries.length}</div>
        </div>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>क्र.</th>
            <th>प्रकार</th>
            <th>व्यक्ति</th>
            <th>गाँव / पता</th>
            <th>कार्यक्रम</th>
            <th>तारीख</th>
            <th style="text-align: right;">नकद राशि</th>
          </tr>
        </thead>
        <tbody>
          ${entries.map((e, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td><span class="${e.direction === 'mila' ? 'badge-mila' : 'badge-diya'}">${e.direction === 'mila' ? '↓ मिला' : '↑ दिया'}</span></td>
              <td><strong>${e.person_name}</strong></td>
              <td>${e.person_village || '—'}</td>
              <td>${e.event_title}</td>
              <td>${formatHindiDate(e.event_date || e.created_at)}</td>
              <td style="text-align: right; font-weight: 700; color: ${e.direction === 'mila' ? '#16A34A' : '#DC2626'};">${formatCurrency(e.cash_amount_paise)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    return this.createPdfAndShare('संपूर्ण पारिवारिक बही खाता', 'समस्त दर्ज व्यवहारों की आधिकारिक सूची', bodyContent);
  }

  /**
   * 2. Person-wise report
   */
  static async generatePersonReport(personId: string): Promise<string> {
    const db = getDb();
    const person = db.getFirstSync<Person>('SELECT * FROM people WHERE id = ?', personId);
    if (!person) throw new Error('व्यक्ति नहीं मिला');

    const entries = db.getAllSync<Entry>(
      `SELECT e.*, ev.title as event_title, ev.event_date as event_date
       FROM entries e
       JOIN events ev ON e.event_id = ev.id
       WHERE e.person_id = ? AND e.deleted_at IS NULL AND e.status = 'recorded'
       ORDER BY e.created_at DESC`,
      personId
    );

    let totalMila = 0;
    let totalDiya = 0;
    entries.forEach(e => {
      if (e.direction === 'mila') totalMila += e.cash_amount_paise;
      else if (e.direction === 'diya') totalDiya += e.cash_amount_paise;
    });

    const bodyContent = `
      <div class="summary-grid">
        <div class="summary-card card-mila">
          <div class="summary-label">इनसे मिला</div>
          <div class="summary-value val-mila">${formatCurrency(totalMila)}</div>
        </div>
        <div class="summary-card card-diya">
          <div class="summary-label">इनको दिया</div>
          <div class="summary-value val-diya">${formatCurrency(totalDiya)}</div>
        </div>
        <div class="summary-card card-neutral">
          <div class="summary-label">कुल व्यवहार संख्या</div>
          <div class="summary-value val-neutral">${entries.length}</div>
        </div>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>क्र.</th>
            <th>प्रकार</th>
            <th>कार्यक्रम</th>
            <th>तारीख</th>
            <th>नोट</th>
            <th style="text-align: right;">नकद राशि</th>
          </tr>
        </thead>
        <tbody>
          ${entries.map((e, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td><span class="${e.direction === 'mila' ? 'badge-mila' : 'badge-diya'}">${e.direction === 'mila' ? '↓ मिला' : '↑ दिया'}</span></td>
              <td><strong>${e.event_title}</strong></td>
              <td>${formatHindiDate(e.event_date || e.created_at)}</td>
              <td>${e.notes || '—'}</td>
              <td style="text-align: right; font-weight: 700; color: ${e.direction === 'mila' ? '#16A34A' : '#DC2626'};">${formatCurrency(e.cash_amount_paise)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    return this.createPdfAndShare(
      `${person.name} का व्यक्तिगत बही खाता`,
      `गाँव: ${person.village || '—'} | रिश्ता: ${person.relationship || '—'} | फोन: ${person.phone || '—'}`,
      bodyContent
    );
  }

  /**
   * 3. Event-wise report
   */
  static async generateEventReport(eventId: string): Promise<string> {
    const db = getDb();
    const event = db.getFirstSync<Event>('SELECT * FROM events WHERE id = ?', eventId);
    if (!event) throw new Error('कार्यक्रम नहीं मिला');

    const entries = db.getAllSync<Entry>(
      `SELECT e.*, p.name as person_name, p.village as person_village, p.relationship as person_relationship
       FROM entries e
       JOIN people p ON e.person_id = p.id
       WHERE e.event_id = ? AND e.deleted_at IS NULL AND e.status = 'recorded'
       ORDER BY e.created_at DESC`,
      eventId
    );

    let totalMila = 0;
    let totalDiya = 0;
    entries.forEach(e => {
      if (e.direction === 'mila') totalMila += e.cash_amount_paise;
      else if (e.direction === 'diya') totalDiya += e.cash_amount_paise;
    });

    const bodyContent = `
      <div class="summary-grid">
        <div class="summary-card card-mila">
          <div class="summary-label">कार्यक्रम में मिला</div>
          <div class="summary-value val-mila">${formatCurrency(totalMila)}</div>
        </div>
        <div class="summary-card card-diya">
          <div class="summary-label">कार्यक्रम में दिया</div>
          <div class="summary-value val-diya">${formatCurrency(totalDiya)}</div>
        </div>
        <div class="summary-card card-neutral">
          <div class="summary-label">कुल व्यवहार संख्या</div>
          <div class="summary-value val-neutral">${entries.length}</div>
        </div>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>क्र.</th>
            <th>प्रकार</th>
            <th>व्यक्ति</th>
            <th>गाँव</th>
            <th>रिश्ता</th>
            <th>नोट</th>
            <th style="text-align: right;">नकद राशि</th>
          </tr>
        </thead>
        <tbody>
          ${entries.map((e, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td><span class="${e.direction === 'mila' ? 'badge-mila' : 'badge-diya'}">${e.direction === 'mila' ? '↓ मिला' : '↑ दिया'}</span></td>
              <td><strong>${e.person_name}</strong></td>
              <td>${e.person_village || '—'}</td>
              <td>${e.person_relationship || '—'}</td>
              <td>${e.notes || '—'}</td>
              <td style="text-align: right; font-weight: 700; color: ${e.direction === 'mila' ? '#16A34A' : '#DC2626'};">${formatCurrency(e.cash_amount_paise)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    return this.createPdfAndShare(
      `${event.title} — व्यवहार रिपोर्ट`,
      `प्रकार: ${event.event_type} | तारीख: ${formatHindiDate(event.event_date)}`,
      bodyContent
    );
  }

  /**
   * 4. Year-wise report
   */
  static async generateYearReport(year: string): Promise<string> {
    const db = getDb();
    const entries = db.getAllSync<Entry>(
      `SELECT e.*, p.name as person_name, p.village as person_village, ev.title as event_title, ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL AND e.status = 'recorded'
         AND (ev.event_date LIKE ? OR e.created_at LIKE ?)
       ORDER BY e.created_at DESC`,
      DEFAULT_HOUSEHOLD_ID,
      `${year}%`,
      `${year}%`
    );

    let totalMila = 0;
    let totalDiya = 0;
    entries.forEach(e => {
      if (e.direction === 'mila') totalMila += e.cash_amount_paise;
      else if (e.direction === 'diya') totalDiya += e.cash_amount_paise;
    });

    const bodyContent = `
      <div class="summary-grid">
        <div class="summary-card card-mila">
          <div class="summary-label">वर्ष ${year} में मिला</div>
          <div class="summary-value val-mila">${formatCurrency(totalMila)}</div>
        </div>
        <div class="summary-card card-diya">
          <div class="summary-label">वर्ष ${year} में दिया</div>
          <div class="summary-value val-diya">${formatCurrency(totalDiya)}</div>
        </div>
        <div class="summary-card card-neutral">
          <div class="summary-label">कुल व्यवहार संख्या</div>
          <div class="summary-value val-neutral">${entries.length}</div>
        </div>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>क्र.</th>
            <th>प्रकार</th>
            <th>व्यक्ति</th>
            <th>गाँव</th>
            <th>कार्यक्रम</th>
            <th>तारीख</th>
            <th style="text-align: right;">नकद राशि</th>
          </tr>
        </thead>
        <tbody>
          ${entries.map((e, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td><span class="${e.direction === 'mila' ? 'badge-mila' : 'badge-diya'}">${e.direction === 'mila' ? '↓ मिला' : '↑ दिया'}</span></td>
              <td><strong>${e.person_name}</strong></td>
              <td>${e.person_village || '—'}</td>
              <td>${e.event_title}</td>
              <td>${formatHindiDate(e.event_date || e.created_at)}</td>
              <td style="text-align: right; font-weight: 700; color: ${e.direction === 'mila' ? '#16A34A' : '#DC2626'};">${formatCurrency(e.cash_amount_paise)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    return this.createPdfAndShare(`वार्षिक रिपोर्ट (${year})`, `वर्ष ${year} के समस्त व्यवहारों का लेखा-जोखा`, bodyContent);
  }

  /**
   * 5. Gift/item-wise report (estimated values strictly kept separate from cash)
   */
  static async generateItemReport(): Promise<string> {
    const db = getDb();
    const items = db.getAllSync<EntryItem & { person_name: string; event_title: string; direction: string; event_date: string }>(
      `SELECT i.*, p.name as person_name, ev.title as event_title, e.direction, ev.event_date
       FROM entry_items i
       JOIN entries e ON i.entry_id = e.id
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL AND e.status = 'recorded'
       ORDER BY i.created_at DESC`,
      DEFAULT_HOUSEHOLD_ID
    );

    let totalEstimatedValue = 0;
    items.forEach(it => {
      if (it.estimated_value_paise) totalEstimatedValue += it.estimated_value_paise;
    });

    const bodyContent = `
      <div class="summary-grid">
        <div class="summary-card card-neutral">
          <div class="summary-label">कुल उपहार/सामान संख्या</div>
          <div class="summary-value val-neutral">${items.length}</div>
        </div>
        <div class="summary-card card-neutral">
          <div class="summary-label">अनुमानित कुल सामान मूल्य (नकद से अलग)</div>
          <div class="summary-value" style="color: #C05A2B;">${formatCurrency(totalEstimatedValue)}</div>
        </div>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>क्र.</th>
            <th>वस्तु का नाम</th>
            <th>मात्रा</th>
            <th>प्रकार</th>
            <th>व्यक्ति</th>
            <th>कार्यक्रम</th>
            <th>अनुमानित मूल्य</th>
          </tr>
        </thead>
        <tbody>
          ${items.map((it, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td><strong>${it.item_name}</strong></td>
              <td>${it.quantity} ${it.unit}</td>
              <td><span class="${it.direction === 'mila' ? 'badge-mila' : 'badge-diya'}">${it.direction === 'mila' ? '↓ मिला' : '↑ दिया'}</span></td>
              <td>${it.person_name}</td>
              <td>${it.event_title}</td>
              <td style="color: #C05A2B; font-weight: 600;">${it.estimated_value_paise ? formatCurrency(it.estimated_value_paise) : '—'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    return this.createPdfAndShare('उपहार एवं सामान रिपोर्ट', 'समस्त भेंट व पारिवारिक उपहारों का विवरण', bodyContent);
  }

  /**
   * 6. Custom date-range report
   */
  static async generateCustomDateReport(startDate: string, endDate: string, direction?: 'mila' | 'diya'): Promise<string> {
    const db = getDb();
    let sql = `SELECT e.*, p.name as person_name, p.village as person_village, ev.title as event_title, ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL AND e.status = 'recorded'
         AND (ev.event_date BETWEEN ? AND ? OR e.created_at BETWEEN ? AND ?)`;
    const params: (string | number)[] = [DEFAULT_HOUSEHOLD_ID, startDate, endDate, startDate, endDate];
    if (direction) {
      sql += ' AND e.direction = ?';
      params.push(direction);
    }
    sql += ' ORDER BY e.created_at DESC';

    const entries = db.getAllSync<Entry>(sql, ...params);

    let totalMila = 0;
    let totalDiya = 0;
    entries.forEach(e => {
      if (e.direction === 'mila') totalMila += e.cash_amount_paise;
      else if (e.direction === 'diya') totalDiya += e.cash_amount_paise;
    });

    const bodyContent = `
      <div class="summary-grid">
        <div class="summary-card card-mila">
          <div class="summary-label">अवधि में मिला</div>
          <div class="summary-value val-mila">${formatCurrency(totalMila)}</div>
        </div>
        <div class="summary-card card-diya">
          <div class="summary-label">अवधि में दिया</div>
          <div class="summary-value val-diya">${formatCurrency(totalDiya)}</div>
        </div>
        <div class="summary-card card-neutral">
          <div class="summary-label">कुल व्यवहार संख्या</div>
          <div class="summary-value val-neutral">${entries.length}</div>
        </div>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>क्र.</th>
            <th>प्रकार</th>
            <th>व्यक्ति</th>
            <th>गाँव</th>
            <th>कार्यक्रम</th>
            <th>तारीख</th>
            <th style="text-align: right;">नकद राशि</th>
          </tr>
        </thead>
        <tbody>
          ${entries.map((e, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td><span class="${e.direction === 'mila' ? 'badge-mila' : 'badge-diya'}">${e.direction === 'mila' ? '↓ मिला' : '↑ दिया'}</span></td>
              <td><strong>${e.person_name}</strong></td>
              <td>${e.person_village || '—'}</td>
              <td>${e.event_title}</td>
              <td>${formatHindiDate(e.event_date || e.created_at)}</td>
              <td style="text-align: right; font-weight: 700; color: ${e.direction === 'mila' ? '#16A34A' : '#DC2626'};">${formatCurrency(e.cash_amount_paise)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;

    return this.createPdfAndShare(
      'तारीख अनुसार व्यवहार रिपोर्ट',
      `अवधि: ${formatHindiDate(startDate)} से ${formatHindiDate(endDate)} तक`,
      bodyContent
    );
  }

  /**
   * Creates the real PDF file and opens the Android native sharing dialog
   */
  private static async createPdfAndShare(title: string, subtitle: string, bodyContent: string): Promise<string> {
    const html = this.getBaseHtml(title, subtitle, bodyContent);
    const { uri } = await Print.printToFileAsync({ html });

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(uri, {
        mimeType: 'application/pdf',
        dialogTitle: `${title} — व्यवहार रिपोर्ट साझा करें`,
        UTI: 'com.adobe.pdf',
      });
    }

    return uri;
  }
}
