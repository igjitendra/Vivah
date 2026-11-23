import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../app/app_providers.dart';

/// Advanced Event Creation Form for व्यवहार (Vyavahaar)
/// Features progressive disclosure, multi-functions (Haldi, Mehndi, Reception, etc.),
/// role-based people/family associations, venue details, initial checklist, and real-time conflict detection.
class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // A. Basic Information Controllers
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageCityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCeremonyController = TextEditingController();
  final _budgetController = TextEditingController();

  EventType _selectedType = EventType.shaadi;
  EventStatus _selectedStatus = EventStatus.planned;
  EventPriority _selectedPriority = EventPriority.normal;
  late String _eventDate;
  String? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  bool _isSaving = false;

  // Progressive Disclosure Panel States
  bool _expandFunctions = false;
  bool _expandPeople = false;
  bool _expandLocation = false;
  bool _expandChecklist = false;
  bool _expandBudgetAndReminders = false;

  // B. Sub-Entities Form State
  final List<EventFunction> _functions = [];
  final List<EventParticipant> _participants = [];
  final List<EventTask> _initialTasks = [];
  final List<EventReminder> _reminders = [];

  List<String> _conflictWarnings = [];

  @override
  void initState() {
    super.initState();
    _eventDate = DateTime.now().toIso8601String().split('T').first;
    _initializeDefaultPresets();
  }

  void _initializeDefaultPresets() {
    // Add default reminders
    _reminders.add(
      EventReminder(
        id: const Uuid().v4(),
        eventId: '',
        title: 'कार्यक्रम 1 दिन पहले अनुस्मारक',
        reminderDate: _eventDate,
        preset: '1_day_before',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _villageCityController.dispose();
    _landmarkController.dispose();
    _mapLinkController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _customCeremonyController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _checkConflicts() async {
    final repo = ref.read(eventsRepositoryProvider);
    final tempEvent = Event(
      id: 'temp_check',
      title: _titleController.text.trim(),
      eventType: _selectedType,
      eventDate: _eventDate,
      endDate: _endDate,
      startTime: _startTime != null ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}' : null,
      tasks: _initialTasks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final conflicts = await repo.detectConflicts(tempEvent);
    if (mounted) {
      setState(() => _conflictWarnings = conflicts);
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
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
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 48),
                children: [
                  // 1. Conflict Warning Alert (if any detected)
                  if (_conflictWarnings.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
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

                  // 2. Primary Card: Core Event Information
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: 18,
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
                          onChanged: (_) => _checkConflicts(),
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.eventType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<EventType>(
                                    value: _selectedType,
                                    dropdownColor: cardBg,
                                    items: EventType.values.map((t) {
                                      final label = l10n.isEnglish ? t.name : t.labelHindi;
                                      return DropdownMenuItem(value: t, child: Text(label, style: TextStyle(color: textPrimary, fontSize: 13.5)));
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedType = val ?? EventType.other);
                                      _checkConflicts();
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: inputBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                                  Text('प्राथमिकता (Priority)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<EventPriority>(
                                    value: _selectedPriority,
                                    dropdownColor: cardBg,
                                    items: EventPriority.values.map((p) {
                                      return DropdownMenuItem(value: p, child: Text(p.labelHindi, style: TextStyle(color: textPrimary, fontSize: 13.5)));
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedPriority = val ?? EventPriority.normal),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: inputBg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (_selectedType == EventType.other) ...[
                          const SizedBox(height: 16),
                          Text(l10n.customCeremony, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customCeremonyController,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              hintText: l10n.customCeremonyHint,
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        // Date Picker & End Date Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.eventDate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _pickDate(isEndDate: false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_eventDate, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                                          Icon(Icons.calendar_month, size: 18, color: primaryAccent),
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
                                  Text('समाप्ति दिनांक (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _pickDate(isEndDate: true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_endDate ?? 'समाप्ति चुनें', style: TextStyle(fontSize: 14, color: _endDate != null ? textPrimary : textSecondary)),
                                          Icon(Icons.event_available, size: 18, color: primaryAccent),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        // Time Pickers & All Day Toggle
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickStartTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: primaryAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        _startTime != null ? _startTime!.format(context) : 'प्रारंभ समय',
                                        style: TextStyle(fontSize: 13, color: _startTime != null ? textPrimary : textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: _pickEndTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time_filled, size: 16, color: primaryAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        _endTime != null ? _endTime!.format(context) : 'समाप्ति समय',
                                        style: TextStyle(fontSize: 13, color: _endTime != null ? textPrimary : textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('पूरा दिन', style: TextStyle(fontSize: 12, color: textSecondary)),
                                Switch(
                                  value: _isAllDay,
                                  activeColor: primaryAccent,
                                  onChanged: (val) => setState(() => _isAllDay = val),
                                ),
                              ],
                            ),
                          ],
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
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // =========================================================
                  // 3. PROGRESSIVE DISCLOSURE: EXPANDABLE ADVANCED MODULES
                  // =========================================================

                  // Module 1: Multi-Functions & Ceremonies (रस्में व उप-कार्यक्रम)
                  _buildExpandableTile(
                    icon: Icons.celebration_outlined,
                    iconTint: const Color(0xFFF59E0B),
                    title: 'रस्में व उप-कार्यक्रम (${_functions.length})',
                    isExpanded: _expandFunctions,
                    onToggle: () => setState(() => _expandFunctions = !_expandFunctions),
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    content: _buildFunctionsSection(inputBg, cardBorder, textPrimary, textSecondary, primaryAccent),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Module 2: People, Family & Roles Association
                  _buildExpandableTile(
                    icon: Icons.people_outline,
                    iconTint: const Color(0xFF38BDF8),
                    title: 'संबद्ध लोग व भूमिकाएं (${_participants.length})',
                    isExpanded: _expandPeople,
                    onToggle: () => setState(() => _expandPeople = !_expandPeople),
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    content: _buildPeopleSection(inputBg, cardBorder, textPrimary, textSecondary, primaryAccent),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Module 3: Detailed Location & Navigation Link
                  _buildExpandableTile(
                    icon: Icons.location_on_outlined,
                    iconTint: const Color(0xFF10B981),
                    title: 'विस्तृत पता व नेविगेशन',
                    isExpanded: _expandLocation,
                    onToggle: () => setState(() => _expandLocation = !_expandLocation),
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    content: _buildLocationSection(inputBg, textPrimary, textSecondary),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Module 4: Initial Task Checklist
                  _buildExpandableTile(
                    icon: Icons.checklist_rtl_outlined,
                    iconTint: const Color(0xFF8B5CF6),
                    title: 'प्रारंभिक कार्य चेकलिस्ट (${_initialTasks.length})',
                    isExpanded: _expandChecklist,
                    onToggle: () => setState(() => _expandChecklist = !_expandChecklist),
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    content: _buildChecklistSection(inputBg, cardBorder, textPrimary, textSecondary, primaryAccent),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Module 5: Budget Estimate & Reminders
                  _buildExpandableTile(
                    icon: Icons.account_balance_wallet_outlined,
                    iconTint: const Color(0xFFEC4899),
                    title: 'बजट अनुमान एवं अनुस्मारक',
                    isExpanded: _expandBudgetAndReminders,
                    onToggle: () => setState(() => _expandBudgetAndReminders = !_expandBudgetAndReminders),
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    content: _buildBudgetAndRemindersSection(inputBg, cardBorder, textPrimary, textSecondary, primaryAccent),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Final Action Button
                  ExpressButton(
                    label: l10n.saveEvent,
                    icon: Icons.check_circle_outline,
                    tone: ExpressTone.filled,
                    tint: primaryAccent,
                    expand: true,
                    isLoading: _isSaving,
                    onPressed: _saveEvent,
                  ),
                ],
              ),
            ),
    );
  }

  // --- SUB-SECTIONS IMPLEMENTATIONS ---

  Widget _buildExpandableTile({
    required IconData icon,
    required Color iconTint,
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconTint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconTint, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: cardBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFunctionsSection(Color inputBg, Color cardBorder, Color textPrimary, Color textSecondary, Color primaryAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_functions.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _functions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final fn = _functions[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fn.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                          Text('${fn.functionDate} ${fn.startTime ?? ""}', style: TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _functions.removeAt(i)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _showAddFunctionDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('नई रस्म जोड़ें (Add Function)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryAccent,
            side: BorderSide(color: primaryAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleSection(Color inputBg, Color cardBorder, Color textPrimary, Color textSecondary, Color primaryAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_participants.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _participants.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Chip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text('${p.name} (${p.role.labelHindi})', style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _participants.removeAt(i)),
                backgroundColor: inputBg,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _showSelectPersonSheet,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
              label: const Text('व्यक्ति जोड़ें (Select / Add Person)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryAccent,
                side: BorderSide(color: primaryAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(Color inputBg, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          style: TextStyle(color: textPrimary, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'पूरा पता (Full Address)',
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _villageCityController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'गाँव / शहर (Village / City)',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _landmarkController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'लैंडमार्क (Landmark)',
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _mapLinkController,
          style: TextStyle(color: textPrimary, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'गूगल मैप्स लिंक (Google Maps Link)',
            prefixIcon: const Icon(Icons.map_outlined, size: 18),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(Color inputBg, Color cardBorder, Color textPrimary, Color textSecondary, Color primaryAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_initialTasks.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _initialTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final t = _initialTasks[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.title, style: TextStyle(fontSize: 13, color: textPrimary))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () => setState(() => _initialTasks.removeAt(i)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add_task, size: 16),
          label: const Text('कार्य जोड़ें (Add Task)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryAccent,
            side: BorderSide(color: primaryAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAndRemindersSection(Color inputBg, Color cardBorder, Color textPrimary, Color textSecondary, Color primaryAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'अनुमानित कुल बजट ₹ (Estimated Budget)',
            prefixText: '₹ ',
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
        Text('ऑफ़लाइन अनुस्मारक (Offline Reminders):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
        const SizedBox(height: 6),
        ..._reminders.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFFEAB308)),
                  const SizedBox(width: 8),
                  Text(r.title, style: TextStyle(fontSize: 12.5, color: textPrimary)),
                ],
              ),
            )),
      ],
    );
  }

  // --- DIALOGS & PICKERS ---

  Future<void> _pickDate({required bool isEndDate}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isEndDate
          ? (DateTime.tryParse(_endDate ?? _eventDate) ?? now)
          : (DateTime.tryParse(_eventDate) ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final iso = picked.toIso8601String().split('T').first;
      setState(() {
        if (isEndDate) {
          _endDate = iso;
        } else {
          _eventDate = iso;
        }
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

  void _showAddFunctionDialog() {
    final fnTitleCtrl = TextEditingController();
    final fnVenueCtrl = TextEditingController(text: _venueController.text);
    String fnDate = _eventDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('रस्म / कार्यक्रम जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fnTitleCtrl,
                decoration: const InputDecoration(labelText: 'रस्म का नाम (उदा. हल्दी, मेहंदी, रिसेप्शन)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fnVenueCtrl,
                decoration: const InputDecoration(labelText: 'स्थल (Venue)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () {
                final title = fnTitleCtrl.text.trim();
                if (title.isNotEmpty) {
                  setState(() {
                    _functions.add(
                      EventFunction(
                        id: const Uuid().v4(),
                        eventId: '',
                        title: title,
                        functionDate: fnDate,
                        venue: fnVenueCtrl.text.trim().isNotEmpty ? fnVenueCtrl.text.trim() : null,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('जोड़ें'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final taskCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('चेकलिस्ट कार्य जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: taskCtrl,
          decoration: const InputDecoration(labelText: 'कार्य का विवरण (उदा. हलवाई बुक करना, निमंत्रण पत्र बांटना)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () {
              final t = taskCtrl.text.trim();
              if (t.isNotEmpty) {
                setState(() {
                  _initialTasks.add(
                    EventTask(
                      id: const Uuid().v4(),
                      eventId: '',
                      title: t,
                      dueDate: _eventDate,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                _checkConflicts();
                Navigator.pop(ctx);
              }
            },
            child: const Text('जोड़ें'),
          ),
        ],
      ),
    );
  }

  void _showSelectPersonSheet() {
    final peopleAsync = ref.read(activePeopleListProvider);
    final searchCtrl = TextEditingController();
    String search = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: 400,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('व्यक्ति व भूमिका चुनें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('नया व्यक्ति बनाएं'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showInlineCreatePersonDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (val) => setSheetState(() => search = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'नाम या संबंध से खोजें...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: peopleAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('त्रुटि: $e')),
                      data: (people) {
                        final filtered = people.where((p) {
                          if (search.isEmpty) return true;
                          return p.fullName.toLowerCase().contains(search) ||
                              (p.relationshipLabel ?? '').toLowerCase().contains(search);
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(child: Text('कोई व्यक्ति नहीं मिला। ऊपर "नया व्यक्ति बनाएं" पर टैप करें।'));
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final person = filtered[index];
                            final alreadyAdded = _participants.any((p) => p.personId == person.id);
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                              title: Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(person.relationshipLabel ?? person.phoneNumber ?? ''),
                              trailing: alreadyAdded
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : const Icon(Icons.add_circle_outline),
                              onTap: alreadyAdded
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _promptRoleSelection(person);
                                    },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _promptRoleSelection(Person person) {
    ParticipantRole chosenRole = ParticipantRole.familyMember;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('${person.fullName} की भूमिका चुनें'),
          content: DropdownButtonFormField<ParticipantRole>(
            value: chosenRole,
            items: ParticipantRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.labelHindi)))
                .toList(),
            onChanged: (val) => setDlgState(() => chosenRole = val ?? ParticipantRole.familyMember),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _participants.add(
                    EventParticipant(
                      id: const Uuid().v4(),
                      eventId: '',
                      personId: person.id,
                      familyId: person.familyId,
                      name: person.fullName,
                      role: chosenRole,
                      phone: person.phoneNumber,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('स्वीकार करें'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInlineCreatePersonDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नया व्यक्ति जोड़ें', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'पूरा नाम *')),
            const SizedBox(height: 8),
            TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'संबंध (उदा. मामा, चाचा, मित्र)')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'फ़ोन नंबर')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newPerson = Person(
                  id: const Uuid().v4(),
                  fullName: name,
                  relationshipLabel: relationCtrl.text.trim().isNotEmpty ? relationCtrl.text.trim() : null,
                  phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await ref.read(peopleRepositoryProvider).createPerson(newPerson);
                setState(() {
                  _participants.add(
                    EventParticipant(
                      id: const Uuid().v4(),
                      eventId: '',
                      personId: newPerson.id,
                      name: newPerson.fullName,
                      role: ParticipantRole.familyMember,
                      phone: newPerson.phoneNumber,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('सहेजें व जोड़ें'),
          ),
        ],
      ),
    );
  }

  // --- SAVE EVENT TO DATABASE ---

  Future<void> _saveEvent() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);
      final eventId = const Uuid().v4();
      final now = DateTime.now();

      // Parse budget
      int? estimatedBudgetPaise;
      final budgetText = _budgetController.text.trim().replaceAll(',', '');
      if (budgetText.isNotEmpty) {
        final parsed = double.tryParse(budgetText);
        if (parsed != null && parsed > 0) {
          estimatedBudgetPaise = (parsed * 100).toInt();
        }
      }

      final customCeremony = _customCeremonyController.text.trim();
      String? notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
      if (_selectedType == EventType.other && customCeremony.isNotEmpty) {
        notes = notes != null ? '$notes ($customCeremony)' : customCeremony;
      }

      final event = Event(
        id: eventId,
        title: _titleController.text.trim(),
        eventType: _selectedType,
        category: _selectedType.name,
        eventDate: _eventDate,
        endDate: _endDate,
        startTime: _startTime != null ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}' : null,
        endTime: _endTime != null ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}' : null,
        isAllDay: _isAllDay,
        venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        villageCity: _villageCityController.text.trim().isNotEmpty ? _villageCityController.text.trim() : null,
        landmark: _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : null,
        mapLink: _mapLinkController.text.trim().isNotEmpty ? _mapLinkController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        notes: notes,
        status: _selectedStatus,
        priority: _selectedPriority,
        budgetEstimatedPaise: estimatedBudgetPaise,
        createdAt: now,
        updatedAt: now,
        functions: _functions.map((fn) => EventFunction(
          id: fn.id,
          eventId: eventId,
          title: fn.title,
          functionDate: fn.functionDate,
          startTime: fn.startTime,
          endTime: fn.endTime,
          venue: fn.venue,
          description: fn.description,
          status: fn.status,
          createdAt: now,
          updatedAt: now,
        )).toList(),
        participants: _participants.map((p) => EventParticipant(
          id: p.id,
          eventId: eventId,
          personId: p.personId,
          familyId: p.familyId,
          name: p.name,
          role: p.role,
          phone: p.phone,
          notes: p.notes,
          createdAt: now,
        )).toList(),
        tasks: _initialTasks.map((t) => EventTask(
          id: t.id,
          eventId: eventId,
          title: t.title,
          description: t.description,
          dueDate: t.dueDate,
          priority: t.priority,
          status: t.status,
          createdAt: now,
        )).toList(),
        reminders: _reminders.map((r) => EventReminder(
          id: r.id,
          eventId: eventId,
          title: '${_titleController.text.trim()} - ${r.title}',
          reminderDate: r.reminderDate,
          preset: r.preset,
          createdAt: now,
        )).toList(),
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
}
