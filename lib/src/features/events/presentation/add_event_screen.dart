import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';

/// Screen to Create a New Ceremonial Event (नया कार्यक्रम)
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
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('नया कार्यक्रम बनाएं', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
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
                          const Text('कार्यक्रम का नाम (Event Title) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'उदा. अमित का विवाह, आराध्या का मुंडन',
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'नाम आवश्यक है' : null,
                          ),
                          const SizedBox(height: 16),
                          const Text('कार्यक्रम का प्रकार (Event Type)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<EventType>(
                            value: _selectedType,
                            items: EventType.values.map((t) {
                              return DropdownMenuItem(value: t, child: Text(t.labelHindi));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedType = val ?? EventType.other),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('दिनांक (Event Date)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          const Text('स्थल / स्थान (Venue)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _venueController,
                            decoration: InputDecoration(
                              hintText: 'उदा. शिव वाटिका मैरिज लॉन, कानपुर',
                              filled: true,
                              fillColor: AppColors.warmCream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('टिप्पणी (Notes)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'अतिरिक्त विवरण...',
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
                      child: const Text('कार्यक्रम सहेजें (Save Event)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);
      final now = DateTime.now();
      final ev = Event(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        eventType: _selectedType,
        eventDate: _eventDate,
        venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.createEvent(ev);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('कार्यक्रम सफलतापूर्वक बनाया गया!'), backgroundColor: AppColors.milaGreen),
        );
        Navigator.pop(context);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('त्रुटि: $err')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
