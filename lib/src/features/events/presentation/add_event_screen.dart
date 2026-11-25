import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../app/app_providers.dart';

/// Sub-event item helper for ceremonies and functions
class _SubEventItem {
  final String id;
  String title;
  String date;
  TimeOfDay? time;

  _SubEventItem({
    required this.id,
    required this.title,
    required this.date,
  });
}

/// Clean, focused, and responsive Event Creation Form for व्यवहार (Vyavahaar)
/// with full sub-events (उप-कार्यक्रम व रस्में) support and individual date selection.
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
  String? _selectedCustomTypeName;
  late String _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  bool _isSaving = false;

  final List<_SubEventItem> _subEvents = [];
  List<String> _conflictWarnings = [];

  List<String> get _quickSubEventSuggestions {
    switch (_selectedType) {
      case EventType.shaadi:
        return const ['तिलक', 'हल्दी', 'मेहंदी', 'संगीत', 'बारात', 'रिसेप्शन'];
      case EventType.engagement:
      case EventType.sagai:
        return const ['रोका', 'अंगूठी रस्म', 'प्रीतिभोज'];
      case EventType.mundan:
        return const ['हवन / पूजा', 'मुंडन संस्कार', 'भोज'];
      case EventType.grihaPravesh:
        return const ['वास्तु शांति', 'गृह प्रवेश पूजा', 'भोज'];
      default:
        return const ['मुख्य समारोह', 'प्रीतिभोज / दावत', 'पूजा'];
    }
  }

  List<EventType> _getDistinctStandardEventTypes() {
    return const [
      EventType.shaadi,
      EventType.sagai,
      EventType.tilak,
      EventType.baraat,
      EventType.haldi,
      EventType.mehndi,
      EventType.reception,
      EventType.grihaPravesh,
      EventType.namkaran,
      EventType.mundan,
      EventType.janeu,
      EventType.godhBharai,
      EventType.chhathi,
      EventType.birthday,
      EventType.anniversary,
      EventType.katha,
      EventType.religiousCeremony,
      EventType.festival,
      EventType.familyGathering,
      EventType.retirement,
      EventType.inauguration,
      EventType.funeral,
      EventType.communityEvent,
      EventType.other,
    ];
  }

  IconData _getEventTypeIcon(EventType type) {
    return switch (type) {
      EventType.shaadi || EventType.wedding => Icons.favorite_border,
      EventType.sagai || EventType.engagement => Icons.diamond_outlined,
      EventType.tilak => Icons.auto_awesome_outlined,
      EventType.baraat => Icons.music_note_outlined,
      EventType.haldi || EventType.mehndi => Icons.spa_outlined,
      EventType.reception => Icons.restaurant_outlined,
      EventType.grihaPravesh => Icons.home_outlined,
      EventType.namkaran => Icons.child_care_outlined,
      EventType.mundan => Icons.content_cut_outlined,
      EventType.janeu => Icons.self_improvement_outlined,
      EventType.godhBharai => Icons.pregnant_woman_outlined,
      EventType.chhathi => Icons.celebration_outlined,
      EventType.birthday => Icons.cake_outlined,
      EventType.anniversary => Icons.alarm_on_outlined,
      EventType.katha || EventType.religiousCeremony => Icons.wb_sunny_outlined,
      EventType.festival => Icons.festival_outlined,
      EventType.familyGathering => Icons.groups_outlined,
      EventType.retirement => Icons.badge_outlined,
      EventType.inauguration => Icons.storefront_outlined,
      EventType.funeral => Icons.nights_stay_outlined,
      EventType.communityEvent => Icons.people_outline,
      _ => Icons.event_outlined,
    };
  }

  void _showCreateCustomTypeDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addNewEventType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.customEventTypeHint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.enterCustomEventType,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              await ref.read(settingsRepositoryProvider).addCustomEventType(text);
              if (mounted) {
                setState(() {
                  _selectedType = EventType.other;
                  _selectedCustomTypeName = text;
                  _customCeremonyController.text = text;
                });
                _checkConflicts();
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.saveAndSelect, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEventTypePickerSheet(BuildContext context, AppLocalizations l10n, List<String> customTypes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
            final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
            final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
            final textPrimary = theme.colorScheme.onSurface;
            final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final primaryAccent = theme.colorScheme.primary;

            final filteredCustom = customTypes.where((c) =>
                searchQuery.isEmpty || c.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            final filteredStandard = _getDistinctStandardEventTypes().where((t) {
              if (searchQuery.isEmpty) return true;
              final label = l10n.eventTypeLabel(t).toLowerCase();
              return label.contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.selectEventType,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: TextField(
                          onChanged: (val) => setSheetState(() => searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: l10n.searchEventTypeHint,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: searchBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCreateCustomTypeDialog(context, l10n);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: primaryAccent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '+ ${l10n.addNewEventType}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryAccent),
                                      ),
                                      Text(
                                        l10n.customEventTypeHint,
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: primaryAccent, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            if (filteredCustom.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  l10n.customEventTypes,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent, letterSpacing: 0.5),
                                ),
                              ),
                              ...filteredCustom.map((cType) {
                                final isSelected = _selectedCustomTypeName == cType;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryAccent.withValues(alpha: 0.12) : searchBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? primaryAccent : cardBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(Icons.stars_outlined, size: 18, color: isSelected ? primaryAccent : textSecondary),
                                    title: Text(
                                      cType,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? primaryAccent : textPrimary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          Icon(Icons.check, size: 18, color: primaryAccent),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, size: 18, color: textSecondary),
                                          onPressed: () async {
                                            await ref.read(settingsRepositoryProvider).removeCustomEventType(cType);
                                            if (_selectedCustomTypeName == cType) {
                                              setState(() {
                                                _selectedCustomTypeName = null;
                                                _selectedType = EventType.shaadi;
                                              });
                                            }
                                            setSheetState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedType = EventType.other;
                                        _selectedCustomTypeName = cType;
                                        _customCeremonyController.text = cType;
                                      });
                                      _checkConflicts();
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                );
                              }),
                              const Divider(height: 24),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                l10n.standardEventTypes,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
                              ),
                            ),
                            ...filteredStandard.map((type) {
                              final label = l10n.eventTypeLabel(type);
                              final isSelected = _selectedCustomTypeName == null && _selectedType == type;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryAccent.withValues(alpha: 0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? primaryAccent : Colors.transparent,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    _getEventTypeIcon(type),
                                    size: 18,
                                    color: isSelected ? primaryAccent : textSecondary,
                                  ),
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? primaryAccent : textPrimary,
                                    ),
                                  ),
                                  trailing: isSelected ? Icon(Icons.check, size: 18, color: primaryAccent) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedType = type;
                                      _selectedCustomTypeName = null;
                                      _customCeremonyController.clear();
                                    });
                                    _checkConflicts();
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _eventDate = AppDateUtils.getTodayIsoString();
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
      category: _selectedCustomTypeName,
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
      final newDate = AppDateUtils.toIsoDateString(picked);
      setState(() {
        _eventDate = newDate;
        // Optionally update sub-events that had the old default date
        for (final sub in _subEvents) {
          if (sub.date.isEmpty) sub.date = newDate;
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

  void _addSubEventQuick(String title) {
    if (_subEvents.any((s) => s.title == title)) return;
    setState(() {
      _subEvents.add(_SubEventItem(
        id: const Uuid().v4(),
        title: title,
        date: _eventDate,
      ));
    });
  }

  void _showAddSubEventDialog(AppLocalizations l10n) {
    final titleController = TextEditingController();
    String subDate = _eventDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final textPrimary = theme.colorScheme.onSurface;
          final primaryAccent = theme.colorScheme.primary;

          return AlertDialog(
            title: const Text('उप-कार्यक्रम / रस्म जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('रस्म का नाम', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'उदा. महिला संगीत, भात / मायरा',
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text('रस्म की तारीख', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final initialDate = DateTime.tryParse(subDate) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        subDate = AppDateUtils.toIsoDateString(picked);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppDateUtils.formatIsoDate(subDate, l10n.locale.languageCode),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        Icon(Icons.calendar_month_outlined, size: 18, color: primaryAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    _subEvents.add(_SubEventItem(
                      id: const Uuid().v4(),
                      title: text,
                      date: subDate,
                    ));
                  });
                  Navigator.pop(ctx);
                },
                child: Text(l10n.add, style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSubEventDialog(int idx, AppLocalizations l10n) {
    if (idx < 0 || idx >= _subEvents.length) return;
    final item = _subEvents[idx];
    final titleController = TextEditingController(text: item.title);
    String subDate = item.date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final textPrimary = theme.colorScheme.onSurface;
          final primaryAccent = theme.colorScheme.primary;

          return AlertDialog(
            title: const Text('उप-कार्यक्रम / रस्म संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('रस्म का नाम', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'उदा. महिला संगीत, भात / मायरा',
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text('रस्म की तारीख', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final initialDate = DateTime.tryParse(subDate) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        subDate = AppDateUtils.toIsoDateString(picked);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppDateUtils.formatIsoDate(subDate, l10n.locale.languageCode),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        Icon(Icons.calendar_month_outlined, size: 18, color: primaryAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    item.title = text;
                    item.date = subDate;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('सहेजें', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(eventsRepositoryProvider);
      final l10n = context.l10n;
      final now = DateTime.now();
      final eventId = const Uuid().v4();

      final customName = _selectedCustomTypeName?.trim().isNotEmpty == true
          ? _selectedCustomTypeName!.trim()
          : (_selectedType == EventType.other && _customCeremonyController.text.trim().isNotEmpty
              ? _customCeremonyController.text.trim()
              : null);

      final event = Event(
        id: eventId,
        title: _titleController.text.trim(),
        eventType: _selectedType,
        category: customName,
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
        functions: _subEvents.map((s) => EventFunction(
          id: s.id,
          eventId: eventId,
          title: s.title,
          functionDate: s.date,
          startTime: s.time != null
              ? '${s.time!.hour.toString().padLeft(2, '0')}:${s.time!.minute.toString().padLeft(2, '0')}'
              : null,
          venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
          status: EventStatus.planned,
          createdAt: now,
          updatedAt: now,
        )).toList(),
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

      if (customName != null && customName.isNotEmpty) {
        await ref.read(settingsRepositoryProvider).addCustomEventType(customName);
      }

      // Reactive invalidation for instant numbers update
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(activeEventsListProvider);
      ref.invalidate(customEventTypesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventSavedSuccess), backgroundColor: AppColors.milaGreen),
        );
        Navigator.pop(context, event);
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
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;
    final customTypes = ref.watch(customEventTypesProvider).value ?? [];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.createNewEvent,
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.eventType, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                          InkWell(
                            onTap: () => _showCreateCustomTypeDialog(context, l10n),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                '+ ${l10n.addNewEventType}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Main Event Type Selection Card
                      InkWell(
                        onTap: () => _showEventTypePickerSheet(context, l10n, customTypes),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedCustomTypeName != null ? primaryAccent.withValues(alpha: 0.5) : cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedCustomTypeName != null ? Icons.stars_outlined : _getEventTypeIcon(_selectedType),
                                size: 20,
                                color: primaryAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedCustomTypeName ?? l10n.eventTypeLabel(_selectedType),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (_selectedCustomTypeName != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l10n.customEventTypes,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                  ),
                                ),
                              Icon(Icons.keyboard_arrow_down, size: 20, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Chips Horizontal Scroll
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                avatar: Icon(Icons.add, size: 14, color: primaryAccent),
                                label: Text(
                                  l10n.addNewEventType,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                                ),
                                backgroundColor: primaryAccent.withValues(alpha: 0.08),
                                side: BorderSide(color: primaryAccent.withValues(alpha: 0.3)),
                                onPressed: () => _showCreateCustomTypeDialog(context, l10n),
                              ),
                            ),
                            ...customTypes.map((cType) {
                              final isSelected = _selectedCustomTypeName == cType;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  avatar: Icon(Icons.stars_outlined, size: 14, color: isSelected ? Colors.white : primaryAccent),
                                  label: Text(
                                    cType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: primaryAccent,
                                  backgroundColor: inputBg,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedType = EventType.other;
                                        _selectedCustomTypeName = cType;
                                        _customCeremonyController.text = cType;
                                      });
                                      _checkConflicts();
                                    }
                                  },
                                ),
                              );
                            }),
                            ...[
                              EventType.shaadi,
                              EventType.sagai,
                              EventType.tilak,
                              EventType.grihaPravesh,
                              EventType.mundan,
                              EventType.namkaran,
                              EventType.birthday,
                              EventType.anniversary,
                              EventType.katha,
                              EventType.religiousCeremony,
                            ].map((type) {
                              final isSelected = _selectedCustomTypeName == null && _selectedType == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(
                                    l10n.eventTypeLabel(type),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: primaryAccent,
                                  backgroundColor: inputBg,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedType = type;
                                        _selectedCustomTypeName = null;
                                        _customCeremonyController.clear();
                                      });
                                      _checkConflicts();
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      if (_selectedType == EventType.other) ...[
                        const SizedBox(height: 12),
                        Text(l10n.enterCustomEventType, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _customCeremonyController,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: _inputDecoration(l10n.customEventTypeHint, inputBg, textSecondary),
                          onChanged: (val) {
                            setState(() => _selectedCustomTypeName = val.trim().isNotEmpty ? val.trim() : null);
                          },
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

                  // 3. Sub-Events & Ceremonies Card (उप-कार्यक्रम व रस्में)
                  _buildSectionCard(
                    title: 'उप-कार्यक्रम व रस्में (${_subEvents.length})',
                    icon: Icons.event_note_outlined,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    primaryAccent: primaryAccent,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'कार्यक्रम से जुड़ी मुख्य रस्में जोड़ें:',
                              style: TextStyle(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddSubEventDialog(l10n),
                            icon: const Icon(Icons.add, size: 15),
                            label: const Text('अन्य रस्म', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Quick Suggestion Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _quickSubEventSuggestions.map((title) {
                          final isAlreadyAdded = _subEvents.any((s) => s.title == title);
                          return InkWell(
                            onTap: isAlreadyAdded ? null : () => _addSubEventQuick(title),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isAlreadyAdded
                                    ? primaryAccent.withValues(alpha: 0.15)
                                    : inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAlreadyAdded ? primaryAccent : cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAlreadyAdded ? Icons.check : Icons.add,
                                    size: 13,
                                    color: isAlreadyAdded ? primaryAccent : textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isAlreadyAdded ? FontWeight.bold : FontWeight.w500,
                                      color: isAlreadyAdded ? primaryAccent : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_subEvents.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        ..._subEvents.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sub = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.stars_rounded, size: 16, color: primaryAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showEditSubEventDialog(idx, l10n),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Text(
                                      sub.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Sub-Event Date Selector Chip
                                InkWell(
                                  onTap: () async {
                                    final initialDate = DateTime.tryParse(sub.date) ?? DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initialDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        sub.date = AppDateUtils.toIsoDateString(picked);
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: primaryAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_month, size: 13, color: primaryAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppDateUtils.formatIsoDate(sub.date, l10n.locale.languageCode),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: primaryAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 16, color: primaryAccent),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  tooltip: 'संपादित करें',
                                  onPressed: () => _showEditSubEventDialog(idx, l10n),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  tooltip: 'हटाएं',
                                  onPressed: () => setState(() => _subEvents.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 4. Location & Notes Card
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
