import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';

/// Screen to record a new Mila / Diya entry (Pure, Isolated, Fully Localized)
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
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String? _selectedPersonId;
  late String? _selectedEventId;
  TransactionDirection _direction = TransactionDirection.received;
  final TransactionStatus _status = TransactionStatus.recorded;
  final TransactionType _transactionType = TransactionType.cash;
  final String _transactionDate = AppDateUtils.getTodayIsoString();

  final List<EntryItem> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    _selectedPersonId = widget.initialPersonId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final peopleAsync = ref.watch(activePeopleListProvider);
    final eventsAsync = ref.watch(activeEventsListProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(l10n.recordNewTransaction, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // 1. Direction Selector (Mila / Diya)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _direction = TransactionDirection.received),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _direction == TransactionDirection.received ? AppColors.milaGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '↓ ${l10n.received}',
                                style: TextStyle(
                                  color: _direction == TransactionDirection.received ? AppColors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _direction = TransactionDirection.given),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _direction == TransactionDirection.given ? AppColors.diyaRed : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '↑ ${l10n.given}',
                                style: TextStyle(
                                  color: _direction == TransactionDirection.given ? AppColors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 2. Select Person Card
                  Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.selectPersonRequired, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          peopleAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => Text('${l10n.errorGeneric}: $err'),
                            data: (people) {
                              return DropdownButtonFormField<String>(
                                value: _selectedPersonId,
                                hint: Text('${l10n.selectPerson}...'),
                                items: people.map((p) {
                                  final rel = p.relationshipLabel ?? l10n.relativeDefault;
                                  return DropdownMenuItem(
                                    value: p.id,
                                    child: Text('${p.fullName} ($rel)'),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedPersonId = val),
                                validator: (val) => val == null ? l10n.selectPersonRequired : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.warmCream,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 3. Amount & Type Card
                  Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.amountRupees, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              hintText: l10n.amountPlaceholder,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (val) {
                              if (_transactionType == TransactionType.cash || _transactionType == TransactionType.cashAndItem) {
                                if (val == null || val.trim().isEmpty) return l10n.amountRequired;
                                final num = int.tryParse(val.trim());
                                if (num == null || num <= 0) return l10n.amountRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 4. Select Event Card
                  Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.selectEventOptional, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          eventsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => Text('${l10n.errorGeneric}: $err'),
                            data: (events) {
                              return DropdownButtonFormField<String>(
                                value: _selectedEventId,
                                hint: Text('${l10n.selectEventOptional}...'),
                                items: [
                                  DropdownMenuItem(value: null, child: Text(l10n.noEvent)),
                                  ...events.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.title} (${e.eventDate})'))),
                                ],
                                onChanged: (val) => setState(() => _selectedEventId = val),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.warmCream,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 5. Notes Card
                  Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.notes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: l10n.notesPlaceholder,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l10n.saveTransaction, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(entriesRepositoryProvider);
      final rawAmount = int.tryParse(_amountController.text.trim()) ?? 0;
      final amountPaise = rawAmount > 0 ? CurrencyUtils.rupeesToPaise(rawAmount) : null;

      final entryId = const Uuid().v4();
      final now = DateTime.now();

      final entry = TransactionEntry(
        id: entryId,
        personId: _selectedPersonId!,
        eventId: _selectedEventId,
        direction: _direction,
        transactionType: _items.isNotEmpty ? (_amountController.text.isNotEmpty ? TransactionType.cashAndItem : TransactionType.item) : TransactionType.cash,
        status: _status,
        amountPaise: amountPaise,
        transactionDate: _transactionDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveEntryWithItemsAtomic(entry: entry, items: _items);

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
