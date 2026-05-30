// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'מעקב שגרת טיפוח';

  @override
  String get navToday => 'היום';

  @override
  String get navCalendar => 'לוח שנה';

  @override
  String get navJournal => 'יומן עור';

  @override
  String get navProducts => 'המוצרים שלי';

  @override
  String get navSettings => 'הגדרות';

  @override
  String get slotMorning => 'בוקר';

  @override
  String get slotEvening => 'ערב';

  @override
  String get productSelectionTitle => 'בחירת מוצרים';

  @override
  String get scheduleTitle => 'תזמון מוצרים';

  @override
  String get orderTitle => 'סדר מוצרים';

  @override
  String get streakCurrent => 'ימי רצף';

  @override
  String get streakLongest => 'הרצף הארוך';

  @override
  String get streakMissesThisWeek => 'החסרות השבוע';

  @override
  String streakMissesOf(Object current, Object max) {
    return '$current מתוך $max';
  }

  @override
  String get warningDeprecated => 'לא מומלץ עוד';

  @override
  String get warningIncompatible => 'לא מומלץ לשימוש יחד';

  @override
  String get warningMute => 'השתק';

  @override
  String get warningOverCap => 'נבחרו יותר ימים מההמלצה';

  @override
  String get exportTitle => 'ייצוא / ייבוא';

  @override
  String get exportAction => 'ייצא עכשיו';

  @override
  String get importAction => 'ייבא';

  @override
  String get importReplace => 'החלפה';

  @override
  String get importMerge => 'מיזוג';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get aboutTitle => 'אודות / מה חדש';

  @override
  String get updateReviewTitle => 'עדכון הושלם';

  @override
  String get backupReminderMessage => 'גבי את הנתונים שלך';

  @override
  String get backupAction => 'גיבוי';

  @override
  String get skinLogTitle => 'יומן עור';

  @override
  String get skinLogPlaceholder => 'איך העור שלך היום?';

  @override
  String get emptyRoutine => 'אין מוצרים מתוכננים להיום';

  @override
  String get emptyJournal => 'עדיין אין תמונות ביומן';

  @override
  String get continueAction => 'המשך';

  @override
  String get saveAction => 'שמור';

  @override
  String get resetOrder => 'אפס לסדר מומלץ';

  @override
  String get dataIntactConfirmation => 'כל הנתונים שלך שמורים ובשלמותם';

  @override
  String get before6amNote => 'פעילות לפני 6:00 נרשמת ליום אמש';

  @override
  String conflictChooserTitle(Object current, Object total) {
    return 'התנגשות $current מתוך $total';
  }

  @override
  String get chooseArchive => 'מהגיבוי';

  @override
  String get chooseDevice => 'מהמכשיר';

  @override
  String get webStorageWarning => 'תמונות מאוחסנות בנפח מוגבל. גיבוי מומלץ.';
}
