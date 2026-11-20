import { db } from '../src/db/database';
import { formatCurrency, rupeesToPaise, paiseToRupees } from '../src/utils/currency';

async function runVerification() {
  console.log('--- व्यवहार (Vyavahaar) Database Verification ---');

  // 1. Currency test
  console.log('\n1. Testing Currency & Paise Math:');
  const rupees = 1100;
  const paise = rupeesToPaise(rupees);
  console.log(`₹${rupees} in paise: ${paise} (expected 110000)`);
  if (paise !== 110000) throw new Error('Paise conversion failed!');
  console.log(`Format paise ${paise}: ${formatCurrency(paise)} (expected ₹1,100)`);
  if (formatCurrency(paise) !== '₹1,100') throw new Error('Currency formatting failed!');

  // 2. Fetch People
  console.log('\n2. Testing People:');
  const people = await db.getPeople();
  console.log(`Total people seeded: ${people.length}`);
  people.forEach(p => console.log(` - ${p.name} (${p.village || 'No village'}) [${p.relationship || 'No relation'}]`));

  // 3. Fetch Events
  console.log('\n3. Testing Events:');
  const events = await db.getEvents();
  console.log(`Total events: ${events.length}`);
  events.forEach(e => {
    console.log(` - ${e.title} (${e.event_type}) on ${e.event_date}`);
    console.log(`   कुल मिला: ${formatCurrency(e.total_mila_paise || 0)} | कुल दिया: ${formatCurrency(e.total_diya_paise || 0)} | एंट्री: ${e.total_entries_count}`);
  });

  // 4. Fetch Entries
  console.log('\n4. Testing Entries & Items:');
  const entries = await db.getEntries();
  console.log(`Total entries: ${entries.length}`);
  entries.forEach(e => {
    console.log(` - [${e.direction.toUpperCase()}] ${e.person_name}: ${formatCurrency(e.cash_amount_paise)} for ${e.event_title}`);
    if (e.items && e.items.length > 0) {
      e.items.forEach(it => {
        console.log(`   🎁 Item: ${it.item_name} x ${it.quantity} ${it.unit} (est: ${it.estimated_value_paise ? formatCurrency(it.estimated_value_paise) : 'N/A'})`);
      });
    }
  });

  // 5. Dashboard Summary
  console.log('\n5. Testing Dashboard Summary:');
  const summary = await db.getDashboardSummary();
  console.log(`Dashboard Total Mila: ${formatCurrency(summary.totalMilaPaise)}`);
  console.log(`Dashboard Total Diya: ${formatCurrency(summary.totalDiyaPaise)}`);
  console.log(`Total Events: ${summary.totalEventsCount}, Total People: ${summary.totalPeopleCount}`);

  // 6. Test Backup Export and Restore
  console.log('\n6. Testing Backup & Restore:');
  const backupJson = await db.exportBackupJson();
  console.log(`Exported Backup size: ${backupJson.length} bytes`);
  const restoreSuccess = await db.restoreBackupJson(backupJson);
  console.log(`Restore operation success: ${restoreSuccess}`);
  if (!restoreSuccess) throw new Error('Backup restore failed!');

  console.log('\n✅ ALL VERIFICATION CHECKS PASSED SUCCESSFULLY!');
}

runVerification().catch(err => {
  console.error('❌ Verification failed:', err);
  process.exit(1);
});
