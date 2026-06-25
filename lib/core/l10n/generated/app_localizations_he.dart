// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get navToday => 'היום שלי';

  @override
  String get navCalendar => 'יומן';

  @override
  String get navJournal => 'יומן עור';

  @override
  String get navProducts => 'המוצרים שלי';

  @override
  String get navCollection => 'המדף שלי';

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
  String get warningMute => 'השתיקי';

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
  String get aboutTitle => 'אודות';

  @override
  String get updateReviewTitle => 'עדכון הושלם';

  @override
  String get backupReminderMessage => 'גבי את הנתונים שלך';

  @override
  String get backupAction => 'גיבוי';

  @override
  String get skinLogPlaceholder => 'איך העור שלך היום?';

  @override
  String get emptyRoutine => 'אין מוצרים מתוכננים להיום';

  @override
  String get emptyJournal => 'עדיין אין תמונות ביומן';

  @override
  String get continueAction => 'המשיכי';

  @override
  String get backAction => 'חזרה';

  @override
  String get saveAction => 'שמור';

  @override
  String get cancelAction => 'ביטול';

  @override
  String get resetOrder => 'אפס לסדר מומלץ';

  @override
  String get dataIntactConfirmation => 'כל הנתונים שלך שמורים ובשלמותם';

  @override
  String get before6amNote => 'פעילות לפני 6:00 נרשמת ליום אמש';

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
  String get homeTitle => 'היום שלי';

  @override
  String get homeTapImageToDone => 'הקישי על התמונה לסימון בוצע';

  @override
  String get homeTapProductToDone => 'הקישי על מוצר לסימון בוצע';

  @override
  String get homeEmptyToday => 'אין מוצרים להיום';

  @override
  String get homeAddProducts => 'הוסיפי מוצרים';

  @override
  String homeDayLabel(Object day) {
    return 'יום $day';
  }

  @override
  String homeDayLabelGreeting(Object day, Object name) {
    return 'שלום $name • יום $day';
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
  String get journalCtaButton => 'תעדי עכשיו';

  @override
  String get weeklyReminderBadge => 'תיעוד שבועי';

  @override
  String get weeklyReminderTitle => 'איך העור שלך השבוע?';

  @override
  String get weeklyReminderBody =>
      'צלמי תמונה קצרה ורשמי איך העור מרגיש — פעם בשבוע, כדי לראות את ההתקדמות לאורך זמן.';

  @override
  String get weeklyReminderNotesHint =>
      'איך העור מרגיש היום? יובש, אדמומיות, פצעונים...';

  @override
  String get weeklyReminderCapture => 'צלמי';

  @override
  String get weeklyReminderBrowse => 'או מהגלריה';

  @override
  String get weeklyReminderDismiss => 'אחר כך';

  @override
  String get weeklyReminderNeverShow => 'אל תציג שוב';

  @override
  String get settingsWeeklyReminder => 'תזכורת תיעוד שבועי';

  @override
  String get settingsWeeklyReminderDesc =>
      'תזכורת שבועית לצלם ולתעד את מצב העור';

  @override
  String get settingsDebugResumeReminder => 'הצג שוב תזכורת שבועית';

  @override
  String get settingsDebugSectionNote => 'כלי פיתוח (Debug בלבד)';

  @override
  String get settingsDebugResumeReminderDone => 'התזכורת השבועית תוצג שוב';

  @override
  String get settingsDebugClearShelf => 'נקה את המדף';

  @override
  String get settingsDebugClearShelfConfirm =>
      'למחוק את כל המוצרים מהמדף? לא ניתן לבטל.';

  @override
  String get settingsDebugClearShelfDone => 'המדף נוקה';

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
  String get onboardingTakesMinute => 'לוקח פחות מדקה';

  @override
  String get onboardingFeature1 => 'מעקב יומי אחר השגרה';

  @override
  String get onboardingFeature2 => 'תזמון שבועי לפי המוצר';

  @override
  String get onboardingFeature3 => 'יומן עור ומצב רוח';

  @override
  String get onboardingTellUs => 'כמה פרטים כדי להתחיל';

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
    return 'עד $max פעמים בשבוע';
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
  String get calendarEdit => 'ערכי';

  @override
  String get calendarSkinState => 'מצב העור היום';

  @override
  String get calendarNoNotes => 'לא נרשמו הערות';

  @override
  String get calendarTasksDone => 'משימות שביצעת היום:';

  @override
  String get journalNoPhotos => 'אין תמונות עדיין';

  @override
  String get journalEmptyInstruction =>
      'הוסיפי תמונות ביומן העור היומי כדי לעקוב אחר ההתקדמות שלך';

  @override
  String get journalStartDocumenting => 'התחילי לתעד';

  @override
  String get journalNewEntry => 'תיעוד חדש';

  @override
  String get journalProgressTitle => 'מעקב התקדמות';

  @override
  String journalDateFormat(Object day, Object month, Object year) {
    return '$day ב$month $year';
  }

  @override
  String productSelStepCounter(Object step, Object total) {
    return 'שלב $step מתוך $total';
  }

  @override
  String get productSelSkipStep => 'דלגי על השלב';

  @override
  String get productSelNoCategories => 'לא נמצאו קטגוריות';

  @override
  String get productSelNoProducts => 'אין מוצרים בקטגוריה זו';

  @override
  String get productSelContinueToSchedule => 'המשיכי לתזמון';

  @override
  String get productSelFilterAll => 'הכל';

  @override
  String productSelCategoryOptions(Object count) {
    return '$count אפשרויות';
  }

  @override
  String productSelCategorySelected(Object count) {
    return '$count נבחרו';
  }

  @override
  String get productSelFrequencyLabel => 'תדירות מומלצת: ';

  @override
  String get productSelTimingLabel => 'מתי?';

  @override
  String get productSelListHint =>
      'לחצי על מוצר כדי להוסיף לרשימה או הוסיפי מוצר חדש';

  @override
  String get catHintCleanser1 => 'הסרת איפור ומסנני הגנה, לרוב בערב.';

  @override
  String get catHintCleanser2 => 'ניקוי פנים יומיומי ועדין.';

  @override
  String get catHintCleanser =>
      'ניקוי פנים – שמן/באלם לשלב ראשון, ג׳ל/קצף לשלב שני. ערב בלבד.';

  @override
  String get catHintRetinoid => 'חידוש העור. ערב בלבד, בהדרגה.';

  @override
  String get catHintToner => 'איזון העור והכנה לספיגת השלבים הבאים.';

  @override
  String get catHintSerum => 'החומרים הפעילים שלך. אפשר לבחור כמה שתרצי.';

  @override
  String get catHintMoisturizer => 'נעילת הלחות והרגעת העור.';

  @override
  String get catHintOil => 'שכבת הזנה אחרונה, לרוב בערב.';

  @override
  String get catHintSpf => 'הגנה מהשמש, שלב הבוקר האחרון. חובה.';

  @override
  String get catUsageCleanser1 =>
      'עסי על עור יבש להמסת איפור ומסנני הגנה, ושטפי במים פושרים.';

  @override
  String get catUsageCleanser2 =>
      'הקציפי עם מעט מים, עסי בעדינות בתנועות מעגליות ושטפי.';

  @override
  String get catUsageCleanser =>
      'שלב ראשון: עסי על עור יבש, המסי, שטפי. שלב שני: הקציפי עם מים ועסי בעדינות.';

  @override
  String get catUsageRetinoid =>
      'כמות בגודל אפונה על עור יבש, הימנעי מאזור העיניים. ערב בלבד, בהדרגה.';

  @override
  String get catUsageToner =>
      'טפחי כמה טיפות בכפות הידיים על עור נקי, לפני הסרומים.';

  @override
  String get catUsageSerum =>
      'כמה טיפות על עור נקי. המתיני לספיגה לפני השלב הבא.';

  @override
  String get catUsageMoisturizer => 'מרחי שכבה אחידה לנעילת הלחות והרגעת העור.';

  @override
  String get catUsageOil =>
      'חממי כמה טיפות בין כפות הידיים ולחצי על העור כשלב אחרון.';

  @override
  String get catUsageSpf =>
      'כמות נדיבה (אורך אצבע - על שתי אצבעות) כשלב אחרון בבוקר, גם ביום מעונן.';

  @override
  String get scheduleNoProducts => 'לא נבחרו מוצרים עדיין';

  @override
  String get scheduleConflictInMorning =>
      'יש התנגשות בשגרת בוקר. אפשר לתקן בלחיצה.';

  @override
  String get scheduleConflictInEvening =>
      'יש התנגשות בשגרת ערב. אפשר לתקן בלחיצה.';

  @override
  String get scheduleOccasional => 'לא לשימוש יומי';

  @override
  String get scheduleDaily => 'יומיים';

  @override
  String get scheduleWeeklyView => 'מבט שבועי';

  @override
  String get scheduleTapConflictDay => 'הקישי על יום מסומן';

  @override
  String get scheduleProductsPerDay => 'מספר מוצרים ביום';

  @override
  String get scheduleProductWillRemain =>
      'המוצר יישאר בכל שאר הימים. אפשר להשאיר כך.';

  @override
  String scheduleConflictHeader(Object day) {
    return 'שילוב לא מומלץ ביום $day';
  }

  @override
  String get scheduleConflictInstruction => 'הקישי «הסר» על אחד מהם כדי לפתור';

  @override
  String get scheduleClose => 'סגור';

  @override
  String scheduleRemoveFrom(Object day) {
    return 'הסר מ$day';
  }

  @override
  String get scheduleRemove => 'הסר';

  @override
  String get scheduleNoMix => 'לא לשלב יחד';

  @override
  String get scheduleRecommendedDaily => 'מומלץ: כל יום';

  @override
  String scheduleRecommendedWeekly(Object max) {
    return 'מומלץ: עד $max פעמים בשבוע';
  }

  @override
  String get scheduleCountEveryDay => 'כל יום';

  @override
  String scheduleOverCap(Object max) {
    return 'מעבר למומלץ. כדאי להפחית עד $max ימים.';
  }

  @override
  String get scheduleNoDaySelected => 'לא נבחר יום. המוצר לא ישובץ.';

  @override
  String get scheduleSaveFinish => 'סיום ושמירת השגרה';

  @override
  String get scheduleAlertsOne => 'התראה אחת';

  @override
  String scheduleAlertsCount(int count) {
    return '$count התראות';
  }

  @override
  String scheduleAlertsConflicts(int count) {
    return '$count שילובים בעיתיים';
  }

  @override
  String scheduleAlertsOverFreq(int count) {
    return '$count שימושים מעל המומלץ';
  }

  @override
  String get scheduleConflictsSection => 'שילובים לא מומלצים';

  @override
  String get scheduleOverFreqSection => 'חריגה בתדירות';

  @override
  String get scheduleByFrequency => 'לפי תדירות';

  @override
  String scheduleDayChip(Object day) {
    return 'יום $day';
  }

  @override
  String get scheduleSoftAlertsNote =>
      'כל ההתראות הן רכות. מותר לחרוג, רק מזכירים.';

  @override
  String get orderInstruction => 'גררי את המוצרים כדי לסדר את השגרה שלך';

  @override
  String get orderNoProducts => 'לא נבחרו מוצרים';

  @override
  String get orderResetToRecommended => 'איפוס לסדר המומלץ';

  @override
  String get orderSaveFinish => 'סיום והתחלה';

  @override
  String get orderSaveNew => 'שמירת הסדר החדש';

  @override
  String get settingsGreeting => 'שלום';

  @override
  String get settingsWelcome => 'ברוכה הבאה ל־The Glow Protocol';

  @override
  String get settingsSectionRoutine => 'שגרת הטיפוח שלי';

  @override
  String get settingsSectionData => 'נתונים';

  @override
  String get settingsExportSubtitle => 'גיבוי מקומי של הנתונים';

  @override
  String get settingsSectionInfo => 'מידע';

  @override
  String get settingsAbout => 'אודות';

  @override
  String settingsAboutSubtitle(Object version) {
    return 'גרסה $version • יומן שינויים';
  }

  @override
  String get settingsCheckUpdates => 'בדוק עדכונים';

  @override
  String get settingsCheckUpdatesSubtitle => 'בדיקת גרסה עדכנית';

  @override
  String get settingsPremium => 'הפעלת רישיון';

  @override
  String get settingsPremiumSubtitle => 'גיבוי ושחזור בענן';

  @override
  String get settingsSectionAccount => 'חשבון';

  @override
  String get settingsLogout => 'התנתקות';

  @override
  String get settingsLogoutSubtitle => 'איפוס פרופיל וחזרה להתחלה';

  @override
  String get settingsLogoutConfirmContent =>
      'פעולה זו תאפס את הפרופיל שלך ותחזיר אותך למסך ההתחלה. הנתונים שלך יישמרו.';

  @override
  String get settingsLogoutConfirmBtn => 'התנתקי';

  @override
  String aboutVersionLabel(Object version) {
    return 'גרסה $version';
  }

  @override
  String get exportDataTitle => 'ייצוא נתונים';

  @override
  String get exportDataDesc => 'שמור גיבוי של כל הנתונים שלך כארכיון ZIP';

  @override
  String get exportDataAction => 'ייצוא';

  @override
  String get importDataTitle => 'ייבוא נתונים';

  @override
  String get importDataDesc => 'שחזר נתונים מגיבוי קיים (החלפה מלאה או מיזוג)';

  @override
  String get importDataAction => 'ייבוא';

  @override
  String get exportSuccess => 'הייצוא הושלם בהצלחה';

  @override
  String exportError(Object error) {
    return 'שגיאה בייצוא: $error';
  }

  @override
  String importError(Object error) {
    return 'שגיאה בייבוא: $error';
  }

  @override
  String get importFileReadError => 'לא ניתן לקרוא את הקובץ';

  @override
  String get importInvalidFile => 'קובץ לא תקין';

  @override
  String get importDialogQuestion => 'כיצד לטפל בנתונים הקיימים?';

  @override
  String get importReplaceSuccess => 'הנתונים הוחלפו בהצלחה';

  @override
  String get importMergeNoConflicts => 'המיזוג הושלם. לא נמצאו התנגשויות.';

  @override
  String get updateAllUpToDate => 'הכל מעודכן';

  @override
  String get updateGoBack => 'חזור';

  @override
  String get updateDataIntact => 'הנתונים שלך שמורים ועדיין קיימים';

  @override
  String get updateExportBefore => 'לפני ההמשך:';

  @override
  String get updateBackupAction => 'גבי נתונים';

  @override
  String updateNewProducts(Object count) {
    return 'מוצרים חדשים ($count)';
  }

  @override
  String get updateNewProductsDesc =>
      'מוצרים אלה לא נבחרו עדיין. הוסיפי אותם בבחירת המוצרים';

  @override
  String updateDeprecated(Object count) {
    return 'מוצרים שאינם מומלצים עוד ($count)';
  }

  @override
  String get updateDeprecatedDesc =>
      'מוצרים אלה נמצאים ברשימה שלך אך אינם מומלצים עוד';

  @override
  String get updateAcknowledge => 'הבנתי, המשך';

  @override
  String get mergeNoData => 'אין נתונים למיזוג';

  @override
  String get mergeCompleting => 'ממזג...';

  @override
  String get mergeFinish => 'סיים';

  @override
  String mergeProgressCounter(Object current, Object total) {
    return 'התנגשות $current מתוך $total';
  }

  @override
  String mergeRecordInfo(Object recordType, Object recordId) {
    return 'סוג: $recordType  ·  מזהה: $recordId';
  }

  @override
  String get mergeChooseVersion => 'בחרי איזו גרסה לשמור:';

  @override
  String get mergeKeepLocal => 'שמור גרסה מקומית';

  @override
  String get mergeKeepLocalDesc => 'המשיכי עם הנתונים הנוכחיים במכשיר';

  @override
  String get mergeUseArchive => 'השתמשי בגרסת הגיבוי';

  @override
  String get mergeUseArchiveDesc => 'החלף עם הנתונים מקובץ הגיבוי';

  @override
  String get mergeAllResolved => 'כל ההתנגשויות נפתרו';

  @override
  String get mergeClickFinish => 'לחצי על \"סיים\" להחלת המיזוג';

  @override
  String get mergeSuccess => 'המיזוג הושלם בהצלחה';

  @override
  String get premiumTitle => 'גיבוי לענן, בקרוב';

  @override
  String get premiumDescWeb =>
      'הזן מפתח הפעלה כדי לאפשר גיבוי ושחזור אוטומטי בין מכשירים';

  @override
  String get premiumDescAndroid => 'תכונה זו זמינה בגרסת הווב בלבד';

  @override
  String get premiumKeyLabel => 'מפתח הפעלה';

  @override
  String get premiumActivate => 'הפעל';

  @override
  String get skinLogNotesHint => 'הערות על העור היום...';

  @override
  String get skinLogAddPhotoLabel => 'הוסיפי תמונה';

  @override
  String get skinLogTakePhoto => 'צלמי תמונה';

  @override
  String get skinLogGallery => 'בחרי מהגלריה';

  @override
  String get skinLogWebStorageWarning =>
      'תמונות בדפדפן עשויות להימחק על ידי Safari. גבי את הנתונים שלך.';

  @override
  String get dayDetailNoData => 'אין נתונים ליום זה';

  @override
  String get dayDetailJournalTooltip => 'יומן עור';

  @override
  String get streakDaysInRow => 'ימים ברצף';

  @override
  String get streakOnTrack => 'את בדרך הנכונה לזוהר מושלם!';

  @override
  String get streakStartToday => 'כל יום נחשב. נתחיל היום ✨';

  @override
  String streakPersonalBest(Object days) {
    return 'שיא אישי · $days ימים';
  }

  @override
  String get streakNoGraces => 'אין עוד \" אופס, פיספסתי...\"';

  @override
  String streakGracesLeft(Object count) {
    return 'נשארו $count \"אופס, פיספסתי...\"';
  }

  @override
  String streakSemanticDays(Object count) {
    return '$count ימים ברצף';
  }

  @override
  String get routineItemDone => 'בוצע';

  @override
  String get routineItemNotDone => 'לא בוצע';

  @override
  String get routineItemFlexibleSlots => 'בוקר • ערב';

  @override
  String get routineItemDeprecatedPill => 'לא מומלץ';

  @override
  String get routineItemDeprecatedWarning => 'מוצר זה אינו מומלץ עוד';

  @override
  String get backupReminderText => 'מומלץ לגבות את הנתונים שלך';

  @override
  String get backupNowAction => 'גבי';

  @override
  String get categoryItemsSuffix => 'פריטים';

  @override
  String get fixedSlotMorningOnly => 'בוקר בלבד';

  @override
  String get fixedSlotEveningOnly => 'ערב בלבד';

  @override
  String get skinStateCalm => 'רגוע';

  @override
  String get skinStateMoist => 'לח';

  @override
  String get skinStateOily => 'שומני';

  @override
  String get weekdayOverCapWarning => 'מעבר למומלץ. כדאי להפחית.';

  @override
  String get customProductTitle => 'הוספת מוצר משלי';

  @override
  String get customProductPhotoLabel => 'הוספת תמונה (לא חובה)';

  @override
  String get customProductNameLabel => 'שם המוצר';

  @override
  String get customProductNameHint => 'לדוגמה: סרם לחות אישי';

  @override
  String get customProductCategoryLabel => 'קטגוריה';

  @override
  String get customProductSlotLabel => 'מתי משתמשים בו?';

  @override
  String get customProductSlotBoth => 'בוקר + ערב';

  @override
  String get customProductFrequencyLabel => 'תדירות שימוש';

  @override
  String get customProductFrequencyWeekly => 'שבועי';

  @override
  String get customProductFrequencyDaily => 'כל יום';

  @override
  String get customProductTimesPerWeekLabel => 'פעמים בשבוע:';

  @override
  String get customProductSave => 'הוספה למדף';

  @override
  String get customProductEditButton => 'עריכת מוצר';

  @override
  String get customProductEditTitle => 'עריכת מוצר';

  @override
  String get customProductEditSave => 'שמירת שינויים';

  @override
  String get customProductDeleteButton => 'הסרת מוצר';

  @override
  String get customProductDeleteConfirmTitle => 'הסרת מוצר';

  @override
  String get customProductDeleteConfirmBody =>
      'המוצר יוסר לצמיתות מהרשימה שלך. פעולה זו אינה הפיכה.';

  @override
  String get customProductDeleteConfirmAction => 'הסרה';

  @override
  String get productRemoveFromShelfConfirmBody => 'המוצר יוסר מהשגרה שלך.';

  @override
  String get customProductCommentLabel => 'הערה';

  @override
  String get customProductCommentHint => 'הערה אישית על המוצר (לא חובה)';

  @override
  String customProductCommentLanguageNote(Object language) {
    return '(נכתב ב$language)';
  }

  @override
  String scheduleConflictWarning(Object slot) {
    return 'עדיין יש ימי התנגשות ב$slot';
  }

  @override
  String get slotMorningRoutine => 'שגרת בוקר';

  @override
  String get slotEveningRoutine => 'שגרת ערב';

  @override
  String scheduleStepBadge(int n, int total) {
    return 'שלב $n מתוך $total';
  }

  @override
  String get scheduleGuidedBothSlots =>
      'תזמני קודם את שגרת הבוקר, וכך נמשיך יחד גם לשגרת הערב. אפשר לחרוג מהמומלץ, רק נזכיר.';

  @override
  String scheduleGuidedSingleSlot(Object routine) {
    return 'באילו ימים להשתמש בכל מוצר ב$routine…';
  }

  @override
  String scheduleContinueTo(Object routine) {
    return 'המשך ל$routine';
  }

  @override
  String scheduleNextStepPending(Object routine) {
    return 'נשאר עוד שלב. $routine מחכה לתזמון';
  }

  @override
  String scheduleConflictWarningCount(int count, Object label) {
    return 'עדיין יש $count ימי התנגשות ב$label';
  }

  @override
  String scheduleZeroDayError(Object slot) {
    return 'מוצר אחד או יותר ב$slot לא משויך לאף יום. בחרי ימים לפני שממשיכים.';
  }

  @override
  String get scheduleCustomizeDays => 'בחירת ימים';

  @override
  String get scheduleDailyDefaultSuffix => '· כברירת מחדל כל יום';

  @override
  String get scheduleDailyCollapse => 'סגירה';

  @override
  String get scheduleBadgeNoneSelected => 'לא נבחר';

  @override
  String get aboutDisclaimer =>
      'האפליקציה מיועדת למעקב אישי בלבד ואינה מהווה ייעוץ רפואי או קוסמטי.';

  @override
  String get aboutPrivacyPolicyLink => 'מדיניות פרטיות';

  @override
  String get settingsSectionLanguage => 'שפה';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSubtitle => 'עברית / אנגלית';

  @override
  String get settingsLanguageHebrew => 'עברית';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get calendarDayFullSun => 'ראשון';

  @override
  String get calendarDayFullMon => 'שני';

  @override
  String get calendarDayFullTue => 'שלישי';

  @override
  String get calendarDayFullWed => 'רביעי';

  @override
  String get calendarDayFullThu => 'חמישי';

  @override
  String get calendarDayFullFri => 'שישי';

  @override
  String get calendarDayFullSat => 'שבת';

  @override
  String get settingsProfileEdit => 'עריכת פרופיל';

  @override
  String get settingsProfileGuest => 'אורחת';

  @override
  String get settingsProfileNameLabel => 'השם שלך';

  @override
  String get settingsProfileNameHint => 'הכניסי שם';

  @override
  String get settingsProfileSave => 'שמירה';

  @override
  String get backupNeverBacked => 'לא גיבית את הנתונים שלך מעולם';

  @override
  String backupDaysAgo(int days) {
    return 'גיבוי אחרון לפני $days ימים';
  }

  @override
  String get onboardingSelectLanguage => 'בחרי שפה';

  @override
  String get onboardingFrequencyWeeklyShort => 'שבועי';

  @override
  String get onboardingWelcomeNeutral => 'ברוכה הבאה';

  @override
  String get onboardingTellUsNeutral => 'כמה פרטים כדי להתחיל';

  @override
  String get onboardingStartNeutral => 'נתחיל?';

  @override
  String get continueActionNeutral => 'המשך';

  @override
  String get addCustomProductCtaTitle => 'הוסיפי מוצר חדש';

  @override
  String get addCustomProductCtaSub => 'המוצר שלך לא ברשימה?';

  @override
  String get productSelManualCardTitle => 'הוספה ידנית';

  @override
  String get productSelManualCardSub => 'הזינו מוצר שלא נמצא בחיפוש';

  @override
  String get myProductsSearchHint => 'חיפוש מוצרים...';

  @override
  String get barcodeScan => 'סריקת ברקוד';

  @override
  String get barcodeScanHint => 'כוונו את הברקוד למסגרת לזיהוי אוטומטי';

  @override
  String get barcodeScanFound => 'ברקוד זוהה';

  @override
  String get barcodeScanLookingUp => 'מחפש במאגרי מוצרים…';

  @override
  String get barcodeScanProductFound => 'מוצר נמצא';

  @override
  String get barcodeScanProductNotFound => 'המוצר לא נמצא במאגרים';

  @override
  String get barcodeScanAddManually => 'הוסיפי ידנית';

  @override
  String get barcodeScanAddProduct => 'הוסיפי מוצר';

  @override
  String get barcodeScanRetry => 'סריקה חוזרת';

  @override
  String get barcodeScanPermissionDenied => 'נדרשת הרשאת מצלמה לסריקת ברקודים';

  @override
  String get barcodeScanIngredients => 'רכיבים';

  @override
  String get barcodeScanCategoryHint => 'הצעת קטגוריה';

  @override
  String get barcodeScanFromScanLabel => 'מידע מהסריקה';

  @override
  String get barcodeScanMasterProductFound => 'מוצר מוכר';

  @override
  String get barcodeScanAddToRoutine => 'הוסיפי לשגרה';

  @override
  String get barcodeScanAlreadyInRoutine => 'כבר בשגרה שלך';

  @override
  String get barcodeScanFromGallery => 'סריקה מתמונה בגלריה';

  @override
  String get barcodeScanAnalyzing => 'מנתח תמונה…';

  @override
  String get homeViewWeek => 'השבוע';

  @override
  String get homeWeekGlanceTitle => 'השבוע שלי';

  @override
  String get collectionHealthCard => 'בריאות המדף';

  @override
  String get collectionAllProducts => 'כל המוצרים';

  @override
  String get collectionOnShelf => 'במדף';

  @override
  String get collectionInRoutines => 'בשגרות';

  @override
  String get collectionToCheck => 'לבדיקה';

  @override
  String get collectionProBanner => 'נסי PRO כדי לעקוב אחרי חיי המדף';

  @override
  String get collectionSortByCategory => 'לפי קטגוריה';

  @override
  String get collectionCountSuffix => 'מוצרים';

  @override
  String get lifecycleTitle => 'מחזור חיים';

  @override
  String get lifecycleOpenedDate => 'נפתח בתאריך';

  @override
  String get lifecycleNotOpened => 'טרם נפתח';

  @override
  String get lifecycleSetOpenedDate => 'הגדירי תאריך פתיחה';

  @override
  String lifecyclePao(Object months) {
    return 'PAO $months חודשים';
  }

  @override
  String lifecycleMonthsLeft(Object months) {
    return 'נותרו $months חודשים';
  }

  @override
  String get lifecycleExpired => 'פג תוקף';

  @override
  String get lifecycleNotify => 'התראה לקראת סיום';

  @override
  String get lifecycleInUse => 'בשימוש';

  @override
  String get lifecycleFinished => 'סיימתי אותו';

  @override
  String get lifecycleDiscarded => 'נזרק';

  @override
  String get detailIngredients => 'מרכיבים עיקריים';

  @override
  String get collectionTabInUse => 'בשימוש';

  @override
  String get collectionTabSealed => 'סגורים';

  @override
  String get collectionTabArchive => 'ארכיון';

  @override
  String collectionAttentionCount(int count) {
    return '$count מוצרים לסיום בקרוב';
  }

  @override
  String get collectionHealthOk => 'המדף במצב טוב';

  @override
  String get collectionSealedBadge => 'סגור';

  @override
  String get collectionArchiveBadge => 'בארכיון';

  @override
  String get collectionSealedEmpty => 'אין מוצרים סגורים';

  @override
  String get collectionArchiveEmpty => 'הארכיון ריק';

  @override
  String homeAttentionCount(int count) {
    return '$count מוצרים כדאי לסיים בקרוב';
  }

  @override
  String get homeAttentionNone =>
      'ייתכן שיש במדף שלך דברים שכדאי לשים לב אליהם';

  @override
  String get settingsAccountFree => 'חשבון חינמי';

  @override
  String get settingsAccountPro => 'מנויית Glow PRO';

  @override
  String get settingsProTitle => 'שדרגי ל־Glow PRO';

  @override
  String get settingsProSubtitle => 'מעקב התקדמות, ניהול מדף, תוקף ו־PAO';

  @override
  String get settingsDemoTitle => 'תצוגת הדגמה';

  @override
  String get settingsDemoDesc =>
      'החליפי בין חוויה חינמית למנויית PRO כדי לראות איך המסכים משתנים.';

  @override
  String get settingsDemoFree => 'חינמי';

  @override
  String get settingsDemoMilestone => 'יום ציון דרך (יום 7)';

  @override
  String get settingsDemoMilestoneDesc => 'מציג את רגע ההמרה בבאנר הרצף';

  @override
  String get streakMilestoneTitle => 'שבוע שלם של התמדה! 🎉';

  @override
  String get streakMilestoneSub => 'זה הזמן המושלם לתעד את נקודת ההתחלה';

  @override
  String get streakPitchTitle => 'רוצה לראות אם זה עובד?';

  @override
  String get streakPitchSub => 'צלמי תמונת ׳לפני׳, ובעוד שבועיים תשווי';

  @override
  String get streakPitchCta => 'נסי';

  @override
  String get productSelV3Title => 'אילו מוצרים יש לכם?';

  @override
  String get productSelV3Subtitle =>
      'הוסיפו את המוצרים שיש לכם. אנחנו נסדר אותם לפי שלבים ונבנה מהם שגרה.';

  @override
  String get productSelV3SearchTab => 'חיפוש';

  @override
  String get productSelV3ScanTab => 'סריקה';

  @override
  String get productSelV3SearchHint => 'חפשו מוצר או מותג...';

  @override
  String get productSelV3Popular => 'מוצרים נפוצים';

  @override
  String get productSelV3AddManual => 'לא מצאתם? הוסיפו ידנית';

  @override
  String productSelV3SelectedCount(int count) {
    return '$count מוצרים נבחרו';
  }

  @override
  String get productSelV3ShelfCTA => 'סידור המדף שלי';

  @override
  String get categoryReviewTitle => 'סידרנו את המוצרים לפי שלבים';

  @override
  String get categoryReviewSubtitle =>
      'בדקו שהקטגוריות נכונות. אפשר לשנות בלחיצה.';

  @override
  String get categoryReviewChangeCategory => 'שינוי קטגוריה';

  @override
  String get categoryReviewRemove => 'הסרה';

  @override
  String get categoryReviewAddMore => 'הוספת מוצרים נוספים';

  @override
  String get categoryReviewCTA => 'המשך לבחירת ימים';

  @override
  String get categoryReviewEmpty => 'אין מוצרים במדף עדיין';

  @override
  String get scheduleHeaderWeekly => 'תזמון שבועי';

  @override
  String scheduleStepLabel(Object slot) {
    return 'שלב 1 מתוך 2 · $slot';
  }

  @override
  String get scheduleSubtitleV3 =>
      'בחרו באילו ימים להשתמש בכל מוצר. נציג הערות רק כשצריך.';

  @override
  String get scheduleContextChipMorning => 'שגרת בוקר';

  @override
  String get scheduleContextChipEvening => 'שגרת ערב';

  @override
  String get scheduleContinueToOrder => 'המשיכי לסדר המריחה';

  @override
  String daySummaryNoteCount(int count, Object day) {
    return '$count הערות ליום $day';
  }

  @override
  String get daySummaryNoteSub => 'יש שילוב מוצרים או שימוש גבוה שכדאי לבדוק';

  @override
  String daySummaryAllGood(Object day) {
    return 'יום $day נראה טוב, אין הערות.';
  }

  @override
  String issueSheetTitle(Object day) {
    return 'הערות ליום $day';
  }

  @override
  String get issueSheetSubtitle =>
      'אפשר לשנות רק את היום הזה, או להשאיר את השגרה כמו שהיא.';

  @override
  String get issueSheetConflictSection => 'לא מומלץ לשלב באותו יום';

  @override
  String get issueSheetOveruseSection => 'שימוש גבוה מההמלצה';

  @override
  String issueSheetOveruseBody(int count, int cap) {
    return 'המוצר מתוכנן ל־$count פעמים בשבוע, וההמלצה היא עד $cap.';
  }

  @override
  String get issueActionRemoveFromDay => 'הסרה מהיום הזה';

  @override
  String get issueActionKeep => 'להשאיר בכל זאת';

  @override
  String get issueActionAutoFix => 'התאמה אוטומטית';

  @override
  String issueActionRemoveFromDayNamed(Object name) {
    return 'הסרת $name מהיום הזה';
  }

  @override
  String get issueActionAutoDistribute => 'התאמה אוטומטית';

  @override
  String get issueActionReviewNotes => 'בדיקת ההערות';

  @override
  String get autoFixUndo => 'שחזר';

  @override
  String get autoFixKeep => 'שמור שינויים';

  @override
  String get autoFixAppliedFallback => 'התאמנו את השגרה כדי לפתור את ההתנגשות';

  @override
  String get chipPossibleConflict => 'התנגשות אפשרית';

  @override
  String get chipHighUsage => 'שימוש גבוה';

  @override
  String get orderHeaderMorning => 'סדר המריחה בבוקר';

  @override
  String get orderHeaderEvening => 'סדר המריחה בערב';

  @override
  String orderStepLabel(Object slot) {
    return 'שלב 2 מתוך 2 · $slot';
  }

  @override
  String get orderSubtitleV3 =>
      'סידרנו את המוצרים לפי סדר שימוש מומלץ. אפשר לגרור כדי לשנות.';

  @override
  String get orderViewGeneral => 'סדר כללי';

  @override
  String get orderAdvancedTitle => 'אפשרויות מתקדמות';

  @override
  String get orderAdvancedSub => 'שינוי סדר לפי יום, רק אם צריך';

  @override
  String get orderPerDayTitle => 'שינוי סדר לפי יום';

  @override
  String get orderPerDayMicrocopy =>
      'ברירת המחדל מתאימה לרוב המשתמשים. שינוי לפי יום נדרש רק אם יש ימים עם מוצרים מיוחדים.';

  @override
  String get orderPerDayCustomBadge => 'סדר מותאם';

  @override
  String get orderPerDayClearDay => 'בטל סדר יומי';

  @override
  String orderPerDaySheetTitle(String day) {
    return 'סדר יום $day';
  }

  @override
  String get orderCtaMorning => 'נראה טוב, נמשיך לשגרת הערב';

  @override
  String get orderCtaFinish => 'סיום והצגת השגרה שלי';

  @override
  String get eveningTransitionTitle => 'עכשיו נעבור לשגרת הערב';

  @override
  String get eveningTransitionBody =>
      'נשתמש באותם מוצרים ונציע ימים וסדר שמתאימים לערב.';

  @override
  String get addProductTitle => 'הוספת מוצר';

  @override
  String get addProductConfirmCategory => 'לאיזה שלב המוצר שייך?';

  @override
  String get addProductChooseSlot => 'מתי משתמשים במוצר?';

  @override
  String get addProductSlotMorning => 'בוקר';

  @override
  String get addProductSlotEvening => 'ערב';

  @override
  String get addProductSlotBoth => 'שניהם';

  @override
  String get addProductChooseDays => 'באילו ימים?';

  @override
  String get addProductPlacementTitle => 'המיקום המוצע';

  @override
  String addProductPlacement(Object before, Object after) {
    return 'נמקם אותו אחרי $before ולפני $after';
  }

  @override
  String addProductPlacementAfter(Object before) {
    return 'נמקם אותו אחרי $before';
  }

  @override
  String get addProductPlacementGeneric => 'נמקם אותו במקום המתאים בשגרה';

  @override
  String get addProductCta => 'הוספה לשגרה';

  @override
  String get addProductSuccess => 'המוצר נוסף לשגרה';

  @override
  String addProductSuccessSubMorning(Object days) {
    return 'הוספנו אותו לשגרת הבוקר בימים $days.';
  }

  @override
  String addProductSuccessSubEvening(Object days) {
    return 'הוספנו אותו לשגרת הערב בימים $days.';
  }

  @override
  String addProductSuccessSubBoth(Object days) {
    return 'הוספנו אותו לשגרת הבוקר והערב בימים $days.';
  }

  @override
  String get commonDone => 'סיום';

  @override
  String get welcomeAppName => 'The Glow Protocol';

  @override
  String welcomeGreeting(String name, String weekday) {
    return 'ברוכה השבה, $name · $weekday';
  }

  @override
  String get welcomeStreakLabel => 'ימים ברצף';

  @override
  String get welcomeCta => 'לשגרה של היום';

  @override
  String get welcomeHint => 'ממשיכים לשגרה אוטומטית · הקישו לדילוג';

  @override
  String welcomeGraceLabel(int n) {
    return 'נשארו $n \"אופס פיספסתי...\" השבוע';
  }

  @override
  String welcomeGraceMissedCount(int n) {
    return '$n פעמים פיספסתי השבוע';
  }

  @override
  String get welcomePersonalBestLabel => 'שיא אישי';

  @override
  String welcomeDaysCount(int n) {
    return '$n ימים';
  }

  @override
  String get welcomeHeadline0 => 'התחלה חדשה ✨';

  @override
  String get welcomeSubline0 => 'יום אחד בכיף ואת כבר בדרך.';

  @override
  String get welcomeHeadline1 => 'יום ראשון של זוהר ✨';

  @override
  String get welcomeSubline1 => 'יום ראשון בשגרה — כל מסע מתחיל בצעד הראשון.';

  @override
  String welcomeHeadline2to4(int streak) {
    return '$streak ימים של הרגל מתהווה ✨';
  }

  @override
  String welcomeSubline2to4(int streak) {
    return 'שמרת על השגרה $streak ימים ברצף — המומנטום בנייה.';
  }

  @override
  String welcomeHeadline5to9(int streak) {
    return '$streak ימים של זוהר רצוף ✨';
  }

  @override
  String welcomeSubline5to9(int streak) {
    return 'שמרת על השגרה $streak ימים ברצף — את בדרך הנכונה לזוהר מושלם.';
  }

  @override
  String welcomeHeadline10to29(int streak) {
    return '$streak ימים — את בוהקת! ✨';
  }

  @override
  String welcomeSubline10to29(int streak) {
    return 'עשרה ימים ומעלה של עקביות — העור שלך מרגיש את זה.';
  }

  @override
  String welcomeHeadline30plus(int streak) {
    return '$streak ימים! מדהים! 🌟';
  }

  @override
  String get welcomeSubline30plus =>
      'חודש ויותר של שגרת טיפוח עקבית — את אגדה!';

  @override
  String get weekGlanceTitle => 'שגרת השבוע שלי';

  @override
  String get weekGlanceStartGlowingCta => 'הכול מוכן, מתחילים לזרוח!';

  @override
  String get weekGlanceEntrySubtitle => 'מה בשגרת הבוקר ומה בשגרת הערב בכל יום';

  @override
  String get weekGlanceEditButton => 'עריכה';

  @override
  String get weekGlanceStatusOkTitle => 'השגרה נראית תקינה';

  @override
  String get weekGlanceStatusOkSubMorning => 'אין התנגשויות בשגרת הבוקר';

  @override
  String get weekGlanceStatusOkSubEvening => 'אין התנגשויות בשגרת הערב';

  @override
  String get weekGlanceIssueSub => 'יש מוצרים שכדאי לבדוק';

  @override
  String get weekGlanceCheckIssues => 'בדיקת הערות';

  @override
  String get weekGlanceConflictSheetSubtitle =>
      'שילובים שכדאי לשנות בימים מסוימים';

  @override
  String get weekGlanceConflictNotMix => 'לא מומלץ לשלב יחד';

  @override
  String get weekGlanceConflictExplanation =>
      'ניאצינמיד ורטינול עשויים להפחית זה את יעילות זה כשמשתמשים בהם באותו ערב. מומלץ להפריד לערבים שונים.';

  @override
  String weekGlanceIssueTitle(int count, String slot) {
    return '$count הערות בשגרת $slot';
  }

  @override
  String weekGlanceEditRoutine(String slot) {
    return 'עריכת שגרת $slot';
  }

  @override
  String get customProductBrandLabel => 'מותג';

  @override
  String get customProductBrandHint => 'לדוגמה: The Ordinary';

  @override
  String get customProductCategoryHint => 'בחרו קטגוריה...';

  @override
  String get customProductSubCategoryLabel => 'תת־קטגוריה';

  @override
  String get customProductSubCategoryHint => 'בחרו תת־קטגוריה...';

  @override
  String get customProductMoreDetails => 'פרטים נוספים (רשות)';

  @override
  String get customProductScanTitle => 'מצאנו את המוצר!';

  @override
  String get customProductScanSubtitle =>
      'מילאנו את הפרטים מהסריקה — בדקו, התאימו במידת הצורך ואשרו הוספה למדף.';

  @override
  String get customProductAutofillBanner => 'מולא אוטומטית מהסריקה';

  @override
  String get customProductAutofillBannerSub => 'אפשר לערוך כל פרט לפני ההוספה';

  @override
  String get customProductReplacePhoto => 'החלפת תמונה';

  @override
  String get customProductRemovePhoto => 'הסרה';

  @override
  String get customProductScanAgain => 'סריקה נוספת';

  @override
  String customProductScanImagesHeading(int count) {
    return 'נמצאו $count תמונות לבחירה — בחרו אחת לשמירה';
  }

  @override
  String get customProductScanImagesHint =>
      'התמונה שתבחרו תישמר עם המוצר. אפשר גם להעלות תמונה משלכם.';

  @override
  String get customProductScanOwnPhoto => 'תמונה משלי';

  @override
  String get barcodeScanWebTitle => 'סריקה ממצלמה אינה זמינה בדפדפן';

  @override
  String get barcodeScanWebSub => 'בחרו תמונה עם ברקוד מהגלריה';

  @override
  String get customProductFormSubtitle =>
      'מלאו את פרטי המוצר. שדות עם * הם חובה.';

  @override
  String get customProductWhenLabel => 'מתי משתמשים בו?';

  @override
  String get customProductSubCategoryDisabledHint => 'בחרו קטגוריה תחילה';

  @override
  String get customProductSubCategoryNone => 'ללא';

  @override
  String get customProductNotesLabel => 'הערות';

  @override
  String get customProductIngredientsLabel => 'רכיבים (INCI)';

  @override
  String get customProductIngredientsHint => 'Aqua, Glycerin, Niacinamide...';

  @override
  String get customProductIngredientsHelper => 'מפרידים בפסיקים בין הרכיבים';

  @override
  String get customProductSmartCompleteTitle => 'השלמה חכמה מהאינטרנט';

  @override
  String get customProductSmartCompleteBody =>
      'נמצא עבורכם קטגוריה, תמונה, רכיבים ותזמון לפי שם המוצר. כל פרט ניתן לעריכה אחר כך.';

  @override
  String get customProductSmartCompleteButton => 'מצאו לי את הפרטים';

  @override
  String get customProductSmartCompleteManual => 'אמלא ידנית במקום';

  @override
  String get customProductSmartCompleteLockNote =>
      'שאר השדות ייפתחו אחרי ההשלמה';

  @override
  String get customProductSmartCompleteSearching => 'מחפשים את הפרטים…';

  @override
  String get customProductSmartCompleteNotFound =>
      'לא מצאנו פרטים נוספים — אפשר למלא ידנית.';

  @override
  String get unsavedChangesTitle => 'שינויים לא שמורים';

  @override
  String get unsavedChangesMessage => 'האם לשמור את השינויים לפני יציאה?';

  @override
  String get discardChangesAction => 'בטל שינויים';

  @override
  String get productDetailViewDetails => 'לפרטים המלאים';

  @override
  String get routineReadyTitle => 'השגרה שלך מוכנה ✨';

  @override
  String routineReadyCounts(int total, int morning, int evening) {
    return '$total מוצרים סודרו · $morning בבוקר, $evening בערב';
  }

  @override
  String get routineReadyChangesHeader => 'מה סידרנו בשבילך';

  @override
  String get routineReadyChangesExplainer =>
      'התאמות קטנות שעשינו עבור שגרה בטוחה ויעילה — תמיד אפשר לשנות.';

  @override
  String get routineReadyAdvisoriesHeader => 'כדאי לשים לב';

  @override
  String get routineReadyAdvisoriesExplainer =>
      'לא חסמנו — רק המלצה קטנה לתשומת ליבך.';

  @override
  String get routineReadyNothingToReport =>
      'לא נדרשו התאמות — השגרה מסודרת ומוכנה.';

  @override
  String get routineReadyCta => 'הצגת השגרה שלי';

  @override
  String routineReadyReviewSlotCta(String slot) {
    return 'נסקור את שגרת ה$slot';
  }
}

