import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../app/app_providers.dart';

/// Modern Card-Based Screen to Record New Transaction (मिला या दिया व्यवहार)
/// Full Material 3 theming with InlitX/streak inspired tactile spring motion,
/// quick shagun amount chips, relative search modal with inline creator, and zero hardcoded text.
class AddEntryScreen extends ConsumerStatefulWidget {
  final String? initialPersonId;
  final String? initialEventId;

  const AddEntryScreen({
    super.key,
    this.initialPersonId,
    this.initialEventId,
  });

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  TransactionDirection _direction = TransactionDirection.received;
  TransactionType _transactionType = TransactionType.cash;
  TransactionStatus _status = TransactionStatus.recorded;

  String? _selectedPersonId;
  String? _selectedEventId;
  late String _transactionDate;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<EntryItem> _items = [];
  bool _isSaving = false;

  // Traditional cultural shagun denominations
  static const List<int> _shagunAmounts = [101, 251, 501, 1100, 2100, 5100, 11000];

  // Quick increment amounts
  static const List<int> _incrementAmounts = [100, 500, 1000];

  @override
  void initState() {
    super.initState();
    _transactionDate = DateTime.now().toIso8601String().split('T').first;
    _selectedEventId = widget.initialEventId;
    _selectedPersonId = widget.initialPersonId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setDatePreset(int offsetDays) {
    final target = DateTime.now().add(Duration(days: offsetDays));
    setState(() {
      _transactionDate = target.toIso8601String().split('T').first;
    });
  }

  Future<void> _pickTransactionDate(ThemeData theme) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_transactionDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: theme, child: child!),
    );

    if (picked != null) {
      setState(() {
        _transactionDate = picked.toIso8601String().split('T').first;
      });
    }
  }

  void _addQuickAmount(int delta) {
    final current = int.tryParse(_amountController.text.trim()) ?? 0;
    final next = current + delta;
    setState(() {
      _amountController.text = next.toString();
    });
  }

  void _addQuickGift(String name) {
    final now = DateTime.now();
    final newItem = EntryItem(
      id: const Uuid().v4(),
      entryId: '',
      itemName: name,
      quantity: 1.0,
      unit: context.l10n.isEnglish ? 'Count' : (context.l10n.isUrdu ? 'تعداد' : 'संख्या'),
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _items.add(newItem);
    });
  }

  void _showAddItemDialog(ThemeData theme, Color inputBg, Color cardBg) {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final estValueController = TextEditingController();

    final unitOptions = l10n.isEnglish
        ? const ['Count', 'Gram', 'Tola', 'Piece', 'Metre', 'Kg', 'Box']
        : (l10n.isUrdu
            ? const ['تعداد', 'گرام', 'تولہ', 'پیس', 'میٹر', 'کلو', 'ڈبہ']
            : const ['संख्या', 'ग्राम', 'तोला', 'पीस', 'थान / मीटर', 'किलो', 'डिब्बा']);

    String selectedUnit = unitOptions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.addItem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: l10n.itemNameHint,
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.quantity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.unit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedUnit,
                            dropdownColor: cardBg,
                            items: unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedUnit = val);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${l10n.estimated} (₹)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: estValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    hintText: l10n.isEnglish ? 'e.g. 5000' : (l10n.isUrdu ? 'مثال: 5000' : 'उदा. 5000'),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
                final estRupees = int.tryParse(estValueController.text.trim());
                final estPaise = estRupees != null && estRupees > 0 ? CurrencyUtils.rupeesToPaise(estRupees) : null;

                final now = DateTime.now();
                final newItem = EntryItem(
                  id: const Uuid().v4(),
                  entryId: '',
                  itemName: name,
                  quantity: qty,
                  unit: selectedUnit,
                  estimatedValuePaise: estPaise,
                  createdAt: now,
                  updatedAt: now,
                );

                setState(() {
                  _items.add(newItem);
                });

                Navigator.pop(ctx);
              },
              child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonPickerSheet(BuildContext context, ThemeData theme, List<Person> people, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = people.where((p) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              final matchName = p.fullName.toLowerCase().contains(q);
              final matchRel = (p.relationshipLabel ?? '').toLowerCase().contains(q);
              final matchAddr = (p.address ?? '').toLowerCase().contains(q);
              return matchName || matchRel || matchAddr;
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (_, scrollController) => Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: cardBorder, borderRadius: BorderRadius.circular(10)),
                  ),
                  // Header with Title & Quick Add
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.selectPerson,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        ExpressSquish(
                          scale: 0.94,
                          onTap: () {
                            Navigator.pop(ctx);
                            _showQuickAddPersonSheet(context, theme, l10n);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_add_alt_1, size: 16, color: primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.quickAddRelative,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                      autofocus: false,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.searchRelativeHint,
                        hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setSheetState(() => query = val.trim()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Relatives List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_search_outlined, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                                  const SizedBox(height: 12),
                                  Text(l10n.noPeopleFound, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                                  const SizedBox(height: 12),
                                  ExpressSquish(
                                    scale: 0.95,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _showQuickAddPersonSheet(context, theme, l10n);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        l10n.quickAddRelative,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, idx) {
                              final p = filtered[idx];
                              final isSelected = p.id == _selectedPersonId;
                              final rel = p.relationshipLabel ?? l10n.relativeDefault;
                              final initial = p.fullName.isNotEmpty ? p.fullName.characters.first : '?';

                              return ExpressCard(
                                radius: 14,
                                color: isSelected ? primaryAccent.withValues(alpha: 0.12) : inputBg,
                                borderColor: isSelected ? primaryAccent : cardBorder,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                onTap: () {
                                  setState(() => _selectedPersonId = p.id);
                                  Navigator.pop(ctx);
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isSelected ? primaryAccent : cardBorder,
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.fullName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: primaryAccent.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  rel,
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryAccent),
                                                ),
                                              ),
                                              if (p.address != null && p.address!.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    '• ${p.address!}',
                                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: primaryAccent, size: 22)
                                    else
                                      Icon(Icons.chevron_right, color: textSecondary, size: 18),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickAddPersonSheet(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    final nameController = TextEditingController();
    final relController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    final commonRelations = l10n.quickRelations;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: cardBorder, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.quickAddRelative,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 16),
                // Full Name
                Text(l10n.personFullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.personFullNameHint,
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                // Relationship
                Text(l10n.relationship, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: relController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.isEnglish ? 'e.g. Uncle / Aunt' : (l10n.isUrdu ? 'مثال: ماموں / چچا' : 'उदा. मामा / चाचा'),
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: commonRelations.map((r) {
                    final isSel = relController.text.trim() == r;
                    return ActionChip(
                      label: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : textPrimary)),
                      backgroundColor: isSel ? primaryAccent : inputBg,
                      side: BorderSide(color: isSel ? primaryAccent : cardBorder),
                      onPressed: () {
                        setSheetState(() => relController.text = r);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Village / City
                Text('${l10n.villageOrCity} (${l10n.optionalField})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.villageOrCityHint,
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.cancel, style: TextStyle(color: textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ExpressSquish(
                        scale: 0.95,
                        onTap: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          final repo = ref.read(peopleRepositoryProvider);
                          final now = DateTime.now();
                          final newPerson = Person(
                            id: const Uuid().v4(),
                            fullName: name,
                            relationshipLabel: relController.text.trim().isNotEmpty ? relController.text.trim() : null,
                            address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                            phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                            createdAt: now,
                            updatedAt: now,
                          );

                          await repo.createPerson(newPerson);

                          if (context.mounted) {
                            setState(() => _selectedPersonId = newPerson.id);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${l10n.relativeSavedSuccess}: $name'),
                                backgroundColor: AppColors.milaGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.save,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final peopleAsync = ref.watch(activePeopleListProvider);
    final eventsAsync = ref.watch(activeEventsListProvider);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    final isReceived = _direction == TransactionDirection.received;
    final showCashSection = _transactionType == TransactionType.cash || _transactionType == TransactionType.cashAndItem;
    final showItemSection = _transactionType == TransactionType.item || _transactionType == TransactionType.cashAndItem;

    final rawAmountInt = int.tryParse(_amountController.text.trim()) ?? 0;
    final wordsPreview = rawAmountInt > 0
        ? CurrencyUtils.formatRupeesInWords(rawAmountInt, lang: l10n.locale.languageCode)
        : '';

    final isToday = _transactionDate == DateTime.now().toIso8601String().split('T').first;
    final isYesterday = _transactionDate == DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T').first;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.recordNewTransaction,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Status Pill (Recorded vs Planned)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ExpressSquish(
              scale: 0.94,
              onTap: () {
                setState(() {
                  _status = _status == TransactionStatus.recorded ? TransactionStatus.planned : TransactionStatus.recorded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _status == TransactionStatus.recorded
                      ? AppColors.milaGreen.withValues(alpha: 0.25)
                      : AppColors.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _status == TransactionStatus.recorded ? AppColors.milaGreen : AppColors.gold,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _status == TransactionStatus.recorded ? Icons.check_circle_outline : Icons.schedule,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _status == TransactionStatus.recorded ? l10n.statusRecorded : l10n.statusPlanned,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // 1. DIRECTION HERO CARD (Mila / Diya Switcher)
                  ExpressCard(
                    radius: 20,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // मिला (Received) Tab
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.96,
                                onTap: () => setState(() => _direction = TransactionDirection.received),
                                child: AnimatedContainer(
                                  duration: Express.quick,
                                  curve: Express.settle,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isReceived ? AppColors.milaGreen : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isReceived
                                        ? [
                                            BoxShadow(
                                              color: AppColors.milaGreen.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.south_west_rounded,
                                        size: 20,
                                        color: isReceived ? Colors.white : textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.received,
                                        style: TextStyle(
                                          color: isReceived ? Colors.white : textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // दिया (Given) Tab
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.96,
                                onTap: () => setState(() => _direction = TransactionDirection.given),
                                child: AnimatedContainer(
                                  duration: Express.quick,
                                  curve: Express.settle,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: !isReceived ? AppColors.diyaRed : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: !isReceived
                                        ? [
                                            BoxShadow(
                                              color: AppColors.diyaRed.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.north_east_rounded,
                                        size: 20,
                                        color: !isReceived ? Colors.white : textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.given,
                                        style: TextStyle(
                                          color: !isReceived ? Colors.white : textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. PERSON SELECTION HERO TILE
                  peopleAsync.when(
                    loading: () => Container(
                      height: 72,
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: cardBorder)),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF381A1D) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${l10n.errorDatabase}: $err', style: const TextStyle(fontSize: 12, color: Colors.red))),
                        ],
                      ),
                    ),
                    data: (people) {
                      Person? selectedPerson;
                      if (_selectedPersonId != null) {
                        for (final p in people) {
                          if (p.id == _selectedPersonId) {
                            selectedPerson = p;
                            break;
                          }
                        }
                      }

                      return ExpressCard(
                        radius: 18,
                        color: cardBg,
                        borderColor: _selectedPersonId != null ? primaryAccent.withValues(alpha: 0.6) : cardBorder,
                        padding: const EdgeInsets.all(14),
                        onTap: () => _showPersonPickerSheet(context, theme, people, l10n),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: selectedPerson != null ? primaryAccent : inputBg,
                              child: selectedPerson != null
                                  ? Text(
                                      selectedPerson.fullName.isNotEmpty ? selectedPerson.fullName.characters.first : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    )
                                  : Icon(Icons.person_add_alt_1_outlined, color: primaryAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedPerson != null ? selectedPerson.fullName : l10n.selectPerson,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: selectedPerson != null ? textPrimary : textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (selectedPerson != null) ...[
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            selectedPerson.relationshipLabel ?? l10n.relativeDefault,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                          ),
                                        ),
                                        if (selectedPerson.address != null && selectedPerson.address!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '• ${selectedPerson.address!}',
                                              style: TextStyle(fontSize: 11, color: textSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      l10n.selectPersonRequired,
                                      style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedPerson != null ? l10n.change : l10n.selectPerson,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 14, color: primaryAccent),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. TRANSACTION TYPE SELECTOR (नकद, भेंट, नकद+भेंट)
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.type,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // नकद (Cash)
                            Expanded(
                              child: _buildTypePill(
                                label: l10n.cash,
                                icon: Icons.payments_outlined,
                                isSelected: _transactionType == TransactionType.cash,
                                activeColor: primaryAccent,
                                inputBg: inputBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                onTap: () => setState(() => _transactionType = TransactionType.cash),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // भेंट / उपहार (Gift)
                            Expanded(
                              child: _buildTypePill(
                                label: l10n.giftItem,
                                icon: Icons.card_giftcard_outlined,
                                isSelected: _transactionType == TransactionType.item,
                                activeColor: AppColors.gold,
                                inputBg: inputBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                onTap: () => setState(() => _transactionType = TransactionType.item),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // नकद + भेंट (Both)
                            Expanded(
                              child: _buildTypePill(
                                label: l10n.cashAndItem,
                                icon: Icons.redeem_outlined,
                                isSelected: _transactionType == TransactionType.cashAndItem,
                                activeColor: AppColors.terracotta,
                                inputBg: inputBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                onTap: () => setState(() => _transactionType = TransactionType.cashAndItem),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. CASH AMOUNT CARD (With Shagun Denominations)
                  if (showCashSection) ...[
                    const SizedBox(height: 12),
                    ExpressCard(
                      radius: 18,
                      color: cardBg,
                      borderColor: cardBorder,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.amountRupees,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                              ),
                              Text(
                                l10n.quickShagun,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Amount Input with large Hero styling
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '₹',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: l10n.amountPlaceholder,
                                      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 24),
                                      border: InputBorder.none,
                                    ),
                                    validator: (val) {
                                      if (showCashSection) {
                                        if (val == null || val.trim().isEmpty) return l10n.amountRequired;
                                        final num = int.tryParse(val.trim());
                                        if (num == null || num <= 0) return l10n.amountRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_amountController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    color: textSecondary,
                                    onPressed: () {
                                      setState(() => _amountController.clear());
                                    },
                                  ),
                              ],
                            ),
                          ),
                          // Live Words Preview
                          if (wordsPreview.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.format_quote, size: 14, color: primaryAccent),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      wordsPreview,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          // Cultural Shagun Denominations
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _shagunAmounts.map((amt) {
                              final isSelected = _amountController.text.trim() == amt.toString();
                              return ExpressSquish(
                                scale: 0.94,
                                onTap: () => setState(() => _amountController.text = amt.toString()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryAccent : inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? primaryAccent : cardBorder,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    '₹$amt',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          // Increment Chips (+₹100, +₹500, +₹1000)
                          Row(
                            children: [
                              Text(
                                '+',
                                style: TextStyle(fontWeight: FontWeight.bold, color: textSecondary, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              ..._incrementAmounts.map((inc) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ExpressSquish(
                                    scale: 0.94,
                                    onTap: () => _addQuickAmount(inc),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: primaryAccent.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        '+₹$inc',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 5. PHYSICAL GIFTS / ITEMS SECTION
                  if (showItemSection) ...[
                    const SizedBox(height: 12),
                    ExpressCard(
                      radius: 18,
                      color: cardBg,
                      borderColor: cardBorder,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.giftItem,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                              ),
                              ExpressSquish(
                                scale: 0.94,
                                onTap: () => _showAddItemDialog(theme, inputBg, cardBg),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, size: 16, color: primaryAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.addItem,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Quick suggestions chips
                          Text(
                            l10n.quickGiftsTitle,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: l10n.quickGiftSuggestions.map((g) {
                              return ActionChip(
                                label: Text(g, style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w600)),
                                backgroundColor: inputBg,
                                side: BorderSide(color: cardBorder),
                                avatar: const Icon(Icons.add, size: 14),
                                onPressed: () => _addQuickGift(g),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          if (_items.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Center(
                                child: Text(
                                  l10n.addAtLeastOneItemError,
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                              ),
                            ),
                          ] else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final item = _items[idx];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.card_giftcard, size: 20, color: primaryAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.itemName} (${item.quantity} ${item.unit ?? ""})',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                            ),
                                            if (item.estimatedValuePaise != null)
                                              Text(
                                                '${l10n.estimated}: ${CurrencyUtils.formatPaise(item.estimatedValuePaise!)}',
                                                style: TextStyle(fontSize: 11, color: textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                        onPressed: () {
                                          setState(() => _items.removeAt(idx));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 6. DATE SELECTOR (With Today / Yesterday Presets)
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.transactionDate,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // "आज" (Today)
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.95,
                                onTap: () => _setDatePreset(0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isToday ? primaryAccent : inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isToday ? primaryAccent : cardBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    l10n.today,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isToday ? Colors.white : textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // "कल" (Yesterday)
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.95,
                                onTap: () => _setDatePreset(-1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isYesterday ? primaryAccent : inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isYesterday ? primaryAccent : cardBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    l10n.yesterday,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isYesterday ? Colors.white : textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // "अन्य" (Custom Date)
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.95,
                                onTap: () => _pickTransactionDate(theme),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: (!isToday && !isYesterday) ? primaryAccent : inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: (!isToday && !isYesterday) ? primaryAccent : cardBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color: (!isToday && !isYesterday) ? Colors.white : primaryAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppDateUtils.formatIsoDate(_transactionDate, l10n.locale.languageCode),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: (!isToday && !isYesterday) ? Colors.white : textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 7. EVENT SELECTOR (Optional Ceremony Link)
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectEventOptional,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 10),
                        eventsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF381A1D) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${l10n.errorDatabase}: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ),
                          data: (events) {
                            return DropdownButtonFormField<String?>(
                              value: _selectedEventId,
                              dropdownColor: cardBg,
                              hint: Text('${l10n.selectEventOptional}...', style: TextStyle(color: textSecondary, fontSize: 13)),
                              items: [
                                DropdownMenuItem(value: null, child: Text(l10n.noEvent, style: TextStyle(color: textPrimary, fontSize: 13))),
                                ...events.map(
                                  (e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(
                                      '${e.title} (${e.eventDate})',
                                      style: TextStyle(color: textPrimary, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) => setState(() => _selectedEventId = val),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 8. NOTES & QUICK TAGS
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notes,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l10n.notesPlaceholder,
                            hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.quickNotesTitle,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: l10n.quickTags.map((tag) {
                            return ActionChip(
                              label: Text(tag, style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w600)),
                              backgroundColor: inputBg,
                              side: BorderSide(color: cardBorder),
                              onPressed: () {
                                final current = _notesController.text.trim();
                                if (current.isEmpty) {
                                  _notesController.text = tag;
                                } else if (!current.contains(tag)) {
                                  _notesController.text = '$current, $tag';
                                }
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // SAVE BUTTON
                  ExpressButton(
                    label: l10n.saveTransaction,
                    icon: Icons.check,
                    tone: ExpressTone.filled,
                    tint: isReceived ? AppColors.milaGreen : AppColors.diyaRed,
                    expand: true,
                    isLoading: _isSaving,
                    onPressed: _saveEntry,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildTypePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color inputBg,
    required Color cardBorder,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return ExpressSquish(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Express.quick,
        curve: Express.settle,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : textPrimary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectPersonError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((_transactionType == TransactionType.item || _transactionType == TransactionType.cashAndItem) && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addAtLeastOneItemError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(entriesRepositoryProvider);
      final rawAmount = int.tryParse(_amountController.text.trim()) ?? 0;
      final amountPaise = (_transactionType == TransactionType.cash || _transactionType == TransactionType.cashAndItem) && rawAmount > 0
          ? CurrencyUtils.rupeesToPaise(rawAmount)
          : null;

      final entryId = const Uuid().v4();
      final now = DateTime.now();

      final preparedItems = _items
          .map((item) => EntryItem(
                id: item.id.isNotEmpty ? item.id : const Uuid().v4(),
                entryId: entryId,
                itemName: item.itemName,
                quantity: item.quantity,
                unit: item.unit,
                estimatedValuePaise: item.estimatedValuePaise,
                notes: item.notes,
                createdAt: now,
                updatedAt: now,
              ))
          .toList();

      final entry = TransactionEntry(
        id: entryId,
        personId: _selectedPersonId!,
        eventId: _selectedEventId,
        direction: _direction,
        transactionType: _transactionType,
        status: _status,
        amountPaise: amountPaise,
        transactionDate: _transactionDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveEntryWithItemsAtomic(entry: entry, items: preparedItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.transactionSavedSuccess), backgroundColor: AppColors.milaGreen),
        );
        Navigator.pop(context);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $err')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
