import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../people/presentation/add_person_screen.dart';
import '../../events/presentation/add_event_screen.dart';

/// Modern Card-Based Screen to Record New Transaction (मिला या दिया व्यवहार)
/// Distinct Received (मिला) and Given (दिया) experiences with color theming,
/// inline full relative creation with People-page parity, inline event creation,
/// reciprocal past history peek, rapid entry mode, and zero hardcoded strings.
class AddEntryScreen extends ConsumerStatefulWidget {
  final String? initialPersonId;
  final String? initialEventId;
  final TransactionDirection? initialDirection;

  const AddEntryScreen({
    super.key,
    this.initialPersonId,
    this.initialEventId,
    this.initialDirection,
  });

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionDirection _direction;
  TransactionType _transactionType = TransactionType.cash;
  TransactionStatus _status = TransactionStatus.recorded;

  String? _selectedPersonId;
  String? _selectedEventId;
  late String _transactionDate;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _receivedByController = TextEditingController();
  final TextEditingController _handedOverByController = TextEditingController();

  String _paymentMode = 'cash'; // 'cash' | 'online' | 'gift'
  final List<EntryItem> _items = [];
  bool _isSaving = false;

  // Traditional cultural shagun denominations
  static const List<int> _shagunAmounts = [101, 251, 501, 1100, 2100, 5100, 11000];

