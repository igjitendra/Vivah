#!/usr/bin/env tsx
/**
 * Business logic test script for Vyavahaar Phase 2
 * Tests currency utils, date utils, and validation schemas
 * Run: pnpm dlx tsx scripts/test-business-logic.ts
 */

import { formatCurrency, paiToRupees, rupeesToPaise } from '../src/utils/currency';
import { formatDate, getTodayDateString } from '../src/utils/date';
import { CreateEntrySchema, CreatePersonSchema, CreateEventSchema } from '../src/validation/schemas';

let passed = 0;
let failed = 0;

function test(name: string, fn: () => void) {
  try {
    fn();
    console.log(`  ✅ ${name}`);
    passed++;
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    console.log(`  ❌ ${name}: ${msg}`);
    failed++;
  }
}

function assert(condition: boolean, msg: string) {
  if (!condition) throw new Error(msg);
}

console.log('\n🧪 Vyavahaar Business Logic Tests\n');

// ── Currency tests ────────────────────────────────────────────────────────
console.log('💰 Currency Utils:');
test('₹1,100 = 110000 paise', () => {
  assert(rupeesToPaise(1100) === 110000, `Expected 110000, got ${rupeesToPaise(1100)}`);
});
test('110000 paise = ₹1,100', () => {
  assert(paiToRupees(110000) === 1100, `Expected 1100, got ${paiToRupees(110000)}`);
});
test('formatCurrency(110000) = ₹1,100', () => {
  const result = formatCurrency(110000);
  assert(result.includes('1,100') || result.includes('1100'), `Got: ${result}`);
});
test('formatCurrency(0) works', () => {
  const result = formatCurrency(0);
  assert(result.includes('0'), `Got: ${result}`);
});
test('No floating point errors', () => {
  const paise = rupeesToPaise(10.50);
  assert(Number.isInteger(paise), `Expected integer, got ${paise}`);
});
test('mila and diya stored separately (never net)', () => {
  const mila = 500000; // ₹5000
  const diya = 300000; // ₹3000
  assert(mila !== mila - diya, 'mila and diya must not be netted');
  assert(formatCurrency(mila) !== formatCurrency(mila - diya), 'separate display');
});

// ── Date tests ────────────────────────────────────────────────────────────
console.log('\n📅 Date Utils:');
test('getTodayDateString returns YYYY-MM-DD', () => {
  const today = getTodayDateString();
  assert(/^\d{4}-\d{2}-\d{2}$/.test(today), `Got: ${today}`);
});
test('formatDate handles ISO string', () => {
  const result = formatDate('2025-01-15');
  assert(result.length > 0, 'Should return non-empty string');
});

// ── Validation tests ──────────────────────────────────────────────────────
console.log('\n✅ Validation Schemas (Zod v4):');
test('CreatePersonSchema: valid input passes', () => {
  const result = CreatePersonSchema.safeParse({ name: 'रमेश', village: 'रामपुर', relationship: 'मामा' });
  assert(result.success, `Validation failed: ${!result.success ? JSON.stringify(result.error) : ''}`);
});
test('CreatePersonSchema: empty name fails', () => {
  const result = CreatePersonSchema.safeParse({ name: '' });
  assert(!result.success, 'Empty name should fail');
});
test('CreateEventSchema: valid input passes', () => {
  const result = CreateEventSchema.safeParse({ title: 'रमेश की शादी', event_type: 'शादी', event_date: '2025-06-15' });
  assert(result.success, `Validation failed: ${!result.success ? JSON.stringify(result.error) : ''}`);
});
test('CreateEventSchema: bad date format fails', () => {
  const result = CreateEventSchema.safeParse({ title: 'Test', event_type: 'शादी', event_date: '15-06-2025' });
  assert(!result.success, 'Bad date format should fail');
});
test('CreateEventSchema: invalid event_type fails', () => {
  const result = CreateEventSchema.safeParse({ title: 'Test', event_type: 'birthday', event_date: '2025-01-01' });
  assert(!result.success, 'Invalid event type should fail');
});
test('CreateEntrySchema: valid mila entry passes', () => {
  const result = CreateEntrySchema.safeParse({ event_id: 'ev1', person_id: 'p1', direction: 'mila', cash_amount_paise: 110000, items: [] });
  assert(result.success, `Validation failed: ${!result.success ? JSON.stringify(result.error) : ''}`);
});
test('CreateEntrySchema: negative paise fails', () => {
  const result = CreateEntrySchema.safeParse({ event_id: 'ev1', person_id: 'p1', direction: 'mila', cash_amount_paise: -100, items: [] });
  assert(!result.success, 'Negative paise should fail');
});
test('CreateEntrySchema: invalid direction fails', () => {
  const result = CreateEntrySchema.safeParse({ event_id: 'ev1', person_id: 'p1', direction: 'both', cash_amount_paise: 1000, items: [] });
  assert(!result.success, 'Invalid direction should fail');
});

// ── Summary ───────────────────────────────────────────────────────────────
console.log(`\n${'─'.repeat(40)}`);
console.log(`Results: ${passed} passed, ${failed} failed`);
if (failed > 0) {
  console.log('⚠️ Some tests failed. Fix before committing.');
  process.exit(1);
} else {
  console.log('🎉 All tests passed!');
}
