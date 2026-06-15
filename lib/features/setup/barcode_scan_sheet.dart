import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/scanned_product_info.dart';
import '../../shared/providers/root_providers.dart';
import 'add_custom_product_sheet.dart';

enum _ScanState { scanning, lookingUp, productFound, productNotFound, permissionDenied }

class BarcodeScanSheet extends ConsumerStatefulWidget {
  const BarcodeScanSheet({super.key});

  @override
  ConsumerState<BarcodeScanSheet> createState() => _BarcodeScanSheetState();
}

class _BarcodeScanSheetState extends ConsumerState<BarcodeScanSheet> {
  late final MobileScannerController _controller;
  _ScanState _state = _ScanState.scanning;
  String? _scannedBarcode;
  ScannedProductInfo? _lookupResult;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController(
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_state != _ScanState.scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _controller.stop();
    final code = barcode!.rawValue!;
    setState(() {
      _state = _ScanState.lookingUp;
      _scannedBarcode = code;
      _lookupResult = null;
    });
    _performLookup(code);
  }

  Future<void> _performLookup(String barcode) async {
    final service = ref.read(barcodeProductLookupServiceProvider);
    final result = await service.lookup(barcode);
    if (!mounted) return;
    setState(() {
      _lookupResult = result;
      _state = (result != null && result.hasUsefulData)
          ? _ScanState.productFound
          : _ScanState.productNotFound;
    });
  }

  void _addProduct(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomProductSheet(prefillFromScan: _lookupResult),
    );
  }

  void _addManually(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCustomProductSheet(),
    );
  }

  void _scanAgain() {
    setState(() {
      _state = _ScanState.scanning;
      _lookupResult = null;
    });
    _controller.start();
  }

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
          color: Color(0xFF0E0C0B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primaryContainer, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.barcodeScan,
                      style: AppTypography.headlineMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (_state) {
                _ScanState.lookingUp => _LookingUpState(
                    barcode: _scannedBarcode ?? '',
                    l: l,
                  ),
                _ScanState.productFound => _ProductFoundState(
                    barcode: _scannedBarcode ?? '',
                    info: _lookupResult!,
                    l: l,
                    onAddProduct: () => _addProduct(context),
                    onAddManually: () => _addManually(context),
                    onScanAgain: _scanAgain,
                  ),
                _ScanState.productNotFound => _ProductNotFoundState(
                    barcode: _scannedBarcode ?? '',
                    l: l,
                    onAddManually: () => _addManually(context),
                    onScanAgain: _scanAgain,
                  ),
                _ScanState.permissionDenied => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_rounded,
                              size: 48, color: Colors.white38),
                          const SizedBox(height: 16),
                          Text(
                            l.barcodeScanPermissionDenied,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd.copyWith(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _ScanState.scanning => _ScannerView(
                    controller: _controller,
                    hint: l.barcodeScanHint,
                    onDetect: _onDetect,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scanner viewfinder ─────────────────────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController controller;
  final String hint;
  final void Function(BarcodeCapture) onDetect;

  const _ScannerView({
    required this.controller,
    required this.hint,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MobileScanner(
                controller: controller,
                onDetect: onDetect,
              ),
            ),
          ),
        ),
        // Aiming frame
        Center(
          child: Container(
            width: 240,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryContainer, width: 2.5),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40FF8B71),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // Corner accents
        Center(
          child: SizedBox(
            width: 240,
            height: 140,
            child: CustomPaint(painter: _CornerPainter()),
          ),
        ),
        // Hint text at bottom
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: AppTypography.labelMd.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
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
              color: AppColors.primaryContainer,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.barcodeScanLookingUp,
            style: AppTypography.bodyMd.copyWith(
              color: Colors.white70,
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

// ── Product-found state ───────────────────────────────────────────────────────

class _ProductFoundState extends StatelessWidget {
  final String barcode;
  final ScannedProductInfo info;
  final AppLocalizations l;
  final VoidCallback onAddProduct;
  final VoidCallback onAddManually;
  final VoidCallback onScanAgain;

  const _ProductFoundState({
    required this.barcode,
    required this.info,
    required this.l,
    required this.onAddProduct,
    required this.onAddManually,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primaryContainer, size: 20),
              const SizedBox(width: 8),
              Text(
                l.barcodeScanProductFound,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Product card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: info.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.white10,
                        child: const Icon(Icons.image_outlined,
                            color: Colors.white24, size: 28),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.white24, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.brand != null)
                        Text(
                          info.brand!,
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      if (info.name != null)
                        Text(
                          info.name!,
                          style: AppTypography.headlineMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      if (info.categoryHint != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.label_outline_rounded,
                                size: 13, color: Colors.white38),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${l.barcodeScanCategoryHint}: ${info.categoryHint}',
                                style: AppTypography.labelMd.copyWith(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (info.quantity != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          info.quantity!,
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (info.ingredients != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.barcodeScanIngredients,
                    style: AppTypography.labelMd.copyWith(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _truncate(info.ingredients!, 180),
                    style: AppTypography.bodyMd.copyWith(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _BarcodeChip(barcode: barcode),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                l.barcodeScanAddProduct,
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
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: onAddManually,
              child: Text(
                l.barcodeScanAddManually,
                style: AppTypography.labelMd.copyWith(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onScanAgain,
              child: Text(
                l.barcodeScanRetry,
                style: AppTypography.labelMd.copyWith(
                  color: Colors.white38,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Colors.white38,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.barcodeScanProductNotFound,
            style: AppTypography.headlineMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _BarcodeChip(barcode: barcode),
          const SizedBox(height: 32),
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
          const SizedBox(height: 12),
          TextButton(
            onPressed: onScanAgain,
            child: Text(
              l.barcodeScanRetry,
              style: AppTypography.labelMd.copyWith(
                color: Colors.white38,
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
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_rounded, color: Colors.white54, size: 15),
          const SizedBox(width: 8),
          Text(
            barcode,
            style: AppTypography.labelMd.copyWith(
              color: Colors.white70,
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