/// The translations for Hebrew, as used in Morocco (`he_MA`).
class AppLocalizationsHeMa extends AppLocalizationsHe {
  AppLocalizationsHeMa() : super('he_MA');

  @override
  String get warningMute => 'השתק';

  @override
  String get backupReminderMessage => 'גבה את הנתונים שלך';

  @override
  String get continueAction => 'המשך';

  @override
  String get homeTapImageToDone => 'הקש על התמונה לסימון בוצע';

  @override
  String get homeTapProductToDone => 'הקש על מוצר לסימון בוצע';

  @override
  String get homeAddProducts => 'הוסף מוצרים';

  @override
  String homeDayLabel(Object day) {
    return 'יום $day';
  }

  @override
  String get journalCtaSubtitle => 'תעד את התקדמותך';

  @override
  String get journalCtaButton => 'תעד עכשיו';

  @override
  String get weeklyReminderBody =>
      'צלם תמונה קצרה ורשום איך העור מרגיש — פעם בשבוע, כדי לראות את ההתקדמות לאורך זמן.';

  @override
  String get weeklyReminderNotesHint =>
      'איך העור מרגיש היום? יובש, אדמומיות, פצעונים...';

  @override
  String get weeklyReminderCapture => 'צלם';

  @override
  String get weeklyReminderNeverShow => 'אל תציג שוב';

