/**
 * Currency utilities for paise integer calculation.
 * ₹1,100 is stored as 110000 paise to prevent floating-point calculation issues.
 */

export function paiseToRupees(paise: number = 0): number {
  return Math.round(paise) / 100;
}

export function rupeesToPaise(rupees: number | string = 0): number {
  const numeric = typeof rupees === 'string' ? parseFloat(rupees.replace(/[^0-9.]/g, '')) : rupees;
  if (isNaN(numeric) || numeric < 0) return 0;
  return Math.round(numeric * 100);
}

export function formatCurrency(paise: number = 0): string {
  const rupees = paiseToRupees(paise);
  return '₹' + rupees.toLocaleString('en-IN', {
    maximumFractionDigits: 2,
    minimumFractionDigits: rupees % 1 === 0 ? 0 : 2,
  });
}
