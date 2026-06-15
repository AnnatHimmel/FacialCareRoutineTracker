import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/scanned_product_info.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/user_data_repository.dart';
import '../../shared/providers/root_providers.dart';

const _uuid = Uuid();

class AddCustomProductSheet extends ConsumerStatefulWidget {
  final UserCustomProduct? initialProduct;
  final ScannedProductInfo? prefillFromScan;

  const AddCustomProductSheet({
    super.key,
    this.initialProduct,
    this.prefillFromScan,
  });

  @override
  ConsumerState<AddCustomProductSheet> createState() =>
      _AddCustomProductSheetState();
}

class _AddCustomProductSheetState
    extends ConsumerState<AddCustomProductSheet> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();

  Uint8List? _photoBytes;
  bool _photoChanged = false;
  String? _categoryId;
  bool _inMorning = true;
  bool _inEvening = false;
  bool _isDaily = true;
  int _timesPerWeek = 3;
  bool _saving = false;
  String? _prefillImageUrl;

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    if (p != null) {
      _nameController.text = p.name;
      _categoryId = p.categoryId;
      // comment is loaded after locale is available — deferred to didChangeDependencies
      _inMorning = p.inMorning;
      _inEvening = p.inEvening;
      _isDaily = p.isDaily;
      _timesPerWeek = p.timesPerWeek ?? 3;
      if (p.photoKey != null) _loadInitialPhoto(p.photoKey!);
    } else if (widget.prefillFromScan != null) {
      final scan = widget.prefillFromScan!;
      final brandPrefix =
          (scan.brand?.isNotEmpty == true) ? '${scan.brand} ' : '';
      _nameController.text = '$brandPrefix${scan.name ?? ''}'.trim();
      if (scan.ingredients?.isNotEmpty == true) {
        _commentController.text = scan.ingredients!;
      }
      _prefillImageUrl = scan.imageUrl;
    }
  }

  Future<void> _loadInitialPhoto(String photoKey) async {
    final bytes = await ref.read(photoRepositoryProvider).readPhoto(photoKey);
    if (mounted && bytes != null) setState(() => _photoBytes = bytes);
  }

  bool _commentLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_commentLoaded) {
      _commentLoaded = true;
      final locale = AppLocalizations.of(context)!.localeName;
      final result = widget.initialProduct?.commentForLocale(locale);
      if (result != null) _commentController.text = result.$1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _categoryId != null;

  Future<void> _pickPhoto(AppLocalizations l) async {
    if (kIsWeb) {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() { _photoBytes = bytes; _photoChanged = true; });
    } else {
      final choice = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l.skinLogTakePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l.skinLogGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: choice,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() { _photoBytes = bytes; _photoChanged = true; });
    }
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final locale = AppLocalizations.of(context)!.localeName;
      final commentText = _commentController.text.trim();
      final existingComment =
          Map<String, String>.from(widget.initialProduct?.comment ?? {});
      if (commentText.isNotEmpty) {
        existingComment[locale] = commentText;
      } else {
        existingComment.remove(locale);
      }
      final id = _isEditing ? widget.initialProduct!.id : _uuid.v4();

      String? photoKey = _isEditing ? widget.initialProduct!.photoKey : null;
      if (_photoBytes != null && (_photoChanged || !_isEditing)) {
        photoKey = 'custom_product_$id';
        await ref.read(photoRepositoryProvider).savePhoto(photoKey, _photoBytes!);
      }

      final inMorning = _inMorning;
      final inEvening = _inEvening;

      final product = UserCustomProduct(
        id: id,
        name: name,
        photoKey: photoKey,
        categoryId: _categoryId!,
        inMorning: inMorning,
        inEvening: inEvening,
        isDaily: _isDaily,
        timesPerWeek: _isDaily ? null : _timesPerWeek,
        lastModified: DateTime.now(),
        comment: existingComment.isNotEmpty ? existingComment : null,
      );

      final repo = ref.read(userDataRepositoryProvider);
      await repo.upsertCustomProduct(product);

      if (_isEditing) {
        final morningSelections =
            ref.read(selectionsProvider(Slot.morning)).valueOrNull ?? [];
        final eveningSelections =
            ref.read(selectionsProvider(Slot.evening)).valueOrNull ?? [];
        await _updateSlot(repo, id, Slot.morning, inMorning, morningSelections);
        await _updateSlot(repo, id, Slot.evening, inEvening, eveningSelections);
      } else {
        if (inMorning) {
          await repo.upsertSelection(ProductSelection(
            id: _uuid.v4(),
            productId: id,
            slot: Slot.morning,
            isSelected: true,
            lastModified: DateTime.now(),
          ));
        }
        if (inEvening) {
          await repo.upsertSelection(ProductSelection(
            id: _uuid.v4(),
            productId: id,
            slot: Slot.evening,
            isSelected: true,
            lastModified: DateTime.now(),
          ));
        }
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateSlot(
    UserDataRepository repo,
    String productId,
    Slot slot,
    bool shouldBeSelected,
    List<ProductSelection> existing,
  ) async {
    final matches =
        existing.where((s) => s.productId == productId && s.slot == slot).toList();
    if (matches.isNotEmpty) {
      for (final match in matches) {
        await repo.upsertSelection(
          match.copyWith(isSelected: shouldBeSelected, lastModified: DateTime.now()),
        );
      }
    } else if (shouldBeSelected) {
      await repo.upsertSelection(ProductSelection(
        id: _uuid.v4(),
        productId: productId,
        slot: slot,
        isSelected: true,
        lastModified: DateTime.now(),
      ));
    }
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
      await ref
          .read(userDataRepositoryProvider)
          .deleteCustomProduct(widget.initialProduct!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final categories = masterAsync.valueOrNull?.categories ?? [];

    final isRtl = l.localeName == 'he';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? l.customProductEditTitle : l.customProductTitle,
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.onSurfaceVariant,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
                  children: [
                    GestureDetector(
                      onTap: () => _pickPhoto(l),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        child: _photoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(19),
                                child: Image.memory(
                                  _photoBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : _prefillImageUrl != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(19),
                                        child: CachedNetworkImage(
                                          imageUrl: _prefillImageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) =>
                                              const _PhotoPlaceholder(),
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
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            l.barcodeScanFromScanLabel,
                                            style:
                                                AppTypography.labelMd.copyWith(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const _PhotoPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      l.customProductCategoryLabel,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CategoryDropdown(
                      categories: categories,
                      selected: _categoryId,
                      locale: l.localeName,
                      onSelect: (id) => setState(() => _categoryId = id),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      l.customProductSlotLabel,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SlotTogglePill(
                            label: l.slotMorning,
                            selected: _inMorning,
                            onTap: () {
                              if (_inMorning && !_inEvening) return;
                              setState(() => _inMorning = !_inMorning);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SlotTogglePill(
                            label: l.slotEvening,
                            selected: _inEvening,
                            onTap: () {
                              if (_inEvening && !_inMorning) return;
                              setState(() => _inEvening = !_inEvening);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                        ('daily', l.onboardingFrequencyDaily),
                        ('weekly', l.customProductFrequencyWeekly),
                      ],
                      selected: _isDaily ? 'daily' : 'weekly',
                      onSelect: (v) => setState(() => _isDaily = v == 'daily'),
                    ),
                    if (!_isDaily) ...[
                      const SizedBox(height: 12),
                      _TimesPerWeekPicker(
                        label: l.customProductTimesPerWeekLabel,
                        value: _timesPerWeek,
                        onChanged: (v) => setState(() => _timesPerWeek = v),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Text(
                      l.customProductCommentLabel,
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
                    ),

                    const SizedBox(height: 32),

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
                            label: _isEditing ? l.customProductEditSave : l.customProductSave,
                            icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
                            enabled: _canSave,
                            saving: _saving,
                            onTap: _save,
                          ),
                        ),
                      ],
                    ),
                  ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.start,
        maxLines: maxLines,
        onChanged: onChanged,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(
            '—',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline.withAlpha(153),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurfaceVariant),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          items: [
            for (final cat in categories)
              DropdownMenuItem(
                value: cat.id,
                child: Text(cat.localizedName(locale)),
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_outlined,
          color: AppColors.onSurfaceVariant,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          l.customProductPhotoLabel,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
