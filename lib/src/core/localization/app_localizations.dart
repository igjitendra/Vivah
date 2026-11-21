import 'package:flutter/material.dart';
import '../../domain/enums/transaction_enums.dart';

/// Central Type-Safe Localizations for व्यवहार (Vyavahaar).
/// Provides complete key parity across English, Hindi, Urdu, and all 22 Scheduled Indian Languages.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('hi', 'IN'));
  }

  static AppLocalizations fromLocale(Locale locale) {
    return AppLocalizations(locale);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isEnglish => locale.languageCode == 'en';
  bool get isUrdu => locale.languageCode == 'ur';

  // App Identity
  String get appName => isEnglish ? 'Vyavahaar' : (isUrdu ? 'ویوہار' : 'व्यवहार');
  String get appTagline => isEnglish
      ? 'Remembering family relations, forever.'
      : (isUrdu ? 'رشتوں کا حساب، ہمیشہ یاد۔' : 'रिश्तों का हिसाब, हमेशा याद।');

  // Navigation Tabs
  String get tabHome => isEnglish ? 'Home' : (isUrdu ? 'ہوم' : 'होम');
  String get tabBahi => isEnglish ? 'Ledger' : (isUrdu ? 'بہی' : 'बही');
  String get tabEvents => isEnglish ? 'Events' : (isUrdu ? 'تقاریب' : 'कार्यक्रम');
  String get tabPeople => isEnglish ? 'People' : (isUrdu ? 'افراد' : 'लोग');
  String get tabSettings => isEnglish ? 'Settings' : (isUrdu ? 'ترتیبات' : 'सेटिंग्स');

  // Financial Semantics (Strictly pure Mila / Diya without credit/debt/netting)
  String get received => isEnglish ? 'Received' : (isUrdu ? 'ملا' : 'मिला');
  String get given => isEnglish ? 'Given' : (isUrdu ? 'دیا' : 'दिया');
  String get direction => isEnglish ? 'Direction' : (isUrdu ? 'سمت' : 'दिशा');
  String get totalReceived => isEnglish ? 'Total Received' : (isUrdu ? 'کل ملا' : 'कुल मिला');
  String get totalGiven => isEnglish ? 'Total Given' : (isUrdu ? 'کل دیا' : 'कुल दिया');
  String get cashAmount => isEnglish ? 'Cash Amount' : (isUrdu ? 'نقد رقم' : 'नकद राशि');
  String get cash => isEnglish ? 'Cash' : (isUrdu ? 'نقد' : 'नकद');
  String get giftItem => isEnglish ? 'Gift / Item' : (isUrdu ? 'تحفہ' : 'भेंट / उपहार');
  String get cashAndItem => isEnglish ? 'Cash & Gift' : (isUrdu ? 'نقد و تحفہ' : 'नकद व भेंट');
  String get all => isEnglish ? 'All' : (isUrdu ? 'تمام' : 'सभी');
  String get itemOnly => isEnglish ? 'Item / Gift only' : (isUrdu ? 'صرف تحفہ / شے' : 'केवल वस्तु / भेंट');

  // Ledger / Transactions
  String get ledgerTitle => isEnglish ? 'Ledger' : (isUrdu ? 'بہی کھاتہ' : 'बही-खाता');
  String get newTransaction => isEnglish ? 'New Transaction' : (isUrdu ? 'نیا لین دین' : 'नया व्यवहार');
  String get recordNewTransaction => isEnglish ? 'Record New Transaction' : (isUrdu ? 'نیا لین دین درج کریں' : 'नया व्यवहार दर्ज करें');
  String get searchLedgerHint => isEnglish ? 'Search person, village or event...' : (isUrdu ? 'شخص، گاؤں یا تقریب تلاش کریں...' : 'व्यक्ति, गाँव या कार्यक्रम खोजें...');
  String get noTransactionsFound => isEnglish ? 'No transactions found' : (isUrdu ? 'کوئی لین دین نہیں ملا' : 'कोई व्यवहार नहीं मिला');
  String get transactionDetails => isEnglish ? 'Transaction Details' : (isUrdu ? 'لین دین کی تفصیلات' : 'व्यवहार विवरण');
  String get transactionDate => isEnglish ? 'Transaction Date' : (isUrdu ? 'تاریخ' : 'व्यवहार दिनांक');
  String get status => isEnglish ? 'Status' : (isUrdu ? 'حیثیت' : 'स्थिति');
  String get statusRecorded => isEnglish ? 'Recorded' : (isUrdu ? 'درج شدہ' : 'दर्ज किया गया');
  String get statusPlanned => isEnglish ? 'Planned' : (isUrdu ? 'منصوبہ بندی' : 'योजना');
  String get statusCancelled => isEnglish ? 'Cancelled' : (isUrdu ? 'منسوخ' : 'रद्द');
  String get notes => isEnglish ? 'Notes / Description' : (isUrdu ? 'نوٹس / تفصیلات' : 'टिप्पणी / विवरण');
  String get notesPlaceholder => isEnglish ? 'e.g. Wedding gift given...' : (isUrdu ? 'مثال: شادی کا تحفہ...' : 'उदा. अमित के विवाह में दिया गया शगुन...');
  String get saveTransaction => isEnglish ? 'Save Transaction' : (isUrdu ? 'لین دین محفوظ کریں' : 'व्यवहार सहेजें');
  String get deleteTransaction => isEnglish ? 'Delete Transaction' : (isUrdu ? 'لین دین حذف کریں' : 'व्यवहार हटाएं');
  String get confirmDeleteTransaction => isEnglish
      ? 'Are you sure you want to delete this transaction?'
      : (isUrdu ? 'کیا آپ واقعی اس لین دین کو حذف کرنا چاہتے ہیں؟' : 'क्या आप वाकई इस व्यवहार को हटाना चाहते हैं?');
  String get confirmDeleteTransactionTitle => isEnglish ? 'Delete Transaction?' : (isUrdu ? 'لین دین حذف کریں؟' : 'व्यवहार हटाएं?');
  String get transactionSavedSuccess => isEnglish ? 'Transaction saved successfully' : (isUrdu ? 'لین دین کامیابی سے محفوظ ہو گیا' : 'व्यवहार सफलतापूर्वक सहेजा गया');
  String get transactionDeletedSuccess => isEnglish ? 'Transaction deleted' : (isUrdu ? 'لین دین حذف کر دیا گیا' : 'व्यवहार हटा दिया गया');
  String get selectPerson => isEnglish ? 'Select Person' : (isUrdu ? 'شخص منتخب کریں' : 'व्यक्ति चुनें');
  String get selectPersonRequired => isEnglish ? 'Person is required *' : (isUrdu ? 'شخص درکار ہے *' : 'व्यक्ति (अनिवार्य) *');
  String get selectEventOptional => isEnglish ? 'Event (Optional)' : (isUrdu ? 'تقریب (اختیاری)' : 'कार्यक्रम (ऐच्छिक)');
  String get noEvent => isEnglish ? 'No Event' : (isUrdu ? 'کوئی تقریب نہیں' : 'कोई कार्यक्रम नहीं');
  String get amountRequired => isEnglish ? 'Please enter a valid amount' : (isUrdu ? 'برائے مہربانی درست رقم درج کریں' : 'कृपया वैध राशि दर्ज करें');
  String get amountPlaceholder => isEnglish ? 'e.g. 1100' : (isUrdu ? 'مثال: 1100' : 'उदा. 1100');
  String get amountRupees => isEnglish ? 'Cash Amount (₹ Rupees)' : (isUrdu ? 'نقد رقم (روپے)' : 'नकद राशि (₹ Rupees)');
  String get unknownPerson => isEnglish ? 'Unknown Person' : (isUrdu ? 'نامعلوم شخص' : 'अज्ञात व्यक्ति');
  String get generalEvent => isEnglish ? 'General' : (isUrdu ? 'عام' : 'सामान्य');
  String get relativeDefault => isEnglish ? 'Relative' : (isUrdu ? 'رشتہ دار' : 'रिश्तेदार');
  String get villageUnknown => isEnglish ? 'Village unknown' : (isUrdu ? 'گاؤں نامعلوم' : 'गाँव अज्ञात');
  String get noTransactionsForPerson => isEnglish ? 'No transactions recorded for this person yet' : (isUrdu ? 'اس شخص کے ساتھ ابھی کوئی لین دین درج نہیں ہے' : 'इस व्यक्ति के साथ अभी कोई व्यवहार दर्ज नहीं है');
  String get markRecorded => isEnglish ? 'Mark as Recorded' : (isUrdu ? 'مکمل نشان زد کریں' : 'व्यवहार पूर्ण मार्क करें');
  String get markedRecordedSuccess => isEnglish ? 'Transaction recorded successfully!' : (isUrdu ? 'لین دین کامیابی سے درج کر لیا گیا!' : 'व्यवहार दर्ज कर लिया गया!');
  String get cancelPlan => isEnglish ? 'Cancel Plan' : (isUrdu ? 'منصوبہ منسوخ کریں' : 'नियोजन रद्द करें');
  String get planCancelledSuccess => isEnglish ? 'Plan cancelled.' : (isUrdu ? 'منصوبہ منسوخ کر دیا گیا۔' : 'नियोजन रद्द किया गया।');
  String get type => isEnglish ? 'Type' : (isUrdu ? 'قسم' : 'प्रकार');
  String get estimated => isEnglish ? 'Estimated' : (isUrdu ? 'تخمینہ' : 'अनुमानित');
  String get items => isEnglish ? 'items' : (isUrdu ? 'اشیاء' : 'सामान');
  String giftItemsWithCount(int count) => isEnglish
      ? 'Gift items ($count)'
      : (isUrdu ? 'تحفے کی اشیاء ($count)' : 'भेंट की गई वस्तुएं ($count)');

  // People & Relatives
  String get peopleTitle => isEnglish ? 'People & Relatives' : (isUrdu ? 'لوگ اور رشتہ دار' : 'लोग व रिश्तेदार');
  String get searchPeopleHint => isEnglish ? 'Search by name, phone or village...' : (isUrdu ? 'نام، فون یا گاؤں سے تلاش کریں...' : 'नाम, फोन या गाँव से खोजें...');
  String get newPerson => isEnglish ? 'New Person' : (isUrdu ? 'نیا شخص' : 'नया व्यक्ति');
  String get addNewPerson => isEnglish ? 'Add New Person' : (isUrdu ? 'نیا شخص شامل کریں' : 'नया व्यक्ति जोड़ें');
  String get personName => isEnglish ? 'Full Name *' : (isUrdu ? 'مکمل نام *' : 'पूरा नाम *');
  String get personNameHint => isEnglish ? 'e.g. Ramesh Kumar' : (isUrdu ? 'مثال: رمیش کمار' : 'उदा. रमेश कुमार');
  String get phoneNumber => isEnglish ? 'Phone Number' : (isUrdu ? 'فون نمبر' : 'मोबाइल नंबर');
  String get phoneNumberHint => isEnglish ? 'e.g. 9876543210' : (isUrdu ? 'مثال: 9876543210' : 'उदा. 9876543210');
  String get villageCity => isEnglish ? 'Village / City' : (isUrdu ? 'گاؤں / شہر' : 'गाँव / शहर');
  String get villageCityHint => isEnglish ? 'e.g. Rampur' : (isUrdu ? 'مثال: رام پور' : 'उदा. रामपुर');
  String get relationCategory => isEnglish ? 'Relationship / Category' : (isUrdu ? 'رشتہ / زمرہ' : 'रिश्ता / श्रेणी');
  String get relationCategoryHint => isEnglish ? 'e.g. Maternal Uncle, Friend...' : (isUrdu ? 'مثال: ماموں، دوست...' : 'उदा. मामा, मित्र, पड़ोसी...');
  String get savePerson => isEnglish ? 'Save Person' : (isUrdu ? 'شخص محفوظ کریں' : 'व्यक्ति सहेजें');
  String get personDetails => isEnglish ? 'Person Details' : (isUrdu ? 'تفصیلات' : 'व्यक्ति विवरण');
  String get personSavedSuccess => isEnglish ? 'Person saved successfully' : (isUrdu ? 'شخص کامیابی سے محفوظ ہو گیا' : 'व्यक्ति सफलतापूर्वक सहेजा गया');
  String get noPeopleFound => isEnglish ? 'No people found' : (isUrdu ? 'کوئی شخص نہیں ملا' : 'कोई व्यक्ति नहीं मिला');
  String get personHistory => isEnglish ? 'Transaction History' : (isUrdu ? 'لین دین کی تاریخ' : 'व्यवहार इतिहास');
  String get call => isEnglish ? 'Call' : (isUrdu ? 'کال' : 'कॉल करें');
  String get whatsapp => isEnglish ? 'WhatsApp' : (isUrdu ? 'واٹس ایپ' : 'व्हाट्सएप');

  // Events
  String get eventsTitle => isEnglish ? 'Family Events' : (isUrdu ? 'خاندانی تقاریب' : 'पारिवारिक कार्यक्रम');
  String get searchEventsHint => isEnglish ? 'Search event name or venue...' : (isUrdu ? 'تقریب کا نام یا مقام تلاش کریں...' : 'कार्यक्रम का नाम या स्थल खोजें...');
  String get newEvent => isEnglish ? 'New Event' : (isUrdu ? 'نئی تقریب' : 'नया कार्यक्रम');
  String get createNewEvent => isEnglish ? 'Create New Event' : (isUrdu ? 'نئی تقریب بنائیں' : 'नया कार्यक्रम बनाएं');
  String get eventName => isEnglish ? 'Event Name *' : (isUrdu ? 'تقریب کا نام *' : 'कार्यक्रम का नाम *');
  String get eventNameHint => isEnglish ? "e.g. Amit's Wedding" : (isUrdu ? 'مثال: امت کی شادی' : 'उदा. अमित का विवाह');
  String get eventType => isEnglish ? 'Event Type' : (isUrdu ? 'تقریب کی قسم' : 'कार्यक्रम प्रकार');
  String get eventDate => isEnglish ? 'Date' : (isUrdu ? 'تاریخ' : 'दिनांक');
  String get eventLocation => isEnglish ? 'Venue / Location' : (isUrdu ? 'مقام' : 'स्थल / स्थान');
  String get eventLocationHint => isEnglish ? 'e.g. Shubh Vivah Hall, Jaipur' : (isUrdu ? 'مثال: شادی ہال، جے پور' : 'उदा. शुभ विवाह वाटिका, जयपुर');
  String get eventDescription => isEnglish ? 'Description' : (isUrdu ? 'تفصیل' : 'विवरण');
  String get saveEvent => isEnglish ? 'Save Event' : (isUrdu ? 'تقریب محفوظ کریں' : 'कार्यक्रम सहेजें');
  String get eventDetails => isEnglish ? 'Event Details' : (isUrdu ? 'تقریب کی تفصیلات' : 'कार्यक्रम विवरण');
  String get eventSavedSuccess => isEnglish ? 'Event saved successfully' : (isUrdu ? 'تقریب کامیابی سے محفوظ ہو گئی' : 'कार्यक्रम सफलतापूर्वक सहेजा गया');
  String get noEventsFound => isEnglish ? 'No events found' : (isUrdu ? 'کوئی تقریب نہیں ملی' : 'कोई कार्यक्रम नहीं मिला');
  String get recentEvent => isEnglish ? 'Recent Event' : (isUrdu ? 'حالیہ تقریب' : 'हाल का कार्यक्रम');
  String get viewAll => isEnglish ? 'View All' : (isUrdu ? 'تمام دیکھیں' : 'सभी देखें');
  String get noRecentEvent => isEnglish ? 'No active event' : (isUrdu ? 'کوئی فعال تقریب نہیں' : 'अभी कोई सक्रिय कार्यक्रम नहीं है');
  String get createFirstEvent => isEnglish ? 'Create First Event' : (isUrdu ? 'پہلی تقریب بنائیں' : 'पहला कार्यक्रम बनाएं');
  String get deleteEvent => isEnglish ? 'Delete Event' : (isUrdu ? 'تقریب حذف کریں' : 'कार्यक्रम हटाएं');
  String get confirmDeleteEventTitle => isEnglish ? 'Delete Event?' : (isUrdu ? 'تقریب حذف کریں؟' : 'कार्यक्रम हटाएं?');
  String get confirmDeleteEventBody => isEnglish
      ? 'Are you sure you want to delete this event? Its transactions will remain safe.'
      : (isUrdu ? 'کیا آپ واقعی اس تقریب کو حذف کرنا چاہتے ہیں؟ اس کے لین دین محفوظ رہیں گے۔' : 'क्या आप वाकई इस कार्यक्रम को हटाना चाहते हैं? इसके लेन-देन सुरक्षित रहेंगे।');
  String get eventTransactions => isEnglish ? 'Transactions' : (isUrdu ? 'لین دین کے اندراجات' : 'व्यवहार प्रविष्टियां');
  String get total => isEnglish ? 'Total' : (isUrdu ? 'کل' : 'कुल');
  String get noTransactionsForEvent => isEnglish ? 'No transactions in this event yet.' : (isUrdu ? 'اس تقریب میں کوئی اندراج نہیں ہے۔' : 'इस कार्यक्रम में कोई प्रविष्टि नहीं है।');
  String get familyEvent => isEnglish ? 'Family Occasion' : (isUrdu ? 'خاندانی تقریب' : 'पारिवारिक प्रसंग');

  // Event Types mapping
  String eventTypeLabel(EventType type) {
    if (isEnglish) {
      return switch (type) {
        EventType.shaadi => 'Wedding',
        EventType.tilak => 'Tilak Ceremony',
        EventType.mundan => 'Mundan (Tonsure)',
        EventType.baraat => 'Baraat',
        EventType.sagai => 'Engagement',
        EventType.anniversary => 'Anniversary',
        EventType.grihaPravesh => 'Housewarming',
        EventType.other => 'Other',
      };
    } else if (isUrdu) {
      return switch (type) {
        EventType.shaadi => 'شادی',
        EventType.tilak => 'تلک',
        EventType.mundan => 'منڈن',
        EventType.baraat => 'بارات',
        EventType.sagai => 'منگنی',
        EventType.anniversary => 'سالگرہ',
        EventType.grihaPravesh => 'تقریبِ رہائش',
        EventType.other => 'دیگر',
      };
    } else {
      return type.labelHindi;
    }
  }

  // Dashboard
  String get dashboardTitle => isEnglish ? 'Home' : (isUrdu ? 'ہوم' : 'होम');
  String get quickActions => isEnglish ? 'Quick Actions' : (isUrdu ? 'فوری اقدامات' : 'त्वरित कार्य');
  String get newEntrySubtitle => isEnglish ? 'Record cash or gift entry' : (isUrdu ? 'نقد رقم یا تحفہ درج کریں' : 'रुपये या भेंट की नई प्रविष्टि करें');
  String get newEventSubtitle => isEnglish ? 'Wedding, birthday or celebration' : (isUrdu ? 'شادی، سالگرہ یا تقریب' : 'शादी, जन्मदिन या पारिवारिक उत्सव');
  String get newPersonSubtitle => isEnglish ? 'Relative, friend or family member' : (isUrdu ? 'رشتہ دار، دوست یا فیملی ممبر' : 'रिश्तेदार, मित्र या परिवार का सदस्य');

  // Settings
  String get settingsTitle => isEnglish ? 'Settings' : (isUrdu ? 'ترتیبات' : 'सेटिंग्स');
  String get themeAndColors => isEnglish ? 'Themes & Colors' : (isUrdu ? 'تھیم اور رنگ' : 'थीम और रंग');
  String get themeAndColorsSubtitle => isEnglish ? 'Light, Dark, and 18+ Color Palettes' : (isUrdu ? 'لائٹ، ڈارک اور 18+ رنگ پیلیٹ' : 'लाइट, डार्क और 18+ रंग पैलेट');
  String get selectLanguage => isEnglish ? 'Language' : (isUrdu ? 'زبان منتخب کریں' : 'भाषा चुनें');
  String get selectLanguageSubtitle => isEnglish ? '22 Indian Languages + English' : (isUrdu ? '22 ہندوستانی زبانیں + انگریزی' : '22 भारतीय भाषाएं + English');
  String get selectLanguageTitle => isEnglish ? 'Select Language' : (isUrdu ? 'زبان منتخب کریں' : 'भाषा चुनें');
  String get searchLanguageHint => isEnglish ? 'Search language...' : (isUrdu ? 'زبان تلاش کریں...' : 'भाषा खोजें...');
  String scheduledLanguagesSubtitle(int count) => isEnglish
      ? 'All 22 Scheduled Indian Languages ($count + English)'
      : (isUrdu ? 'تمام 22 ہندوستانی زبانیں ($count + انگریزی)' : 'संविधान की 8वीं अनुसूची की सभी 22 भारतीय भाषाएं ($count + English)');
  String languageChangedTo(String lang) => isEnglish
      ? 'Language changed to: $lang'
      : (isUrdu ? 'زبان تبدیل ہو گئی: $lang' : 'भाषा बदली गई: $lang');

  String get backup => isEnglish ? 'Offline Backup' : (isUrdu ? 'آف لائن بیک اپ' : 'ऑफ़लाइन बैकअप');
  String get backupSubtitle => isEnglish ? 'Encrypted backup on your device' : (isUrdu ? 'محفوظ بیک اپ فائل حاصل کریں' : 'सुरक्षित बैकअप अपने डिवाइस पर लें');
  String get restore => isEnglish ? 'Restore Data' : (isUrdu ? 'ڈیٹا بحال کریں' : 'डेटा पुनर्स्थापना');
  String get restoreSubtitle => isEnglish ? 'Restore from encrypted backup file' : (isUrdu ? 'بیک اپ فائل سے بحال کریں' : 'सुरक्षित बैकअप फ़ाइल से पुनर्स्थापित करें');
  String get reports => isEnglish ? 'Reports & Export' : (isUrdu ? 'رپورٹس اور ایکسپورٹ' : 'रिपोर्ट्स व निर्यात');
  String get reportsSubtitle => isEnglish ? 'Export PDF and CSV ledger records' : (isUrdu ? 'پی ڈی ایف اور سی ایس وی برآمد کریں' : 'पीडीएफ़ और सीएसवी प्रारूप में निकालें');
  String get displayAndPreferences => isEnglish ? 'Display & Preferences' : (isUrdu ? 'ڈسپلے اور ترجیحات' : 'भाषा और प्राथमिकताएं');
  String get reportsAndReminders => isEnglish ? 'Reports & Reminders' : (isUrdu ? 'رپورٹس اور یاد دہانیاں' : 'रिपोर्ट्स और अनुस्मारक');
  String get offlineBackupAndRestore => isEnglish ? 'Offline Backup & Restore' : (isUrdu ? 'آف لائن بیک اپ اور بحالی' : 'ऑफ़लाइन बैकअप और पुनर्स्थापना');
  String get privacySecurity => isEnglish ? 'Privacy & Security' : (isUrdu ? 'رازداری اور سیکیورٹی' : 'गोपनीयता और सुरक्षा');
  String get offlineGuaranteed => isEnglish ? '100% Offline & Private' : (isUrdu ? '100% آف لائن اور محفوظ' : '100% ऑफ़लाइन और सुरक्षित');
  String get privacyPolicyNotice => isEnglish
      ? 'Vyavahaar does not send your family records to any external cloud or server. All data stays strictly private on your device.'
      : (isUrdu ? 'ویوہار آپ کے ریکارڈ کو کسی کلاؤڈ پر نہیں بھیجتا۔ تمام ڈیٹا آپ کے آلے پر محفوظ ہے۔' : 'व्यवहार आपके पारिवारिक रिकॉर्ड्स को किसी भी बाहरी सर्वर या क्लाउड पर नहीं भेजता। आपका सारा डेटा केवल आपके डिवाइस में सुरक्षित रहता है।');
  String get enterBackupPassword => isEnglish ? 'Enter Backup Password' : (isUrdu ? 'بیک اپ پاس ورڈ درج کریں' : 'बैकअप पासवर्ड दर्ज करें');
  String get backupPasswordHint => isEnglish ? 'Password (minimum 6 characters)' : (isUrdu ? 'پاس ورڈ (کم از کم 6 حروف)' : 'पासवर्ड (कम से कम 6 अक्षर)');
  String get enterRestorePassword => isEnglish ? 'Enter Decryption Password' : (isUrdu ? 'ڈکرپشن پاس ورڈ درج کریں' : 'डिक्रिप्शन पासवर्ड दर्ज करें');
  String get restorePasswordHint => isEnglish ? 'Password used during backup' : (isUrdu ? 'بیک اپ کے وقت استعمال کیا گیا پاس ورڈ' : 'बैकअप बनाते समय उपयोग किया गया पासवर्ड');
  String get appVersion => isEnglish ? 'App Version' : (isUrdu ? 'ایپ کا ورژن' : 'ऐप संस्करण');

  // Reminders
  String get reminders => isEnglish ? 'Reminders' : (isUrdu ? 'یاد دہانیاں' : 'अनुस्मारक');
  String get remindersTitle => isEnglish ? 'Reminders' : (isUrdu ? 'یاد دہانیاں' : 'अनुस्मारक');
  String get remindersSubtitle => isEnglish ? 'Upcoming transactions and events' : (isUrdu ? 'آنے والے لین دین اور تقاریب' : 'आगामी व्यवहार और आयोजनों की सूची');
  String get noReminders => isEnglish ? 'No reminders yet' : (isUrdu ? 'کوئی یاد دہانی نہیں ہے' : 'कोई अनुस्मारक नहीं है।');
  String get noRemindersSubtitle => isEnglish ? 'Set reminders for upcoming events or transactions' : (isUrdu ? 'آنے والی تقاریب کے لیے یاد دہانی سیٹ کریں' : 'आगामी आयोजनों या व्यवहार के लिए याद दिलाएं।');
  String get reminderDeleted => isEnglish ? 'Reminder deleted' : (isUrdu ? 'یاد دہانی حذف کر دی گئی' : 'अनुस्मारक हटाया गया');
  String get datePrefix => isEnglish ? 'Date: ' : (isUrdu ? 'تاریخ: ' : 'दिनांक: ');
  String get newReminder => isEnglish ? 'New Reminder' : (isUrdu ? 'نئی یاد دہانی' : 'नया अनुस्मारक बनाएं');
  String get reminderTitleLabel => isEnglish ? 'Title *' : (isUrdu ? 'عنوان *' : 'शीर्षक *');
  String get reminderTitleHint => isEnglish ? 'e.g. Wedding gift follow-up' : (isUrdu ? 'مثال: شادی کا تحفہ' : 'उदा. शादी में शगुन देना है');
  String get changeDate => isEnglish ? 'Change' : (isUrdu ? 'تبدیل کریں' : 'बदलें');
  String get notesOptional => isEnglish ? 'Notes (Optional)' : (isUrdu ? 'نوٹس (اختیاری)' : 'टिप्पणी (वैकल्पिक)');
  String get notesOptionalHint => isEnglish ? 'Add extra details' : (isUrdu ? 'اضافی تفصیلات لکھیں' : 'अतिरिक्त विवरण लिखें');

  // Reports
  String get completeLedgerPdf => isEnglish ? 'Complete Ledger (PDF)' : (isUrdu ? 'مکمل بہی کھاتہ (پی ڈی ایف)' : 'सम्पूर्ण बही-खाता (PDF)');
  String get completeLedgerPdfSubtitle => isEnglish ? 'All received and given transactions with dates and events' : (isUrdu ? 'تمام ملا و دیا لین دین، تاریخ اور تقریب کے ساتھ' : 'सभी मिला व दिया व्यवहार, दिनांक व कार्यक्रम के साथ A4 प्रिंट');
  String get receivedOnlyPdf => isEnglish ? 'Total Received Report (PDF)' : (isUrdu ? 'کل ملا رپورٹ (پی ڈی ایف)' : 'कुल मिला रिपोर्ट (PDF)');
  String get receivedOnlyPdfSubtitle => isEnglish ? 'Details of cash and gifts received only' : (isUrdu ? 'صرف موصولہ رقم اور تحائف کی تفصیلات' : 'केवल प्राप्त हुए नकद व उपहारों का विवरण');
  String get givenOnlyPdf => isEnglish ? 'Total Given Report (PDF)' : (isUrdu ? 'کل دیا رپورٹ (پی ڈی ایف)' : 'कुल दिया रिपोर्ट (PDF)');
  String get givenOnlyPdfSubtitle => isEnglish ? 'Details of cash and gifts given only' : (isUrdu ? 'صرف دیے گئے رقم اور تحائف کی تفصیلات' : 'केवल दिए गए नकद व उपहारों का विवरण');
  String get csvExport => isEnglish ? 'Excel / CSV Data Export' : (isUrdu ? 'ایکسل / سی ایس وی ڈیٹا ایکسپورٹ' : 'एक्सेल / सीएसवी डेटा निर्यात');
  String get csvExportSubtitle => isEnglish ? 'Microsoft Excel compatible (UTF-8 BOM), all columns' : (isUrdu ? 'مائیکروسافٹ ایکسل ہم آہنگ، تمام کالم' : 'माइक्रोसॉफ्ट एक्सेल संगत (UTF-8 BOM), सभी पंक्तियां और कॉलम');

  // Theme Gallery
  String get themeGalleryTitle => isEnglish ? 'Themes' : (isUrdu ? 'تھیمز' : 'थीम');
  String get themeGallerySubtitle => isEnglish ? 'Light and dark mode, and theme gallery' : (isUrdu ? 'لائٹ اور ڈارک موڈ، اور تھیم گیلری' : 'लाइट और डार्क मोड, एवं थीम गैलरी');
  String get colorTheme => isEnglish ? 'Color Theme' : (isUrdu ? 'رنگین تھیم' : 'रंग थीम');
  String get colorThemeAuto => isEnglish ? 'Auto (System)' : (isUrdu ? 'آٹو (سسٹم)' : 'ऑटो (सिस्टम)');
  String get colorThemeLight => isEnglish ? 'Light' : (isUrdu ? 'لائٹ' : 'लाइट');
  String get colorThemeDark => isEnglish ? 'Dark' : (isUrdu ? 'ڈارک' : 'डार्क');
  String get lightThemeSection => isEnglish ? 'Light theme' : (isUrdu ? 'لائٹ تھیم' : 'लाइट थीम');
  String get lightThemeDescription => isEnglish
      ? 'Used in Light mode, and by Auto when the system is light.'
      : (isUrdu ? 'لائٹ موڈ میں اور سسٹم لائٹ ہونے پر استعمال ہوگی۔' : 'लाइट मोड में और सिस्टम लाइट होने पर उपयोग होगी।');
  String get darkThemeSection => isEnglish ? 'Dark theme' : (isUrdu ? 'ڈارک تھیم' : 'डार्क थीम');
  String get darkThemeDescription => isEnglish
      ? 'Used in Dark mode, and by Auto when the system is dark.'
      : (isUrdu ? 'ڈارک موڈ میں اور سسٹم ڈارک ہونے پر استعمال ہوگی۔' : 'डार्क मोड में और सिस्टम डार्क होने पर उपयोग होगी।');
  String get done => isEnglish ? 'Done' : (isUrdu ? 'مکمل' : 'पूर्ण');

  // Common Actions & Dialogs
  String get save => isEnglish ? 'Save' : (isUrdu ? 'محفوظ کریں' : 'सहेजें');
  String get cancel => isEnglish ? 'Cancel' : (isUrdu ? 'منسوخ کریں' : 'रद्द करें');
  String get confirm => isEnglish ? 'Confirm' : (isUrdu ? 'تصدیق کریں' : 'पुष्टि करें');
  String get delete => isEnglish ? 'Delete' : (isUrdu ? 'حذف کریں' : 'हटाएं');
  String get edit => isEnglish ? 'Edit' : (isUrdu ? 'ترمیم کریں' : 'संपादित करें');
  String get search => isEnglish ? 'Search' : (isUrdu ? 'تلاش کریں' : 'खोजें');
  String get filters => isEnglish ? 'Filters' : (isUrdu ? 'فلٹرز' : 'फ़िल्टर');
  String get loading => isEnglish ? 'Loading...' : (isUrdu ? 'لوڈ ہو رہا ہے...' : 'लोड हो रहा है...');
  String get validationRequired => isEnglish ? 'This field is required' : (isUrdu ? 'یہ خانہ درکار ہے' : 'यह फ़ील्ड आवश्यक है');
  String get errorDatabase => isEnglish ? 'Database Error' : (isUrdu ? 'ڈیٹابیس کی خرابی' : 'डेटाबेस त्रुटि');
  String get errorGeneric => isEnglish ? 'An error occurred' : (isUrdu ? 'ایک خرابی پیش آ گئی' : 'एक त्रुटि हुई');
  String get retry => isEnglish ? 'Retry' : (isUrdu ? 'دوبارہ کوشش کریں' : 'पुनः प्रयास करें');
  String get languageChanged => isEnglish ? 'Language changed' : (isUrdu ? 'زبان تبدیل ہو گئی' : 'भाषा बदली गई');
  String get backupSuccess => isEnglish ? 'Backup created successfully' : (isUrdu ? 'بیک اپ کامیابی سے بن گیا' : 'बैकअप सफलतापूर्वक बनाया गया');
  String get restoreSuccess => isEnglish ? 'Data restored successfully' : (isUrdu ? 'ڈیٹا کامیابی سے بحال ہو گیا' : 'डेटा सफलतापूर्वक पुनर्स्थापित हुआ');

  // Plurals
  String entryCount(int count) {
    if (isEnglish) {
      if (count == 0) return 'No transactions';
      if (count == 1) return '1 transaction';
      return '$count transactions';
    } else if (isUrdu) {
      if (count == 0) return 'کوئی لین دین نہیں';
      if (count == 1) return '1 لین دین';
      return '$count لین دین';
    } else {
      if (count == 0) return 'कोई व्यवहार नहीं';
      if (count == 1) return '1 व्यवहार';
      return '$count व्यवहार';
    }
  }

  String personCount(int count) {
    if (isEnglish) {
      if (count == 0) return 'No people';
      if (count == 1) return '1 person';
      return '$count people';
    } else if (isUrdu) {
      if (count == 0) return 'کوئی شخص نہیں';
      if (count == 1) return '1 شخص';
      return '$count افراد';
    } else {
      if (count == 0) return 'कोई व्यक्ति नहीं';
      if (count == 1) return '1 व्यक्ति';
      return '$count व्यक्ति';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
