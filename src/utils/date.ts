const hindiMonths = [
  'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
  'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
];

export function formatHindiDate(isoDateString?: string): string {
  if (!isoDateString) return '';
  try {
    const parts = isoDateString.split('T')[0].split('-');
    if (parts.length === 3) {
      const year = parts[0];
      const monthIdx = parseInt(parts[1], 10) - 1;
      const day = parseInt(parts[2], 10);
      const monthName = hindiMonths[monthIdx] || parts[1];
      return `${day} ${monthName} ${year}`;
    }
    const d = new Date(isoDateString);
    if (isNaN(d.getTime())) return isoDateString;
    return `${d.getDate()} ${hindiMonths[d.getMonth()]} ${d.getFullYear()}`;
  } catch {
    return isoDateString;
  }
}

export const formatDate = formatHindiDate;

export function getTodayDateString(): string {
  const d = new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
