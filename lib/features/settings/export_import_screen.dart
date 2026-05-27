import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';
import 'merge_conflict_screen.dart';

class ExportImportScreen extends ConsumerStatefulWidget {
  const ExportImportScreen({super.key});

  @override
  ConsumerState<ExportImportScreen> createState() =>
      _ExportImportScreenState();
}

class _ExportImportScreenState extends ConsumerState<ExportImportScreen> {
  bool _exporting = false;
  bool _importing = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _statusMessage = null;
      _isError = false;
    });
    try {
      final service = ref.read(exportImportServiceProvider);
      final bytes = await service.exportToArchive();

      if (kIsWeb) {
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: 'skincare_backup.zip', mimeType: 'application/zip')],
          subject: 'גיבוי נתונים — טיפוח עור',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/skincare_backup.zip');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'גיבוי נתונים — טיפוח עור',
        );
      }
      if (mounted) {
        setState(() => _statusMessage = 'הייצוא הושלם בהצלחה');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'שגיאה בייצוא: $e';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport() async {
    setState(() {
      _importing = true;
      _statusMessage = null;
      _isError = false;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );

      if (result == null || result.files.isEmpty || !mounted) {
        setState(() => _importing = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        setState(() {
          _importing = false;
          _statusMessage = 'לא ניתן לקרוא את הקובץ';
          _isError = true;
        });
        return;
      }

      await _showImportDialog(Uint8List.fromList(bytes));
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'שגיאה בייבוא: $e';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _showImportDialog(Uint8List bytes) async {
    final service = ref.read(exportImportServiceProvider);
    final validation = service.validateArchive(bytes);

    if (!validation.isValid) {
      if (mounted) {
        setState(() {
          _statusMessage = validation.errorMessage ?? 'קובץ לא תקין';
          _isError = true;
        });
      }
      return;
    }

    if (!mounted) return;

    final choice = await showDialog<_ImportChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ייבוא נתונים', style: AppTypography.headlineMd),
        content: Text(
          'כיצד לטפל בנתונים הקיימים?',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ImportChoice.cancel),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ImportChoice.replace),
            child: const Text('החלפה'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ImportChoice.merge),
            child: const Text('מיזוג'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _ImportChoice.cancel) {
      return;
    }

    if (choice == _ImportChoice.replace) {
      await service.replaceAll(validation);
      if (mounted) {
        setState(() => _statusMessage = 'הנתונים הוחלפו בהצלחה');
      }
    } else {
      // Merge flow — navigate to merge screen with bytes encoded
      final session = await service.startMerge(validation);
      if (!mounted) return;
      if (session.conflicts.isEmpty) {
        await session.complete();
        if (mounted) {
          setState(() => _statusMessage = 'המיזוג הושלם — לא נמצאו התנגשויות');
        }
      } else {
        // Pass merge session via a state provider and navigate
        ref.read(pendingMergeSessionProvider.notifier).state = session;
        context.push('/export-import/merge');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ייצוא / ייבוא', style: AppTypography.headlineMd),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Export section
          _SectionCard(
            icon: Icons.upload_outlined,
            title: 'ייצוא נתונים',
            description:
                'שמור גיבוי של כל הנתונים שלך כארכיון ZIP',
            actionLabel: _exporting ? null : 'ייצוא',
            isLoading: _exporting,
            onTap: _exporting ? null : _export,
          ),
          const SizedBox(height: 16),

          // Import section
          _SectionCard(
            icon: Icons.download_outlined,
            title: 'ייבוא נתונים',
            description:
                'שחזר נתונים מגיבוי קיים (החלפה מלאה או מיזוג)',
            actionLabel: _importing ? null : 'ייבוא',
            isLoading: _importing,
            onTap: _importing ? null : _pickAndImport,
          ),

          // Status message
          if (_statusMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError
                    ? AppColors.errorContainer
                    : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusMessage!,
                style: AppTypography.bodyMd.copyWith(
                  color: _isError
                      ? AppColors.error
                      : AppColors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ImportChoice { replace, merge, cancel }

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(title, style: AppTypography.headlineMd),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: onTap,
                      child: Text(actionLabel ?? ''),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

