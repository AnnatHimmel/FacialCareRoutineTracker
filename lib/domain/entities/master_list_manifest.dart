import 'package:meta/meta.dart';

@immutable
class ChangelogEntry {
  final String contentVersion;
  final List<String> changes;

  const ChangelogEntry({required this.contentVersion, required this.changes});

  @override
  bool operator ==(Object other) =>
      other is ChangelogEntry &&
      other.contentVersion == contentVersion &&
      _listEqual(other.changes, changes);

  @override
  int get hashCode => Object.hash(contentVersion, Object.hashAll(changes));

  ChangelogEntry copyWith({String? contentVersion, List<String>? changes}) =>
      ChangelogEntry(
        contentVersion: contentVersion ?? this.contentVersion,
        changes: changes ?? this.changes,
      );

  static bool _listEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

@immutable
class MasterListManifest {
  final String contentVersion;
  final String appVersion;
  final List<ChangelogEntry> changelog;

  const MasterListManifest({
    required this.contentVersion,
    required this.appVersion,
    required this.changelog,
  });

  @override
  bool operator ==(Object other) =>
      other is MasterListManifest &&
      other.contentVersion == contentVersion &&
      other.appVersion == appVersion &&
      _listEqual(other.changelog, changelog);

  @override
  int get hashCode =>
      Object.hash(contentVersion, appVersion, Object.hashAll(changelog));

  MasterListManifest copyWith({
    String? contentVersion,
    String? appVersion,
    List<ChangelogEntry>? changelog,
  }) =>
      MasterListManifest(
        contentVersion: contentVersion ?? this.contentVersion,
        appVersion: appVersion ?? this.appVersion,
        changelog: changelog ?? this.changelog,
      );

  static bool _listEqual(List<ChangelogEntry> a, List<ChangelogEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
