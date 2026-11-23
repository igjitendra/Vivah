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


  String get today => isEnglish ? 'Today' : (isUrdu ? 'آج' : 'आज');
  String get yesterday => isEnglish ? 'Yesterday' : (isUrdu ? 'کل' : 'कल');
  String get customDate => isEnglish ? 'Pick Date' : (isUrdu ? 'کیلنڈر' : 'कैलेंडर');
  String get searchRelativeHint => isEnglish ? 'Search by name, relation or village...' : (isUrdu ? 'نام، رشتہ یا گاؤں سے تلاش کریں...' : 'नाम, रिश्ता या गाँव से खोजें...');
  String get quickAddRelative => isEnglish ? '+ New Relative' : (isUrdu ? '+ نیا شخص شامل کریں' : '+ नया व्यक्ति जोड़ें');
  String get selectRelativeTapHint => isEnglish ? 'Tap to choose or create a person *' : (isUrdu ? 'شخص منتخب کرنے کے لیے ٹیپ کریں *' : 'व्यक्ति या रिश्तेदार चुनने के लिए टैप करें *');
  String get shagunReceivedSubtitle => isEnglish ? 'Money / Gift received from relative' : (isUrdu ? 'خاندان سے تحفہ یا رقم ملی' : 'पारिवारिक शगुन / न्योता प्राप्त हुआ');
  String get shagunGivenSubtitle => isEnglish ? 'Money / Gift given to relative' : (isUrdu ? 'رشتہ داروں کو دیا گیا شگون' : 'रिश्तेदारी में दिया गया शगुन / भेंट');
  String get amountInWords => isEnglish ? 'Amount in words' : (isUrdu ? 'الفاظ میں رقم' : 'शब्दों में राशि');
  String get quickGiftsTitle => isEnglish ? 'Suggested Gifts' : (isUrdu ? 'تجویز کردہ تحائف' : 'सुझाए गए उपहार');
  String get quickNotesTitle => isEnglish ? 'Quick Tags' : (isUrdu ? 'فوری ٹیگز' : 'त्वरित टैग');
  String get selectPersonError => isEnglish ? 'Please select a person' : (isUrdu ? 'برائے مہربانی شخص منتخب کریں' : 'कृपया व्यक्ति या रिश्तेदार चुनें');
  String get addAtLeastOneItemError => isEnglish ? 'Please add at least 1 item' : (isUrdu ? 'کم از کم 1 شے شامل کریں' : 'कम से कम 1 सामान जोड़ें');
  String get relativeSavedSuccess => isEnglish ? 'Person added successfully' : (isUrdu ? 'شخص کامیابی سے شامل ہو گیا' : 'व्यक्ति सफलतापूर्वक जोड़ा गया');
  String get personFullName => isEnglish ? 'Full Name *' : (isUrdu ? 'پورا نام *' : 'पूरा नाम *');
  String get personFullNameHint => isEnglish ? 'e.g. Ramesh Sharma' : (isUrdu ? 'مثال: رمیش شرما' : 'उदा. रमेश शर्मा');
  String get relationship => isEnglish ? 'Relationship' : (isUrdu ? 'رشتہ' : 'रिश्ता / संबंध');
  String get villageOrCity => isEnglish ? 'Village / City' : (isUrdu ? 'گاؤں / شہر' : 'गाँव / शहर');
  String get villageOrCityHint => isEnglish ? 'e.g. Rampur, Jaipur' : (isUrdu ? 'مثال: رام پور' : 'उदा. रामपुर, जयपुर');
  String get optionalField => isEnglish ? 'Optional' : (isUrdu ? 'اختیاری' : 'ऐच्छिक');

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
  String get transactions => isEnglish ? 'Transactions' : (isUrdu ? 'لین دین' : 'व्यवहार');
  String get recordNewTransaction => isEnglish ? 'Record New Transaction' : (isUrdu ? 'نیا لین دین درج کریں' : 'नया व्यवहार दर्ज करें');
  String get searchLedgerHint => isEnglish ? 'Search person, village or event...' : (isUrdu ? 'شخص، گاؤں یا تقریب تلاش کریں...' : 'व्यक्ति, गाँव या कार्यक्रम खोजें...');
  String get noTransactionsFound => isEnglish ? 'No transactions found' : (isUrdu ? 'کوئی لین دین نہیں ملا' : 'कोई व्यवहार नहीं मिला');
  String get noResultsFound => isEnglish ? 'No results found' : (isUrdu ? 'کوئی نتیجہ نہیں ملا' : 'कोई परिणाम नहीं मिला');
  String get noEntriesYet => isEnglish ? 'No transactions yet' : (isUrdu ? 'ابھی کوئی لین دین نہیں ہے' : 'अभी कोई व्यवहार नहीं है');
  String get tryDifferentSearch => isEnglish ? 'Try a different search term' : (isUrdu ? 'مختلف الفاظ سے تلاش کرنے کی کوشش کریں' : 'अलग नाम या शब्द से खोजें');
  String get recordFirstTransaction => isEnglish ? 'Tap below to record your first transaction' : (isUrdu ? 'اپنا پہلا لین دین درج کرنے کے لیے نیچے ٹیپ کریں' : 'नीचे बटन दबाकर पहला व्यवहार दर्ज करें');
  String get offlineNotice => isEnglish ? '100% Offline & Private' : (isUrdu ? '100% آف لائن اور نجی' : '100% ऑफ़लाइन और सुरक्षित');
  String get planned => statusPlanned;
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
  String get quickShagun => isEnglish ? 'Quick Shagun' : (isUrdu ? 'فوری شگون' : 'त्वरित शगुन');
  String get addItem => isEnglish ? 'Add Gift Item' : (isUrdu ? 'تحفہ شامل کریں' : 'भेंट/सामान जोड़ें');
  String get itemName => isEnglish ? 'Item Name' : (isUrdu ? 'شے کا نام' : 'सामान का नाम');
  String get itemNameHint => isEnglish ? 'e.g. Gold ring, Saree, Sweets' : (isUrdu ? 'مثال: سونے کی انگوٹھی، ساڑھی' : 'उदा. सोने की अंगूठी, साड़ी, मिठाई');
  String get quantity => isEnglish ? 'Quantity' : (isUrdu ? 'مقدار' : 'मात्रा');
  String get unit => isEnglish ? 'Unit' : (isUrdu ? 'اکائی' : 'इकाई');
  String get customCeremony => isEnglish ? 'Custom Ceremony' : (isUrdu ? 'دیگر تقریب' : 'कस्टम कार्यक्रम');
  String get customCeremonyHint => isEnglish ? 'e.g. Birthday, Naming Ceremony, Upanayana' : (isUrdu ? 'مثال: سالگرہ، نام رکھنے کی تقریب' : 'उदा. जन्मदिन, नामकरण, जनेऊ');
  String get suggestedRelationshipsTitle => isEnglish ? 'Common Relationships' : (isUrdu ? 'عام رشتے' : 'सामान्य संबंध');
  String get suggestedCeremoniesTitle => isEnglish ? 'Popular Ceremonies' : (isUrdu ? 'مشہور تقاریب' : 'लोकप्रिय कार्यक्रम');

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
  String get personNotFound => isEnglish ? 'Person not found' : (isUrdu ? 'شخص نہیں ملا' : 'व्यक्ति नहीं मिला');
  String get personSavedSuccess => isEnglish ? 'Person saved successfully' : (isUrdu ? 'شخص کامیابی سے محفوظ ہو گیا' : 'व्यक्ति सफलतापूर्वक सहेजा गया');
  String get noPeopleFound => isEnglish ? 'No people found' : (isUrdu ? 'کوئی شخص نہیں ملا' : 'कोई व्यक्ति नहीं मिला');
  String get editPerson => isEnglish ? 'Edit Person' : (isUrdu ? 'شخص ترمیم کریں' : 'व्यक्ति संपादित करें');
  String get editEvent => isEnglish ? 'Edit Event' : (isUrdu ? 'تقریب ترمیم کریں' : 'कार्यक्रम संपादित करें');
  String get editTransaction => isEnglish ? 'Edit Transaction' : (isUrdu ? 'لین دین ترمیم کریں' : 'व्यवहार संपादित करें');
  String get deletePerson => isEnglish ? 'Delete Person' : (isUrdu ? 'شخص حذف کریں' : 'व्यक्ति हटाएं');
  String get confirmDeletePersonTitle => isEnglish ? 'Delete Person?' : (isUrdu ? 'کیا شخص حذف کریں؟' : 'व्यक्ति हटाएं?');
  String get cannotDeletePersonWithTransactions => isEnglish
      ? 'Cannot delete person with recorded transactions.'
      : (isUrdu ? 'لین دین والے شخص کو حذف نہیں کیا جا سکتا۔' : 'जिन व्यक्तियों के साथ लेनदेन दर्ज हैं, उन्हें हटाया नहीं जा सकता।');
  String get confirmDeletePerson => isEnglish
      ? 'Are you sure you want to delete this person?'
      : (isUrdu ? 'کیا آپ واقعی اس شخص کو حذف کرنا چاہتے ہیں؟' : 'क्या आप वाकई इस व्यक्ति को हटाना चाहते हैं?');
  String get personUpdatedSuccess => isEnglish ? 'Person updated successfully' : (isUrdu ? 'شخص کامیابی سے اپ ڈیٹ ہو گیا' : 'व्यक्ति विवरण सफलतापूर्वक अपडेट हुआ');
  String get eventUpdatedSuccess => isEnglish ? 'Event updated successfully' : (isUrdu ? 'تقریب کامیابی سے اپ ڈیٹ ہو گئی' : 'कार्यक्रम सफलतापूर्वक अपडेट हुआ');
  String get transactionUpdatedSuccess => isEnglish ? 'Transaction updated successfully' : (isUrdu ? 'لین دین کامیابی سے اپ ڈیٹ ہو گیا' : 'व्यवहार सफलतापूर्वक अपडेट हुआ');

  // Families / Clan System
  String get familiesTitle => isEnglish ? 'Families & Clans' : (isUrdu ? 'خاندان' : 'परिवार व कुल');
  String get newFamily => isEnglish ? 'New Family' : (isUrdu ? 'نیا خاندان' : 'नया परिवार');
  String get addNewFamily => isEnglish ? 'Add New Family' : (isUrdu ? 'نیا خاندان شامل کریں' : 'नया परिवार जोड़ें');
  String get familyName => isEnglish ? 'Family Name *' : (isUrdu ? 'خاندان کا نام *' : 'परिवार का नाम *');
  String get familyNameHint => isEnglish ? 'e.g. Sharma Family - Kanpur' : (isUrdu ? 'مثال: شرما خاندان' : 'उदा. शर्मा परिवार - कानपुर');
  String get familyDescription => isEnglish ? 'Description / Village' : (isUrdu ? 'تفصیل / گاؤں' : 'विवरण / गाँव');
  String get familyDescriptionHint => isEnglish ? 'e.g. Maternal side relatives' : (isUrdu ? 'مثال: ننھیال کے رشتہ دار' : 'उदा. ननिहाल पक्ष के रिश्तेदार');
  String get selectFamilyOptional => isEnglish ? 'Family / Clan (Optional)' : (isUrdu ? 'خاندان (اختیاری)' : 'परिवार / कुल (वैकल्पिक)');
  String get noFamily => isEnglish ? 'No Family (Independent)' : (isUrdu ? 'کوئی خاندان نہیں' : 'कोई परिवार नहीं');
  String get familySavedSuccess => isEnglish ? 'Family saved successfully' : (isUrdu ? 'خاندان کامیابی سے محفوظ ہو گیا' : 'परिवार सफलतापूर्वक सहेजा गया');
  String get membersCount => isEnglish ? 'Members' : (isUrdu ? 'افراد' : 'सदस्य');
  String get noFamiliesFound => isEnglish ? 'No families added yet' : (isUrdu ? 'ابھی کوئی خاندان شامل نہیں ہے' : 'अभी कोई परिवार नहीं जोड़ा गया');
  String get peopleTab => isEnglish ? 'People' : (isUrdu ? 'افراد' : 'लोग');
  String get familiesTab => isEnglish ? 'Families' : (isUrdu ? 'خاندان' : 'परिवार');

  // Advanced Filters
  String get advancedFilters => isEnglish ? 'Advanced Filters' : (isUrdu ? 'مزید فلٹرز' : 'उन्नत फ़िल्टर');
  String get filterByEvent => isEnglish ? 'Filter by Event' : (isUrdu ? 'تقریب سے فلٹر' : 'कार्यक्रम अनुसार फ़िल्टर');
  String get filterByType => isEnglish ? 'Transaction Type' : (isUrdu ? 'لین دین کی قسم' : 'लेनदेन का प्रकार');
  String get filterByStatus => isEnglish ? 'Status' : (isUrdu ? 'حیثیت' : 'स्थिति');
  String get sortBy => isEnglish ? 'Sort By' : (isUrdu ? 'ترتیب دیں' : 'क्रमबद्ध करें');
  String get newestFirst => isEnglish ? 'Newest First' : (isUrdu ? 'تازہ ترین پہلے' : 'नवीनतम पहले');
  String get oldestFirst => isEnglish ? 'Oldest First' : (isUrdu ? 'قدیم ترین پہلے' : 'पुरातन पहले');
  String get amountHighToLow => isEnglish ? 'Amount: High to Low' : (isUrdu ? 'رقم: زیادہ سے کم' : 'अधिकतम राशि पहले');
  String get amountLowToHigh => isEnglish ? 'Amount: Low to High' : (isUrdu ? 'رقم: کم سے زیادہ' : 'न्यूनतम राशि पहले');
  String get clearFilters => isEnglish ? 'Clear Filters' : (isUrdu ? 'فلٹرز صاف کریں' : 'फ़िल्टर हटाएं');
  String get applyFilters => isEnglish ? 'Apply Filters' : (isUrdu ? 'فلٹرز لگائیں' : 'फ़िल्टर लागू करें');

  // Analytics & Insights
  String get insightsTitle => isEnglish ? 'Insights & Analytics' : (isUrdu ? 'تجزیات اور شماریات' : 'सांख्यिकी व अंतर्दृष्टि');
  String get topTransactions => isEnglish ? 'Top Shagun Transactions' : (isUrdu ? 'سب سے بڑے لین دین' : 'शीर्ष शगुन लेनदेन');
  String get topReceived => isEnglish ? 'Top Received' : (isUrdu ? 'سب سے زیادہ ملا' : 'शीर्ष प्राप्त');
  String get topGiven => isEnglish ? 'Top Given' : (isUrdu ? 'سب سے زیادہ دیا' : 'शीर्ष दिया गया');
  String get eventBreakdown => isEnglish ? 'Event-Wise Summary' : (isUrdu ? 'تقریب وار تفصیل' : 'कार्यक्रम-वार सारांश');
  String get activitySummary => isEnglish ? 'Activity Overview' : (isUrdu ? 'سرگرمی کا خلاصہ' : 'गतिविधि विवरण');
  String get totalTransactionsCount => isEnglish ? 'Total Transactions' : (isUrdu ? 'کل لین دین' : 'कुल लेनदेन');
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
  String get eventNotFound => isEnglish ? 'Event not found' : (isUrdu ? 'تقریب نہیں ملی' : 'कार्यक्रम नहीं मिला');
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
        EventType.shaadi || EventType.wedding => 'Wedding',
        EventType.tilak => 'Tilak Ceremony',
        EventType.mundan => 'Mundan (Tonsure)',
        EventType.baraat => 'Baraat',
        EventType.sagai || EventType.engagement => 'Engagement',
        EventType.haldi => 'Haldi Ceremony',
        EventType.mehndi => 'Mehndi Ceremony',
        EventType.reception => 'Reception',
        EventType.birthday => 'Birthday',
        EventType.anniversary => 'Anniversary',
        EventType.grihaPravesh => 'Housewarming (Griha Pravesh)',
        EventType.religiousCeremony => 'Religious Ceremony',
        EventType.festival => 'Festival',
        EventType.familyGathering => 'Family Gathering',
        EventType.funeral => 'Funeral / Shraddh',
        EventType.communityEvent => 'Community Event',
        EventType.other => 'Other',
      };
    } else if (isUrdu) {
      return switch (type) {
        EventType.shaadi || EventType.wedding => 'شادی',
        EventType.tilak => 'تلک',
        EventType.mundan => 'منڈن',
        EventType.baraat => 'بارات',
        EventType.sagai || EventType.engagement => 'منگنی',
        EventType.haldi => 'ہلدی',
        EventType.mehndi => 'مہندی',
        EventType.reception => 'دعوتِ ولیمہ',
        EventType.birthday => 'سالگرہ پيدائش',
        EventType.anniversary => 'سالگرہ',
        EventType.grihaPravesh => 'تقریبِ رہائش',
        EventType.religiousCeremony => 'مذہبی تقریب',
        EventType.festival => 'تہوار',
        EventType.familyGathering => 'خاندانی اجتماع',
        EventType.funeral => 'تعزیت / فاتحہ',
        EventType.communityEvent => 'سماجی تقریب',
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
  String get change => changeDate;
  String get notesOptional => isEnglish ? 'Notes (Optional)' : (isUrdu ? 'نوٹس (اختیاری)' : 'टिप्पणी (वैकल्पिक)');
  String get notesOptionalHint => isEnglish ? 'Add extra details' : (isUrdu ? 'اضافی تفصیلات لکھیں' : 'अतिरिक्त विवरण लिखें');
  String get notesHint => notesOptionalHint;

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

  // Splash & Onboarding
  String get splashLoading => isEnglish ? 'Initializing offline ledger...' : (isUrdu ? 'آف لائن بہی لوڈ ہو رہی ہے...' : 'ऑफ़लाइन बही लोड हो रही है...');
  String get onboardingSkip => isEnglish ? 'Skip' : (isUrdu ? 'چھوڑیں' : 'छोड़ें');
  String get onboardingNext => isEnglish ? 'Next' : (isUrdu ? 'آگے بڑھیں' : 'आगे बढ़ें');
  String get onboardingGetStarted => isEnglish ? 'Get Started' : (isUrdu ? 'شروع کریں' : 'शुरू करें');
  String get onboardingSlide1Title => isEnglish ? 'Companion for Family Celebrations' : (isUrdu ? 'خاندانی تقاریب کا سچا ساتھی' : 'पारिवारिक उत्सवों का सच्चा साथी');
  String get onboardingSlide1Desc => isEnglish
      ? 'Weddings, celebrations, ceremonies — safely keep record of every gift, cash and social offering.'
      : (isUrdu ? 'شادی، بارات، عقیقہ یا کوئی بھی تقریب — ہر تحفے اور نقد کا حساب محفوظ رکھیں۔' : 'शादी, बारात, मुंडन, गृह प्रवेश या कोई भी सामाजिक अवसर — हर नेग, शगुन और भेंट का हिसाब सुरक्षित रखें।');
  String get onboardingSlide1Badge => isEnglish ? 'Received & Given Always Separated' : (isUrdu ? 'ملا اور دیا ہمیشہ الگ' : 'मिला और दिया हमेशा अलग');
  String get onboardingSlide2Title => isEnglish ? 'Dignity of Family Relations' : (isUrdu ? 'رشتوں کا مان و احترام' : 'रिश्तों का मान-सम्मान');
  String get onboardingSlide2Desc => isEnglish
      ? 'Recording social exchanges is a gesture of love and respect. Pure separation of cash and items.'
      : (isUrdu ? 'سماجی لین دین کا حساب محبت اور احترام کی علامت ہے۔ نقد اور تحائف کا الگ الگ اندراج۔' : 'सामाजिक लेन-देन में हिसाब रखना स्नेह और सम्मान का प्रतीक है। नकद और भेंट दोनों का अलग-अलग विवरण।');
  String get onboardingSlide2Badge => isEnglish ? '100% Respectful Ledger' : (isUrdu ? '100% باوقار حساب' : '100% सम्मानजनक हिसाब');
  String get onboardingSlide3Title => isEnglish ? '100% Offline & Private' : (isUrdu ? 'مکمل آف لائن اور نجی' : 'पूर्णतः ऑफ़लाइन और निजी');
  String get onboardingSlide3Desc => isEnglish
      ? 'Your ledger stays exclusively on your device. Zero cloud, zero tracking, no accounts needed.'
      : (isUrdu ? 'آپ کا ڈیٹا صرف آپ کے فون میں رہتا ہے۔ کسی انٹرنیٹ، سرور یا لاگ ان کی ضرورت نہیں۔' : 'आपका डेटा केवल आपके फोन में रहता है। किसी इंटरनेट, सर्वर या लॉगिन की आवश्यकता नहीं है।');
  String get onboardingSlide3Badge => isEnglish ? 'No Internet, No Login' : (isUrdu ? 'بغیر انٹرنیٹ، بغیر لاگ ان' : 'बिना इंटरनेट, बिना लॉगिन');
  String get onboardingAppTour => isEnglish ? 'App Tour & Onboarding' : (isUrdu ? 'ایپ کا تعارف' : 'ऐप परिचय (ऑनबोर्डिंग)');

  // Dual-Pane Desktop Split View
  String get selectEntryToViewDetails => isEnglish ? 'Select an entry to view details' : (isUrdu ? 'تفصیلات دیکھنے کے لیے کوئی اندراج منتخب کریں' : 'विवरण देखने के लिए कोई प्रविष्टि चुनें');
  String get selectEntrySubtitle => isEnglish ? 'Click any entry from the ledger to view breakdown and gifts' : (isUrdu ? 'کھاتے से किसी اندراج پر کلک کر کے تفصیل دیکھیں' : 'बही खाते से किसी भी व्यवहार पर क्लिक करके उपहार व विवरण देखें');
  String get selectPersonToViewDetails => isEnglish ? 'Select a person to view passbook' : (isUrdu ? 'پاس بک دیکھنے کے لیے کسی فرد کو منتخب کریں' : 'विवरण देखने के लिए किसी व्यक्ति को चुनें');
  String get selectPersonSubtitle => isEnglish ? 'Click any relative or acquaintance to view their gift history' : (isUrdu ? 'تاریخ دیکھنے کے لیے کسی پر کلک کریں' : 'उपहार व व्यवहार इतिहास देखने के लिए किसी रिश्तेदार पर क्लिक करें');
  String get selectEventToViewDetails => isEnglish ? 'Select an event to view celebration ledger' : (isUrdu ? 'تفصیلات دیکھنے کے لیے کوئی تقریب منتخب کریں' : 'विवरण देखने के लिए कोई कार्यक्रम चुनें');
  String get selectEventSubtitle => isEnglish ? 'Click any ceremony to inspect shagun received and given' : (isUrdu ? 'تقریب میں ملا اور دیا گیا شگون دیکھنے کے لیے کلک کریں' : 'कार्यक्रम में मिला व दिया शगुन देखने के लिए क्लिक करें');

  // Shortcuts & Navigation
  String get shortcutHome => isEnglish ? 'Home Dashboard' : (isUrdu ? 'ہوم ڈیش بورڈ' : 'होम डैशबोर्ड');
  String get shortcutBahi => isEnglish ? 'Bahi Ledger' : (isUrdu ? 'بہی کھاتہ' : 'बही-खाता');
  String get shortcutEvents => isEnglish ? 'Events Directory' : (isUrdu ? 'خاندانی تقاریب' : 'पारिवारिक कार्यक्रम');
  String get shortcutPeople => isEnglish ? 'People & Relatives' : (isUrdu ? 'افراد و رشتہ دار' : 'लोग व रिश्तेदार');
  String get shortcutSettings => isEnglish ? 'Settings' : (isUrdu ? 'ترتیبات' : 'सेटिंग्स');
  String get shortcutNewEntry => isEnglish ? 'New Transaction' : (isUrdu ? 'نیا اندراج' : 'नया व्यवहार दर्ज करें');
  String get shortcutSearch => isEnglish ? 'Search' : (isUrdu ? 'تلاش' : 'खोजें');
  String get shortcutGuide => isEnglish ? 'Keyboard Shortcuts Guide' : (isUrdu ? 'کی بورڈ شارٹ کٹس' : 'कीबोर्ड शॉर्टकट्स गाइड');
  String get shortcutClose => isEnglish ? 'Close / Back' : (isUrdu ? 'بند کریں / واپس' : 'बंद करें / पीछे जाएं');
  String get desktopShortcutsHint => isEnglish ? 'Ctrl+N New • Ctrl+F Search • F1 Shortcuts' : (isUrdu ? 'Ctrl+N نیا • Ctrl+F تلاش • F1 شارٹ کٹس' : 'Ctrl+N नया जोड़ें • Ctrl+F खोजें • F1 शॉर्टकट');

  // Onboarding Highlights
  String get onboardingSlide1Detail1 => isEnglish
      ? 'Separation of money received and given in weddings, ceremonies or any occasion.'
      : (isUrdu ? 'شادی یا کسی بھی تقریب میں ملا اور دیا گیا ہمیشہ الگ درج ہوتا ہے۔' : 'शादी, मुंडन या किसी भी अवसर पर मिला व दिया हमेशा अलग दर्ज होता है।');
  String get onboardingSlide1Detail2 => isEnglish
      ? 'Transparent records for both cash and physical gifts.'
      : (isUrdu ? 'نقد رقم اور تحائف دونوں کا الگ الگ شفاف حساب۔' : 'नकद राशि और भौतिक उपहार दोनों का अलग-अलग पारदर्शी हिसाब।');
  String get onboardingSlide2TitlePoint1 => isEnglish ? 'Mutual Respect' : (isUrdu ? 'باہمی احترام' : 'पारस्परिक सम्मान');
  String get onboardingSlide2Detail1 => isEnglish
      ? 'No financial stress or pressure in familial social exchanges.'
      : (isUrdu ? 'خاندانی لین دین میں کسی بوجھ یا دباؤ کا نام نہیں۔' : 'पारिवारिक लेन-देन में कोई तनाव या दबाव नहीं होता।');
  String get onboardingSlide2Detail2 => isEnglish
      ? 'Plan ahead and prepare budgets for upcoming family ceremonies.'
      : (isUrdu ? 'آنے والی تقاریب کے لیے پہلے سے بجٹ اور منصوبہ بندی کریں۔' : 'आगामी कार्यक्रमों के लिए पहले से योजना बनाकर बजट तैयार करें।');
  String get onboardingSlide3TitlePoint1 => isEnglish ? 'Secure Encryption' : (isUrdu ? 'محفوظ انکرپشن' : 'सुरक्षित एन्क्रिप्शन');
  String get onboardingSlide3Detail1 => isEnglish
      ? 'Military-grade AES-256-GCM password-encrypted backup.'
      : (isUrdu ? 'پاس ورڈ سے محفوظ انکرپٹڈ بیک اپ۔' : 'AES-256-GCM मिलिट्री-ग्रेड पासवर्ड एन्क्रिप्टेड बैकअप।');
  String get onboardingSlide3TitlePoint2 => isEnglish ? 'Reports & Exports' : (isUrdu ? 'رپورٹس اور برآمد' : 'रिपोर्ट व निर्यात');
  String get onboardingSlide3Detail2 => isEnglish
      ? 'Download complete ledger in A4 PDF and Excel CSV format.'
      : (isUrdu ? 'مکمل کھاتہ پی ڈی ایف اور ایکسل میں ڈاؤن لوڈ کریں۔' : 'A4 PDF और Excel (CSV) में सम्पूर्ण बही डाउनलोड करें।');

  // Quick Suggestion Tags & Gifts
  String get quickTagWedding => isEnglish ? 'Wedding Shagun' : (isUrdu ? 'شادی شگون' : 'विवाह शगुन');
  String get quickTagBhaat => isEnglish ? 'Bhaat / Mayra' : (isUrdu ? 'بھات / مائرا' : 'भात / मायरा');
  String get quickTagDikhawa => isEnglish ? 'Dikhawa / Teeka' : (isUrdu ? 'دکھاوا / ٹیکا' : 'दिखावा / टीका');
  String get quickTagGrihaPravesh => isEnglish ? 'Housewarming' : (isUrdu ? 'گھر میں داخلہ' : 'गृह प्रवेश');
  String get quickTagMundan => isEnglish ? 'Tonsure Ceremony' : (isUrdu ? 'عقیقہ / منڈن' : 'मुंडन संस्कार');
  String get quickTagBirthday => isEnglish ? 'Birthday' : (isUrdu ? 'سالگرہ' : 'जन्मदिन');

  List<String> get quickTags => [
    quickTagWedding,
    quickTagBhaat,
    quickTagDikhawa,
    quickTagGrihaPravesh,
    quickTagMundan,
    quickTagBirthday,
  ];

  String get quickGiftGoldRing => isEnglish ? 'Gold Ring' : (isUrdu ? 'سونے کی انگوٹھی' : 'सोने की अंगूठी');
  String get quickGiftSilverCoin => isEnglish ? 'Silver Coin' : (isUrdu ? 'چاندی کا سکہ' : 'चांदी का सिक्का');
  String get quickGiftClothes => isEnglish ? 'Clothes / Suit' : (isUrdu ? 'کپڑے / سوٹ' : 'कपड़े / सूट');
  String get quickGiftUtensils => isEnglish ? 'Utensils Set' : (isUrdu ? 'برتنوں کا سیٹ' : 'बर्तन सेट');
  String get quickGiftSweetsFruit => isEnglish ? 'Sweets / Fruit' : (isUrdu ? 'مٹھائی / پھل' : 'मिठाई / फल');

  List<String> get quickGiftSuggestions => [
    quickGiftGoldRing,
    quickGiftSilverCoin,
    quickGiftClothes,
    quickGiftUtensils,
    quickGiftSweetsFruit,
  ];

  // Quick Relationships
  String get relMama => isEnglish ? 'Maternal Uncle (Mama)' : (isUrdu ? 'ماموں' : 'मामा');
  String get relChacha => isEnglish ? 'Paternal Uncle (Chacha)' : (isUrdu ? 'چچا' : 'चाचा');
  String get relTau => isEnglish ? 'Elder Uncle (Tau)' : (isUrdu ? 'تایا' : 'ताऊ');
  String get relBua => isEnglish ? 'Paternal Aunt (Bua)' : (isUrdu ? 'پھوپھی' : 'बुआ');
  String get relMausi => isEnglish ? 'Maternal Aunt (Mausi)' : (isUrdu ? 'خالہ' : 'मौसी');
  String get relFufa => isEnglish ? 'Uncle-in-law (Fufa)' : (isUrdu ? 'پھوپا' : 'फूफा');
  String get relJija => isEnglish ? 'Brother-in-law (Jija)' : (isUrdu ? 'بہنوئی' : 'जीजा');
  String get relSala => isEnglish ? 'Brother-in-law (Sala)' : (isUrdu ? 'سالا' : 'साला');
  String get relSamdhi => isEnglish ? 'In-law (Samdhi)' : (isUrdu ? 'سمدھی' : 'समधी');
  String get relMitra => isEnglish ? 'Friend' : (isUrdu ? 'دوست' : 'मित्र');
  String get relPadosi => isEnglish ? 'Neighbor' : (isUrdu ? 'پڑوسی' : 'पड़ोसी');
  String get relOther => isEnglish ? 'Other' : (isUrdu ? 'دیگر' : 'अन्य');

  List<String> get quickRelations => [
    relMama,
    relChacha,
    relTau,
    relBua,
    relMausi,
    relFufa,
    relJija,
    relSala,
    relSamdhi,
    relMitra,
    relPadosi,
    relOther,
  ];

  // Quick Event Suggestions
  String get eventBirthday => isEnglish ? 'Birthday' : (isUrdu ? 'سالگرہ' : 'जन्मदिन');
  String get eventNamkaran => isEnglish ? 'Naming Ceremony' : (isUrdu ? 'نام رکھنے کی تقریب' : 'नामकरण');
  String get eventJaneu => isEnglish ? 'Sacred Thread' : (isUrdu ? 'رسم دھاگہ' : 'जनेऊ / उपनयन');
  String get eventChhathi => isEnglish ? 'Chhathi' : (isUrdu ? 'چھٹی' : 'छठी');
  String get eventGodhBharai => isEnglish ? 'Baby Shower' : (isUrdu ? 'گود بھرائی' : 'गोद भराई');
  String get eventSatsang => isEnglish ? 'Prayer Gathering' : (isUrdu ? 'محفل / دعا' : 'सत्संग / जगराता');
  String get eventRetirement => isEnglish ? 'Retirement' : (isUrdu ? 'ریٹائرمنٹ' : 'रिटायरमेंट');
  String get eventMemorial => isEnglish ? 'Memorial Ceremony' : (isUrdu ? 'فاتحہ خوانی / برسی' : 'श्राद्ध / तेरहवीं');

  List<String> get quickCustomEvents => [
    eventBirthday,
    eventNamkaran,
    eventJaneu,
    eventChhathi,
    eventGodhBharai,
    eventSatsang,
    eventRetirement,
    eventMemorial,
  ];

  String get noFamilyMembersYet => isEnglish ? 'No members added to this family yet.' : (isUrdu ? 'اس خاندان میں ابھی کوئی رکن شامل نہیں ہے۔' : 'इस परिवार में अभी कोई सदस्य नहीं जुड़ा है।');
  String get searchFamilyOrVillageHint => isEnglish ? 'Search by family name or village...' : (isUrdu ? 'خاندان یا گاؤں سے تلاش کریں...' : 'परिवार या गाँव से खोजें...');
  String get searchFamiliesHint => searchFamilyOrVillageHint;
  String get themeGalleryDescription => isEnglish ? 'Personalize your Vyavahaar ledger with curated themes. Your choice is always saved.' : (isUrdu ? 'اپنے کھاتے کو اپنی پسندیدہ تھیم میں سجائیں۔ یہ ترتیبات ہمیشہ محفوظ رہیں گی۔' : 'व्यवहार बही-खाते को अपने मनपसंद रंग व थीम में सजाएं। यह चयन हमेशा सुरक्षित रहेगा।');
  String get onboardingTourSubtitle => isEnglish ? 'View interactive walkthrough and guide' : (isUrdu ? 'ایپ کا تعارف اور رہنمائی دیکھیں' : 'ऐप का परिचय और मार्गदर्शन देखें');
  String get generalCategory => isEnglish ? 'General' : (isUrdu ? 'عام' : 'सामान्य');
  String get close => isEnglish ? 'Close' : (isUrdu ? 'بند کریں' : 'बंद करें');
  String get defaultUnit => isEnglish ? 'Count' : (isUrdu ? 'تعداد' : 'संख्या');
  String get hintAmountEstimate => isEnglish ? 'e.g. 5000' : (isUrdu ? 'مثال: 5000' : 'उदा. 5000');
  String get hintRelationExample => isEnglish ? 'e.g. Uncle / Aunt' : (isUrdu ? 'مثال: ماموں / چچا' : 'उदा. मामा / चाचा');
  String get appearanceSection => isEnglish ? 'Appearance' : (isUrdu ? 'ظاہری شکل اور تھیم' : 'रूप-रंग व दिखावट');
  String get themeModeLabel => isEnglish ? 'Theme Mode' : (isUrdu ? 'تھیم موڈ' : 'थीम मोड');
  String get systemDefault => isEnglish ? 'System Default' : (isUrdu ? 'سسٹم کے مطابق' : 'सिस्टम अनुसार');
  String get lightMode => isEnglish ? 'Light Mode' : (isUrdu ? 'لائٹ موڈ' : 'लाइट मोड');
  String get darkMode => isEnglish ? 'Dark Mode' : (isUrdu ? 'ڈارک موڈ' : 'डार्क मोड');
  String get themePalettes => isEnglish ? '18+ Palettes' : (isUrdu ? '18+ پیلیٹس' : '18+ पैलेट्स');
  String get preferencesSection => isEnglish ? 'Preferences' : (isUrdu ? 'عام ترجیحات' : 'सामान्य प्राथमिकताएं');
  String get defaultCurrency => isEnglish ? 'Currency' : (isUrdu ? 'کرنسی' : 'मुद्रा');
  String get currencyName => isEnglish ? '₹ INR (Indian Rupee)' : (isUrdu ? '₹ INR (ہندوستانی روپیہ)' : '₹ INR (भारतीय रुपया)');
  String get dataSection => isEnglish ? 'Data & Security' : (isUrdu ? 'ڈیٹا اور سیکیورٹی' : 'डेटा बैकअप व सुरक्षा');
  String get offlineGuaranteeTitle => isEnglish ? '100% Offline & Private' : (isUrdu ? '100% آف لائن اور محفوظ' : '100% ऑफ़लाइन व सुरक्षित');
  String get offlineGuaranteeSubtitle => isEnglish
      ? 'All records stay strictly on your device. Zero internet, zero accounts.'
      : (isUrdu ? 'تمام ریکارڈ صرف آپ کے آلے پر محفوظ ہیں۔ کوئی کلاؤڈ یا انٹرنیٹ نہیں۔' : 'सारा बही-खाता केवल आपके डिवाइस में सुरक्षित है। कोई क्लाउड या इंटरनेट नहीं।');

  // Advanced Event Management Getters
  String get eventOverview => isEnglish ? 'Overview' : (isUrdu ? 'جائزہ' : 'अवलोकन');
  String get eventFunctions => isEnglish ? 'Functions' : (isUrdu ? 'رسومات' : 'रस्में व कार्यक्रम');
  String get eventPeople => isEnglish ? 'People' : (isUrdu ? 'لوگ' : 'लोग व परिवार');
  String get eventGuests => isEnglish ? 'Guests' : (isUrdu ? 'مہمان' : 'निमंत्रण व मेहमान');
  String get eventTasks => isEnglish ? 'Tasks' : (isUrdu ? 'کام' : 'कार्य व चेकलिस्ट');
  String get eventBudget => isEnglish ? 'Budget' : (isUrdu ? 'بجٹ' : 'बजट व व्यवहार');
  String get eventNotesTab => isEnglish ? 'Notes' : (isUrdu ? 'نوٹس' : 'नोट्स व दस्तावेज़');
  String get eventRemindersTab => isEnglish ? 'Reminders' : (isUrdu ? 'یاد دہانیاں' : 'अनुस्मारक');
  String get eventHistoryTab => isEnglish ? 'History' : (isUrdu ? 'تاریخ' : 'गतिविधि इतिहास');
  String get addFunctionTitle => isEnglish ? 'Add Function' : (isUrdu ? 'نئی تقریب شامل کریں' : 'नई रस्म जोड़ें');
  String get addTaskTitle => isEnglish ? 'Add Task' : (isUrdu ? 'نیا کام شامل کریں' : 'नया कार्य जोड़ें');
  String get addGuestTitle => isEnglish ? 'Add Guest' : (isUrdu ? 'مہمان شامل کریں' : 'अतिथि जोड़ें');
  String get addBudgetCategoryTitle => isEnglish ? 'Add Category' : (isUrdu ? 'بجٹ کیٹیگری شامل کریں' : 'बजट श्रेणी जोड़ें');
  String get estimatedBudget => isEnglish ? 'Estimated Budget' : (isUrdu ? 'تخمینی بجٹ' : 'अनुमानित बजट');
  String get actualExpense => isEnglish ? 'Actual Expense' : (isUrdu ? 'اصل خرچ' : 'वास्तविक खर्च');
  String get remainingBudget => isEnglish ? 'Remaining Budget' : (isUrdu ? 'باقی بجٹ' : 'शेष बजट');
  String get budgetUtilization => isEnglish ? 'Budget Utilization' : (isUrdu ? 'بجٹ کا استعمال' : 'बजट उपयोग');
  String get checklistProgress => isEnglish ? 'Checklist Progress' : (isUrdu ? 'چیک لسٹ پیش رفت' : 'चेकलिस्ट प्रगति');
  String get guestCountSummary => isEnglish ? 'Guest Summary' : (isUrdu ? 'مہمانوں کی تفصیل' : 'अतिथि विवरण');
  String get invitationStatusLabel => isEnglish ? 'Invitation Status' : (isUrdu ? 'دعوت کی حیثیت' : 'निमंत्रण स्थिति');
  String get attendanceStatusLabel => isEnglish ? 'Attendance' : (isUrdu ? 'حاضری' : 'उपस्थिति');
  String get conflictWarning => isEnglish ? 'Conflict Warning' : (isUrdu ? 'ممکنہ تصادم' : 'संभावित टकराव');
  String get duplicateEventTitle => isEnglish ? 'Duplicate Event' : (isUrdu ? 'تقریب کی نقل بنائیں' : 'कार्यक्रम की प्रतिलिपि बनाएं');
  String get cancelEventTitle => isEnglish ? 'Cancel Event' : (isUrdu ? 'تقریب منسوخ کریں' : 'कार्यक्रम रद्द करें');
  String get archiveEventTitle => isEnglish ? 'Archive Event' : (isUrdu ? 'تقریب محفوظ کریں' : 'कार्यक्रम संग्रहीत करें');
  String get restoreEventTitle => isEnglish ? 'Restore Event' : (isUrdu ? 'بحال کریں' : 'पुनर्स्थापित करें');
  String get calendarView => isEnglish ? 'Calendar' : (isUrdu ? 'کیلنڈر ویو' : 'कैलेंडर दृश्य');
  String get listView => isEnglish ? 'List' : (isUrdu ? 'لسٹ ویو' : 'सूची दृश्य');
  String get filterAll => isEnglish ? 'All' : (isUrdu ? 'سب' : 'सभी');
  String get filterUpcoming => isEnglish ? 'Upcoming' : (isUrdu ? 'آنے والی' : 'आगामी');
  String get filterToday => isEnglish ? 'Today' : (isUrdu ? 'آج' : 'आज');
  String get filterCompleted => isEnglish ? 'Completed' : (isUrdu ? 'مکمل' : 'सम्पन्न');
  String get filterDraft => isEnglish ? 'Draft' : (isUrdu ? 'ڈرافٹ' : 'ड्राफ़्ट');
  String get filterArchived => isEnglish ? 'Archived' : (isUrdu ? 'محفوظ شدہ' : 'संग्रहीत');
  String get filterCancelled => isEnglish ? 'Cancelled' : (isUrdu ? 'منسوخ' : 'रद्द');
  String get shareInvitation => isEnglish ? 'Share Invitation' : (isUrdu ? 'دعوت نامہ شیئر کریں' : 'निमंत्रण साझा करें');

  // Contact Import & Relatives Management Getters
  String get importFromContacts => isEnglish ? 'Import from Contacts' : (isUrdu ? 'رابطوں سے درآمد کریں' : 'फ़ोन संपर्क से आयात करें');
  String get addManually => isEnglish ? 'Add Manually' : (isUrdu ? 'دستی طور پر شامل کریں' : 'मैन्युअल जोड़ें');
  String get importVCard => isEnglish ? 'Import vCard File' : (isUrdu ? 'vCard فائل سے درآمد کریں' : 'vCard फ़ाइल से आयात करें');
  String get contactPermissionRationale => isEnglish
      ? 'Vyavahaar needs contact access to let you select and import relatives directly. All data remains 100% offline on your device.'
      : (isUrdu
          ? 'رشتہ داروں کو درآمد کرنے کے لیے رابطوں کی اجازت درکار ہے۔ آپ کا تمام ڈیٹا 100% آف لائن محفوظ رہے گا۔'
          : 'रिश्तेदारों को सीधे आयात करने के लिए संपर्क अनुमति की आवश्यकता है। आपका सारा डेटा 100% ऑफ़लाइन रहेगा।');
  String get selectContactsToImport => isEnglish ? 'Select Contacts to Import' : (isUrdu ? 'درآمد کرنے کے لیے رابطے منتخب کریں' : 'आयात करने हेतु संपर्क चुनें');
  String get importContactsCount => isEnglish ? 'Import Contacts' : (isUrdu ? 'رابطے درآمد کریں' : 'संपर्क आयात करें');
  String get importSuccess => isEnglish ? 'Contacts imported successfully' : (isUrdu ? 'رابطے کامیابی کے ساتھ درآمد ہو گئے' : 'संपर्क सफलतापूर्वक आयात किए गए');
  String get noContactsSelected => isEnglish ? 'No contacts selected' : (isUrdu ? 'کوئی رابطہ منتخب نہیں کیا گیا' : 'कोई संपर्क नहीं चुना गया');
  String get duplicateFoundTitle => isEnglish ? 'Possible Duplicate Detected' : (isUrdu ? 'ممکنہ ڈپلیکیٹ رابطہ پایا گیا' : 'संभावित डुप्लीकेट संपर्क मिला');
  String get duplicateFoundDesc => isEnglish
      ? 'This contact appears to already exist in your directory.'
      : (isUrdu ? 'یہ رابطہ پہلے ہی آپ کی فہرست میں موجود لگتا ہے۔' : 'यह संपर्क पहले से आपकी सूची में मौजूद प्रतीत होता है।');
  String get skipImport => isEnglish ? 'Skip' : (isUrdu ? 'چھوڑیں' : 'छोड़ें');
  String get importAsSeparate => isEnglish ? 'Add as Separate Person' : (isUrdu ? 'علیحدہ شخص کے طور پر شامل کریں' : 'अलग व्यक्ति के रूप में जोड़ें');
  String get mergeWithExisting => isEnglish ? 'Merge with Existing' : (isUrdu ? 'موجودہ شخص میں ضم کریں' : 'मौजूदा व्यक्ति में विलय करें');
  String get compareBoth => isEnglish ? 'Review & Compare' : (isUrdu ? 'موازنہ کریں' : 'तुलना करें');
  String get primaryPhone => isEnglish ? 'Primary Mobile' : (isUrdu ? 'بنیادی موبائل نمبر' : 'मुख्य मोबाइल नंबर');
  String get secondaryPhones => isEnglish ? 'Additional Phone Numbers' : (isUrdu ? 'اضافی فون نمبر' : 'अतिरिक्त फ़ोन नंबर');
  String get whatsappNumber => isEnglish ? 'WhatsApp Number' : (isUrdu ? 'واٹس ایپ نمبر' : 'व्हाट्सएप नंबर');
  String get emailAddresses => isEnglish ? 'Email Addresses' : (isUrdu ? 'ای میل پتے' : 'ईमेल पते');
  String get village => isEnglish ? 'Village / Town' : (isUrdu ? 'گاؤں / قصبہ' : 'गाँव / कस्बा');
  String get city => isEnglish ? 'City' : (isUrdu ? 'شہر' : 'शहर');
  String get district => isEnglish ? 'District' : (isUrdu ? 'ضلع' : 'ज़िला');
  String get state => isEnglish ? 'State' : (isUrdu ? 'صوبہ / ریاست' : 'राज्य');
  String get pinCode => isEnglish ? 'PIN Code' : (isUrdu ? 'پن کوڈ' : 'पिन कोड');
  String get occupation => isEnglish ? 'Occupation' : (isUrdu ? 'پیشہ' : 'व्यवसाय / पेशा');
  String get company => isEnglish ? 'Company / Organization' : (isUrdu ? 'کمپنی / ادارہ' : 'कंपनी / संस्थान');
  String get tags => isEnglish ? 'Tags' : (isUrdu ? 'ٹیگز' : 'टैग');
  String get contactSource => isEnglish ? 'Source' : (isUrdu ? 'ذریعہ' : 'स्रोत');
  String get contactSourceManual => isEnglish ? 'Manual Entry' : (isUrdu ? 'دستی اندراج' : 'मैन्युअल प्रविष्टि');
  String get contactSourcePhone => isEnglish ? 'Phone Contact' : (isUrdu ? 'فون رابطہ' : 'फ़ोन संपर्क');
  String get callAction => isEnglish ? 'Call' : (isUrdu ? 'کال کریں' : 'कॉल करें');
  String get smsAction => isEnglish ? 'SMS' : (isUrdu ? 'پیغام بھیجیں' : 'संदेश भेजें');
  String get whatsappAction => isEnglish ? 'WhatsApp' : (isUrdu ? 'واٹس ایپ' : 'व्हाट्सएप');
  String get emailAction => isEnglish ? 'Email' : (isUrdu ? 'ای میل بھیجیں' : 'ईमेल भेजें');
  String get shareContactAction => isEnglish ? 'Share Contact' : (isUrdu ? 'رابطہ شیئر کریں' : 'संपर्क साझा करें');
  String get exportVCardAction => isEnglish ? 'Export as vCard (.vcf)' : (isUrdu ? 'vCard (.vcf) برآمد کریں' : 'vCard (.vcf) निर्यात करें');
  String get exportCsvAction => isEnglish ? 'Export as CSV' : (isUrdu ? 'CSV برآمد کریں' : 'CSV निर्यात करें');
  String get bulkActions => isEnglish ? 'Bulk Actions' : (isUrdu ? 'اجتماعی کارروائیاں' : 'थोक क्रियाएं');
  String get bulkAssignFamily => isEnglish ? 'Assign to Family' : (isUrdu ? 'خاندان میں شامل کریں' : 'परिवार से जोड़ें');
  String get bulkAddTag => isEnglish ? 'Add Tag' : (isUrdu ? 'ٹیگ شامل کریں' : 'टैग लगाएं');
  String get bulkArchive => isEnglish ? 'Archive Selected' : (isUrdu ? 'منتخب کو محفوظ کریں' : 'चयनित संग्रहित करें');
  String get selectedCount => isEnglish ? 'Selected' : (isUrdu ? 'منتخب' : 'चयनित');
  String get confirmMerge => isEnglish ? 'Confirm Merge' : (isUrdu ? 'ضم کرنے کی تصدیق کریں' : 'विलय की पुष्टि करें');
  String get keepExisting => isEnglish ? 'Keep Existing' : (isUrdu ? 'موجودہ رکھیں' : 'मौजूदा रखें');
  String get keepIncoming => isEnglish ? 'Use Incoming' : (isUrdu ? 'نیا استعمال کریں' : 'नया उपयोग करें');
  List<String> get unitOptions => isEnglish
      ? const ['Count', 'Gram', 'Tola', 'Piece', 'Metre', 'Kg', 'Box']
      : (isUrdu
          ? const ['تعداد', 'گرام', 'تولہ', 'پیس', 'میٹر', 'کلو', 'ڈبہ']
          : const ['संख्या', 'ग्राम', 'तोला', 'पीस', 'थान / मीटर', 'किलो', 'डिब्बा']);

  List<String> get quickReceivedByChips => isEnglish
      ? const ['Father', 'Mother', 'Self', 'Bride/Groom']
      : (isUrdu
          ? const ['والد', 'والدہ', 'خود', 'دولہا/دلہن']
          : const ['पिताजी', 'माताजी', 'स्वयं', 'दूल्हा/दुल्हन']);

  List<String> get quickHandedOverByChips => isEnglish
      ? const ['Self', 'Father', 'Mother', 'Brother', 'Uncle']
      : (isUrdu
          ? const ['خود', 'والد', 'والدہ', 'بھائی', 'چچا']
          : const ['स्वयं', 'पिताजी', 'माताजी', 'भाई', 'चाचाजी']);

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

  String get recordReceivedTitle => isEnglish ? 'Record Received (+ Mila)' : (isUrdu ? '+ ملا لین دین درج کریں' : '+ मिला व्यवहार दर्ज करें');
  String get recordGivenTitle => isEnglish ? 'Record Given (+ Diya)' : (isUrdu ? '+ دیا لین دین درج کریں' : '+ दिया व्यवहार दर्ज करें');
  String get recordMilaShort => isEnglish ? '+ Received' : (isUrdu ? '+ ملا' : '+ मिला');
  String get recordDiyaShort => isEnglish ? '+ Given' : (isUrdu ? '+ دیا' : '+ दिया');
  String get saveAndAddNext => isEnglish ? 'Save & Add Next' : (isUrdu ? 'محفوظ کریں اور اگلا شامل کریں' : 'दर्ज करें और अगला जोड़ें');
  String get receivedBy => isEnglish ? 'Received By (Family Member)' : (isUrdu ? 'کس نے وصول کیا (خاندان کا فرد)' : 'किसने प्राप्त किया (घर का सदस्य)');
  String get receivedByHint => isEnglish ? 'e.g. Father, Mother, Self' : (isUrdu ? 'مثال: والد، والدہ، خود' : 'उदा. पिताजी, माताजी, स्वयं');
  String get handedOverBy => isEnglish ? 'Handed Over By' : (isUrdu ? 'किसके द्वारा दिया / भिजवाया गया' : 'किसके द्वारा दिया / भिजवाया गया');
  String get handedOverByHint => isEnglish ? 'e.g. Self, Brother, Uncle' : (isUrdu ? 'مثال: خود، بھائی، چچا' : 'उदा. स्वयं, भाई, चाचाजी');
  String get paymentMode => isEnglish ? 'Payment Mode' : (isUrdu ? 'ادائیگی کا طریقہ' : 'भुगतान का माध्यम');
  String get paymentCash => isEnglish ? 'Cash' : (isUrdu ? 'نقد' : 'नकद');
  String get paymentOnline => isEnglish ? 'Online / UPI' : (isUrdu ? 'آن لائن / یو پی آئی' : 'ऑनलाइन / UPI');
  String get paymentGiftOnly => isEnglish ? 'Gift Items Only' : (isUrdu ? 'صرف تحفہ' : 'केवल उपहार / भेंट');
  String get reciprocalHistory => isEnglish ? 'Past Exchange History' : (isUrdu ? 'پچھلی لین دین کی تاریخ' : 'पिछला व्यवहार इतिहास');
  String get reciprocalReceivedFromThem => isEnglish ? 'They gave us' : (isUrdu ? 'انہوں نے ہمیں دیا تھا' : 'इन्होंने हमें दिया था');
  String get reciprocalGivenToThem => isEnglish ? 'We gave them' : (isUrdu ? 'ہم نے انہیں دیا تھا' : 'हमने इन्हें दिया था');
  String get firstExchangeWithPerson => isEnglish ? 'First transaction with this relative' : (isUrdu ? 'اس رشتہ دار کے ساتھ پہلا لین دین' : 'इस रिश्तेदार के साथ पहला व्यवहार');
  String get sendThankYouMessage => isEnglish ? 'Send Thank You Note' : (isUrdu ? 'شکریہ کا پیغام بھیجیں' : 'धन्यवाद संदेश भेजें');
  String get thankYouTemplate => isEnglish
      ? 'Greetings! Wholehearted gratitude for your love, blessings and shagun in our family celebration.'
      : (isUrdu
          ? 'سلام! ہماری خاندانی تقریب میں آپ کے پیار، دعاؤں اور تحفے کے لیے دل کی گہرائیوں سے شکریہ۔'
          : 'सादर प्रणाम! हमारे पारिवारिक मांगलिक उत्सव में आपके स्नेह, आशीर्वाद एवं व्यवहार के लिए सपरिवार हार्दिक धन्यवाद।');
  String get createNewEventInline => isEnglish ? '+ Create New Event' : (isUrdu ? '+ نئی تقریب بنائیں' : '+ नया कार्यक्रम बनाएं');
  String get newRelativeFullForm => isEnglish ? '+ Add New Relative' : (isUrdu ? '+ نیا رشتہ دار شامل کریں' : '+ नया रिश्तेदार जोड़ें');
  String get rapidEntrySuccess => isEnglish
      ? 'Entry saved. Ready for next relative entry.'
      : (isUrdu
          ? 'لین دین محفوظ ہو گیا۔ اگلے رشتہ دار کے اندراج کے لیے تیار۔'
          : 'व्यवहार दर्ज हुआ। अगले रिश्तेदार की एंट्री के लिए तैयार।');
  String get copy => isEnglish ? 'Copy' : (isUrdu ? 'کاپی کریں' : 'कॉपी करें');
  String get copiedToClipboard => isEnglish ? 'Copied to clipboard' : (isUrdu ? 'کلپ بورڈ پر کاپی کیا گیا' : 'क्लिपबोर्ड पर कॉपी किया गया');

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
