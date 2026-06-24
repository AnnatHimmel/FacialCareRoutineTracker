import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/scanned_product_info.dart';
import '../../domain/entities/sub_category.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/slot.dart';
import '../../shared/widgets/product_thumb.dart' show userPhotoProvider;
import '../../domain/services/category_helpers.dart';
import '../../domain/services/default_schedule.dart';
import '../../domain/services/routine_build_summary.dart';
import '../../domain/services/routine_scheduler.dart';
import '../../domain/services/product_classifier.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/soft_icon_button.dart';
import 'routine_ready_summary_screen.dart';

const _uuid = Uuid();

/// Category id for chemical exfoliants (acids). Capped + evening-only by default.
const _exfoliateCategoryId = 'cat-exfoliate';

class AddCustomProductSheet extends ConsumerStatefulWidget {
  final UserCustomProduct? initialProduct;
  final ScannedProductInfo? prefillFromScan;
  final VoidCallback? onScanAgain;
  /// When set, the sheet opens in read-only view mode showing this product's
  /// fields. [isUserProduct] controls whether the edit pencil is enabled.
  final MasterProduct? viewProduct;
  final bool isUserProduct;

  /// When set and no other content (initialProduct / viewProduct / prefillFromScan)
  /// is provided, pre-fills the name field in the fresh manual-add flow.
  /// Mirrors the search query typed on the product-selection screen so the user
  /// does not have to re-type it. Has no effect on scan/edit/view flows.
  final String? initialName;

  /// Test-only: skip the smart-completion gate so the full manual form is shown
  /// immediately. Lets pre-gate tests exercise the form without first dismissing
  /// the gate. Has no effect on scan/edit/view flows (never gated anyway).
  @visibleForTesting
  final bool startRevealed;

  const AddCustomProductSheet({
    super.key,
    this.initialProduct,
    this.prefillFromScan,
    this.onScanAgain,
    this.viewProduct,
    this.isUserProduct = false,
    this.initialName,
    this.startRevealed = false,
  });

  @override
  ConsumerState<AddCustomProductSheet> createState() =>
      _AddCustomProductSheetState();
}

