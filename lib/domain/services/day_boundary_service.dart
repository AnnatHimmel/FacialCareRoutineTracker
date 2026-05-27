class DayBoundaryService {
  /// Returns the effective calendar date for [dateTime].
  /// If hour < 6, returns the previous calendar date (activity before 6am
  /// belongs to the prior day).
  DateTime effectiveDate(DateTime dateTime) {
    final normalized = dateTime.toLocal();
    if (normalized.hour < 6) {
      return DateTime(normalized.year, normalized.month, normalized.day - 1);
    }
    return DateTime(normalized.year, normalized.month, normalized.day);
  }

  /// Effective date for right now.
  DateTime get todayEffectiveDate => effectiveDate(DateTime.now());

  /// Formats a DateTime as 'YYYY-MM-DD'.
  String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Parses 'YYYY-MM-DD' back to DateTime (midnight).
  DateTime parseDate(String date) {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
