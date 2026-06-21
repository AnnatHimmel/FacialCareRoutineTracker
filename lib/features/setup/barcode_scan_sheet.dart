import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/scanned_product_info.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/product_thumb.dart';
import 'add_custom_product_sheet.dart';

enum _ScanState {
  scanning,
  analyzing,
  lookingUp,
  productNotFound,
  permissionDenied,
  masterProductFound,
}

/// Bottom-sheet wrapper around [BarcodeScanView] — used by the floating "scan"
/// button on the My-Products browse tab. The inline guided-flow scan tab embeds
/// [BarcodeScanView] directly instead (single screen, no separate black sheet).
class BarcodeScanSheet extends StatelessWidget {
  const BarcodeScanSheet({
    super.key,
    this.testBarcodeToScan,
    this.testGalleryResult,
    this.testForceCameraUnavailable = false,
    this.onExternalProductFound,
  });

  final String? testBarcodeToScan;
  final ({String? code})? testGalleryResult;
  final bool testForceCameraUnavailable;
  final void Function(ScannedProductInfo info)? onExternalProductFound;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.barcodeScan,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BarcodeScanView(
                testBarcodeToScan: testBarcodeToScan,
                testGalleryResult: testGalleryResult,
                testForceCameraUnavailable: testForceCameraUnavailable,
                onExternalProductFound: onExternalProductFound,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The live barcode-scanning experience: camera viewfinder, lookup, and the
/// recognized / not-found result states. Used inline (embedded) on the guided
/// scan tab and inside [BarcodeScanSheet]. When [onClose] is null the view is
/// embedded — after adding a product it stays put so the user can keep scanning.
class BarcodeScanView extends ConsumerStatefulWidget {
  const BarcodeScanView({
    super.key,
    @visibleForTesting this.testBarcodeToScan,
    @visibleForTesting this.testGalleryResult,
    @visibleForTesting this.testForceCameraUnavailable = false,
    this.onExternalProductFound,
    this.onClose,
  });

  @visibleForTesting
  final String? testBarcodeToScan;

  @visibleForTesting
  final ({String? code})? testGalleryResult;

  @visibleForTesting
  final bool testForceCameraUnavailable;

  final void Function(ScannedProductInfo info)? onExternalProductFound;

  /// Dismisses the scanner (sheet mode). Null when embedded inline.
  final VoidCallback? onClose;

  @override
  ConsumerState<BarcodeScanView> createState() => _BarcodeScanViewState();
}

class _BarcodeScanViewState extends ConsumerState<BarcodeScanView> {
  late final MobileScannerController _controller;
  bool _cameraAvailable = false;
  _ScanState _state = _ScanState.scanning;
  String? _scannedBarcode;
  MasterProduct? _matchedMasterProduct;
  bool _matchedProductAlreadyInRoutine = false;

  @override
  void initState() {
    super.initState();
    if (widget.testGalleryResult != null) {
      final code = widget.testGalleryResult!.code;
      if (code != null) {
        _state = _ScanState.lookingUp;
        _scannedBarcode = code;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _performLookup(code),
        );
      } else {
        _state = _ScanState.productNotFound;
        _scannedBarcode = '';
      }
    } else if (widget.testBarcodeToScan != null) {
      _state = _ScanState.lookingUp;
      _scannedBarcode = widget.testBarcodeToScan;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _performLookup(widget.testBarcodeToScan!),
      );
    } else if (!kIsWeb &&
        !widget.testForceCameraUnavailable &&
        widget.testBarcodeToScan == null &&
        widget.testGalleryResult == null) {
      _controller = MobileScannerController(
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.normal,
      );
      _cameraAvailable = true;
    }
  }

  @override
  void dispose() {
    if (_cameraAvailable) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_state != _ScanState.scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    if (_cameraAvailable) _controller.stop();
    final code = barcode!.rawValue!;
    setState(() {
      _state = _ScanState.lookingUp;
      _scannedBarcode = code;
      _matchedMasterProduct = null;
    });
    _performLookup(code);
  }