  // Quick increment amounts
  static const List<int> _incrementAmounts = [100, 500, 1000];

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection ?? TransactionDirection.received;
    _transactionDate = AppDateUtils.getTodayIsoString();
    _selectedEventId = widget.initialEventId;
    _selectedPersonId = widget.initialPersonId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _receivedByController.dispose();
    _handedOverByController.dispose();
    super.dispose();
  }

  void _setDatePreset(int offsetDays) {
    final target = DateTime.now().add(Duration(days: offsetDays));
    setState(() {
      _transactionDate = AppDateUtils.toIsoDateString(target);
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
        _transactionDate = AppDateUtils.toIsoDateString(picked);
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
      unit: context.l10n.defaultUnit,
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

    final unitOptions = l10n.unitOptions;
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
                    hintText: l10n.hintAmountEstimate,
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
    final primaryAccent = _direction == TransactionDirection.received ? AppColors.milaGreen : AppColors.diyaRed;

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
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              builder: (_, scrollController) => Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: cardBorder, borderRadius: BorderRadius.circular(10)),
                  ),
                  // Header with Title & Full New Relative Action
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
                          onTap: () async {
                            Navigator.pop(ctx);
                            // Open the full People form with Contact import, phones, notes, village
                            final newPerson = await Navigator.push<Person>(
                              context,
                              MaterialPageRoute(builder: (_) => const AddPersonScreen()),
                            );
                            if (newPerson != null && mounted) {
                              setState(() {
                                _selectedPersonId = newPerson.id;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_add_alt_1, size: 16, color: primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.newRelativeFullForm,
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
                                  Icon(Icons.person_search_outlined, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.noResultsFound,
                                    style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 16),
                                  ExpressButton(
                                    label: l10n.newRelativeFullForm,
                                    icon: Icons.person_add,
                                    tint: primaryAccent,
                                    compact: true,
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      final newPerson = await Navigator.push<Person>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddPersonScreen()),
                                      );
                                      if (newPerson != null && mounted) {
                                        setState(() {
                                          _selectedPersonId = newPerson.id;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(color: cardBorder, height: 1),
                            itemBuilder: (context, idx) {
                              final p = filtered[idx];
                              final isSelected = p.id == _selectedPersonId;
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSelected ? primaryAccent : inputBg,
                                  child: Text(
                                    p.fullName.isNotEmpty ? p.fullName.characters.first : '?',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p.fullName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                                ),
                                subtitle: Text(
                                  [
                                    if (p.relationshipLabel != null && p.relationshipLabel!.isNotEmpty) p.relationshipLabel!,
                                    if (p.address != null && p.address!.isNotEmpty) p.address!,
                                    if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) p.phoneNumber!,
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isSelected ? Icon(Icons.check_circle, color: primaryAccent, size: 20) : null,
                                onTap: () {
                                  setState(() => _selectedPersonId = p.id);
                                  Navigator.pop(ctx);
                                },
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

  void _showEventPickerSheet(BuildContext context, ThemeData theme, List<Event> events, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = _direction == TransactionDirection.received ? AppColors.milaGreen : AppColors.diyaRed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = events.where((e) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return e.title.toLowerCase().contains(q) || (e.venue ?? '').toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (_, scrollController) => Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: cardBorder, borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.selectEventOptional,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        ExpressSquish(
                          scale: 0.94,
                          onTap: () async {
                            Navigator.pop(ctx);
                            // Push AddEventScreen directly inline
                            final newEvent = await Navigator.push<Event>(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEventScreen()),
                            );
                            if (newEvent != null && mounted) {
                              setState(() {
                                _selectedEventId = newEvent.id;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 16, color: primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.createNewEventInline,
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
                        hintText: l10n.searchEventsHint,
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
                  // "No Event" Option
                  ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: _selectedEventId == null ? primaryAccent : inputBg,
                      child: Icon(Icons.clear, size: 18, color: _selectedEventId == null ? Colors.white : textSecondary),
                    ),
                    title: Text(l10n.noEvent, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                    subtitle: Text(l10n.generalCategory, style: TextStyle(fontSize: 12, color: textSecondary)),
                    trailing: _selectedEventId == null ? Icon(Icons.check_circle, color: primaryAccent, size: 20) : null,
                    onTap: () {
                      setState(() => _selectedEventId = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  Divider(color: cardBorder, height: 1),
                  // Events list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(color: cardBorder, height: 1),
                      itemBuilder: (context, idx) {
                        final e = filtered[idx];
                        final isSelected = e.id == _selectedEventId;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: isSelected ? primaryAccent : inputBg,
                            child: Icon(Icons.celebration_outlined, size: 18, color: isSelected ? Colors.white : primaryAccent),
                          ),
                          title: Text(e.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          subtitle: Text(
                            [
                              AppDateUtils.formatIsoDate(e.eventDate),
                              if (e.venue != null && e.venue!.isNotEmpty) e.venue!,
                            ].join(' • '),
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          trailing: isSelected ? Icon(Icons.check_circle, color: primaryAccent, size: 20) : null,
                          onTap: () {
                            setState(() => _selectedEventId = e.id);
                            Navigator.pop(ctx);
                          },
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

  void _showThankYouNoteDialog(AppLocalizations l10n, String personName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.volunteer_activism_outlined, color: AppColors.milaGreen),
            const SizedBox(width: 8),
            Text(l10n.sendThankYouMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.relativeDefault}: $personName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                l10n.thankYouTemplate,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.milaGreen),
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: Text(l10n.copy, style: const TextStyle(color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: l10n.thankYouTemplate));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.copiedToClipboard)),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _executeSave() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return false;

    if (_selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectPersonError),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if ((_transactionType == TransactionType.item || _transactionType == TransactionType.cashAndItem) && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addAtLeastOneItemError),
          backgroundColor: Colors.red,
        ),
      );
      return false;
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

      // Assemble formatted notes incorporating cultural metadata
      final noteParts = <String>[];
      if (_notesController.text.trim().isNotEmpty) {
        noteParts.add(_notesController.text.trim());
      }
      if (_direction == TransactionDirection.received) {
        if (_receivedByController.text.trim().isNotEmpty) {
          noteParts.add('[प्राप्तकर्ता: ${_receivedByController.text.trim()}]');
        }
      } else {
        if (_handedOverByController.text.trim().isNotEmpty) {
          noteParts.add('[द्वारा: ${_handedOverByController.text.trim()}]');
        }
        if (_paymentMode == 'online') {
          noteParts.add('[माध्यम: UPI/ऑनलाइन]');
        }
      }

      final entry = TransactionEntry(
        id: entryId,
        personId: _selectedPersonId!,
        eventId: _selectedEventId,
        direction: _direction,
        transactionType: _transactionType,
        status: _status,
        amountPaise: amountPaise,
        transactionDate: _transactionDate,
        notes: noteParts.isNotEmpty ? noteParts.join(' ') : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveEntryWithItemsAtomic(entry: entry, items: preparedItems);

      // Reactive invalidation for instant cross-app live numbers update
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(entriesListProvider);
      if (_selectedPersonId != null) {
        ref.invalidate(personHistoryStatsProvider(_selectedPersonId!));
      }
      if (_selectedEventId != null) {
        ref.invalidate(eventDetailProvider(_selectedEventId!));
      }

      return true;
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $err')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveEntry() async {
    final l10n = context.l10n;
    final success = await _executeSave();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transactionSavedSuccess),
          backgroundColor: _direction == TransactionDirection.received ? AppColors.milaGreen : AppColors.diyaRed,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveAndAddNext() async {
    final l10n = context.l10n;
    final success = await _executeSave();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rapidEntrySuccess),
          backgroundColor: AppColors.milaGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      // Keep event and date intact for rapid entry of next guest; clear amount, person, items, notes
      setState(() {
        _selectedPersonId = null;
        _amountController.clear();
        _notesController.clear();
        _items.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final isReceived = _direction == TransactionDirection.received;
    final primaryAccent = isReceived ? AppColors.milaGreen : AppColors.diyaRed;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final peopleAsync = ref.watch(activePeopleListProvider);
    final eventsAsync = ref.watch(activeEventsListProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          isReceived ? l10n.recordReceivedTitle : l10n.recordGivenTitle,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          // If Given, allow quick toggle for Planned vs Recorded
          if (!isReceived)
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
                        ? AppColors.diyaRed.withValues(alpha: 0.12)
                        : AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _status == TransactionStatus.recorded ? AppColors.diyaRed.withValues(alpha: 0.4) : AppColors.gold,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _status == TransactionStatus.recorded ? Icons.check_circle_outline : Icons.schedule,
                        size: 14,
                        color: _status == TransactionStatus.recorded ? AppColors.diyaRed : AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _status == TransactionStatus.recorded ? l10n.statusRecorded : l10n.statusPlanned,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _status == TransactionStatus.recorded ? AppColors.diyaRed : AppColors.gold,
                        ),
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
                  // 1. DIRECTION HERO SWITCHER (मिला vs दिया Tab Bar)
                  ExpressCard(
                    radius: 20,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        // मिला (Received) Tab
                        Expanded(
                          child: ExpressSquish(
                            scale: 0.96,
                            onTap: () => setState(() => _direction = TransactionDirection.received),
                            child: AnimatedContainer(
                              duration: Express.quick,
                              curve: Express.settle,
                              padding: const EdgeInsets.symmetric(vertical: 13),
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
                                    size: 19,
                                    color: isReceived ? Colors.white : textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.recordMilaShort,
                                    style: TextStyle(
                                      color: isReceived ? Colors.white : textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
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
                              padding: const EdgeInsets.symmetric(vertical: 13),
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
                                    size: 19,
                                    color: !isReceived ? Colors.white : textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.recordDiyaShort,
                                    style: TextStyle(
                                      color: !isReceived ? Colors.white : textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. PERSON SELECTION & RECIPROCAL HISTORY PEEK
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
                      child: Text('${l10n.errorDatabase}: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
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

                      return Column(
                        children: [
                          ExpressCard(
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
                                          l10n.selectPersonSubtitle,
                                          style: TextStyle(fontSize: 12, color: textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: textSecondary, size: 22),
                              ],
                            ),
                          ),

                          // Reciprocal Past History Peek Card
                          if (selectedPerson != null) ...[
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, _) {
                                final historyAsync = ref.watch(personHistoryStatsProvider(selectedPerson!.id));
                                return historyAsync.when(
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                  data: (stats) {
                                    final receivedPaise = stats['received_paise'] ?? 0;
                                    final givenPaise = stats['given_paise'] ?? 0;
                                    final hasAnyHistory = receivedPaise > 0 || givenPaise > 0;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: primaryAccent.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: primaryAccent.withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.history_rounded, size: 18, color: primaryAccent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.reciprocalHistory,
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                                ),
                                                const SizedBox(height: 2),
                                                if (!hasAnyHistory)
                                                  Text(
                                                    l10n.firstExchangeWithPerson,
                                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                                  )
                                                else if (!isReceived) ...[
                                                  // When Given: Highlight what they gave us
                                                  Text(
                                                    '${l10n.reciprocalReceivedFromThem}: ${CurrencyUtils.formatPaise(receivedPaise)}  •  ${l10n.reciprocalGivenToThem}: ${CurrencyUtils.formatPaise(givenPaise)}',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                                  ),
                                                ] else ...[
                                                  // When Received: Highlight past exchanges
                                                  Text(
                                                    '${l10n.reciprocalGivenToThem}: ${CurrencyUtils.formatPaise(givenPaise)}  •  ${l10n.reciprocalReceivedFromThem}: ${CurrencyUtils.formatPaise(receivedPaise)}',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. EVENT SELECTION & INLINE EVENT CREATOR
                  eventsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (events) {
                      Event? selectedEvent;
                      if (_selectedEventId != null) {
                        for (final e in events) {
                          if (e.id == _selectedEventId) {
                            selectedEvent = e;
                            break;
                          }
                        }
                      }

                      return ExpressCard(
                        radius: 18,
                        color: cardBg,
                        borderColor: cardBorder,
                        padding: const EdgeInsets.all(14),
                        onTap: () => _showEventPickerSheet(context, theme, events, l10n),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: selectedEvent != null ? primaryAccent : inputBg,
                              child: Icon(
                                Icons.celebration_outlined,
                                size: 19,
                                color: selectedEvent != null ? Colors.white : primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedEvent != null ? selectedEvent.title : l10n.selectEventOptional,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: selectedEvent != null ? textPrimary : textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedEvent != null
                                        ? '${AppDateUtils.formatIsoDate(selectedEvent.eventDate)}${selectedEvent.venue != null ? ' • ${selectedEvent.venue}' : ''}'
                                        : l10n.selectEventSubtitle,
                                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            ExpressSquish(
                              scale: 0.94,
                              onTap: () async {
                                final newEvent = await Navigator.push<Event>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddEventScreen()),
                                );
                                if (newEvent != null && mounted) {
                                  setState(() {
                                    _selectedEventId = newEvent.id;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.add, size: 16, color: primaryAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // 4. AMOUNT INPUT & TRADITIONAL SHAGUN QUICK CHIPS
                  ExpressCard(
                    radius: 20,
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
                              '${l10n.amountRupees} (₹)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                            ),
                            if (_amountController.text.isNotEmpty)
                              ExpressSquish(
                                scale: 0.92,
                                onTap: () => setState(() => _amountController.clear()),
                                child: Icon(Icons.clear, size: 18, color: primaryAccent),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Big Numeric Amount Field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: primaryAccent,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 8),
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: textSecondary.withValues(alpha: 0.35),
                            ),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          validator: (val) {
                            if (_transactionType == TransactionType.cash && (val == null || val.trim().isEmpty)) {
                              return l10n.amountRequired;
                            }
                            if (val != null && val.isNotEmpty) {
                              final numVal = int.tryParse(val.trim());
                              if (numVal == null || numVal <= 0) {
                                return l10n.amountRequired;
                              }
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 14),

                        // Shagun Denominations (₹101, 251, 501, 1100, 2100, 5100, 11000)
                        Text(
                          l10n.quickShagun,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _shagunAmounts.map((amt) {
                            final isSelected = _amountController.text.trim() == amt.toString();
                            return ActionChip(
                              label: Text('₹$amt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textPrimary)),
                              backgroundColor: isSelected ? primaryAccent : inputBg,
                              side: BorderSide(color: isSelected ? primaryAccent : cardBorder),
                              onPressed: () => setState(() => _amountController.text = amt.toString()),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),

                        // Quick Increment Chips (+100, +500, +1000)
                        Row(
                          children: _incrementAmounts.map((inc) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ExpressSquish(
                                scale: 0.94,
                                onTap: () => _addQuickAmount(inc),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Text('+$inc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. TRANSACTION TYPE & GIFT ITEMS
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.type,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeChip(
                                type: TransactionType.cash,
                                label: l10n.cash,
                                icon: Icons.payments_outlined,
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTypeChip(
                                type: TransactionType.item,
                                label: l10n.giftItem,
                                icon: Icons.card_giftcard_outlined,
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTypeChip(
                                type: TransactionType.cashAndItem,
                                label: l10n.cashAndItem,
                                icon: Icons.redeem_outlined,
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                          ],
                        ),

                        // If item is included, show Gift Items Builder
                        if (_transactionType == TransactionType.item || _transactionType == TransactionType.cashAndItem) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.items, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                              ExpressSquish(
                                scale: 0.94,
                                onTap: () => _showAddItemDialog(theme, inputBg, cardBg),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, size: 14, color: primaryAccent),
                                      const SizedBox(width: 4),
                                      Text(l10n.addItem, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Quick Gift Suggestions
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: l10n.quickGiftSuggestions.map((gift) {
                              return ActionChip(
                                label: Text(gift, style: TextStyle(fontSize: 11, color: textPrimary)),
                                backgroundColor: inputBg,
                                side: BorderSide(color: cardBorder),
                                onPressed: () => _addQuickGift(gift),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 10),

                          if (_items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  l10n.addAtLeastOneItemError,
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => Divider(color: cardBorder, height: 8),
                              itemBuilder: (ctx, i) {
                                final it = _items[i];
                                return Row(
                                  children: [
                                    Icon(Icons.card_giftcard, size: 16, color: primaryAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${it.itemName} (${it.quantity} ${it.unit ?? ''})${it.estimatedValuePaise != null ? ' • ₹${CurrencyUtils.paiseToRupees(it.estimatedValuePaise!)}' : ''}',
                                        style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                      onPressed: () => setState(() => _items.removeAt(i)),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. DATE SELECTION
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.transactionDate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Today preset
                            Expanded(
                              child: _buildDatePreset(
                                label: l10n.today,
                                isSelected: AppDateUtils.isToday(_transactionDate),
                                onTap: () => _setDatePreset(0),
                                primaryAccent: primaryAccent,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                cardBorder: cardBorder,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Yesterday preset
                            Expanded(
                              child: _buildDatePreset(
                                label: l10n.yesterday,
                                isSelected: AppDateUtils.isYesterday(_transactionDate),
                                onTap: () => _setDatePreset(-1),
                                primaryAccent: primaryAccent,
                                inputBg: inputBg,
                                textPrimary: textPrimary,
                                cardBorder: cardBorder,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Custom calendar picker
                            Expanded(
                              child: ExpressSquish(
                                scale: 0.95,
                                onTap: () => _pickTransactionDate(theme),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_month_outlined, size: 16, color: primaryAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppDateUtils.formatIsoDate(_transactionDate),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
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

                  // 7. SPECIFIC FIELDS: RECEIVED BY (मिला) VS GIVEN BY / PAYMENT MODE (दिया)
                  if (isReceived) ...[
                    // Received By (किसने प्राप्त किया)
                    ExpressCard(
                      radius: 18,
                      color: cardBg,
                      borderColor: cardBorder,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.receivedBy, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _receivedByController,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: l10n.receivedByHint,
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
                            children: l10n.quickReceivedByChips.map((who) {
                              return ActionChip(
                                label: Text(who, style: TextStyle(fontSize: 11, color: textPrimary)),
                                backgroundColor: inputBg,
                                side: BorderSide(color: cardBorder),
                                onPressed: () => setState(() => _receivedByController.text = who),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Given Mode: Payment Mode + Handed Over By
                    ExpressCard(
                      radius: 18,
                      color: cardBg,
                      borderColor: cardBorder,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.paymentMode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPaymentChip('cash', l10n.paymentCash, Icons.money, primaryAccent, inputBg, textPrimary, textSecondary),
                              const SizedBox(width: 8),
                              _buildPaymentChip('online', l10n.paymentOnline, Icons.qr_code, primaryAccent, inputBg, textPrimary, textSecondary),
                              const SizedBox(width: 8),
                              _buildPaymentChip('gift', l10n.paymentGiftOnly, Icons.card_giftcard, primaryAccent, inputBg, textPrimary, textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(l10n.handedOverBy, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _handedOverByController,
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: l10n.handedOverByHint,
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
                            children: l10n.quickHandedOverByChips.map((who) {
                              return ActionChip(
                                label: Text(who, style: TextStyle(fontSize: 11, color: textPrimary)),
                                backgroundColor: inputBg,
                                side: BorderSide(color: cardBorder),
                                onPressed: () => setState(() => _handedOverByController.text = who),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 8. NOTES & CULTURAL QUICK TAGS
                  ExpressCard(
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.notes, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
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
                        Text(l10n.quickNotesTitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
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

                  // 9. DEDICATED ACTION BUTTONS
                  if (isReceived) ...[
                    // Mila (Received) Buttons: Primary Save + Munshi Rapid Entry Button
                    ExpressButton(
                      label: l10n.saveTransaction,
                      icon: Icons.check_circle_outline,
                      tint: AppColors.milaGreen,
                      expand: true,
                      isLoading: _isSaving,
                      onPressed: _saveEntry,
                    ),
                    const SizedBox(height: 10),
                    ExpressButton(
                      label: l10n.saveAndAddNext,
                      icon: Icons.flash_on_outlined,
                      tone: ExpressTone.tonal,
                      tint: AppColors.milaGreen,
                      expand: true,
                      onPressed: _saveAndAddNext,
                    ),
                    const SizedBox(height: 8),
                    // Thank you slip option
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.favorite_outline, size: 16, color: AppColors.milaGreen),
                        label: Text(
                          l10n.sendThankYouMessage,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.milaGreen),
                        ),
                        onPressed: () {
                          final people = peopleAsync.asData?.value ?? [];
                          final person = people.where((p) => p.id == _selectedPersonId).firstOrNull;
                          _showThankYouNoteDialog(l10n, person?.fullName ?? l10n.relativeDefault);
                        },
                      ),
                    ),
                  ] else ...[
                    // Diya (Given) Button: Dedicated Given Save Button
                    ExpressButton(
                      label: l10n.recordGivenTitle,
                      icon: Icons.north_east_rounded,
                      tint: AppColors.diyaRed,
                      expand: true,
                      isLoading: _isSaving,
                      onPressed: _saveEntry,
                    ),
                  ],

                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeChip({
    required TransactionType type,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryAccent,
    required Color inputBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isSelected = _transactionType == type;
    return ExpressSquish(
      scale: 0.95,
      onTap: () => setState(() => _transactionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent : inputBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePreset({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryAccent,
    required Color inputBg,
    required Color textPrimary,
    required Color cardBorder,
  }) {
    return ExpressSquish(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent : inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryAccent : cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(
    String mode,
    String label,
    IconData icon,
    Color primaryAccent,
    Color inputBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: ExpressSquish(
        scale: 0.95,
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? primaryAccent : inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
