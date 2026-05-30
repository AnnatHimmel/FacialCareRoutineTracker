import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';

const _uuid = Uuid();

class AddCustomProductSheet extends ConsumerStatefulWidget {
  const AddCustomProductSheet({super.key});

  @override
  ConsumerState<AddCustomProductSheet> createState() =>
      _AddCustomProductSheetState();
}

class _AddCustomProductSheetState
    extends ConsumerState<AddCustomProductSheet> {
  final _nameController = TextEditingController();

  Uint8List? _photoBytes;
  String? _categoryId;

  // slot: 'morning', 'evening', 'both'
  String _slot = 'morning';

  // frequency
  bool _isDaily = true;
  int _timesPerWeek = 3;

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _categoryId != null;

  Future<void> _pickPhoto() async {
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
      setState(() => _photoBytes = bytes);
    } else {
      final choice = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('צלם תמונה'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('בחר מהגלריה'),
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
      setState(() => _photoBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final id = _uuid.v4();

      String? photoKey;
      if (_photoBytes != null) {
        photoKey = 'custom_product_$id';
        await ref.read(photoRepositoryProvider).savePhoto(photoKey, _photoBytes!);
      }

      final inMorning = _slot == 'morning' || _slot == 'both';
      final inEvening = _slot == 'evening' || _slot == 'both';

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
      );

      final repo = ref.read(userDataRepositoryProvider);
      await repo.upsertCustomProduct(product);

      // Auto-select in the chosen slot(s)
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

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final categories = masterAsync.valueOrNull?.categories ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
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
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'הוספת מוצר משלי',
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

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // ── Photo picker ────────────────────────────────────────
                    GestureDetector(
                      onTap: _pickPhoto,
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
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppColors.onSurfaceVariant,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'הוספת תמונה (לא חובה)',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Name field ──────────────────────────────────────────
                    Text(
                      'שם המוצר',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'לדוגמה: סרם לחות אישי',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // ── Category chips ──────────────────────────────────────
                    Text(
                      'קטגוריה',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CategoryChips(
                      categories: categories,
                      selected: _categoryId,
                      onSelect: (id) => setState(() => _categoryId = id),
                    ),
                    const SizedBox(height: 20),

                    // ── Slot pills ──────────────────────────────────────────
                    Text(
                      'זמן שגרה',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PillRow(
                      options: const [
                        ('morning', 'בוקר'),
                        ('evening', 'ערב'),
                        ('both', 'בוקר + ערב'),
                      ],
                      selected: _slot,
                      onSelect: (v) => setState(() => _slot = v),
                    ),
                    const SizedBox(height: 20),

                    // ── Frequency ───────────────────────────────────────────
                    Text(
                      'תדירות',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PillRow(
                      options: const [
                        ('daily', 'יומי'),
                        ('weekly', 'כמה פעמים בשבוע'),
                      ],
                      selected: _isDaily ? 'daily' : 'weekly',
                      onSelect: (v) => setState(() => _isDaily = v == 'daily'),
                    ),
                    if (!_isDaily) ...[
                      const SizedBox(height: 12),
                      _TimesPerWeekPicker(
                        value: _timesPerWeek,
                        onChanged: (v) => setState(() => _timesPerWeek = v),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── CTA ─────────────────────────────────────────────────
                    _SaveButton(
                      enabled: _canSave,
                      saving: _saving,
                      onTap: _save,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
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

// ── Category chips ────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in categories)
          GestureDetector(
            onTap: () => onSelect(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected == cat.id
                    ? AppColors.primary
                    : AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: selected == cat.id ? AppColors.glowSm : null,
              ),
              child: Text(
                cat.name,
                style: AppTypography.labelMd.copyWith(
                  color: selected == cat.id
                      ? AppColors.onPrimary
                      : AppColors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Pill row (slot / frequency selector) ─────────────────────────────────────

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
                height: 44,
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

// ── Times per week picker ─────────────────────────────────────────────────────

class _TimesPerWeekPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _TimesPerWeekPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'פעמים בשבוע:',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        for (int i = 1; i <= 5; i++) ...[
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
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool saving;
  final VoidCallback onTap;

  const _SaveButton({
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
                        const Icon(Icons.add_rounded,
                            color: AppColors.onPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'הוספה לשגרה שלי',
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
