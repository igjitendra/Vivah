import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/event_qr_service.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_button.dart';

/// Offline Camera + Gallery QR Scanner screen for adding shared Vyavahaar events.
class EventQrScannerScreen extends ConsumerStatefulWidget {
  const EventQrScannerScreen({super.key});

  @override
  ConsumerState<EventQrScannerScreen> createState() => _EventQrScannerScreenState();
}

class _EventQrScannerScreenState extends ConsumerState<EventQrScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessingScan = false;
  DateTime? _lastInvalidToastAt;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_isProcessingScan || !mounted) return;
    final rawValue = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (rawValue == null) return;

    await _processRawQrString(rawValue);
  }

  Future<void> _pickAndAnalyzeGalleryImage() async {
    if (_isProcessingScan || !mounted) return;
    setState(() => _isProcessingScan = true);

    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image);
      final path = picked?.files.singleOrNull?.path;
      if (path == null || path.isEmpty) {
        if (mounted) setState(() => _isProcessingScan = false);
        return;
      }

      final capture = await _controller.analyzeImage(path);
      final rawValue = capture?.barcodes
          .map((b) => b.rawValue)
          .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);

      if (rawValue == null) {
        if (mounted) {
          _showInvalidQrFeedback();
          setState(() => _isProcessingScan = false);
        }
        return;
      }

      await _processRawQrString(rawValue, alreadyLocked: true);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorGeneric}: $err')),
        );
        setState(() => _isProcessingScan = false);
      }
    }
  }

  Future<void> _processRawQrString(String rawValue, {bool alreadyLocked = false}) async {
    if (!alreadyLocked) {
      if (_isProcessingScan) return;
      _isProcessingScan = true;
    }

    final payload = EventQrService.tryDecode(rawValue);
    if (payload == null) {
      _showInvalidQrFeedback();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        setState(() => _isProcessingScan = false);
      } else {
        _isProcessingScan = false;
      }
      return;
    }

    // Pause live camera while user reviews the event preview sheet
    try {
      await _controller.stop();
    } catch (_) {}

    if (!mounted) return;
    final existingEvents = ref.read(activeEventsListProvider).value ?? const <Event>[];
    final isDuplicate = existingEvents.any(
      (e) =>
          e.title.trim().toLowerCase() == payload.title.trim().toLowerCase() &&
          e.eventDate.trim() == payload.eventDate.trim(),
    );

    final createdEvent = await showModalBottomSheet<Event?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScannedEventPreviewSheet(
        payload: payload,
        isDuplicate: isDuplicate,
      ),
    );

    if (!mounted) return;

    if (createdEvent != null) {
      ref.invalidate(activeEventsListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.eventAddedFromQrSuccess),
          backgroundColor: AppSemanticColors.of(context).mila,
        ),
      );
      context.pushReplacement('/event/${createdEvent.id}');
      return;
    }

    // User dismissed preview sheet -> resume scanning
    _isProcessingScan = false;
    try {
      await _controller.start();
    } catch (_) {}
  }

  void _showInvalidQrFeedback() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastInvalidToastAt != null &&
        now.difference(_lastInvalidToastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInvalidToastAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.invalidEventQr),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Viewfinder
          MobileScanner(
            controller: _controller,
            tapToFocus: true,
            onDetect: _handleBarcodeCapture,
            errorBuilder: (ctx, error) => _CameraErrorFallback(
              error: error,
              semantic: semantic,
              l10n: l10n,
              onPickFromGallery: _pickAndAnalyzeGalleryImage,
              onRetryCamera: () => _controller.start(),
            ),
          ),

          // Viewfinder Cutout Overlay
          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                frameColor: semantic.heroHighlight,
                scrimColor: Colors.black.withValues(alpha: 0.56),
              ),
            ),
          ),

          // Top Floating Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _ScannerCircleButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: l10n.close,
                      color: semantic.onHero,
                      bgColor: semantic.heroStart.withValues(alpha: 0.72),
                      borderColor: semantic.onHero.withValues(alpha: 0.22),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: semantic.heroStart.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: semantic.onHero.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          l10n.scanEventQr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: semantic.onHero,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        final torchOn = state.torchState == TorchState.on;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.torchState != TorchState.unavailable)
                              _ScannerCircleButton(
                                icon: torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                tooltip: 'Flash',
                                color: torchOn ? semantic.heroHighlight : semantic.onHero,
                                bgColor: semantic.heroStart.withValues(alpha: 0.72),
                                borderColor: semantic.onHero.withValues(alpha: 0.22),
                                onTap: () => _controller.toggleTorch(),
                              ),
                            const SizedBox(width: 8),
                            _ScannerCircleButton(
                              icon: Icons.cameraswitch_outlined,
                              tooltip: 'Switch Camera',
                              color: semantic.onHero,
                              bgColor: semantic.heroStart.withValues(alpha: 0.72),
                              borderColor: semantic.onHero.withValues(alpha: 0.22),
                              onTap: () => _controller.switchCamera(),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Instruction & Gallery Import Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: semantic.cardBg.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: semantic.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: semantic.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.qrScanInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: semantic.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ExpressButton(
                          label: l10n.scanFromGallery,
                          icon: Icons.photo_library_outlined,
                          tone: ExpressTone.tonal,
                          expand: true,
                          isLoading: _isProcessingScan,
                          onPressed: _pickAndAnalyzeGalleryImage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ScannerCircleButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        shape: CircleBorder(side: BorderSide(color: borderColor)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

class _CameraErrorFallback extends StatelessWidget {
  final MobileScannerException error;
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final VoidCallback onPickFromGallery;
  final VoidCallback onRetryCamera;

  const _CameraErrorFallback({
    required this.error,
    required this.semantic,
    required this.l10n,
    required this.onPickFromGallery,
    required this.onRetryCamera,
  });

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPermissionDenied ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
                size: 48,
                color: semantic.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isPermissionDenied
                    ? (l10n.isEnglish
                        ? 'Camera permission is required to scan QR codes.'
                        : 'QR स्कैन करने के लिए कैमरा अनुमति आवश्यक है।')
                    : (l10n.isEnglish
                        ? 'Could not start camera preview.'
                        : 'कैमरा शुरू नहीं हो सका।'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: semantic.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.isEnglish
                    ? 'You can allow Camera in App Settings or choose a QR image from Gallery below.'
                    : 'आप ऐप सेटिंग्स में कैमरा अनुमति दे सकते हैं या नीचे गैलरी से QR फोटो चुन सकते हैं।',
                textAlign: TextAlign.center,
                style: TextStyle(color: semantic.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              ExpressButton(
                label: l10n.scanFromGallery,
                icon: Icons.photo_library_outlined,
                expand: true,
                onPressed: onPickFromGallery,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: onRetryCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.isEnglish ? 'Retry Camera' : 'कैमरा पुनः प्रयास करें'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color frameColor;
  final Color scrimColor;

  _ScannerOverlayPainter({
    required this.frameColor,
    required this.scrimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cutoutSize = (size.shortestSide * 0.68).clamp(210.0, 300.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: cutoutSize,
      height: cutoutSize,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    final backgroundPath = Path()..addRect(Offset.zero & size);
    final cutoutPath = Path()..addRRect(rrect);
    final scrimPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    canvas.drawPath(scrimPath, Paint()..color = scrimColor);

    final cornerPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    const r = 20.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLen)
        ..lineTo(rect.left, rect.top + r)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
        ..lineTo(rect.left + cornerLen, rect.top),
      cornerPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLen, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
        ..lineTo(rect.right, rect.top + cornerLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLen)
        ..lineTo(rect.left, rect.bottom - r)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left + r, rect.bottom)
        ..lineTo(rect.left + cornerLen, rect.bottom),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLen, rect.bottom)
        ..lineTo(rect.right - r, rect.bottom)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - r)
        ..lineTo(rect.right, rect.bottom - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.frameColor != frameColor || oldDelegate.scrimColor != scrimColor;
  }
}

class _ScannedEventPreviewSheet extends ConsumerStatefulWidget {
  final EventQrPayload payload;
  final bool isDuplicate;

  const _ScannedEventPreviewSheet({
    required this.payload,
    required this.isDuplicate,
  });

  @override
  ConsumerState<_ScannedEventPreviewSheet> createState() => _ScannedEventPreviewSheetState();
}

class _ScannedEventPreviewSheetState extends ConsumerState<_ScannedEventPreviewSheet> {
  late final TextEditingController _hostController;
  EventScope _scope = EventScope.relative;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.payload.hostName ?? '');
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _saveImportedEvent() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final newEvent = widget.payload.toNewEvent(
        scope: _scope,
        overrideHostName: _hostController.text.trim(),
      );
      await ref.read(eventsRepositoryProvider).createEvent(newEvent);
      if (mounted) {
        Navigator.of(context).pop(newEvent);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorGeneric}: $err')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final p = widget.payload;
    final formattedDate = AppDateUtils.formatLocalizedDate(
      p.eventDate,
      l10n.locale.languageCode,
    );
    final locationText = [
      if (p.venue != null) p.venue!,
      if (p.villageCity != null) p.villageCity!,
    ].join(', ');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: semantic.cardBorder)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: semantic.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: semantic.milaContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event_available_rounded, color: semantic.mila, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.qrEventPreview,
                          style: TextStyle(
                            color: semantic.mila,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          p.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: semantic.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              if (widget.isDuplicate) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: semantic.warningContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: semantic.warning.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: semantic.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.duplicateEventWarning,
                          style: TextStyle(
                            color: semantic.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Summary Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: semantic.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewInfoRow(
                      icon: Icons.category_outlined,
                      label: l10n.eventTypeLabel(
                        p.eventType,
                        customCategory: p.category,
                      ),
                      semantic: semantic,
                    ),
                    const SizedBox(height: 8),
                    _PreviewInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: formattedDate,
                      semantic: semantic,
                    ),
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _PreviewInfoRow(
                        icon: Icons.location_on_outlined,
                        label: locationText,
                        semantic: semantic,
                      ),
                    ],
                    if (p.notes != null) ...[
                      const SizedBox(height: 8),
                      _PreviewInfoRow(
                        icon: Icons.notes_rounded,
                        label: p.notes!,
                        semantic: semantic,
                      ),
                    ],
                    if (p.functions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.functions
                            .map(
                              (fn) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: semantic.cardSubtleBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: semantic.cardBorder),
                                ),
                                child: Text(
                                  fn.title,
                                  style: TextStyle(
                                    color: semantic.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Event Scope Selector
              Row(
                children: [
                  Expanded(
                    child: _ScopeOptionChip(
                      label: l10n.relativeEvent,
                      subtitle: l10n.relativeEventSubtitle,
                      selected: _scope == EventScope.relative,
                      semantic: semantic,
                      onTap: () => setState(() => _scope = EventScope.relative),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ScopeOptionChip(
                      label: l10n.ownFamilyEvent,
                      subtitle: l10n.ownFamilyEventSubtitle,
                      selected: _scope == EventScope.ownFamily,
                      semantic: semantic,
                      onTap: () => setState(() => _scope = EventScope.ownFamily),
                    ),
                  ),
                ],
              ),

              if (_scope == EventScope.relative) ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    labelText: l10n.hostNameLabel,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: semantic.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: semantic.cardBorder),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: semantic.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ExpressButton(
                      label: l10n.addEventFromQr,
                      icon: Icons.add_task_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveImportedEvent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppSemanticColors semantic;

  const _PreviewInfoRow({
    required this.icon,
    required this.label,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: semantic.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: semantic.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScopeOptionChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _ScopeOptionChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? semantic.primary.withValues(alpha: 0.12) : semantic.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? semantic.primary : semantic.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 16,
                  color: selected ? semantic.primary : semantic.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? semantic.primary : semantic.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: semantic.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