  @override
  String get onboardingSkip => 'דלג';

  @override
  String get onboardingWelcome => 'ברוך הבא';

  @override
  String get onboardingProductInstruction =>
      'סמן את המוצרים שיש לך בארון. תוכל לערוך, להוסיף ולתזמן אותם בכל זמן.';

  @override
  String get onboardingCanAddLater => 'תוכל להוסיף מוצרים גם בהמשך';

  @override
  String get calendarEdit => 'ערוך';

  @override
  String get journalEmptyInstruction =>
      'הוסף תמונות ביומן העור היומי כדי לעקוב אחר ההתקדמות שלך';

  @override
  String get journalStartDocumenting => 'התחל לתעד';

  @override
  String get productSelSkipStep => 'דלג על השלב';

  @override
  String get productSelContinueToSchedule => 'המשך לתזמון';

  @override
  String get productSelListHint =>
      'לחץ על מוצר כדי להוסיף לרשימה או הוסף מוצר חדש';

  @override
  String get catHintSerum => 'החומרים הפעילים שלך. אפשר לבחור כמה שתרצה.';

  @override
  String get catUsageCleanser1 =>
      'עסה על עור יבש להמסת איפור ומסנני הגנה, ושטוף במים פושרים.';

  @override
  String get catUsageCleanser2 =>
      'הקצף עם מעט מים, עסה בעדינות בתנועות מעגליות ושטוף.';

