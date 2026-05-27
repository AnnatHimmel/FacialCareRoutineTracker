import 'package:meta/meta.dart';

@immutable
class SkinLogEntry {
  final String id;
  final String date;
  final String? notes;
  final List<String> photoPaths;
  final DateTime lastModified;

  const SkinLogEntry({
    required this.id,
    required this.date,
    this.notes,
    required this.photoPaths,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is SkinLogEntry &&
      other.id == id &&
      other.date == date &&
      other.notes == notes &&
      _listEqual(other.photoPaths, photoPaths) &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        notes,
        Object.hashAll(photoPaths),
        lastModified,
      );

  SkinLogEntry copyWith({
    String? id,
    String? date,
    String? notes,
    List<String>? photoPaths,
    DateTime? lastModified,
  }) =>
      SkinLogEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        photoPaths: photoPaths ?? this.photoPaths,
        lastModified: lastModified ?? this.lastModified,
      );

  static bool _listEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
