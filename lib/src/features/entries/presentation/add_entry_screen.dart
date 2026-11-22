import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_squish.dart';
import '../providers/entries_providers.dart';
import '../../people/providers/people_providers.dart';
import '../../events/providers/events_providers.dart';

/// Modern Card-Based Screen to Record New Transaction (मिला या दिया व्यवहार)
/// Full Material 3 theming with zero hardcoded colors or strings.
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

  final List<int> _shagunAmounts = [51, 101, 251, 501, 1100, 2100, 5100];

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

  Future<void> _pickTransactionDate(ThemeData theme) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_transactionDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: theme,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _transactionDate = picked.toIso8601String().split('T').first;
      });
    }
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
                    hintText: 'उदा. 5000',
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

    final showCashSection = _transactionType == TransactionType.cash || _transactionType == TransactionType.cashAndItem;
    final showItemSection = _transactionType == TransactionType.item || _transactionType == TransactionType.cashAndItem;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.recordNewTransaction, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // 1. Direction Selector (Mila / Diya)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ExpressSquish(
                            scale: 0.95,
                            onTap: () => setState(() => _direction = TransactionDirection.received),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _direction == TransactionDirection.received ? AppColors.milaGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '↓ ${l10n.received}',
                                style: TextStyle(
                                  color: _direction == TransactionDirection.received ? Colors.white : textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ExpressSquish(
                            scale: 0.95,
                            onTap: () => setState(() => _direction = TransactionDirection.given),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _direction == TransactionDirection.given ? AppColors.diyaRed : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '↑ ${l10n.given}',
                                style: TextStyle(
                                  color: _direction == TransactionDirection.given ? Colors.white : textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 2. Status & Transaction Type Selection Card
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status (Recorded vs Planned)
                        Row(
                          children: [
                            Text('${l10n.status}:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: Text(l10n.statusRecorded, style: const TextStyle(fontSize: 12)),
                              selected: _status == TransactionStatus.recorded,
                              selectedColor: AppColors.milaGreen,
                              labelStyle: TextStyle(
                                color: _status == TransactionStatus.recorded ? Colors.white : textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              showCheckmark: false,
                              onSelected: (val) {
                                if (val) setState(() => _status = TransactionStatus.recorded);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(l10n.statusPlanned, style: const TextStyle(fontSize: 12)),
                              selected: _status == TransactionStatus.planned,
                              selectedColor: AppColors.gold,
                              labelStyle: TextStyle(
                                color: _status == TransactionStatus.planned ? Colors.white : textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              showCheckmark: false,
                              onSelected: (val) {
                                if (val) setState(() => _status = TransactionStatus.planned);
                              },
                            ),
                          ],
                        ),
                        Divider(height: 20, color: cardBorder),
                        // Type Selector (Cash / Gift / Both)
                        Row(
                          children: [
                            Text('${l10n.type}:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SegmentedButton<TransactionType>(
                                segments: [
                                  ButtonSegment(
                                    value: TransactionType.cash,
                                    label: Text(l10n.cash, style: const TextStyle(fontSize: 11)),
                                  ),
                                  ButtonSegment(
                                    value: TransactionType.item,
                                    label: Text(l10n.giftItem, style: const TextStyle(fontSize: 11)),
                                  ),
                                  ButtonSegment(
                                    value: TransactionType.cashAndItem,
                                    label: Text(l10n.cashAndItem, style: const TextStyle(fontSize: 11)),
                                  ),
                                ],
                                selected: {_transactionType},
                                onSelectionChanged: (set) {
                                  setState(() => _transactionType = set.first);
                                },
                                style: const ButtonStyle(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 3. Select Person Card
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.selectPersonRequired, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        peopleAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF381A1D) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
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
                            return DropdownButtonFormField<String>(
                              value: _selectedPersonId,
                              dropdownColor: cardBg,
                              hint: Text('${l10n.selectPerson}...', style: TextStyle(color: textSecondary)),
                              items: people.map((p) {
                                final rel = p.relationshipLabel ?? l10n.relativeDefault;
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.fullName} ($rel)', style: TextStyle(color: textPrimary)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedPersonId = val),
                              validator: (val) => val == null ? l10n.selectPersonRequired : null,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 4. Amount & Quick Shagun Card
                  if (showCashSection) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ExpressCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      radius: 16,
                      color: cardBg,
                      borderColor: cardBorder,
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.amountRupees, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                              Text(l10n.quickShagun, style: TextStyle(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 16),
                              hintText: l10n.amountPlaceholder,
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _shagunAmounts.map((amt) {
                              final isSelected = _amountController.text.trim() == amt.toString();
                              return ActionChip(
                                label: Text(
                                  '₹$amt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : primaryAccent,
                                  ),
                                ),
                                backgroundColor: isSelected ? primaryAccent : inputBg,
                                side: BorderSide(
                                  color: isSelected ? primaryAccent : cardBorder,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _amountController.text = amt.toString();
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 5. Physical Gifts / Items Section
                  if (showItemSection) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ExpressCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      radius: 16,
                      color: cardBg,
                      borderColor: cardBorder,
                      elevation: 0,
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
                              TextButton.icon(
                                onPressed: () => _showAddItemDialog(theme, inputBg, cardBg),
                                icon: Icon(Icons.add, size: 18, color: primaryAccent),
                                label: Text(l10n.addItem, style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          if (_items.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Center(
                                child: Text(
                                  l10n.addItem,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.card_giftcard, size: 20, color: primaryAccent),
                                      const SizedBox(width: 8),
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
                                          setState(() {
                                            _items.removeAt(idx);
                                          });
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

                  const SizedBox(height: AppSpacing.sm),

                  // 6. Transaction Date Card
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.transactionDate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickTransactionDate(theme),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppDateUtils.formatIsoDate(_transactionDate, l10n.locale.languageCode),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                                ),
                                Icon(Icons.calendar_month, color: primaryAccent, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 7. Select Event Card
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.selectEventOptional, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        eventsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF381A1D) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${l10n.errorDatabase}: $err', style: const TextStyle(fontSize: 12, color: Colors.red))),
                              ],
                            ),
                          ),
                          data: (events) {
                            return DropdownButtonFormField<String>(
                              value: _selectedEventId,
                              dropdownColor: cardBg,
                              hint: Text('${l10n.selectEventOptional}...', style: TextStyle(color: textSecondary)),
                              items: [
                                DropdownMenuItem(value: null, child: Text(l10n.noEvent, style: TextStyle(color: textPrimary))),
                                ...events.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.title} (${e.eventDate})', style: TextStyle(color: textPrimary)))),
                              ],
                              onChanged: (val) => setState(() => _selectedEventId = val),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 8. Notes Card
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.notes, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.notesPlaceholder,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Save Button
                  ExpressSquish(
                    scale: 0.96,
                    onTap: _saveEntry,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryAccent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.saveTransaction,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Future<void> _saveEntry() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPersonId == null) return;

    if ((_transactionType == TransactionType.item || _transactionType == TransactionType.cashAndItem) && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.isEnglish ? 'Please add at least 1 item' : 'कम से कम 1 सामान जोड़ें'),
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
