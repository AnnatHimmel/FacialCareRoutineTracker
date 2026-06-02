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
  String get navCalendar => 'יומן';

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
  String get backAction => 'חזרה';

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

  @override
  String genericError(Object error) {
    return 'שגיאה: $error';
  }

  @override
  String get homeTitle => 'השגרה שלך היום';

  @override
  String get homeTapImageToDone => 'הקישי על התמונה לסימון בוצע';

  @override
  String get homeTapProductToDone => 'הקישי על מוצר לסימון בוצע';

  @override
  String get homeEmptyToday => 'אין מוצרים להיום';

  @override
  String get homeAddProducts => 'הוסף מוצרים';

  @override
  String homeDayLabel(Object day) {
    return 'יום $day';
  }

  @override
  String homeDayLabelGreeting(Object day, Object name) {
    return 'יום $day • שלום $name';
  }

  @override
  String get homeViewListSemantics => 'תצוגת רשימה פעילה';

  @override
  String get homeViewImagesSemantics => 'תצוגת תמונות פעילה';

  @override
  String get homeViewList => 'רשימה';

  @override
  String get homeViewImages => 'תמונות';

  @override
  String get homeNamesToggleHide => 'הסתר שמות מוצרים';

  @override
  String get homeNamesToggleShow => 'הצג שמות מוצרים';

  @override
  String get homeNames => 'שמות';

  @override
  String homeProductStepDone(Object name, Object step) {
    return '$name, שלב $step, בוצע';
  }

  @override
  String homeProductStepNotDone(Object name, Object step) {
    return '$name, שלב $step, לא בוצע';
  }

  @override
  String get journalCtaTitle => 'איך העור מרגיש?';

  @override
  String get journalCtaSubtitle => 'תעדי את התקדמותך';

  @override
  String get journalCtaButton => 'תיעוד עכשיו';

  @override
  String get onboardingSkip => 'דלגי';

  @override
  String get onboardingWelcome => 'ברוכה הבאה';

  @override
  String get onboardingAppIntro => 'ל־The Glow Protocol';

  @override
  String get onboardingTagline =>
      'השגרה שלך, בקצב שלך.\nתיעוד יומי, תזמון חכם של מוצרים, וזוהר עקבי.';

  @override
  String get onboardingStart => 'בואי נתחיל';

  @override
  String get onboardingTakesMinute => 'לוקח פחות מדקה';

  @override
  String get onboardingFeature1 => 'מעקב יומי אחר השגרה';

  @override
  String get onboardingFeature2 => 'תזמון שבועי לפי המוצר';

  @override
  String get onboardingFeature3 => 'יומן עור ומצב רוח';

  @override
  String get onboardingTellUs => 'ספרי לנו עלייך';

  @override
  String get onboardingPrivacyDesc =>
      'נשתמש בפרטים האלה כדי להתאים לך תוכן ולפנות אלייך אישית. הכל נשמר על המכשיר שלך.';

  @override
  String get onboardingNamePrompt => 'איך לקרוא לך?';

  @override
  String get onboardingNameHint => 'השם שלך';

  @override
  String get onboardingGenderLabel => 'מגדר';

  @override
  String get onboardingGenderFemale => 'נקבה';

  @override
  String get onboardingGenderMale => 'זכר';

  @override
  String get onboardingPrivacyLock => 'הפרטים נשמרים רק אצלך';

  @override
  String get onboardingYourProducts => 'המוצרים שלך';

  @override
  String get onboardingProductInstruction =>
      'סמני את המוצרים שיש לך בארון. תוכלי לערוך, להוסיף ולתזמן אותם בכל זמן.';

  @override
  String onboardingProductCount(Object count) {
    return 'נבחרו $count מוצרים';
  }

  @override
  String get onboardingCanAddLater => 'תוכלי להוסיף מוצרים גם בהמשך';

  @override
  String get onboardingFinish => 'סיום והתחלה';

  @override
  String get onboardingFrequencyDaily => 'יומי';

  @override
  String onboardingFrequencyWeekly(Object max) {
    return 'עד $max× בשבוע';
  }

  @override
  String get calendarDayAbbrevSun => 'א׳';

  @override
  String get calendarDayAbbrevMon => 'ב׳';

  @override
  String get calendarDayAbbrevTue => 'ג׳';

  @override
  String get calendarDayAbbrevWed => 'ד׳';

  @override
  String get calendarDayAbbrevThu => 'ה׳';

  @override
  String get calendarDayAbbrevFri => 'ו׳';

  @override
  String get calendarDayAbbrevSat => 'ש׳';

  @override
  String get calendarStateComplete => 'הושלם';

  @override
  String get calendarStatePartial => 'חלקי';

  @override
  String get calendarStateMissed => 'הוחמץ';

  @override
  String get calendarStateNoData => 'ללא נתונים';

  @override
  String get calendarMonthlyAvg => 'ממוצע חודשי';

  @override
  String get calendarProgress => 'התקדמות';

  @override
  String get calendarVsPrevMonth => 'לעומת חודש קודם';

  @override
  String get calendarNoComparison => 'אין נתוני השוואה';

  @override
  String calendarDailyRecord(Object day, Object month) {
    return 'תיעוד יומי: $day ב$month';
  }

  @override
  String get calendarEdit => 'ערוך';

  @override
  String get calendarSkinState => 'מצב העור היום';

  @override
  String get calendarNoNotes => 'לא נרשמו הערות';

  @override
  String get calendarTasksDone => 'משימות שביצעו היום:';

  @override
  String get calendarAddPhoto => 'הוסף תמונה';

  @override
  String get journalNoPhotos => 'אין תמונות עדיין';

  @override
  String get journalEmptyInstruction =>
      'הוסיפי תמונות ביומן העור היומי כדי לעקוב אחר ההתקדמות שלך';

  @override
  String get journalStartDocumenting => 'התחלי לתעד';

  @override
  String journalDateFormat(Object day, Object month, Object year) {
    return '$day ב$month $year';
  }
}

/// The translations for Hebrew, as used in Morocco (`he_MA`).
class AppLocalizationsHeMa extends AppLocalizationsHe {
  AppLocalizationsHeMa() : super('he_MA');

  @override
  String get backupReminderMessage => 'גבה את הנתונים שלך';

  @override
  String get homeTapImageToDone => 'הקש על התמונה לסימון בוצע';

  @override
  String get homeTapProductToDone => 'הקש על מוצר לסימון בוצע';

  @override
  String get journalCtaSubtitle => 'תעד את התקדמותך';

  @override
  String get onboardingSkip => 'דלג';

  @override
  String get onboardingWelcome => 'ברוך הבא';

  @override
  String get onboardingStart => 'בוא נתחיל';

  @override
  String get onboardingTellUs => 'ספר לנו עלייך';

  @override
  String get onboardingPrivacyDesc =>
      'נשתמש בפרטים האלה כדי להתאים לך תוכן ולפנות אליך אישית. הכל נשמר על המכשיר שלך.';

  @override
  String get onboardingProductInstruction =>
      'סמן את המוצרים שיש לך בארון. תוכל לערוך, להוסיף ולתזמן אותם בכל זמן.';

  @override
  String get onboardingCanAddLater => 'תוכל להוסיף מוצרים גם בהמשך';

  @override
  String get journalEmptyInstruction =>
      'הוסף תמונות ביומן העור היומי כדי לעקוב אחר ההתקדמות שלך';

  @override
  String get journalStartDocumenting => 'התחל לתעד';
}