  Future<void> _performLookup(String barcode) async {
    MasterContent? content;
    try {
      content = await ref.read(masterContentProvider.future);
    } catch (_) {
      // If master content fails to load, fall through to external APIs
    }

    if (kDebugMode) {
      if (content == null) {
        debugPrint('[Barcode:$barcode] master content unavailable, skipping master check');
      } else {
        final withBarcodes = content.products.where((p) => p.barcodes.isNotEmpty).length;
        final match = content.products
            .where((p) => !p.isDeprecated && p.barcodes.contains(barcode))
            .firstOrNull;
        debugPrint('[Barcode:$barcode] master check: '
            '${match != null ? "✓ matched ${match.id}" : "no match"} '
            '($withBarcodes/${content.products.length} products have barcodes)');
      }
    }

    if (content != null) {
      final match = content.products
          .where((p) => !p.isDeprecated && p.barcodes.contains(barcode))
          .firstOrNull;
      if (match != null) {
        final scheduler = ref.read(routineSchedulerProvider);
        final morningList = await scheduler.watchSelections(Slot.morning).first;
        final eveningList = await scheduler.watchSelections(Slot.evening).first;
        final alreadyMorning = match.morningConfig == null ||
            morningList.any((s) => s.productId == match.id && s.isSelected);
        final alreadyEvening = match.eveningConfig == null ||
            eveningList.any((s) => s.productId == match.id && s.isSelected);

        if (!mounted) return;
        setState(() {
          _matchedMasterProduct = match;
          _matchedProductAlreadyInRoutine = alreadyMorning && alreadyEvening;
          _state = _ScanState.masterProductFound;
        });
        return;
      }
    }

    final service = ref.read(barcodeProductLookupServiceProvider);
    final result = await service.lookup(barcode);
    if (!mounted) return;
    if (result != null && result.hasUsefulData) {
      _handleExternalFound(result);
    } else {
      setState(() {
        _state = _ScanState.productNotFound;
      });
    }
  }

  void _handleExternalFound(ScannedProductInfo result) {
    if (widget.onExternalProductFound != null) {
      setState(() {
        _state = _ScanState.productNotFound;
      });
      widget.onExternalProductFound!(result);
    } else {
      if (!mounted) return;
      _openAdd(context, prefill: result);
    }
  }

