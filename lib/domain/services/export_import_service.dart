import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../entities/day_record.dart';
import '../entities/muted_conflict.dart';
import '../entities/order_override.dart';
import '../entities/product_selection.dart';
import '../entities/skin_log_entry.dart';
import '../entities/user_data_export.dart';
import '../entities/weekday_schedule.dart';
import '../repositories/photo_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_data_repository.dart';

class ArchiveValidationResult {
  final bool isValid;
  final String? errorMessage;
  final UserDataExport? data;
  final Map<String, Uint8List> photos;

  const ArchiveValidationResult({
    required this.isValid,
    this.errorMessage,
    this.data,
    this.photos = const {},
  });
}

class MergeConflict {
  final String recordId;
  final String recordType;
  final dynamic archiveRecord;
  final dynamic localRecord;

  const MergeConflict({
    required this.recordId,
    required this.recordType,
    required this.archiveRecord,
    required this.localRecord,
  });
}

class MergeSession {
  final List<MergeConflict> conflicts;
  final UserDataExport archiveData;
  final Map<String, Uint8List> photos;
  final UserDataRepository _userRepo;
  final PhotoRepository _photoRepo;

  final Map<String, bool> _resolutions = {};

  MergeSession({
    required this.conflicts,
    required this.archiveData,
    required this.photos,
    required UserDataRepository userRepo,
    required PhotoRepository photoRepo,
  })  : _userRepo = userRepo,
        _photoRepo = photoRepo;

  void resolveConflict({required int index, required bool useArchive}) {
    _resolutions[conflicts[index].recordId] = useArchive;
  }

  Future<void> complete() async {
    final currentData = await _userRepo.exportAllData();

    // Merge selections: prefer archive for conflicts where useArchive=true
    final Map<String, ProductSelection> mergedSelections = {
      for (final s in currentData.selections) s.id: s,
    };
    for (final s in archiveData.selections) {
      if (_resolutions[s.id] == true || !mergedSelections.containsKey(s.id)) {
        mergedSelections[s.id] = s;
      }
    }

    final Map<String, WeekdaySchedule> mergedSchedules = {
      for (final s in currentData.schedules) s.id: s,
    };
    for (final s in archiveData.schedules) {
      if (_resolutions[s.id] == true || !mergedSchedules.containsKey(s.id)) {
        mergedSchedules[s.id] = s;
      }
    }

    final Map<String, OrderOverride> mergedOverrides = {
      for (final o in currentData.overrides) o.id: o,
    };
    for (final o in archiveData.overrides) {
      if (_resolutions[o.id] == true || !mergedOverrides.containsKey(o.id)) {
        mergedOverrides[o.id] = o;
      }
    }

    final Map<String, DayRecord> mergedDayRecords = {
      for (final r in currentData.dayRecords) r.id: r,
    };
    for (final r in archiveData.dayRecords) {
      if (_resolutions[r.id] == true || !mergedDayRecords.containsKey(r.id)) {
        mergedDayRecords[r.id] = r;
      }
    }

    final Map<String, SkinLogEntry> mergedSkinLogs = {
      for (final e in currentData.skinLogs) e.id: e,
    };
    for (final e in archiveData.skinLogs) {
      if (_resolutions[e.id] == true || !mergedSkinLogs.containsKey(e.id)) {
        mergedSkinLogs[e.id] = e;
      }
    }

    final Map<String, MutedConflict> mergedMuted = {
      for (final m in currentData.mutedConflicts) m.id: m,
    };
    for (final m in archiveData.mutedConflicts) {
      mergedMuted[m.id] = m;
    }

    final merged = UserDataExport(
      schemaVersion: archiveData.schemaVersion,
      exportDate: archiveData.exportDate,
      appVersion: archiveData.appVersion,
      masterContentVersion: archiveData.masterContentVersion,
      selections: mergedSelections.values.toList(),
      schedules: mergedSchedules.values.toList(),
      overrides: mergedOverrides.values.toList(),
      dayRecords: mergedDayRecords.values.toList(),
      skinLogs: mergedSkinLogs.values.toList(),
      mutedConflicts: mergedMuted.values.toList(),
    );

    await _userRepo.replaceAllData(merged);
    for (final e in photos.entries) {
      await _photoRepo.savePhoto(e.key, e.value);
    }
  }

