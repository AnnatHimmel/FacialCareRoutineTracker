import 'package:meta/meta.dart';

import '../enums/slot.dart';

/// The kind of adjustment the auto-sorter applied to one conflicting pair —
/// drives the icon shown on each "מה סידרנו בשבילך" card.
enum RoutineChangeKind {
  /// Product was moved to different weekday(s), same number of days (↔).
  movedDays,

  /// Product's weekly frequency was reduced — fewer days than before (↓).
  reducedFrequency,

  /// Product was moved off the conflicting slot entirely.
  movedSlot,
}

/// One adjustment the sorter applied while building the routine.
/// [he]/[en] are the resolver's already-localized human descriptions.
@immutable
class RoutineChange {
  final Slot slot;
  final RoutineChangeKind kind;
  final String he;
  final String en;

  const RoutineChange({
    required this.slot,
    required this.kind,
    required this.he,
    required this.en,
  });

  String localized(String locale) => locale == 'en' ? en : he;

  @override
  bool operator ==(Object other) =>
      other is RoutineChange &&
      other.slot == slot &&
      other.kind == kind &&
      other.he == he &&
      other.en == en;

  @override
  int get hashCode => Object.hash(slot, kind, he, en);
}

/// An incompatibility the sorter intentionally did NOT auto-resolve (advisory
/// only — e.g. two daily products that oxidize together). Shown under
/// "כדאי לשים לב".
@immutable
class RoutineAdvisory {
  final Slot slot;
  final String he;
  final String en;

  const RoutineAdvisory({
    required this.slot,
    required this.he,
    required this.en,
  });

  String localized(String locale) => locale == 'en' ? en : he;

  @override
  bool operator ==(Object other) =>
      other is RoutineAdvisory &&
      other.slot == slot &&
      other.he == he &&
      other.en == en;

  @override
  int get hashCode => Object.hash(slot, he, en);
}

/// Snapshot of what the auto-sorter produced for the "השגרה שלך מוכנה" screen.
///
/// [totalProducts] is the count of distinct selected products across both
/// slots (a product chosen for morning and evening counts once); [morningCount]
/// and [eveningCount] are the per-slot selected counts and may overlap.
@immutable
class RoutineBuildSummary {
  final int totalProducts;
  final int morningCount;
  final int eveningCount;
  final List<RoutineChange> changes;
  final List<RoutineAdvisory> advisories;

  const RoutineBuildSummary({
    required this.totalProducts,
    required this.morningCount,
    required this.eveningCount,
    this.changes = const [],
    this.advisories = const [],
  });

  /// True when the sorter neither adjusted anything nor has advisories to note.
  bool get hasNothingToReport => changes.isEmpty && advisories.isEmpty;
}
