import 'package:meta/meta.dart';

@immutable
class SkinLogEntry {
  final String id;
  final String date;
  final String? notes;
  final String? skinState;
  final List<String> photoPaths;
  final DateTime lastModified;

  const SkinLogEntry({
    required this.id,
    required this.date,
    this.notes,
    this.skinState,
    required this.photoPaths,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is SkinLogEntry &&
      other.id == id &&
      other.date == date &&
      other.notes == notes &&
      other.skinState == skinState &&
      _listEqual(other.photoPaths, photoPaths) &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        notes,
        skinState,
        Object.hashAll(photoPaths),
        lastModified,
      );

  SkinLogEntry copyWith({
    String? id,
    String? date,
    String? notes,
    Object? skinState = _sentinel,
    List<String>? photoPaths,
    DateTime? lastModified,
  }) =>
      SkinLogEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        skinState: skinState == _sentinel
            ? this.skinState
            : skinState as String?,
        photoPaths: photoPaths ?? this.photoPaths,
        lastModified: lastModified ?? this.lastModified,
      );

  static const Object _sentinel = Object();

  static bool _listEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
