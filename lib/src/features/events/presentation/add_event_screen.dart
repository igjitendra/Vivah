import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';

/// Screen to Create a New Ceremonial Event (Fully Localized, Zero Hardcoding)
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  EventType _selectedType = EventType.shaadi;
  String _eventDate = AppDateUtils.getTodayIsoString();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(l10n.createNewEvent, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
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
                  Card(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: l10n.eventNameHint,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.eventType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<EventType>(
                            value: _selectedType,
                            items: EventType.values.map((t) {
                              final label = l10n.isEnglish ? t.name : t.labelHindi;
                              return DropdownMenuItem(value: t, child: Text(label));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedType = val ?? EventType.other),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.eventDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.warmCream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_eventDate, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                                  const Icon(Icons.calendar_month, color: AppColors.terracotta),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.eventLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _venueController,
                            decoration: InputDecoration(
                              hintText: l10n.eventLocationHint,
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l10n.saveEvent, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_eventDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.terracotta,
              onPrimary: AppColors.white,
              onSurface: AppColors.deepNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _eventDate = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _saveEvent() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);
      final now = DateTime.now();
      final event = CeremonialEvent(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        eventType: _selectedType,
        eventDate: _eventDate,
        venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventSavedSuccess), backgroundColor: AppColors.milaGreen),
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
