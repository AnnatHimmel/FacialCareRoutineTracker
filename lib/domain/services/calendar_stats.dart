import '../entities/day_record.dart';

/// Average completion rate across past days in a month.
///
/// [today] is 'YYYY-MM-DD' (the effective today). Days >= today are excluded
/// so that an in-progress or future snapshotted day doesn't dilute the result.
/// Pass null to include all records regardless of date.
double computeMonthAvg(List<DayRecord> records, {required String? today}) {
  if (records.isEmpty) return 0.0;
  final Map<String, List<DayRecord>> byDate = {};
  for (final r in records) {
    if (today != null && r.date.compareTo(today) >= 0) continue;
    (byDate[r.date] ??= []).add(r);
  }
  if (byDate.isEmpty) return 0.0;
  double total = 0.0;
  int count = 0;
  for (final dayRecs in byDate.values) {
    int scheduled = 0;
    int done = 0;
    for (final r in dayRecs) {
      if (r.resolvedProductIds.isNotEmpty) {
        scheduled += r.resolvedProductIds.length;
        done += r.recordedProductIds.length;
      }
    }
    if (scheduled > 0) {
      total += done / scheduled;
      count++;
    }
  }
  return count > 0 ? (total / count).clamp(0.0, 1.0) : 0.0;
}
