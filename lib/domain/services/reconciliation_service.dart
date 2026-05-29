import '../entities/master_product.dart';
import '../repositories/master_content_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_data_repository.dart';

class ReconciliationResult {
  final bool isUpdateDetected;
  final List<MasterProduct> newProducts;
  final List<MasterProduct> newlyDeprecatedSelected;
  final String currentContentVersion;

  const ReconciliationResult({
    required this.isUpdateDetected,
    required this.newProducts,
    required this.newlyDeprecatedSelected,
    required this.currentContentVersion,
  });
}

class ReconciliationService {
  final MasterContentRepository _masterRepo;
  final UserDataRepository _userRepo;
  final SettingsRepository _settings;

  ReconciliationService(this._masterRepo, this._userRepo, this._settings);

  Future<ReconciliationResult> reconcile() async {
    final masterContent = await _masterRepo.load();
    final lastKnown = await _settings.getLastKnownMasterVersion();
    final currentVersion = masterContent.manifest.contentVersion;

    if (lastKnown == null || lastKnown == currentVersion) {
      return ReconciliationResult(
        isUpdateDetected: false,
        newProducts: [],
        newlyDeprecatedSelected: [],
        currentContentVersion: currentVersion,
      );
    }

    final exportData = await _userRepo.exportAllData();
    final selectedIds = exportData.selections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();

    // Products added strictly after lastKnown and not yet selected
    final newProducts = masterContent.products
        .where((p) =>
            !p.isDeprecated &&
            !selectedIds.contains(p.id) &&
            _isNewerVersion(p.addedInVersion, lastKnown))
        .toList();

    final newlyDeprecatedSelected = masterContent.products
        .where((p) => p.isDeprecated && selectedIds.contains(p.id))
        .toList();

    return ReconciliationResult(
      isUpdateDetected: true,
      newProducts: newProducts,
      newlyDeprecatedSelected: newlyDeprecatedSelected,
      currentContentVersion: currentVersion,
    );
  }

  Future<void> acknowledgeUpdate(String version) =>
      _settings.setLastKnownMasterVersion(version);

  /// Returns true if [candidate] is strictly newer than [reference] by semver.
  static bool _isNewerVersion(String candidate, String reference) {
    final c = _parts(candidate);
    final r = _parts(reference);
    for (var i = 0; i < 3; i++) {
      if (c[i] > r[i]) return true;
      if (c[i] < r[i]) return false;
    }
    return false; // equal
  }

  static List<int> _parts(String v) =>
      v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
}
