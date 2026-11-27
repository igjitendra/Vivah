import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../localization/app_localizations.dart';

/// Result returned when an image is captured/picked, compressed, and saved.
class SavedCompressedImage {
  final String path;
  final File file;
  final int originalBytes;
  final int compressedBytes;

  const SavedCompressedImage({
    required this.path,
    required this.file,
    required this.originalBytes,
    required this.compressedBytes,
  });

  String get readableSize => ImageStorageService.formatFileSize(compressedBytes);
}

/// Centralized, offline-safe image capture, compression & permanent storage service.
/// Supports real native Camera capture, Gallery picking, desktop fallback,
/// and background Isolate JPEG compression (~80–250 KB output).
class ImageStorageService {
  ImageStorageService._();

  static final ImagePicker _picker = ImagePicker();

  static bool get supportsMobileCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Shows a bottom sheet to choose Camera or Gallery, then captures/picks,
  /// compresses, and persists the JPEG inside app storage.
  static Future<SavedCompressedImage?> pickAndSaveCompressedImage({
    required BuildContext context,
    required AppLocalizations l10n,
    String subFolder = 'attachments',
    String prefix = 'img',
    ImageSource? directSource,
    int maxDimension = 1280,
    int quality = 75,
  }) async {
    ImageSource? source = directSource;
    if (source == null) {
      source = await showSourcePickerSheet(context: context, l10n: l10n);
      if (source == null) return null;
    }

    Uint8List? rawBytes;
    String fallbackExtension = '.jpg';

    try {
      if (supportsMobileCamera) {
        final XFile? picked = await _picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        if (picked == null) return null;
        rawBytes = await picked.readAsBytes();
        final ext = p.extension(picked.path);
        if (ext.isNotEmpty) fallbackExtension = ext;
      } else {
        // Desktop platforms fallback cleanly to FilePicker for image selection
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return null;
        final pf = result.files.first;
        if (pf.bytes != null) {
          rawBytes = pf.bytes;
        } else if (pf.path != null) {
          rawBytes = await File(pf.path!).readAsBytes();
        }
        if (pf.path != null && p.extension(pf.path!).isNotEmpty) {
          fallbackExtension = p.extension(pf.path!);
        }
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        final msg = e.code.toLowerCase().contains('denied')
            ? l10n.cameraPermissionDenied
            : '${l10n.proofImageError} (${e.message ?? e.code})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return null;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.proofImageError)),
        );
      }
      return null;
    }

    if (rawBytes == null || rawBytes.isEmpty) return null;

    return compressAndSaveBytes(
      rawBytes: rawBytes,
      subFolder: subFolder,
      prefix: prefix,
      fallbackExtension: fallbackExtension,
      maxDimension: maxDimension,
      quality: quality,
    );
  }

  /// Shows a bottom sheet letting the user pick Camera or Gallery.
  static Future<ImageSource?> showSourcePickerSheet({
    required BuildContext context,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (supportsMobileCamera)
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    l10n.takePhoto,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  l10n.chooseFromGallery,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.cancel),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compresses raw image bytes inside a background isolate and persists
  /// them under `<appDocumentsDirectory>/<subFolder>/<prefix>_...jpg`.
  static Future<SavedCompressedImage> compressAndSaveBytes({
    required Uint8List rawBytes,
    String subFolder = 'attachments',
    String prefix = 'img',
    String fallbackExtension = '.jpg',
    int maxDimension = 1280,
    int quality = 75,
    Directory? overrideBaseDir,
  }) async {
    final compressed = await compressImageBytes(
      rawBytes,
      maxDimension: maxDimension,
      quality: quality,
    );

    final baseDir = overrideBaseDir ?? await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(baseDir.path, subFolder));
    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }

    final ext = compressed.isJpg ? '.jpg' : fallbackExtension;
    final uniqueSuffix =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final destPath = p.join(targetDir.path, '${prefix}_$uniqueSuffix$ext');

    final destFile = File(destPath);
    await destFile.writeAsBytes(compressed.bytes, flush: true);

    return SavedCompressedImage(
      path: destPath,
      file: destFile,
      originalBytes: rawBytes.length,
      compressedBytes: compressed.bytes.length,
    );
  }

  /// Pure-Dart image compression executed in a background isolate.
  /// Decodes, bakes EXIF orientation, resizes large dimensions down to [maxDimension],
  /// and encodes as compact JPEG.
  static Future<({Uint8List bytes, bool isJpg})> compressImageBytes(
    Uint8List rawBytes, {
    int maxDimension = 1280,
    int quality = 75,
  }) async {
    try {
      return await Isolate.run(() {
        return _compressSync(
          rawBytes,
          maxDimension: maxDimension,
          quality: quality,
        );
      });
    } catch (_) {
      return (bytes: rawBytes, isJpg: false);
    }
  }

  static ({Uint8List bytes, bool isJpg}) _compressSync(
    Uint8List rawBytes, {
    required int maxDimension,
    required int quality,
  }) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return (bytes: rawBytes, isJpg: false);
    }

    var processed = img.bakeOrientation(decoded);
    if (processed.width > maxDimension || processed.height > maxDimension) {
      if (processed.width >= processed.height) {
        processed = img.copyResize(
          processed,
          width: maxDimension,
          interpolation: img.Interpolation.average,
        );
      } else {
        processed = img.copyResize(
          processed,
          height: maxDimension,
          interpolation: img.Interpolation.average,
        );
      }
    }

    final encoded = Uint8List.fromList(img.encodeJpg(processed, quality: quality));

    // If original bytes were already JPEG and smaller even after resize/re-encode
    // (only when dimensions were already within bounds), preserve the smaller JPEG.
    if (decoded.width <= maxDimension &&
        decoded.height <= maxDimension &&
        rawBytes.length < encoded.length &&
        _looksLikeJpeg(rawBytes)) {
      return (bytes: rawBytes, isJpg: true);
    }

    return (bytes: encoded, isJpg: true);
  }

  static bool _looksLikeJpeg(Uint8List bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