class _AddCustomProductSheetState
    extends ConsumerState<AddCustomProductSheet> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _commentController = TextEditingController();
  final _ingredientsController = TextEditingController();

  Uint8List? _photoBytes;
  bool _photoChanged = false;
  String? _categoryId;

  /// Sub-category resolved by the classifier from the product name. Persisted on
  /// the [UserCustomProduct]; null when nothing classified confidently.
  String? _subCategoryId;

  /// True once the user has manually picked a category from the dropdown — after
  /// that, auto-classification no longer overrides their choice.
  bool _categoryManuallyChosen = false;

  /// True once frequency has been auto-defaulted from classification (or the
  /// user has touched it) — prevents clobbering a user-chosen frequency.
  bool _frequencyTouched = false;

  bool _inMorning = true;
  bool _inEvening = true;
  bool _isDaily = true;
  int _maxTimesPerWeek = 3;
  bool _saving = false;
  // View-mode state (set when viewProduct != null)
  bool _readOnly = false;
  UserCustomProduct? _loadedCustomProduct;

  /// Candidate image URLs surfaced by the scan (may be several). When more than
  /// one is present and no local photo has been picked, the user chooses one
  /// from a selection grid.
  List<String> _candidateImageUrls = const [];

  /// The remote candidate image the user has chosen to keep (defaults to the
  /// first candidate). Its already-cached bytes are copied into local storage
  /// on save.
  String? _selectedImageUrl;

  /// Whether the collapsible "more details" section is expanded.
  bool _detailsOpen = false;

  /// When true, only the name + brand fields and the "smart completion" card are
  /// shown; the rest of the form is dimmed and locked until the user either runs
  /// the web lookup or chooses to fill it in manually. Set in [initState] for the
  /// fresh manual-add flow only (scans / edits / views are never gated).
  bool _gated = false;

  /// True while the by-name web lookup is running (drives the card's spinner).
  bool _lookingUp = false;

  /// True after a lookup that returned nothing — shows a gentle "not found" note
  /// once the form has been revealed for manual entry.
  bool _lookupNotFound = false;

  /// Category hint from a scan or web lookup, consulted by [_classifyName] as a
  /// fallback when the on-device classifier can't resolve a sub-category.
  String? _categoryHint;

  // True when editing (existing custom product or switched to edit from view mode).
  bool get _isEditing =>
      widget.initialProduct != null ||
      (widget.isUserProduct && !_readOnly && widget.viewProduct != null);

  @override
  void initState() {
    super.initState();
    // Pre-fill the name field from the search query when opening from the
    // product-selection screen. This only applies to fresh manual-add (no
    // initialProduct / viewProduct / prefillFromScan set).
    if (widget.initialProduct == null &&
        widget.viewProduct == null &&
        widget.prefillFromScan == null &&
        widget.initialName != null &&
        widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }

    // Gate the fresh manual-add flow only: scans, edits and views already carry
    // data, so they go straight to the full (ungated) form.
    _gated = !widget.startRevealed &&
        widget.initialProduct == null &&
        widget.viewProduct == null &&
        widget.prefillFromScan == null;
    final p = widget.initialProduct;
    if (p != null) {
      _nameController.text = p.name;
      _brandController.text = p.brand ?? '';
      _ingredientsController.text = p.ingredients ?? '';
      _categoryId = p.categoryId;
      _subCategoryId = p.subCategoryId;
      _categoryManuallyChosen = true; // editing: respect the saved category
      _frequencyTouched = true; // editing: respect the saved frequency
      // comment is loaded after locale is available — deferred to didChangeDependencies
      _inMorning = p.inMorning;
      _inEvening = p.inEvening;
      _isDaily = p.isDaily;
      _maxTimesPerWeek = p.maxTimesPerWeek ?? 3;
      if (p.photoKey != null) _loadInitialPhoto(p.photoKey!);
    } else if (widget.viewProduct != null) {
      _readOnly = true;
      final vp = widget.viewProduct!;
      _nameController.text = vp.name;
      _brandController.text = vp.brand ?? '';
      _categoryId = vp.categoryId;
      _subCategoryId = vp.subCategoryId;
      _inMorning = vp.morningConfig != null;
      _inEvening = vp.eveningConfig != null;
      final config = vp.morningConfig ?? vp.eveningConfig;
      if (config?.frequencyRule is WeeklyMaxRule) {
        _isDaily = false;
        _maxTimesPerWeek = (config!.frequencyRule as WeeklyMaxRule).maxPerWeek;
      }
      _ingredientsController.text = vp.ingredients.join(', ');
      _categoryManuallyChosen = true;
      _frequencyTouched = true;
      _detailsOpen = true; // show all fields immediately
      if (widget.isUserProduct) {
        // Load the full UserCustomProduct asynchronously for comment + save
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _loadCustomProduct());
      }
    } else if (widget.prefillFromScan != null) {
      final scan = widget.prefillFromScan!;
      // Name-only — brand goes in its own field
      _nameController.text = scan.name ?? '';
      _brandController.text = scan.brand ?? '';
      // Prefill ingredients from scan into the dedicated INCI field.
      if (scan.ingredients?.isNotEmpty == true) {
        _ingredientsController.text = scan.ingredients!;
      }
      // Scan "description" blurbs (e.g. UPCItemDB) are comments, not INCI.
      if (scan.comment?.isNotEmpty == true) {
        _commentController.text = scan.comment!;
        _commentLoaded = true; // don't let didChangeDependencies clobber it
      }
      _candidateImageUrls = scan.imageUrls;
      _selectedImageUrl = scan.imageUrls.isEmpty ? null : scan.imageUrls.first;
      _categoryHint = scan.categoryHint;
      if (kDebugMode) {
        debugPrint('[ScanPrefill] name="${scan.name}" → _nameController');
        debugPrint('[ScanPrefill] brand="${scan.brand}" → _brandController');
        debugPrint('[ScanPrefill] ingredients=${scan.ingredients}'
            ' → _ingredientsController');
        debugPrint('[ScanPrefill] comment=${scan.comment} → _commentController');
        debugPrint('[ScanPrefill] imageUrls(${scan.imageUrls.length})='
            '${scan.imageUrls} → _candidateImageUrls '
            '(selected=$_selectedImageUrl)');
        debugPrint('[ScanPrefill] categoryHint="${scan.categoryHint}" '
            '→ heuristic fallback only (see _classifyName)');
      }
      // Defer classification until the classifier + master content are ready.
      WidgetsBinding.instance.addPostFrameCallback((_) => _classifyName());
    }
  }

  /// Runs the on-device classifier against the current name and, unless the user
  /// has manually overridden it, auto-assigns category + sub-category. Exfoliants
  /// (cat-exfoliate) additionally default to weekly-max-3, evening-only.
  void _classifyName() {
    if (_isEditing) return;
    final name = _nameController.text.trim();
    final classifier = ref.read(productClassifierProvider).valueOrNull;
    final master = ref.read(masterContentProvider).valueOrNull;
    if (classifier == null || master == null) return;

    if (name.isEmpty) {
      if (!_categoryManuallyChosen) {
        setState(() => _subCategoryId = null);
      }
      return;
    }

    final ingredients = _ingredientsController.text.trim();
    final subId = classifier.classify(
      name: name,
      ingredients: ingredients.isEmpty ? const [] : [ingredients],
    );
    if (subId == ProductClassifier.unclassifiedId) {
      if (kDebugMode) {
        debugPrint('[Heuristic] classifier(name="$name") → unclassified');
      }
      if (!_categoryManuallyChosen) {
        setState(() => _subCategoryId = null);
        // categoryHint fallback: if a scan or web lookup provided one, use it.
        if (_categoryId == null && _categoryHint != null) {
          final hintId = categoryIdFromHint(_categoryHint, master);
          if (hintId != null && master.categories.any((c) => c.id == hintId)) {
            if (kDebugMode) {
              debugPrint('[Heuristic] categoryHint "$_categoryHint" '
                  '→ _categoryId=$hintId (categoryIdFromHint)');
            }
            setState(() => _categoryId = hintId);
          }
        }
      }
      return;
    }

    // Map the classified sub-category back to its phase (category).
    final sub = master.subcategories
        .where((s) => s.id == subId)
        .cast<SubCategory?>()
        .firstWhere((_) => true, orElse: () => null);
    final catId = sub?.categoryId;

    if (kDebugMode) {
      debugPrint('[Heuristic] classifier(name="$name") → subId=$subId '
          '→ _subCategoryId; derived _categoryId=$catId');
    }

    setState(() {
      // Once the user has taken manual control of the category (and therefore
      // the sub-category), auto-classification must not override their choice.
      if (!_categoryManuallyChosen) {
        _subCategoryId = subId;
        if (catId != null) _categoryId = catId;
        // Exfoliants default to weekly max 3, evening-only — unless the user has
        // already chosen a frequency/slots.
        if (!_frequencyTouched && catId == _exfoliateCategoryId) {
          _isDaily = false;
          _maxTimesPerWeek = 3;
          _inMorning = false;
          _inEvening = true;
        } else if (!_frequencyTouched) {
          if (catId == 'cat-spf') {
            _inMorning = true;
            _inEvening = false;
          } else if (catId == 'cat-retinoid') {
            _inMorning = false;
            _inEvening = true;
          } else if (catId == 'cat-cleanser') {
            _inMorning = false;
            _inEvening = true;
          }
        }
      }
    });
    if (kDebugMode && !_categoryManuallyChosen && !_frequencyTouched) {
      debugPrint('[Heuristic] frequency defaults (cat=$catId) → '
          'isDaily=$_isDaily, maxTimesPerWeek=$_maxTimesPerWeek, '
          'inMorning=$_inMorning, inEvening=$_inEvening');
    }
  }

  /// Runs the by-name web lookup behind the "find the details for me" button.
  /// On any result it prefills the empty fields, then reveals (un-gates) the
  /// rest of the form. If nothing is found the form is still revealed for manual
  /// entry, with a gentle "not found" note.
  Future<void> _runSmartComplete() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _lookingUp) return;
    setState(() {
      _lookingUp = true;
      _lookupNotFound = false;
    });

    ScannedProductInfo? result;
    try {
      final brand = _brandController.text.trim();
      result = await ref.read(barcodeProductLookupServiceProvider).lookupByName(
            name,
            brand: brand.isEmpty ? null : brand,
          );
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    if (result != null) _applyLookupResult(result);
    setState(() {
      _lookingUp = false;
      _gated = false;
      _lookupNotFound = result == null;
    });
    // Re-run classification now that ingredients / category hint may be filled.
    _classifyName();
  }

  /// Reveals the rest of the form for manual entry without running a lookup.
  /// Classifies once from whatever name was already typed so the category can
  /// still pre-fill (per-keystroke classification is skipped while gated).
  void _fillManually() {
    setState(() {
      _gated = false;
      _lookupNotFound = false;
    });
    _classifyName();
  }

  /// Applies a by-name lookup result without clobbering anything the user has
  /// already typed — name stays as entered; brand, photo, ingredients and
  /// comment only fill when currently empty.
  void _applyLookupResult(ScannedProductInfo r) {
    if (_brandController.text.trim().isEmpty && r.brand != null) {
      _brandController.text = r.brand!;
    }
    if (_photoBytes == null && r.imageUrls.isNotEmpty) {
      _candidateImageUrls = r.imageUrls;
      _selectedImageUrl = r.imageUrls.first;
    }
    if (_ingredientsController.text.trim().isEmpty &&
        (r.ingredients?.isNotEmpty ?? false)) {
      _ingredientsController.text = r.ingredients!;
      _detailsOpen = true;
    }
    if (_commentController.text.trim().isEmpty &&
        (r.comment?.isNotEmpty ?? false)) {
      _commentController.text = r.comment!;
      _detailsOpen = true;
    }
    _categoryHint = r.categoryHint;
  }

  Future<void> _loadInitialPhoto(String photoKey) async {
    final bytes = await ref.read(photoRepositoryProvider).readPhoto(photoKey);
    if (mounted && bytes != null) setState(() => _photoBytes = bytes);
  }

  /// Loads the full [UserCustomProduct] for the custom-product view-mode so the
  /// full comment map is available on save (preserving all locales).
  Future<void> _loadCustomProduct() async {
    if (!mounted) return;
    final customs = ref.read(customProductsProvider).valueOrNull ?? [];
    final custom = customs.cast<UserCustomProduct?>().firstWhere(
      (c) => c?.id == widget.viewProduct!.id,
      orElse: () => null,
    );
    if (custom == null || !mounted) return;
    setState(() => _loadedCustomProduct = custom);
  }

  /// Switches from view mode to edit mode for a custom product.
  void _enableEdit() {
    if (!widget.isUserProduct) return;
    if (_loadedCustomProduct != null) {
      final locale = AppLocalizations.of(context)!.localeName;
      final result = _loadedCustomProduct!.commentForLocale(locale);
      if (result != null) _commentController.text = result.$1;
    }
    setState(() => _readOnly = false);
  }

  bool _commentLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_commentLoaded) {
      _commentLoaded = true;
      final locale = AppLocalizations.of(context)!.localeName;
      if (widget.viewProduct != null) {
        final comment = widget.viewProduct!.localizedComment(locale);
        if (comment.isNotEmpty) _commentController.text = comment;
      } else {
        final result = widget.initialProduct?.commentForLocale(locale);
        if (result != null) _commentController.text = result.$1;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _commentController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _categoryId != null;

  Future<void> _pickFromSource(AppLocalizations l, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoChanged = true;
    });
  }

  Future<void> _pickFromGallery(AppLocalizations l) async =>
      _pickFromSource(l, ImageSource.gallery);

  Future<void> _pickFromCamera(AppLocalizations l) async =>
      _pickFromSource(l, ImageSource.camera);

  /// Resolves the bytes of a scan-chosen image for local persistence. The image
  /// was already downloaded to display the grid/preview, so this reuses the
  /// shared [DefaultCacheManager] cache (the one [CachedNetworkImage] fills)
  /// instead of fetching again; it only hits the network as a fallback if the
  /// cache entry was evicted. Returns null on any failure — saving continues
  /// without a photo rather than blocking.
  Future<Uint8List?> _imageBytesForPersistence(String url) async {
    try {
      final cached = await DefaultCacheManager().getFileFromCache(url);
      if (cached != null) {
        final bytes = await cached.file.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (_) {
      // Cache miss/unavailable (e.g. web) — fall through to a direct fetch.
    }
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {
      // Swallow — offline / bad URL: persist the product without a photo.
    }
    return null;
  }

  /// Static image display for view mode (master product or user photo).
  Widget _buildViewModeImage(String? imageAsset) {
    Widget imageWidget;
    if (imageAsset == null || imageAsset.isEmpty) {
      imageWidget = const Center(
        child: Icon(Icons.spa_rounded, size: 60, color: Color(0xffe58b73)),
      );
    } else if (imageAsset.startsWith('user_photo:')) {
      final key = imageAsset.substring('user_photo:'.length);
      final photoAsync = ref.watch(userPhotoProvider(key));
      imageWidget = photoAsync.when(
        data: (bytes) => bytes != null
            ? Image.memory(bytes, fit: BoxFit.contain, width: double.infinity)
            : const Center(
                child: Icon(Icons.spa_rounded, size: 60, color: Color(0xffe58b73))),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
            child: Icon(Icons.spa_rounded, size: 60, color: Color(0xffe58b73))),
      );
    } else if (imageAsset.startsWith('https://') ||
        imageAsset.startsWith('http://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageAsset,
        fit: BoxFit.contain,
        width: double.infinity,
        errorWidget: (_, _, _) => const Center(
            child: Icon(Icons.spa_rounded, size: 60, color: Color(0xffe58b73))),
      );
    } else {
      imageWidget = Image.asset(
        imageAsset,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.spa_rounded, size: 60, color: Color(0xffe58b73))),
      );
    }
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xfff3d8c2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: imageWidget,
      ),
    );
  }

  /// Builds the photo area:
  ///  - view mode: static image from viewProduct.imageAsset
  ///  - a selection grid when the scan returned several candidate images,
  ///  - a single preview (replace / remove) when there is one image, or
  ///  - the empty gallery pill + camera picker.
  Widget _buildPhotoSection(AppLocalizations l) {
    if (_readOnly && widget.viewProduct != null) {
      return _buildViewModeImage(widget.viewProduct!.imageAsset);
    }
    final showGrid =
        !_isEditing && _photoBytes == null && _candidateImageUrls.length > 1;

    if (showGrid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_outlined,
                  size: 18, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.customProductScanImagesHeading(_candidateImageUrls.length),
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _candidateImageUrls.length; i++)
                _ScanImageTile(
                  key: ValueKey('scan-image-tile-$i'),
                  url: _candidateImageUrls[i],
                  selected: _candidateImageUrls[i] == _selectedImageUrl,
                  onTap: () => setState(
                      () => _selectedImageUrl = _candidateImageUrls[i]),
                ),
              _ScanOwnPhotoTile(
                label: l.customProductScanOwnPhoto,
                onTap: () => _pickFromGallery(l),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.customProductScanImagesHint,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // Single preview when a photo exists (local bytes or a chosen scan image).
    if (_photoBytes != null || _selectedImageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant, width: 1.5),
            ),
            child: _photoBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.memory(
                      _photoBytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: CachedNetworkImage(
                          imageUrl: _selectedImageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l.barcodeScanFromScanLabel,
                            style: AppTypography.labelMd.copyWith(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _pickFromGallery(l),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(l.customProductReplacePhoto),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _photoBytes = null;
                    _selectedImageUrl = null;
                    _candidateImageUrls = const [];
                    _photoChanged = true;
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(l.customProductRemovePhoto),
              ),
            ],
          ),
        ],
      );
    }

    // No photo yet — gallery pill + camera button (camera hidden on web).
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickFromGallery(l),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.outlineVariant, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.customProductPhotoLabel,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _pickFromCamera(l),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final brandText = _brandController.text.trim();
      final locale = AppLocalizations.of(context)!.localeName;
      final commentText = _commentController.text.trim();
      final baseComment = widget.initialProduct?.comment ??
          _loadedCustomProduct?.comment;
      final existingComment = Map<String, String>.from(baseComment ?? {});
      if (commentText.isNotEmpty) {
        existingComment[locale] = commentText;
      } else {
        existingComment.remove(locale);
      }
      // ID: use initialProduct > viewProduct (custom) > new uuid
      final id = widget.initialProduct?.id ??
          (widget.isUserProduct ? widget.viewProduct?.id : null) ??
          _uuid.v4();

      String? photoKey = _isEditing ? widget.initialProduct!.photoKey : null;
      String photoSource = 'unchanged';
      if (_photoBytes != null && (_photoChanged || !_isEditing)) {
        photoKey = 'custom_product_$id';
        await ref.read(photoRepositoryProvider).savePhoto(photoKey, _photoBytes!);
        photoSource = 'local bytes';
      } else if (_selectedImageUrl != null && !_isEditing) {
        // A scanned remote image was kept — reuse the bytes already cached for
        // display so it persists locally (offline-first), no re-download.
        final bytes = await _imageBytesForPersistence(_selectedImageUrl!);
        if (bytes != null) {
          photoKey = 'custom_product_$id';
          await ref.read(photoRepositoryProvider).savePhoto(photoKey, bytes);
          photoSource = 'cached scan image';
        } else {
          photoSource = 'scan image unavailable';
        }
      } else if (_photoChanged && _photoBytes == null) {
        // User removed the photo
        photoKey = null;
        photoSource = 'removed';
      }

      final inMorning = _inMorning;
      final inEvening = _inEvening;

      final ingredientsText = _ingredientsController.text.trim();
      final product = UserCustomProduct(
        id: id,
        name: name,
        brand: brandText.isEmpty ? null : brandText,
        photoKey: photoKey,
        categoryId: _categoryId!,
        subCategoryId: _subCategoryId,
        inMorning: inMorning,
        inEvening: inEvening,
        isDaily: _isDaily,
        maxTimesPerWeek: _isDaily ? null : _maxTimesPerWeek,
        lastModified: DateTime.now(),
        comment: existingComment.isNotEmpty ? existingComment : null,
        ingredients: ingredientsText.isEmpty ? null : ingredientsText,
      );

      if (kDebugMode) {
        debugPrint('[SaveProduct] id=${product.id} | name="${product.name}" | '
            'brand=${product.brand} | categoryId=${product.categoryId} | '
            'subCategoryId=${product.subCategoryId} | '
            'inMorning=${product.inMorning} | inEvening=${product.inEvening} | '
            'isDaily=${product.isDaily} | '
            'maxTimesPerWeek=${product.maxTimesPerWeek} | '
            'photoKey=${product.photoKey} (source: $photoSource) | '
            'ingredients=${product.ingredients} | comment=${product.comment}');
      }

      final userRepo = ref.read(userDataRepositoryProvider);
      await userRepo.upsertCustomProduct(product);

      final scheduler = ref.read(routineSchedulerProvider);

      if (_isEditing) {
        final morningSelections =
            ref.read(selectionsProvider(Slot.morning)).valueOrNull ?? [];
        final eveningSelections =
            ref.read(selectionsProvider(Slot.evening)).valueOrNull ?? [];
        await _updateSlot(scheduler, id, Slot.morning, inMorning, morningSelections);
        await _updateSlot(scheduler, id, Slot.evening, inEvening, eveningSelections);
      } else {
        if (inMorning) {
          await scheduler.upsertSelection(ProductSelection(
            id: _uuid.v4(),
            productId: id,
            slot: Slot.morning,
            isSelected: true,
            lastModified: DateTime.now(),
          ));
        }
        if (inEvening) {
          await scheduler.upsertSelection(ProductSelection(
            id: _uuid.v4(),
            productId: id,
            slot: Slot.evening,
            isSelected: true,
            lastModified: DateTime.now(),
          ));
        }
      }

      // A capped (weekly-max) product must never end up selected with a slot but
      // no scheduled days. Seed a spread default for each selected slot so the
      // product actually appears in the routine on sensible, well-spaced days.
      if (!_isDaily) {
        await _seedSpreadSchedule(scheduler, id, inMorning, inEvening);
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateSlot(
    RoutineScheduler scheduler,
    String productId,
    Slot slot,
    bool shouldBeSelected,
    List<ProductSelection> existing,
  ) async {
    final matches =
        existing.where((s) => s.productId == productId && s.slot == slot).toList();
    if (matches.isNotEmpty) {
      for (final match in matches) {
        await scheduler.upsertSelection(
          match.copyWith(isSelected: shouldBeSelected, lastModified: DateTime.now()),
        );
      }
    } else if (shouldBeSelected) {
      await scheduler.upsertSelection(ProductSelection(
        id: _uuid.v4(),
        productId: productId,
        slot: slot,
        isSelected: true,
        lastModified: DateTime.now(),
      ));
    }
  }

  /// Seeds an evenly-spread [WeekdaySchedule] for a capped product on each
  /// selected slot, so it never ends up selected with a slot but no days
  /// (PRD §15.5). Skips a slot that already has a schedule (e.g. when editing).
  Future<void> _seedSpreadSchedule(
    RoutineScheduler scheduler,
    String productId,
    bool inMorning,
    bool inEvening,
  ) async {
    final days = spreadWeekdays(_maxTimesPerWeek);
    if (days.isEmpty) return;

    final existing =
        ref.read(allSchedulesProvider).valueOrNull ?? const [];

    Future<void> seed(Slot slot) async {
      final already = existing
          .any((s) => s.productId == productId && s.slot == slot);
      if (already) return;
      await scheduler.upsertSchedule(WeekdaySchedule(
        id: _uuid.v4(),
        productId: productId,
        slot: slot,
        weekdays: days.toSet(),
        lastModified: DateTime.now(),
      ));
    }

    if (inMorning) await seed(Slot.morning);
    if (inEvening) await seed(Slot.evening);
  }

  Future<void> _deleteProduct(AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customProductDeleteConfirmTitle),
        content: Text(l.customProductDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.customProductDeleteConfirmAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final deleteId =
          widget.initialProduct?.id ?? widget.viewProduct?.id;
      if (deleteId == null) return;

      // Determine which slots to deselect. Prefer initialProduct (edit flow)
      // over viewProduct (view flow); fall back to the loaded custom product.
      final customProd = widget.initialProduct ??
          (ref.read(customProductsProvider).valueOrNull ?? [])
              .cast<UserCustomProduct?>()
              .firstWhere((p) => p?.id == deleteId, orElse: () => null);
      final scheduler = ref.read(routineSchedulerProvider);
      if (customProd != null) {
        if (customProd.inMorning) {
          await scheduler.removeProduct(
              productId: deleteId, slot: Slot.morning);
        }
        if (customProd.inEvening) {
          await scheduler.removeProduct(
              productId: deleteId, slot: Slot.evening);
        }
      }

      await ref
          .read(userDataRepositoryProvider)
          .deleteCustomProduct(deleteId);

      // Re-run the auto-sorter and present its "routine ready" summary after the
      // shelf change. Build it before closing the sheet; navigate via captured
      // references so we don't touch a defunct context post-pop.
      final master = ref.read(masterContentProvider).valueOrNull;
      RoutineBuildSummary? summary;
      if (master != null) {
        try {
          summary = await scheduler.buildRoutineSummary(master: master);
        } catch (_) {
          summary = null;
        }
      }
      if (!mounted) return;
      final rootNav = Navigator.of(context, rootNavigator: true);
      final router = GoRouter.of(context);
      Navigator.of(context).pop(); // close the sheet
      if (summary != null) {
        void navigateAway() {
          rootNav.pop();
          router.go('/week-glance');
        }
        rootNav.push(MaterialPageRoute<void>(
          builder: (_) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) navigateAway();
            },
            child: RoutineReadySummaryScreen(
              summary: summary!,
              onContinue: navigateAway,
            ),
          ),
        ));
      }
    }
  }

  Future<void> _removeFromShelf(AppLocalizations l) async {
    final product = widget.viewProduct;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customProductDeleteConfirmTitle),
        content: Text(l.productRemoveFromShelfConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.customProductDeleteConfirmAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final scheduler = ref.read(routineSchedulerProvider);
      await scheduler.removeProduct(productId: product.id, slot: Slot.morning);
      await scheduler.removeProduct(productId: product.id, slot: Slot.evening);

      final master = ref.read(masterContentProvider).valueOrNull;
      RoutineBuildSummary? summary;
      if (master != null) {
        try {
          summary = await scheduler.buildRoutineSummary(master: master);
        } catch (_) {
          summary = null;
        }
      }
      if (!mounted) return;
      final rootNav = Navigator.of(context, rootNavigator: true);
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      if (summary != null) {
        rootNav.push(MaterialPageRoute<void>(
          builder: (_) => RoutineReadySummaryScreen(
            summary: summary!,
            onContinue: () {
              rootNav.pop();
              router.go('/week-glance');
            },
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final master = masterAsync.valueOrNull;
    final categories = master?.categories ?? [];
    final subsForCategory = (master != null && _categoryId != null)
        ? subCategoriesForCategory(master, _categoryId!)
        : const <SubCategory>[];
    final isScan = widget.prefillFromScan != null;

    // Once the classifier / master content finish loading, (re)classify the
    // name the user may have already typed, so auto-assignment doesn't depend
    // on which resolved first.
    ref.listen(productClassifierProvider, (_, next) {
      if (next.hasValue) _classifyName();
    });
    ref.listen(masterContentProvider, (_, next) {
      if (next.hasValue) _classifyName();
    });

    final isRtl = l.localeName == 'he';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          // Flex (not Column) so the brand-field test's Column ancestor finder
          // is unambiguous — find.ancestor(matching: find.byType(Column)) must
          // resolve to the brand-field's own Column, not this outer layout widget.
          child: Flex(
            direction: Axis.vertical,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _readOnly
                                ? (_nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : l.customProductTitle)
                                : _isEditing
                                    ? l.customProductEditTitle
                                    : isScan
                                        ? l.customProductScanTitle
                                        : l.customProductTitle,
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!_isEditing && !_readOnly) ...[
                            const SizedBox(height: 4),
                            Text(
                              isScan
                                  ? l.customProductScanSubtitle
                                  : l.customProductFormSubtitle,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.prefillFromScan != null && widget.onScanAgain != null)
                      TextButton(
                        onPressed: widget.onScanAgain,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          l.customProductScanAgain,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    // Edit pencil and remove — shown in view mode
                    if (widget.viewProduct != null && _readOnly) ...[
                      SoftIconButton(
                        icon: Icons.edit_rounded,
                        iconColor: widget.isUserProduct
                            ? AppColors.primary
                            : AppColors.outline.withAlpha(120),
                        tooltip: widget.isUserProduct
                            ? l.customProductEditButton
                            : null,
                        onTap:
                            widget.isUserProduct ? _enableEdit : null,
                      ),
                      const SizedBox(width: 8),
                      SoftIconButton(
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppColors.error,
                        tooltip: l.customProductDeleteButton,
                        onTap: () => widget.isUserProduct
                            ? _deleteProduct(l)
                            : _removeFromShelf(l),
                      ),
                      const SizedBox(width: 8),
                    ],
                    SoftIconButton(
                      icon: Icons.close_rounded,
                      iconColor: AppColors.onSurfaceVariant,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
                  // Flex (not Column) — same reason as the outer layout: keeps the
                // brand-field test's Column ancestor finder unambiguous.
                child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Autofill banner (scan variant only)
                    if (isScan && !_isEditing) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withAlpha(40),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryFixed.withAlpha(80),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.customProductAutofillBanner,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.customProductAutofillBannerSub,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Name field
                    Text(
                      l.customProductNameLabel,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: l.customProductNameHint,
                      enabled: !_readOnly,
                      // While gated, only rebuild so the "find details" button
                      // enables/disables — classification is deferred to the
                      // button (or "fill manually"). Once revealed (or in the
                      // ungated flows) classify as the name changes.
                      onChanged: _readOnly
                          ? null
                          : (_) {
                              setState(() {});
                              if (!_gated) _classifyName();
                            },
                    ),
                    const SizedBox(height: 12),

                    // Brand field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.customProductBrandLabel,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _brandController,
                          hint: l.customProductBrandHint,
                          enabled: !_readOnly,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Smart-completion gate — shown only for the fresh manual-add
                    // flow. Tapping "find the details" runs the by-name web
                    // lookup; "fill manually" just reveals the locked fields.
                    if (_gated) ...[
                      _SmartCompleteCard(
                        l: l,
                        busy: _lookingUp,
                        canSearch: _nameController.text.trim().isNotEmpty,
                        onFind: _runSmartComplete,
                        onManual: _fillManually,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Everything below name/brand stays dimmed and locked until
                    // the smart-completion gate is resolved (looked up or skipped).
                    IgnorePointer(
                      key: const ValueKey('manual-form-lock'),
                      ignoring: _gated,
                      child: Opacity(
                        opacity: _gated ? 0.4 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_lookupNotFound) ...[
                              _LookupNotFoundNote(l: l),
                              const SizedBox(height: 16),
                            ],

                    // Photo section: multi-image selection grid when the scan
                    // returned several candidates, otherwise a single preview
                    // (or the empty pill + camera picker).
                    _buildPhotoSection(l),

                    const SizedBox(height: 12),

                    // Category + sub-category: side-by-side row.
                    // Sub-category is always visible:
                    //   - disabled showing "בחרו קטגוריה תחילה" when no category.
                    //   - disabled showing "ללא" when category has no subs.
                    //   - enabled with "בחרו תת־קטגוריה..." when subs exist.
                    AbsorbPointer(
                      absorbing: _readOnly,
                      child: Opacity(
                        opacity: _readOnly ? 0.7 : 1.0,
                        child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category (leading/right in RTL — first child)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    l.customProductCategoryLabel,
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _CategoryDropdown(
                                categories: categories,
                                selected: _categoryId,
                                locale: l.localeName,
                                onSelect: (id) => setState(() {
                                  _categoryId = id;
                                  _categoryManuallyChosen = true;
                                  _subCategoryId = null;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sub-category (trailing/left in RTL — second child)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.customProductSubCategoryLabel,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SubCategoryDropdown(
                                subcategories: subsForCategory,
                                selected: subsForCategory.any(
                                        (s) => s.id == _subCategoryId)
                                    ? _subCategoryId
                                    : null,
                                locale: l.localeName,
                                noCategoryChosen: _categoryId == null,
                                onSelect: (id) => setState(() {
                                  _subCategoryId = id;
                                  _categoryManuallyChosen = true;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),  // Row (category + sub-cat)
                      ),  // Opacity
                    ),  // AbsorbPointer
                    const SizedBox(height: 12),

                    // Slot toggles
                    AbsorbPointer(
                      absorbing: _readOnly,
                      child: Opacity(
                        opacity: _readOnly ? 0.7 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l.customProductSlotLabel,
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  ' *',
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _SlotTogglePill(
                                    label: l.slotMorningRoutine,
                                    selected: _inMorning,
                                    onTap: () {
                                      if (_inMorning && !_inEvening) return;
                                      setState(() {
                                        _inMorning = !_inMorning;
                                        _frequencyTouched = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _SlotTogglePill(
                                    label: l.slotEveningRoutine,
                                    selected: _inEvening,
                                    onTap: () {
                                      if (_inEvening && !_inMorning) return;
                                      setState(() {
                                        _inEvening = !_inEvening;
                                        _frequencyTouched = true;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Frequency
                    AbsorbPointer(
                      absorbing: _readOnly,
                      child: Opacity(
                        opacity: _readOnly ? 0.7 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                    Text(
                      l.customProductFrequencyLabel,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PillRow(
                      options: [
                        ('daily', l.customProductFrequencyDaily),
                        ('weekly', l.customProductFrequencyWeekly),
                      ],
                      selected: _isDaily ? 'daily' : 'weekly',
                      onSelect: (v) => setState(() {
                        _isDaily = v == 'daily';
                        _frequencyTouched = true;
                      }),
                    ),
                    if (!_isDaily) ...[
                      const SizedBox(height: 12),
                      _TimesPerWeekPicker(
                        label: l.customProductTimesPerWeekLabel,
                        value: _maxTimesPerWeek,
                        onChanged: (v) => setState(() {
                          _maxTimesPerWeek = v;
                          _frequencyTouched = true;
                        }),
                      ),
                    ],
                          ],
                        ),  // Column (frequency)
                      ),  // Opacity
                    ),  // AbsorbPointer
                    const SizedBox(height: 12),

                    // Collapsible "more details" section (comment) — placed at
                    // the bottom, just before the add button.
                    GestureDetector(
                      onTap: () => setState(() => _detailsOpen = !_detailsOpen),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.customProductMoreDetails,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _detailsOpen ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.expand_more_rounded,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_detailsOpen) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.customProductNotesLabel,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _commentController,
                        hint: l.customProductCommentHint,
                        maxLines: 3,
                        enabled: !_readOnly,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.customProductIngredientsLabel,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _ingredientsController,
                        hint: l.customProductIngredientsHint,
                        maxLines: 3,
                        enabled: !_readOnly,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.customProductIngredientsHelper,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    if (!_readOnly)
                      Row(
                        children: [
                          if (_isEditing) ...[
                            GestureDetector(
                              onTap: () => _deleteProduct(l),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withAlpha(20),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: AppColors.error.withAlpha(80),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: _SaveButton(
                              label: _isEditing
                                  ? l.customProductEditSave
                                  : l.customProductSave,
                              icon: _isEditing
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              enabled: _canSave,
                              saving: _saving,
                              onTap: _save,
                            ),
                          ),
                        ],
                      ),
                          ], // locked-section Column children
                        ), // Column
                      ), // Opacity
                    ), // IgnorePointer
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant
              .withAlpha(enabled ? 255 : 140),
        ),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.start,
        maxLines: maxLines,
        enabled: enabled,
        onChanged: onChanged,
        style: AppTypography.bodyMd.copyWith(
          color: enabled
              ? AppColors.onSurface
              : AppColors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMd.copyWith(
            color: AppColors.outline.withAlpha(153),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// The "smart completion from the web" card shown in the gated manual-add flow.
/// Offers a one-tap by-name lookup and a "fill manually" escape hatch, plus a
/// note that the rest of the form unlocks once the gate is resolved.
class _SmartCompleteCard extends StatelessWidget {
  final AppLocalizations l;
  final bool busy;
  final bool canSearch;
  final VoidCallback onFind;
  final VoidCallback onManual;

  const _SmartCompleteCard({
    required this.l,
    required this.busy,
    required this.canSearch,
    required this.onFind,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withAlpha(45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryFixed.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.customProductSmartCompleteTitle,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.customProductSmartCompleteBody,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _SmartCompletePrimaryButton(
            label: busy
                ? l.customProductSmartCompleteSearching
                : l.customProductSmartCompleteButton,
            busy: busy,
            enabled: canSearch && !busy,
            onTap: onFind,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: busy ? null : onManual,
              child: Text(
                l.customProductSmartCompleteManual,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  l.customProductSmartCompleteLockNote,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// White pill button (peach content + outline) used as the primary action of
/// [_SmartCompleteCard]. Shows a spinner in place of the icon while busy.
class _SmartCompletePrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  const _SmartCompletePrimaryButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: (enabled || busy) ? 1.0 : 0.5,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9999),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: AppColors.primary.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.travel_explore_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gentle "we couldn't find more details" note shown after a lookup that
/// returned nothing, once the form has been revealed for manual entry.
class _LookupNotFoundNote extends StatelessWidget {
  final AppLocalizations l;

  const _LookupNotFoundNote({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.customProductSmartCompleteNotFound,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable thumbnail for one scan-candidate image. The selected tile gets
/// a primary border and a check badge in the corner.
class _ScanImageTile extends StatelessWidget {
  final String url;
  final bool selected;
  final VoidCallback onTap;

  const _ScanImageTile({
    super.key,
    required this.url,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outlineVariant,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (selected)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

/// The "upload my own photo" tile shown alongside scan-candidate thumbnails.
class _ScanOwnPhotoTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ScanOwnPhotoTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final String locale;
  final ValueChanged<String> onSelect;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.locale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(
            l.customProductCategoryHint,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outline.withAlpha(153),
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurfaceVariant, size: 18),
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          items: [
            for (final cat in categories)
              DropdownMenuItem(
                value: cat.id,
                child: Text(
                  cat.localizedName(locale),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
        ),
      ),
    );
  }
}

class _SubCategoryDropdown extends StatelessWidget {
  final List<SubCategory> subcategories;
  final String? selected;
  final String locale;
  /// True when no category has been chosen yet — shows disabled "בחרו קטגוריה תחילה".
  final bool noCategoryChosen;
  final ValueChanged<String> onSelect;

  const _SubCategoryDropdown({
    required this.subcategories,
    required this.selected,
    required this.locale,
    required this.noCategoryChosen,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDisabled = noCategoryChosen || subcategories.isEmpty;

    String hintText;
    if (noCategoryChosen) {
      hintText = l.customProductSubCategoryDisabledHint;
    } else if (subcategories.isEmpty) {
      hintText = l.customProductSubCategoryNone;
    } else {
      hintText = l.customProductSubCategoryHint;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDisabled
            ? AppColors.surfaceLow
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(
            hintText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outline.withAlpha(153),
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurfaceVariant, size: 18),
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          items: isDisabled
              ? null // null items → disabled dropdown
              : [
                  for (final sub in subcategories)
                    DropdownMenuItem(
                      value: sub.id,
                      child: Text(
                        sub.localizedName(locale),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
          onChanged: isDisabled
              ? null
              : (v) {
                  if (v != null) onSelect(v);
                },
        ),
      ),
    );
  }
}

class _SlotTogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotTogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: selected ? AppColors.glowSm : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _PillRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(options[i].$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: selected == options[i].$1
                      ? AppColors.primary
                      : AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: selected == options[i].$1 ? AppColors.glowSm : null,
                ),
                child: Center(
                  child: Text(
                    options[i].$2,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMd.copyWith(
                      color: selected == options[i].$1
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimesPerWeekPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _TimesPerWeekPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 1; i <= 6; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value == i ? AppColors.primary : AppColors.surfaceLow,
                    shape: BoxShape.circle,
                    boxShadow: value == i ? AppColors.glowSm : null,
                  ),
                  child: Center(
                    child: Text(
                      '$i',
                      style: AppTypography.labelMd.copyWith(
                        color: value == i
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool saving;
  final VoidCallback onTap;

  const _SaveButton({
    required this.label,
    this.icon = Icons.add_rounded,
    required this.enabled,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGlowGradient : null,
          color: enabled ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: enabled ? AppColors.glowSm : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled && !saving ? onTap : null,
            borderRadius: BorderRadius.circular(9999),
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: AppColors.onPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