  Future<void> _addMasterProduct(MasterProduct product) async {
    final scheduler = ref.read(routineSchedulerProvider);
    final morningList = await scheduler.watchSelections(Slot.morning).first;
    final eveningList = await scheduler.watchSelections(Slot.evening).first;

    final alreadyMorning =
        morningList.any((s) => s.productId == product.id && s.isSelected);
    final alreadyEvening =
        eveningList.any((s) => s.productId == product.id && s.isSelected);

    const uuid = Uuid();
    if (product.morningConfig != null && !alreadyMorning) {
      await scheduler.upsertSelection(ProductSelection(
        id: uuid.v4(),
        productId: product.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime.now(),
      ));
    }
    if (product.eveningConfig != null && !alreadyEvening) {
      await scheduler.upsertSelection(ProductSelection(
        id: uuid.v4(),
        productId: product.id,
        slot: Slot.evening,
        isSelected: true,
        lastModified: DateTime.now(),
      ));
    }

    if (!mounted) return;
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      // Embedded: keep the view, flip to the "already in routine" confirmation
      // and let the user scan the next product.
      setState(() => _matchedProductAlreadyInRoutine = true);
    }
  }

  void _dismiss() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted) {
      _scanAgain();
    }
  }

  /// Opens the manual add-product sheet (optionally prefilled from a scan) on
  /// top of the scanner, then dismisses/resets the scanner once it closes.
  Future<void> _openAdd(BuildContext context, {ScannedProductInfo? prefill}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomProductSheet(prefillFromScan: prefill),
    );
    if (!mounted) return;
    _dismiss();
  }

  void _scanAgain() {
    setState(() {
      _state = _ScanState.scanning;
      _matchedMasterProduct = null;
      _matchedProductAlreadyInRoutine = false;
    });
    if (_cameraAvailable) {
      _controller.start();
    }
  }

  void _handleGalleryCode(String? code) {
    if (code != null) {
      setState(() {
        _state = _ScanState.lookingUp;
        _scannedBarcode = code;
        _matchedMasterProduct = null;
      });
      _performLookup(code);
    } else {
      setState(() {
        _state = _ScanState.productNotFound;
        _scannedBarcode = '';
      });
    }
  }

  Future<void> _pickAndAnalyzeGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _state = _ScanState.analyzing);

    String? code;
    try {
      MobileScannerController? tempController;
      MobileScannerController controller;
      if (_cameraAvailable) {
        controller = _controller;
      } else {
        tempController = MobileScannerController();
        controller = tempController;
      }
      final capture = await controller.analyzeImage(picked.path);
      code = capture?.barcodes.firstOrNull?.rawValue;
      tempController?.dispose();
    } catch (_) {
      code = null;
    }

    if (!mounted) return;
    _handleGalleryCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return switch (_state) {
      _ScanState.analyzing => _AnalyzingState(l: l),
      _ScanState.lookingUp => _LookingUpState(
          barcode: _scannedBarcode ?? '',
          l: l,
        ),
      _ScanState.masterProductFound => _MasterProductFoundState(
          product: _matchedMasterProduct!,
          isAlreadyInRoutine: _matchedProductAlreadyInRoutine,
          l: l,
          onAddToRoutine: () => _addMasterProduct(_matchedMasterProduct!),
          onScanAgain: _scanAgain,
        ),
      _ScanState.productNotFound => _ProductNotFoundState(
          barcode: _scannedBarcode ?? '',
          l: l,
          onAddManually: () => _openAdd(context),
          onScanAgain: _scanAgain,
        ),
      _ScanState.permissionDenied => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_rounded,
                    size: 48, color: AppColors.outline),
                const SizedBox(height: 16),
                Text(
                  l.barcodeScanPermissionDenied,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      _ScanState.scanning => _cameraAvailable
          ? _ScannerView(
              controller: _controller,
              hint: l.barcodeScanHint,
              onDetect: _onDetect,
              galleryLabel: l.barcodeScanFromGallery,
              onPickGallery: _pickAndAnalyzeGallery,
            )
          : _GalleryOnlyScanView(
              l: l,
              onPickGallery: _pickAndAnalyzeGallery,
              onAddManually: () => _openAdd(context),
            ),
    };
  }
}

// ── Scanner viewfinder ─────────────────────────────────────────────────────────

class _ScannerView extends StatefulWidget {
  final MobileScannerController controller;
  final String hint;
  final void Function(BarcodeCapture) onDetect;
  final String galleryLabel;
  final VoidCallback onPickGallery;

  const _ScannerView({
    required this.controller,
    required this.hint,
    required this.onDetect,
    required this.galleryLabel,
    required this.onPickGallery,
  });

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laser;

  @override
  void initState() {
    super.initState();
    _laser = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // ── Viewfinder card (live camera is naturally dark) ───────────────
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                boxShadow: AppColors.glowSm,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Black base so the card never shows cream while the camera
                    // feed is initializing.
                    const Positioned.fill(child: ColoredBox(color: Colors.black)),
                    Positioned.fill(
                      child: MobileScanner(
                        controller: widget.controller,
                        onDetect: widget.onDetect,
                      ),
                    ),
                    // Aiming frame + animated laser line
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 140,
                        child: Stack(
                          children: [
                            // Corner accents
                            Positioned.fill(
                              child: CustomPaint(painter: _CornerPainter()),
                            ),
                            // Glowing peach scan line, sweeping top↔bottom
                            AnimatedBuilder(
                              animation: _laser,
                              builder: (context, _) => Positioned(
                                left: 8,
                                right: 8,
                                top: 8 + _laser.value * 124,
                                child: const _LaserLine(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Hint at bottom inside the card
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.hint,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelMd.copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Gallery scan button — below the card, on cream ────────────────
          _GalleryScanButton(
            label: widget.galleryLabel,
            onPressed: widget.onPickGallery,
          ),
        ],
      ),
    );
  }
}

/// A thin peach gradient line with a soft glow — the sweeping scan indicator.
class _LaserLine extends StatelessWidget {
  const _LaserLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x00FF8B71),
            AppColors.primaryContainer,
            Color(0x00FF8B71),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66FF8B71),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ── Gallery-only scan view (web / camera-unavailable) ─────────────────────────

class _GalleryOnlyScanView extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback onPickGallery;
  final VoidCallback onAddManually;

