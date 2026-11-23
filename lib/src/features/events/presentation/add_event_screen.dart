import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../app/app_providers.dart';

/// Clean, focused, and responsive Event Creation Form for व्यवहार (Vyavahaar)
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCeremonyController = TextEditingController();

  EventType _selectedType = EventType.shaadi;
  late String _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  bool _isSaving = false;

  List<String> _conflictWarnings = [];

  @override
  void initState() {
    super.initState();
    _eventDate = DateTime.now().toIso8601String().split('T').first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _customCeremonyController.dispose();
    super.dispose();
  }

  void _checkConflicts() async {
    final repo = ref.read(eventsRepositoryProvider);
    final tempEvent = Event(
      id: 'temp_check',
      title: _titleController.text.trim(),
      eventType: _selectedType,
      eventDate: _eventDate,
      startTime: _startTime != null
          ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final conflicts = await repo.detectConflicts(tempEvent);
    if (mounted) {
      setState(() => _conflictWarnings = conflicts);
    }
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(_eventDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked.toIso8601String().split('T').first;
      });
      _checkConflicts();
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
      _checkConflicts();
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(eventsRepositoryProvider);
      final l10n = context.l10n;
      final now = DateTime.now();
      final eventId = const Uuid().v4();

      final event = Event(
        id: eventId,
        title: _titleController.text.trim(),
        eventType: _selectedType,
        category: _selectedType == EventType.other && _customCeremonyController.text.trim().isNotEmpty
            ? _customCeremonyController.text.trim()
            : null,
        eventDate: _eventDate,
        startTime: !_isAllDay && _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        endTime: !_isAllDay && _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : null,
        isAllDay: _isAllDay,
        venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        status: EventStatus.planned,
        priority: EventPriority.normal,
        createdAt: now,
        updatedAt: now,
        functions: const [],
        participants: const [],
        tasks: const [],
        reminders: [
          EventReminder(
            id: const Uuid().v4(),
            eventId: eventId,
            title: '${_titleController.text.trim()} - 1 दिन पहले अनुस्मारक',
            reminderDate: _eventDate,
            preset: '1_day_before',
            createdAt: now,
          ),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.errorGeneric}: $err')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: Text(
          l10n.createNewEvent,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                children: [
                  // Conflict Warning Alert (if any detected)
                  if (_conflictWarnings.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'समय या दिनांक टकराव की सूचना:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ..._conflictWarnings.map((w) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('• $w', style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // 1. Core Event Details Card
                  _buildSectionCard(
                    title: 'कार्यक्रम का विवरण',
                    icon: Icons.celebration_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.eventName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        onChanged: (_) => _checkConflicts(),
                        decoration: _inputDecoration(l10n.eventNameHint, inputBg, textSecondary),
                        validator: (val) => val == null || val.trim().isEmpty ? l10n.validationRequired : null,
                      ),
                      const SizedBox(height: 14),

                      Text(l10n.eventType, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<EventType>(
                        value: _selectedType,
                        dropdownColor: cardBg,
                        items: EventType.values.map((t) {
                          final label = l10n.isEnglish ? t.name : t.labelHindi;
                          return DropdownMenuItem(
                            value: t,
                            child: Text(label, style: TextStyle(color: textPrimary, fontSize: 13.5)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedType = val ?? EventType.shaadi);
                          _checkConflicts();
                        },
                        decoration: _inputDecoration(l10n.eventType, inputBg, textSecondary),
                      ),

                      if (_selectedType == EventType.other) ...[
                        const SizedBox(height: 14),
                        Text(l10n.customCeremony, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _customCeremonyController,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: _inputDecoration(l10n.customCeremonyHint, inputBg, textSecondary),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. Date & Time Card
                  _buildSectionCard(
                    title: 'दिनांक व समय',
                    icon: Icons.calendar_today_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.eventDate, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _eventDate,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              Icon(Icons.calendar_month_outlined, size: 20, color: primaryAccent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // All Day Toggle Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.wb_sunny_outlined, size: 18, color: primaryAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'पूरा दिन (All Day)',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isAllDay,
                              activeColor: primaryAccent,
                              onChanged: (val) => setState(() => _isAllDay = val),
                            ),
                          ],
                        ),
                      ),

                      // Start & End Time (if not all day)
                      if (!_isAllDay) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('प्रारंभ समय', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _pickStartTime,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: primaryAccent),
                                          const SizedBox(width: 8),
                                          Text(
                                            _startTime != null ? _startTime!.format(context) : 'समय चुनें',
                                            style: TextStyle(fontSize: 13, color: _startTime != null ? textPrimary : textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('समाप्ति समय (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _pickEndTime,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_filled, size: 16, color: primaryAccent),
                                          const SizedBox(width: 8),
                                          Text(
                                            _endTime != null ? _endTime!.format(context) : 'समय चुनें',
                                            style: TextStyle(fontSize: 13, color: _endTime != null ? textPrimary : textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3. Location & Notes Card
                  _buildSectionCard(
                    title: 'स्थान व अतिरिक्त नोट्स',
                    icon: Icons.location_on_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Text(l10n.eventLocation, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _venueController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration(l10n.eventLocationHint, inputBg, textSecondary).copyWith(
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 18, color: textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('विवरण / नोट्स (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _inputDecoration('कार्यक्रम से जुड़े खास निर्देश या नोट्स', inputBg, textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  ExpressButton(
                    onPressed: _handleSave,
                    label: l10n.saveEvent,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color primaryAccent,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fill, Color hintColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 13),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