  @override
  String get catUsageCleanser =>
      'שלב ראשון: עסה על עור יבש, המס, שטוף. שלב שני: הקצף עם מים ועסה בעדינות.';

  @override
  String get catUsageRetinoid =>
      'כמות בגודל אפונה על עור יבש, הימנע מאזור העיניים. ערב בלבד, בהדרגה.';

  @override
  String get catUsageToner =>
      'טפח כמה טיפות בכפות הידיים על עור נקי, לפני הסרומים.';

  @override
  String get catUsageSerum =>
      'כמה טיפות על עור נקי. המתן לספיגה לפני השלב הבא.';

  @override
  String get catUsageMoisturizer => 'מרח שכבה אחידה לנעילת הלחות והרגעת העור.';

  @override
  String get catUsageOil =>
      'חמם כמה טיפות בין כפות הידיים ולחץ על העור כשלב אחרון.';

  @override
  String get scheduleTapConflictDay => 'הקש על יום מסומן';

  @override
  String get scheduleConflictInstruction => 'הקש «הסר» על אחד מהם כדי לפתור';

  @override
  String get orderInstruction => 'גרור את המוצרים כדי לסדר את השגרה שלך';

  @override
  String get settingsWelcome => 'ברוך הבא ל־The Glow Protocol';

  @override
  String get settingsLogoutConfirmBtn => 'התנתק';