  const _GalleryOnlyScanView({
    required this.l,
    required this.onPickGallery,
    required this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant, width: 1.5),
            ),
            child: const Icon(
              Icons.image_search_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.barcodeScanWebTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.barcodeScanWebSub,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _GalleryScanButton(
            label: l.barcodeScanFromGallery,
            onPressed: onPickGallery,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAddManually,
            child: Text(
              l.barcodeScanAddManually,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared gallery scan button ─────────────────────────────────────────────────

class _GalleryScanButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GalleryScanButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.photo_library_outlined, size: 20),
      label: Text(
        label,
        style: AppTypography.labelMd.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(AppColors.primary.withAlpha(15)),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 22.0;
    const strokeW = 3.5;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    // top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // bottom-left
    canvas.drawLine(
        Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - len), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ── Analyzing state ───────────────────────────────────────────────────────────

class _AnalyzingState extends StatelessWidget {
  final AppLocalizations l;

  const _AnalyzingState({required this.l});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.barcodeScanAnalyzing,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Looking-up state ──────────────────────────────────────────────────────────

class _LookingUpState extends StatelessWidget {
  final String barcode;
  final AppLocalizations l;

  const _LookingUpState({required this.barcode, required this.l});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.barcodeScanLookingUp,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _BarcodeChip(barcode: barcode),
        ],
      ),
    );
  }
}

// ── Master-product-found state ────────────────────────────────────────────────

class _MasterProductFoundState extends StatelessWidget {
  final MasterProduct product;
  final bool isAlreadyInRoutine;
  final AppLocalizations l;
  final VoidCallback onAddToRoutine;
  final VoidCallback onScanAgain;

  const _MasterProductFoundState({
    required this.product,
    required this.isAlreadyInRoutine,
    required this.l,
    required this.onAddToRoutine,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final hasMorning = product.morningConfig != null;
    final hasEvening = product.eveningConfig != null;
    final comment = product.comment ?? product.commentEn ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed header ──────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                l.barcodeScanMasterProductFound,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Scrollable middle: product card + comment ─────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: AppColors.glowSm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductThumb(imageAsset: product.imageAsset, size: 80),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.brand != null)
                                Text(
                                  product.brand!,
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              Text(
                                product.name,
                                style: AppTypography.headlineMd.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (hasMorning || hasEvening) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (hasMorning)
                                      _SlotChip(
                                        label: l.slotMorning,
                                        color: AppColors.secondary,
                                      ),
                                    if (hasEvening)
                                      _SlotChip(
                                        label: l.slotEvening,
                                        color: AppColors.tertiary,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _truncate(comment, 180),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Fixed footer: action + scan-again (always visible) ────────────
          const SizedBox(height: 16),
          if (isAlreadyInRoutine)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.secondary.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l.barcodeScanAlreadyInRoutine,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddToRoutine,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  l.barcodeScanAddToRoutine,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: onScanAgain,
              child: Text(
                l.barcodeScanRetry,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SlotChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Product-not-found state ───────────────────────────────────────────────────

class _ProductNotFoundState extends StatelessWidget {
  final String barcode;
  final AppLocalizations l;
  final VoidCallback onAddManually;
  final VoidCallback onScanAgain;

  const _ProductNotFoundState({
    required this.barcode,
    required this.l,
    required this.onAddManually,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.outlineVariant, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      color: AppColors.outline,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.barcodeScanProductNotFound,
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _BarcodeChip(barcode: barcode),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onAddManually,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                l.barcodeScanAddManually,
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onScanAgain,
            child: Text(
              l.barcodeScanRetry,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared barcode chip ───────────────────────────────────────────────────────

class _BarcodeChip extends StatelessWidget {
  final String barcode;

  const _BarcodeChip({required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_rounded,
              color: AppColors.onSurfaceVariant, size: 15),
          const SizedBox(width: 8),
          Text(
            barcode,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
