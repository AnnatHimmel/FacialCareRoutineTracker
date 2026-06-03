import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
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

  Future<void> _export(AppLocalizations l) async {
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
        setState(() => _statusMessage = l.exportSuccess);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = l.exportError(e);
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport(AppLocalizations l) async {
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
          _statusMessage = l.importFileReadError;
          _isError = true;
        });
        return;
      }

      await _showImportDialog(Uint8List.fromList(bytes), l);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = l.importError(e);
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _showImportDialog(Uint8List bytes, AppLocalizations l) async {
    final service = ref.read(exportImportServiceProvider);
    final validation = service.validateArchive(bytes);

    if (!validation.isValid) {
      if (mounted) {
        setState(() {
          _statusMessage = validation.errorMessage ?? l.importInvalidFile;
          _isError = true;
        });
      }
      return;
    }

    if (!mounted) return;

    final choice = await showDialog<_ImportChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.importDataTitle, style: AppTypography.headlineMd),
        content: Text(
          l.importDialogQuestion,
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ImportChoice.cancel),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ImportChoice.replace),
            child: Text(l.importReplace),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ImportChoice.merge),
            child: Text(l.importMerge),
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
        setState(() => _statusMessage = l.importReplaceSuccess);
      }
    } else {
      final session = await service.startMerge(validation);
      if (!mounted) return;
      if (session.conflicts.isEmpty) {
        await session.complete();
        if (mounted) {
          setState(() => _statusMessage = l.importMergeNoConflicts);
        }
      } else {
        ref.read(pendingMergeSessionProvider.notifier).state = session;
        context.push('/export-import/merge');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _SectionCard(
            icon: Icons.upload_outlined,
            title: l.exportDataTitle,
            description: l.exportDataDesc,
            actionLabel: l.exportDataAction,
            isLoading: _exporting,
            onTap: _exporting ? null : () => _export(l),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            icon: Icons.download_outlined,
            title: l.importDataTitle,
            description: l.importDataDesc,
            actionLabel: l.importDataAction,
            isLoading: _importing,
            onTap: _importing ? null : () => _pickAndImport(l),
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            GlowCard(
              padding: const EdgeInsets.all(14),
              color: _isError ? AppColors.errorContainer : AppColors.secondaryFixed,
              shadow: AppColors.glowSm,
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _isError ? AppColors.error : AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: AppTypography.bodyMd.copyWith(
                        color: _isError
                            ? AppColors.error
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
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
    this.actionLabel,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineMd,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(actionLabel ?? ''),
                  ),
                ),
        ],
      ),
    );
  }
}