  @override
  String get updateBackupAction => 'גבה נתונים';

  @override
  String get updateNewProductsDesc =>
      'מוצרים אלה לא נבחרו עדיין. הוסף אותם בבחירת המוצרים';

  @override
  String get mergeChooseVersion => 'בחר איזו גרסה לשמור:';

  @override
  String get mergeKeepLocalDesc => 'המשך עם הנתונים הנוכחיים במכשיר';

  @override
  String get mergeUseArchive => 'השתמש בגרסת הגיבוי';

  @override
  String get mergeUseArchiveDesc => 'החלף עם הנתונים מקובץ הגיבוי';

  @override
  String get mergeAllResolved => 'כל ההתנגשויות נפתרו';

  @override
  String get mergeClickFinish => 'לחץ על \"סיים\" להחלת המיזוג';

  @override
  String get mergeSuccess => 'המיזוג הושלם בהצלחה';

  @override
  String get premiumTitle => 'גיבוי לענן, בקרוב';

  @override
  String get premiumDescWeb =>
      'הזן מפתח הפעלה כדי לאפשר גיבוי ושחזור אוטומטי בין מכשירים';

  @override
  String get premiumDescAndroid => 'תכונה זו זמינה בגרסת הווב בלבד';

  @override
  String get premiumKeyLabel => 'מפתח הפעלה';

