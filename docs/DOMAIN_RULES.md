# Domain & Financial Rules — व्यवहार (Vyavahaar)

> **Core Philosophy**: "रिश्तों का हिसाब, हमेशा याद।"  
> **Mandatory Status**: Non-negotiable cultural and business rules.  
> **Last Updated**: 2026-11-21

---

## 1. The 12 Mandatory Rules

### Rule 1: Mila (मिला) and Diya (दिया) are ALWAYS Separate
- **Definition**: *Mila* represents cash or gifts received by the user's family. *Diya* represents cash or gifts given by the user's family to others.
- **Rule**: Under NO circumstances shall `totalMila` and `totalDiya` be subtracted, netted, or balanced against one another.
- **Rationale**: Indian social relationships are not commercial credit accounts. Combining ₹10,000 received and ₹7,000 given into "₹3,000 net" is culturally offensive. Both totals must always be presented side-by-side with equal dignity.

### Rule 2: Integer Paise Currency Representation
- **Definition**: All monetary amounts are stored and calculated as integers in paise (`1 Rupee = 100 Paise`).
- **Rule**: Never use JavaScript floating-point numbers (`number`) or SQL `REAL` for financial calculations or storage.
- **Example**: ₹1,100 is strictly `110000` paise.
- **Rationale**: Floating-point rounding inaccuracies (such as `₹0.01` discrepancies) destroy user trust in financial accounting.

### Rule 3: Gift Estimates are Excluded from Cash Totals
- **Definition**: Physical gifts (such as sarees, silver coins, watches) may have an optional estimated valuation (`estimated_value_paise`).
- **Rule**: An item's estimated value must **NEVER** be added to or combined with the cash amount total. Cash totals reflect hard liquid currency; gifts are cultural symbols.
- **Example**: If a guest gives ₹500 cash plus a watch estimated at ₹1,500, the cash total is strictly ₹500, with "+ 1 भेंट (अनुमानित ₹1,500)" listed separately.

### Rule 4: Planned Transactions are NOT Completed Records
- **Definition**: A user may plan to give ₹2,100 at an upcoming wedding next month (`status = 'planned'`).
- **Rule**: Planned transactions and cancelled transactions (`status = 'cancelled'`) must **NEVER** be included in completed financial summary cards, dashboard metrics, or official PDF reports.
- **Rationale**: A planned gift is an intention, not an actual transfer. Counting planned amounts inflates actual family liquidity.

### Rule 5: Zero Automatic Debt Calculation
- **Rule**: The application must never state or imply that one person "owes" another person money, or that a balance is "due".
- **Rationale**: Traditional Indian gift exchanges are social gestures of goodwill, honour, and solidarity. Framing them as legal or enforceable debts is unacceptable.

### Rule 6: Transactions Support Cash-Only, Gift-Only, or Both
- **Rule**: An entry can be recorded with:
  1. Cash only (e.g. ₹501 with zero items).
  2. Physical gift only (e.g. ₹0 cash with "चाँदी का कटोरा").
  3. Cash AND one or more physical gifts together.

### Rule 7: Multiple Gifts per Transaction
- **Rule**: A single व्यवहार entry can have multiple associated physical gift items (e.g. 1 suit piece + 1 box of sweets + 1 silver coin) stored in `entry_items`.

### Rule 8: Never Silently Convert Planned Records
- **Rule**: A planned entry (`status = 'planned'`) must remain planned until the user explicitly confirms the transaction has been executed by changing its status to `recorded`.

### Rule 9: Soft Deletion Preservation
- **Rule**: Deleting an entry sets `deleted_at = datetime('now')`. Records are excluded from queries using `WHERE deleted_at IS NULL`, preserving audit trails and preventing accidental permanent loss of precious family memories.

### Rule 10: Foreign Key Deletion Protection
- **Rule**: A person with associated transaction records cannot be hard deleted (`ON DELETE RESTRICT`). This prevents orphaned transaction records.

### Rule 11: Offline-First Autonomy
- **Rule**: All transaction recording, calculations, PDF generation, and local backups must operate 100% offline without cellular network or Wi-Fi.

### Rule 12: No Commercial Ledger Terminology
- **Rule**: Use traditional, respectful Hindi terminology throughout:
  - Use **मिला** (Received) and **दिया** (Given), NOT *Credit / Debit* or *Income / Expense*.
  - Use **व्यवहार** or **बही-खाता**, NOT *Loan* or *Due*.
  - Use **कार्यक्रम**, NOT *Billing Project*.
