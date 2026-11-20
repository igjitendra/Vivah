# Project Overview — व्यवहार (Vyavahaar)

> **Official Name**: व्यवहार  
> **English Name**: Vyavahaar  
> **Tagline**: रिश्तों का हिसाब, हमेशा याद।  
> **Target Platforms**: Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop  
> **Target Audience**: Indian families, heads of households, event organizers, community elders.

---

## 1. Cultural Context & The Concept of व्यवहार

In traditional Indian society, social occasions are the bedrock of community bonding and familial relationships. During life events such as weddings (*Shaadi / Vivaah*), groom welcoming (*Baraat*), engagement (*Tilak / Sagai*), first haircut (*Mundan*), housewarming (*Griha Pravesh*), birth ceremonies (*Chhathi*), and milestone birthdays, relatives, neighbours, and friends exchange auspicious gifts and cash (*Shagun*, *Nauta*, *Bhaat*, or *Vyavahaar*).

This exchange is not a commercial transaction or a formal debt; rather, it is a **cultural ledger of mutual goodwill, social honour, and reciprocal support**.

### Traditional Practice
Traditionally, these exchanges were recorded by a trusted family member or elder in a red cloth-bound ledger called a **बही-खाता (Bahi-Khata)**. When a family hosts an event, entries are hastily jotted down during the celebration. Later, when attending the donor's family function years later, the hosts consult their old *bahi* to recall what was given to them, ensuring they reciprocate with dignity, respect, and social equilibrium.

### Real-World Problems with Traditional Physical Ledgers
1. **Misplacement & Physical Decay**: Physical notebooks suffer water damage, torn pages, insect infestation, or are simply lost over a decade.
2. **Inability to Search Quickly**: During an active wedding season, finding what "शर्मा जी (रामपुर वाले)" gave at an elder daughter's wedding 8 years ago requires flipping through hundreds of handwritten pages.
3. **Illegible Handwriting**: Hurried handwriting during a busy reception often makes donor names, village names, and amounts unreadable.
4. **No Historical Relationship View**: A paper ledger records by event, not by person. There is no easy way to see the complete 20-year history of reciprocal exchanges with a specific cousin or maternal uncle (*Mama*).
5. **No Planning Support**: Hosts cannot easily plan expected gifts or budget reciprocal attendance for upcoming wedding invitations.

---

## 2. Product Philosophy & Core Value Proposition

**व्यवहार (Vyavahaar)** provides a modern, dignified, and culturally respectful digital ledger designed specifically for Indian families:

1. **Dignity Over Debt**: The app **NEVER** computes a "net balance" or "who owes what". Commercial concepts like "you owe ₹5,000" violate Indian social etiquette. The app simply presents historical facts clearly: *"उन्होंने यह दिया था, हमने यह दिया था।"*
2. **100% Offline-First & Private**: Family relationships and monetary transactions are deeply personal. The app requires **no internet connection**, **no user accounts**, and **no cloud servers**. All data stays on the user's phone or desktop in an autonomous local SQLite database.
3. **Cross-Platform Accessibility**: Available on mobile devices (Android, iOS) for recording on-the-go at functions, and on desktop computers (Linux, macOS, Windows) for comfortable ledger review, data entry, and printing at home.
4. **Hindi-First Accessibility**: Built from the ground up in authentic Devanagari Hindi so that parents, elders, and family members across Bharat can use it without language barriers.
5. **Long-Term Preservation**: Supports encrypted offline backups that can be preserved and transferred across platforms without trusting third-party servers.

---

## 3. Real-World Use Cases

### Scenario A: Attending a Relative's Wedding
*Ramesh receives an invitation to his cousin's son's wedding in Varanasi. Before leaving home, Ramesh opens व्यवहार, searches for his cousin "सुरेश कुमार (वाराणसी)", and instantly sees: Suresh gave ₹2,100 cash and a silver coin at Ramesh's daughter's wedding in 2022. Ramesh can now honor the relationship with appropriate cultural reciprocity.*

### Scenario B: Managing a Family Function in Real-Time
*During a Tilak ceremony, cash gifts arrive rapidly at the stage. The user opens "त्वरित कार्य → नया व्यवहार दर्ज करें", selects the event "तिलक समारोह", picks or quickly adds the guest, enters ₹1,100, and taps save in under 5 seconds. All records are safe instantly.*

### Scenario C: Generating a Printable Family Record
*After a 3-day wedding celebration, the elders want a clean hardcopy record for the family archives. With one tap, व्यवहार generates a formal A4 Hindi PDF report with complete donor names, villages, and gift details, formatted for printing or sharing via WhatsApp with family elders.*

---

## 4. Product Modules Overview

- **होम (Home / Dashboard)**: Refined financial summary (separate Received/Given totals), key statistics, recent event card, and primary quick actions.
- **बही खाता (Ledger)**: Real-time search and filterable directory of all past and planned व्यवहार entries.
- **कार्यक्रम (Events)**: Event management and event-specific financial & gift ledger.
- **लोग व परिवार (People & Families)**: Directory of relatives, friends, village affiliations, and complete reciprocal relationship histories.
- **रिपोर्ट्स व निर्यात (Reports & Export)**: Year-wise, event-wise, person-wise, and item-wise PDF and CSV reports.
- **बैकअप व सुरक्षा (Backup & Restore)**: Military-grade AES-256 local encrypted backup with safety snapshot and rollback protection.