  @override
  String get premiumActivate => 'הפעל';

  @override
  String get skinLogNotesHint => 'הערות על העור שלך היום...';

  @override
  String get skinLogAddPhotoLabel => 'הוסף תמונה';

  @override
  String get skinLogTakePhoto => 'צלם תמונה';

  @override
  String get skinLogGallery => 'בחר מהגלריה';

  @override
  String get skinLogWebStorageWarning =>
      'תמונות בדפדפן עשויות להימחק על ידי Safari. גבה את הנתונים שלך.';

  @override
  String get streakOnTrack => 'אתה בדרך הנכונה לזוהר מושלם!';

  @override
  String get backupNowAction => 'גבה';

  @override
  String get scheduleGuidedBothSlots =>
      'תזמן קודם את שגרת הבוקר, וכך נמשיך יחד גם לשגרת הערב. אפשר לחרוג מהמומלץ, רק נזכיר.';

  @override
  String scheduleContinueTo(Object routine) {
    return 'המשך ל$routine';
  }

  @override
  String get settingsProfileGuest => 'אורח';

  @override
  String get settingsProfileNameHint => 'הכנס שם';

  @override
  String get onboardingSelectLanguage => 'בחר שפה';

  @override
  String get onboardingWelcomeNeutral => 'ברוך הבא';