  void cancel() {}
}

class ExportImportService {
  final UserDataRepository _userRepo;
  final PhotoRepository _photoRepo;
  final SettingsRepository _settings;

  ExportImportService(this._userRepo, this._photoRepo, this._settings);

  Future<Uint8List> exportToArchive() async {
    final export = await _userRepo.exportAllData();
    final archive = Archive();

    final manifest = jsonEncode({
      'exportVersion': '1',
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'contentVersion': export.masterContentVersion,
    });
    final manifestBytes = utf8.encode(manifest);
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final userData = jsonEncode(export.toJson());
    final userDataBytes = utf8.encode(userData);
    archive.addFile(
      ArchiveFile('user_data.json', userDataBytes.length, userDataBytes),
    );

    // Collect all unique photo keys
    final photoKeys = <String>{};
    for (final log in export.skinLogs) {
      photoKeys.addAll(log.photoPaths);
    }

    for (final key in photoKeys) {
      final bytes = await _photoRepo.readPhoto(key);
      if (bytes != null) {
        archive.addFile(
          ArchiveFile('photos/$key.jpg', bytes.length, bytes),
        );
      }
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    await _settings.setLastExportDate(DateTime.now().toIso8601String());
    return Uint8List.fromList(zipBytes);
  }

  ArchiveValidationResult validateArchive(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestFile = archive.findFile('manifest.json');
      final dataFile = archive.findFile('user_data.json');

      if (manifestFile == null || dataFile == null) {
        return const ArchiveValidationResult(
          isValid: false,
          errorMessage: 'קובץ הגיבוי אינו תקין: חסרים קבצים',
        );
      }

      final export = UserDataExport.fromJson(
        jsonDecode(utf8.decode(dataFile.content as List<int>))
            as Map<String, dynamic>,
      );

      final photos = <String, Uint8List>{};
      for (final f in archive.files) {
        if (f.name.startsWith('photos/') && f.name.endsWith('.jpg')) {
          final key = f.name
              .replaceFirst('photos/', '')
              .replaceAll('.jpg', '');
          photos[key] = Uint8List.fromList(f.content as List<int>);
        }
      }

      return ArchiveValidationResult(isValid: true, data: export, photos: photos);
    } catch (e) {
      return ArchiveValidationResult(
        isValid: false,
        errorMessage: 'שגיאה בקריאת הגיבוי: $e',
      );
    }
  }

  Future<void> replaceAll(ArchiveValidationResult validated) async {
    assert(validated.isValid && validated.data != null);
    await _userRepo.replaceAllData(validated.data!);
    for (final e in validated.photos.entries) {
      await _photoRepo.savePhoto(e.key, e.value);
    }
  }

  Future<MergeSession> startMerge(ArchiveValidationResult validated) async {
    assert(validated.isValid && validated.data != null);
    final currentData = await _userRepo.exportAllData();
    final archiveData = validated.data!;

    final conflicts = <MergeConflict>[];

    // Find conflicting day records (same id, different lastModified)
    final currentDayMap = {for (final r in currentData.dayRecords) r.id: r};
    for (final r in archiveData.dayRecords) {
      final local = currentDayMap[r.id];
      if (local != null && local.lastModified != r.lastModified) {
        conflicts.add(MergeConflict(
          recordId: r.id,
          recordType: 'dayRecord',
          archiveRecord: r,
          localRecord: local,
        ));
      }
    }

    // Find conflicting skin logs
    final currentLogMap = {for (final e in currentData.skinLogs) e.id: e};
    for (final e in archiveData.skinLogs) {
      final local = currentLogMap[e.id];
      if (local != null && local.lastModified != e.lastModified) {
        conflicts.add(MergeConflict(
          recordId: e.id,
          recordType: 'skinLog',
          archiveRecord: e,
          localRecord: local,
        ));
      }
    }

    return MergeSession(
      conflicts: conflicts,
      archiveData: archiveData,
      photos: validated.photos,
      userRepo: _userRepo,
      photoRepo: _photoRepo,
    );
  }
}
