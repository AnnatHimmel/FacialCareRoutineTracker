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
