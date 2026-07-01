import '../entities/master_product.dart';
import '../repositories/master_content_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_data_repository.dart';

class ReconciliationResult {
  final bool isUpdateDetected;
  final List<MasterProduct> newProducts;
  final List<MasterProduct> newlyDeprecatedSelected;
  final String currentContentVersion;

  /// The set of non-deprecated master product IDs at the time of this
  /// reconciliation. Callers should pass this back to [ReconciliationService.acknowledgeUpdate]
  /// so the ID snapshot is persisted for the next diff.
  final Set<String> currentMasterProductIds;

  const ReconciliationResult({
    required this.isUpdateDetected,
    required this.newProducts,
    required this.newlyDeprecatedSelected,
    required this.currentContentVersion,
    required this.currentMasterProductIds,
  });
}

class ReconciliationService {
  final MasterContentRepository _masterRepo;
  final UserDataRepository _userRepo;
  final SettingsRepository _settings;

  ReconciliationService(this._masterRepo, this._userRepo, this._settings);

  Future<ReconciliationResult> reconcile() async {
    final masterContent = await _masterRepo.load();
    final currentVersion = masterContent.manifest.contentVersion;

    // Compute the current set of non-deprecated master product IDs.
    final currentIds = masterContent.products
        .where((p) => !p.isDeprecated)
        .map((p) => p.id)
        .toSet();

    final knownIds = await _settings.getKnownProductIds();

    // First run: no snapshot yet. Seed and report no update.
    if (knownIds == null) {
      await _settings.setKnownProductIds(currentIds);
      await _settings.setLastKnownMasterVersion(currentVersion);
      return ReconciliationResult(
        isUpdateDetected: false,
        newProducts: [],
        newlyDeprecatedSelected: [],
        currentContentVersion: currentVersion,
        currentMasterProductIds: currentIds,
      );
    }

    // Version early-out: if the content version hasn't changed we can skip the
    // expensive user-data load, but still surface deprecated-selected products
    // on the rare chance a product was deprecated in a same-version bundle update.
    final lastKnown = await _settings.getLastKnownMasterVersion();
    if (lastKnown != null && lastKnown == currentVersion) {
      return ReconciliationResult(
        isUpdateDetected: false,
        newProducts: [],
        newlyDeprecatedSelected: [],
        currentContentVersion: currentVersion,
        currentMasterProductIds: currentIds,
      );
    }

    final exportData = await _userRepo.exportAllData();
    final selectedIds = exportData.selections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();

    // Products whose IDs are NOT in the last-known snapshot, not deprecated, not selected.
    final newProducts = masterContent.products
        .where((p) =>
            !p.isDeprecated &&
            !selectedIds.contains(p.id) &&
            !knownIds.contains(p.id))
        .toList();

    final newlyDeprecatedSelected = masterContent.products
        .where((p) => p.isDeprecated && selectedIds.contains(p.id))
        .toList();

    return ReconciliationResult(
      isUpdateDetected: newProducts.isNotEmpty || newlyDeprecatedSelected.isNotEmpty,
      newProducts: newProducts,
      newlyDeprecatedSelected: newlyDeprecatedSelected,
      currentContentVersion: currentVersion,
      currentMasterProductIds: currentIds,
    );
  }

  /// Persists [version] as the last-known content version and [masterProductIds]
  /// as the snapshot of known product IDs. Both are used by the next [reconcile]
  /// call to detect new products via ID diff.
  Future<void> acknowledgeUpdate(
    String version,
    Set<String> masterProductIds,
  ) async {
    await _settings.setLastKnownMasterVersion(version);
    await _settings.setKnownProductIds(masterProductIds);
  }
}
