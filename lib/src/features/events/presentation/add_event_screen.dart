import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';

/// Modern Screen for creating a new auspicious family event (शादी, मुंडन, आदि)
/// Fully theme-adaptive with suggested ceremony chips and tactile spring squish.
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
  final _customCeremonyController = TextEditingController();

  EventType _selectedType = EventType.shaadi;
  late String _eventDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _eventDate = DateTime.now().toIso8601String().split('T').first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    _customCeremonyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.createNewEvent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 16,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.eventName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.eventNameHint,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.eventType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<EventType>(
                          value: _selectedType,
                          dropdownColor: cardBg,
                          items: EventType.values.map((t) {
                            final label = l10n.isEnglish ? t.name : t.labelHindi;
                            return DropdownMenuItem(value: t, child: Text(label, style: TextStyle(color: textPrimary)));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedType = val ?? EventType.other),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        if (_selectedType == EventType.other) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.customCeremony, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                              Text(l10n.suggestedCeremoniesTitle, style: TextStyle(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customCeremonyController,
                            style: TextStyle(color: textPrimary),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: l10n.customCeremonyHint,
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _suggestedCeremonies(l10n).map((ceremony) {
                              final isSelected = _customCeremonyController.text.trim() == ceremony;
                              return FilterChip(
                                label: Text(
                                  ceremony,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: primaryAccent,
                                backgroundColor: inputBg,
                                side: BorderSide(
                                  color: isSelected ? primaryAccent : cardBorder,
                                ),
                                showCheckmark: false,
                                onSelected: (val) {
                                  setState(() {
                                    _customCeremonyController.text = val ? ceremony : '';
                                    if (val && _titleController.text.trim().isEmpty) {
                                      _titleController.text = ceremony;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(l10n.eventDate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickDate(theme),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_eventDate, style: TextStyle(fontSize: 16, color: textPrimary)),
                                Icon(Icons.calendar_month, color: primaryAccent),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.eventLocation, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _venueController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.eventLocationHint,
                            hintStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                  ExpressSquish(
                    scale: 0.96,
                    onTap: _saveEvent,
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
                        l10n.saveEvent,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate(ThemeData theme) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_eventDate) ?? now,
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

      final customCeremony = _customCeremonyController.text.trim();
      String? notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
      if (_selectedType == EventType.other && customCeremony.isNotEmpty) {
        notes = notes != null ? '$notes ($customCeremony)' : customCeremony;
      }

      final event = Event(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        eventType: _selectedType,
        eventDate: _eventDate,
        venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await repo.createEvent(event);

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

  List<String> _suggestedCeremonies(AppLocalizations l10n) {
    if (l10n.isEnglish) {
      return const [
        'Birthday',
        'Naming Ceremony',
        'Sacred Thread (Upanayana)',
        'Chhathi',
        'Baby Shower',
        'Satsang / Jagrata',
        'Retirement',
        'Anniversary / Shradh',
      ];
    } else if (l10n.isUrdu) {
      return const [
        'سالگرہ',
        'نام رکھنے کی تقریب',
        'چھٹی',
        'گود بھرائی',
        'محفل / مجلس',
        'ریٹائرمنٹ',
        'برسی',
      ];
    }
    return const [
      'जन्मदिन',
      'नामकरण',
      'जनेऊ / उपनयन',
      'छठी',
      'गोद भराई',
      'सत्संग / जगराता',
      'रिटायरमेंट',
      'श्राद्ध / तेरहवीं',
    ];
  }
}