  @override
  String get addCustomProductCtaTitle => 'הוסף מוצר חדש';

  @override
  String get barcodeScanAddManually => 'הוסף ידנית';

  @override
  String get barcodeScanAddToRoutine => 'הוסף לשגרה';

  @override
  String get collectionProBanner => 'נסה PRO כדי לעקוב אחרי חיי המדף';

  @override
  String get lifecycleSetOpenedDate => 'הגדר תאריך פתיחה';

  @override
  String get settingsAccountPro => 'מנוי Glow PRO';

  @override
  String get settingsProTitle => 'שדרג ל־Glow PRO';

  @override
  String get settingsDemoDesc =>
      'החלף בין חוויה חינמית למנויית PRO כדי לראות איך המסכים משתנים.';

  @override
  String get streakPitchSub => 'צלם תמונת ׳לפני׳, ובעוד שבועיים תשווי';

  @override
  String get streakPitchCta => 'נסה';

  @override
  String get categoryReviewCTA => 'המשך לבחירת ימים';

  @override
  String get scheduleContinueToOrder => 'המשך לסדר המריחה';

  @override
  String welcomeGreeting(String name, String weekday) {
    return 'ברוך השב, $name · $weekday';
  }

  @override
  String welcomeSubline5to9(int streak) {
    return 'שמרת על השגרה $streak ימים ברצף — אתה בדרך הנכונה לזוהר מושלם.';
  }

  @override
  String welcomeHeadline10to29(int streak) {
    return '$streak ימים — אתה מבריק! ✨';
  }

  @override
  String get welcomeSubline30plus =>
      'חודש ויותר של שגרת טיפוח עקבית — אתה אגדה!';

  @override
  String get weekGlanceStartGlowingCta => 'הכול מוכן, מתחילים לזרוח!';

  @override
  String routineReadyReviewSlotCta(String slot) {
    return 'נסקור את שגרת ה$slot';
  }
}
