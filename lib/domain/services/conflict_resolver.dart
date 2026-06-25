import 'package:meta/meta.dart';
import '../entities/master_product.dart';
import '../entities/weekday_schedule.dart';
import '../enums/slot.dart';

/// A desired weekday set for one (product, slot) pair. Applying a list of these
/// is the unit of a [ConflictResolution] — both the forward fix and its inverse
/// are expressed as mutations so the whole thing is trivially reversible.
@immutable
class ScheduleMutation {
  final String productId;
  final Slot slot;
  final Set<int> days;

  const ScheduleMutation({
    required this.productId,
    required this.slot,
    required this.days,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduleMutation &&
      other.productId == productId &&
      other.slot == slot &&
      other.days.length == days.length &&
      other.days.containsAll(days);

  @override
  int get hashCode => Object.hash(
        productId,
        slot,
        Object.hashAll(days.toList()..sort()),
      );
}

/// A described, reversible resolution for a single conflicting product pair.
///
/// [mutations] applied to the current schedules clears the conflict (fully when
/// [isPartial] is false, best-effort otherwise). [inverse] applied afterwards
/// restores the exact prior state — this is what powers the Undo affordance.
@immutable
class ConflictResolution {
  final List<ScheduleMutation> mutations;
  final List<ScheduleMutation> inverse;
  final String description;
  final String? descriptionEn;

  /// True when the pair could not be fully separated (e.g. two capped products
  /// whose combined nights exceed the week). [mutations] still reduce overlap.
  final bool isPartial;

  const ConflictResolution({
    required this.mutations,
    required this.inverse,
    required this.description,
    this.descriptionEn,
    required this.isPartial,
  });

  String localizedDescription(String locale) =>
      locale == 'en' ? (descriptionEn ?? description) : description;
}

const _allDays = <int>{0, 1, 2, 3, 4, 5, 6};

/// Pure planner that turns a conflicting product pair into a reversible
/// resolution (PRD §15.7). It never mutates inputs and performs no I/O —
/// callers apply [ConflictResolution.mutations] via the schedule repository.
class ConflictResolver {
  const ConflictResolver();

  /// Resolve a conflict between [productA] and [productB] occurring in [slot],
  /// given the current [schedules]. Algorithm, in order:
  ///   (a) slot separation — move a bi-slot product off [slot] when the other
  ///       is slot-locked; no frequency loss.
  ///   (b) day separation — assign non-overlapping weekdays, the capped product
  ///       anchoring its N spread days and the other filling the rest.
  ///   (c) tiebreak — when equally flexible, the second product ([productB])
  ///       yields.
  ConflictResolution resolve({
    required MasterProduct productA,
    required MasterProduct productB,
    required Slot slot,
    required List<WeekdaySchedule> schedules,
  }) {
    final otherSlot = slot == Slot.morning ? Slot.evening : Slot.morning;

    final aBiSlot = productA.morningConfig != null && productA.eveningConfig != null;
    final bBiSlot = productB.morningConfig != null && productB.eveningConfig != null;

    // ── (a) SLOT SEPARATION ──────────────────────────────────────────────
    // Exactly one product is flexible enough to leave this slot.
    if (aBiSlot != bBiSlot) {
      final mover = aBiSlot ? productA : productB;
      return _separateBySlot(mover, slot, otherSlot, schedules);
    }

    // ── (b) DAY SEPARATION ───────────────────────────────────────────────
    return _separateByDay(productA, productB, slot, schedules);
  }

  ConflictResolution _separateBySlot(
    MasterProduct mover,
    Slot slot,
    Slot otherSlot,
    List<WeekdaySchedule> schedules,
  ) {
    final currentInSlot = _daysFor(schedules, mover.id, slot);

    // The mover's presence in [slot] is what creates the clash — clear it.
    // Its other-slot schedule is untouched, so no frequency is lost.
    final mutation = ScheduleMutation(
      productId: mover.id,
      slot: slot,
      days: const <int>{},
    );

    // Inverse: restore to the prior state.
    // If the mover is a daily product (no weekly cap) and had no explicit
    // schedule row before, restoring to {} would leave it permanently
    // suppressed (RoutineResolver treats an empty row as "excluded").
    // Use _allDays so the resolver sees it as "daily default" again.
    final isDailyMover = _weeklyCap(mover, slot) == null;
    final inverseDays =
        (currentInSlot.isEmpty && isDailyMover) ? _allDays : currentInSlot;
    final inverse = ScheduleMutation(
      productId: mover.id,
      slot: slot,
      days: inverseDays,
    );

    final slotName = _slotNameHe(otherSlot);
    final slotNameEn = _slotNameEn(otherSlot);
    return ConflictResolution(
      mutations: [mutation],
      inverse: [inverse],
      description: 'העברנו את "${mover.name}" ל$slotName בלבד',
      descriptionEn: 'Moved "${mover.name}" to $slotNameEn only',
      isPartial: false,
    );
  }

  ConflictResolution _separateByDay(
    MasterProduct productA,
    MasterProduct productB,
    Slot slot,
    List<WeekdaySchedule> schedules,
  ) {
    final capA = _weeklyCap(productA, slot);
    final capB = _weeklyCap(productB, slot);

    // Pick the anchor (keeps its days) and the yielder (gives up overlap).
    // More-constrained (capped, smaller cap) product anchors. On a tie, the
    // second product (productB) yields → productA anchors.
    final MasterProduct anchor;
    final MasterProduct yielder;
    if (capA != null && capB == null) {
      anchor = productA;
      yielder = productB;
    } else if (capB != null && capA == null) {
      anchor = productB;
      yielder = productA;
    } else if (capA != null && capB != null) {
      // Both capped: the smaller cap is the more constrained → it anchors.
      // Tie → productA anchors (productB yields).
      anchor = capA <= capB ? productA : productB;
      yielder = anchor.id == productA.id ? productB : productA;
    } else {
      // Both uncapped/daily: equally flexible → productB yields.
      anchor = productA;
      yielder = productB;
    }

    final anchorCap = _weeklyCap(anchor, slot);
    final anchorCurrent = _daysFor(schedules, anchor.id, slot);
    final yielderCurrent = _daysFor(schedules, yielder.id, slot);

    // Anchor's target days: its current spread, capped to its allowance.
    // When starting from scratch (empty), spread the days evenly so capped
    // products land on non-consecutive days (e.g. BHA cap-3 → {0,2,4}).
    Set<int> anchorDays = anchorCurrent.isEmpty
        ? (anchorCap == null ? _allDays : _spreadN(_allDays, anchorCap))
        : anchorCurrent;
    if (anchorCap != null && anchorDays.length > anchorCap) {
      anchorDays = _spreadN(anchorDays, anchorCap);
    }

    // Yielder fills the remaining days, capped to its own allowance.
    final yielderCap = _weeklyCap(yielder, slot);
    final remaining = _allDays.difference(anchorDays);
    final Set<int> yielderDays =
        yielderCap == null ? remaining : _firstN(remaining, yielderCap);

    // Partial when the yielder is capped and can't fit all its needed nights
    // in the leftover days.
    final isPartial = yielderCap != null && remaining.length < yielderCap;

    final mutations = <ScheduleMutation>[];
    final inverse = <ScheduleMutation>[];

    if (!_sameSet(anchorDays, anchorCurrent)) {
      mutations.add(ScheduleMutation(
          productId: anchor.id, slot: slot, days: anchorDays));
      // Inverse: restore prior state. A DailyRule anchor with no prior row
      // must be restored to _allDays so RoutineResolver treats it as daily.
      final isAnchorDaily = _weeklyCap(anchor, slot) == null;
      final anchorInverseDays =
          (anchorCurrent.isEmpty && isAnchorDaily) ? _allDays : anchorCurrent;
      inverse.add(ScheduleMutation(
          productId: anchor.id, slot: slot, days: anchorInverseDays));
    }
    if (!_sameSet(yielderDays, yielderCurrent)) {
      mutations.add(ScheduleMutation(
          productId: yielder.id, slot: slot, days: yielderDays));
      // Inverse: a DailyRule yielder with no prior row restores to _allDays,
      // not {} — an empty explicit schedule would permanently suppress it.
      final isYielderDaily = _weeklyCap(yielder, slot) == null;
      final yielderInverseDays =
          (yielderCurrent.isEmpty && isYielderDaily) ? _allDays : yielderCurrent;
      inverse.add(ScheduleMutation(
          productId: yielder.id, slot: slot, days: yielderInverseDays));
    }

    return ConflictResolution(
      mutations: mutations,
      inverse: inverse,
      description: isPartial
          ? 'פיזרנו את "${anchor.name}" ו- "${yielder.name}" לימים שונים (התאמה חלקית)'
          : 'פיזרנו את "${anchor.name}" ו- "${yielder.name}" לימים שונים',
      descriptionEn: isPartial
          ? 'Spread "${anchor.name}" and "${yielder.name}" across different days '
              '(partial fit)'
          : 'Spread "${anchor.name}" and "${yielder.name}" across different days',
      isPartial: isPartial,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────

  int? _weeklyCap(MasterProduct p, Slot slot) {
    final rule = p.configForSlot(slot)?.frequencyRule;
    return rule is WeeklyMaxRule ? rule.maxPerWeek : null;
  }

  Set<int> _daysFor(List<WeekdaySchedule> schedules, String productId, Slot slot) {
    final s = schedules
        .where((s) => s.productId == productId && s.slot == slot)
        .firstOrNull;
    return s != null ? Set<int>.from(s.weekdays) : <int>{};
  }

  Set<int> _firstN(Iterable<int> days, int n) {
    final sorted = days.toList()..sort();
    return sorted.take(n).toSet();
  }

  /// Picks [n] evenly spread items from [days], maximising the gap between
  /// consecutive picks. For 3 picks from {0..6}: {0,2,4} (gap = 2 each).
  Set<int> _spreadN(Iterable<int> days, int n) {
    final sorted = days.toList()..sort();
    if (sorted.length <= n) return sorted.toSet();
    final result = <int>{};
    for (int i = 0; i < n; i++) {
      result.add(sorted[(i * sorted.length / n).floor()]);
    }
    return result;
  }

  bool _sameSet(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  String _slotNameHe(Slot slot) => slot == Slot.morning ? 'בוקר' : 'ערב';
  String _slotNameEn(Slot slot) =>
      slot == Slot.morning ? 'the morning' : 'the evening';
}

/// Applies [mutations] to [schedules], returning a new list. Each mutation
/// overwrites the weekday set for its (product, slot); other schedules pass
/// through unchanged. Used by the screen to apply a [ConflictResolution] and,
/// with the resolution's inverse, to undo it. Pure — inputs are not mutated.
List<WeekdaySchedule> applyMutations(
  List<WeekdaySchedule> schedules,
  List<ScheduleMutation> mutations,
) {
  final result = List<WeekdaySchedule>.from(schedules);
  for (final m in mutations) {
    final idx = result.indexWhere(
        (s) => s.productId == m.productId && s.slot == m.slot);
    if (idx >= 0) {
      result[idx] = result[idx].copyWith(
        weekdays: Set<int>.from(m.days),
        lastModified: DateTime.now(),
      );
    } else {
      result.add(WeekdaySchedule(
        id: 'resolver-${m.productId}-${m.slot.name}',
        productId: m.productId,
        slot: m.slot,
        weekdays: Set<int>.from(m.days),
        lastModified: DateTime.now(),
      ));
    }
  }
  return result;
}
