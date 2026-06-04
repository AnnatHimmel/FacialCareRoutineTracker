abstract final class HebrewDateStrings {
  /// Month names, index 0 = January … 11 = December.
  /// Use as: `HebrewDateStrings.months[date.month - 1]`
  static const List<String> months = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];

  /// Weekday names, index 0 = Monday … 6 = Sunday (matches DateTime.weekday - 1).
  static const List<String> weekdays = [
    'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת', 'ראשון',
  ];
}

abstract final class EnglishDateStrings {
  /// Month names, index 0 = January … 11 = December.
  static const List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Weekday names, index 0 = Monday … 6 = Sunday (matches DateTime.weekday - 1).
  static const List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// Returns the ordinal suffix string for a day number (e.g. 3 → "3rd").
  static String ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}
