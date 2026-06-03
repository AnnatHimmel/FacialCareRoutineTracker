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
  String get aboutTitle => 'אודות / מה חדש';

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
  String get continueAction => 'המשך';

  @override
  String get backAction => 'חזרה';

  @override
  String get saveAction => 'שמור';

  @override
  String get cancelAction => 'ביטול';

  @override
  String get resetOrder => 'אפסי לסדר מומלץ';

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
  String get homeTitle => 'השגרה שלך היום';

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
  String get homeNamesToggleHide => 'הסתירי שמות מוצרים';

  @override
  String get homeNamesToggleShow => 'הציגי שמות מוצרים';

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
    return 'תיעוד יומי: $day ב $month';
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
  String journalDateFormat(Object day, Object month, Object year) {
    return '$day ב$month $year';
  }

  @override
  String productSelStepCounter(Object step, Object total) {
    return 'שלב $step מתוך $total';
  }

  @override
  String get productSelSkipToSummary => 'דלגי לסיכום';

  @override
  String get productSelToSummary => 'לסיכום';

  @override
  String get productSelSkipStep => 'דלגי על השלב';

  @override
  String get productSelNoCategories => 'לא נמצאו קטגוריות';

  @override
  String get productSelNoProducts => 'אין מוצרים בקטגוריה זו';

  @override
  String get productSelSummaryTitle => 'סיכום · הארון שלך';

  @override
  String get productSelSummarySubtitle =>
      'בחרי מוצר פעם אחת. סנני בוקר/ערב כדי לראות כל שגרה בנפרד.';

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
  String get catHintCleanser1 => 'הסרת איפור ומסנני הגנה — לרוב בערב.';

  @override
  String get catHintCleanser2 => 'ניקוי פנים יומיומי ועדין.';

  @override
  String get catHintRetinoid => 'חידוש העור — ערב בלבד, בהדרגה.';

  @override
  String get catHintToner => 'איזון העור והכנה לספיגת השלבים הבאים.';

  @override
  String get catHintSerum => 'החומרים הפעילים שלך. אפשר לבחור כמה שתרצי.';

  @override
  String get catHintMoisturizer => 'נעילת הלחות והרגעת העור.';

  @override
  String get catHintOil => 'שכבת הזנה אחרונה, לרוב בערב.';

  @override
  String get catHintSpf => 'הגנה מהשמש — שלב הבוקר האחרון, חובה.';

  @override
  String get catUsageCleanser1 =>
      'עסי על עור יבש להמסת איפור ומסנני הגנה, ושטפי במים פושרים.';

  @override
  String get catUsageCleanser2 =>
      'הקציפי עם מעט מים, עסי בעדינות בתנועות מעגליות ושטפי.';

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
      'כמות נדיבה (אורך אצבע) כשלב אחרון בבוקר — גם ביום מעונן.';

  @override
  String get scheduleNoProducts => 'לא נבחרו מוצרים עדיין';

  @override
  String get scheduleConflictInMorning =>
      'יש התנגשות בשגרת בוקר — הקישי לתיקון';

  @override
  String get scheduleConflictInEvening => 'יש התנגשות בשגרת ערב — הקישי לתיקון';

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
      'המוצר יישאר בכל שאר הימים — לא נחסום אם תשאירי כך.';

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
    return 'מעבר למומלץ — שקלי להפחית ל־$max ימים';
  }

  @override
  String get scheduleNoDaySelected => 'לא נבחר יום — המוצר לא ישובץ';

  @override
  String get scheduleSaveFinish => 'סיום ושמירת השגרה';

  @override
  String get orderInstruction => 'גררו את המוצרים כדי לסדר את השגרה שלכם';

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
  String get settingsOrderProducts => 'סדר מוצרים';

  @override
  String get settingsOrderSubtitle => 'גררי לסידור אישי';

  @override
  String get settingsSectionData => 'נתונים';

  @override
  String get settingsExportSubtitle => 'גיבוי מקומי של הנתונים';

  @override
  String get settingsSectionInfo => 'מידע';

  @override
  String get settingsAbout => 'אודות ומה חדש';

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
  String get aboutChangelog => 'מה חדש';

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
  String get importMergeNoConflicts => 'המיזוג הושלם — לא נמצאו התנגשויות';

  @override
  String get updateAllUpToDate => 'הכל מעודכן';

  @override
  String get updateGoBack => 'חזור';

  @override
  String get updateDataIntact => 'הנתונים שלך שמורים ועדיין קיימים';

  @override
  String get updateExportBefore => 'לפני ההמשך:';

  @override
  String get updateBackupAction => 'גבה נתונים';

  @override
  String updateNewProducts(Object count) {
    return 'מוצרים חדשים ($count)';
  }

  @override
  String get updateNewProductsDesc =>
      'מוצרים אלה לא נבחרו עדיין — הוסיפי אותם בבחירת המוצרים';

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
  String get mergeKeepLocalDesc => 'המשך עם הנתונים הנוכחיים במכשיר';

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
  String get premiumTitle => 'גיבוי לענן — בקרוב';

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
  String get streakStartToday => 'כל יום נחשב — נתחיל היום ✨';

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
  String get backupNowAction => 'גבי עכשיו';

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
  String get weekdayOverCapWarning => 'מעבר למומלץ — שקלי להפחית';

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
  String get customProductSlotLabel => 'זמן שגרה';

  @override
  String get customProductSlotBoth => 'בוקר + ערב';

  @override
  String get customProductFrequencyLabel => 'תדירות';

  @override
  String get customProductFrequencyWeekly => 'כמה פעמים בשבוע';

  @override
  String get customProductTimesPerWeekLabel => 'פעמים בשבוע:';

  @override
  String get customProductSave => 'הוספה לשגרה שלי';

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
      'תזמני קודם את שגרת הבוקר, וכך נמשיך יחד גם לשגרת הערב. אפשר לחרוג מהמומלץ — רק נזכיר.';

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
    return 'נשאר עוד שלב — $routine מחכה לתזמון';
  }

  @override
  String scheduleConflictWarningCount(int count, Object label) {
    return 'עדיין יש $count ימי התנגשות ב$label';
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
}

/// The translations for Hebrew, as used in Morocco (`he_MA`).
class AppLocalizationsHeMa extends AppLocalizationsHe {
  AppLocalizationsHeMa() : super('he_MA');

  @override
  String get warningMute => 'השתק';

  @override
  String get backupReminderMessage => 'גבה את הנתונים שלך';

  @override
  String get resetOrder => 'אפס לסדר מומלץ';

  @override
  String get homeTapImageToDone => 'הקש על התמונה לסימון בוצע';

  @override
  String get homeTapProductToDone => 'הקש על מוצר לסימון בוצע';

  @override
  String get homeAddProducts => 'הוסף מוצרים';

  @override
  String get homeNamesToggleHide => 'הסתר שמות מוצרים';

  @override
  String get homeNamesToggleShow => 'הצג שמות מוצרים';

  @override
  String get journalCtaSubtitle => 'תעד את התקדמותך';

  @override
  String get journalCtaButton => 'תעד עכשיו';

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
  String get calendarEdit => 'ערוך';

  @override
  String get journalEmptyInstruction =>
      'הוסף תמונות ביומן העור היומי כדי לעקוב אחר ההתקדמות שלך';

  @override
  String get journalStartDocumenting => 'התחל לתעד';

  @override
  String get productSelSkipToSummary => 'דלג לסיכום';

  @override
  String get productSelSkipStep => 'דלג על השלב';

  @override
  String get productSelSummarySubtitle =>
      'בחר מוצר פעם אחת. סנן בוקר/ערב כדי לראות כל שגרה בנפרד.';

  @override
  String get productSelContinueToSchedule => 'המשך לתזמון';

  @override
  String get catHintSerum => 'החומרים הפעילים שלך. אפשר לבחור כמה שתרצה.';

  @override
  String get catUsageCleanser1 =>
      'עסה על עור יבש להמסת איפור ומסנני הגנה, ושטוף במים פושרים.';

  @override
  String get catUsageCleanser2 =>
      'הקצף עם מעט מים, עסה בעדינות בתנועות מעגליות ושטוף.';

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
  String get scheduleConflictInMorning => 'יש התנגשות בשגרת בוקר — הקש לתיקון';

  @override
  String get scheduleConflictInEvening => 'יש התנגשות בשגרת ערב — הקש לתיקון';

  @override
  String get scheduleTapConflictDay => 'הקש על יום מסומן';

  @override
  String get scheduleProductWillRemain =>
      'המוצר יישאר בכל שאר הימים — לא נחסום אם תשאיר כך.';

  @override
  String get scheduleConflictInstruction => 'הקש «הסר» על אחד מהם כדי לפתור';

  @override
  String scheduleOverCap(Object max) {
    return 'מעבר למומלץ — שקול להפחית ל־$max ימים';
  }

  @override
  String get settingsWelcome => 'ברוך הבא ל־The Glow Protocol';

  @override
  String get settingsOrderSubtitle => 'גרור לסידור אישי';

  @override
  String get settingsLogoutConfirmBtn => 'התנתק';

  @override
  String get updateNewProductsDesc =>
      'מוצרים אלה לא נבחרו עדיין — הוסף אותם בבחירת המוצרים';

  @override
  String get mergeChooseVersion => 'בחר איזו גרסה לשמור:';

  @override
  String get mergeUseArchive => 'השתמש בגרסת הגיבוי';

  @override
  String get mergeClickFinish => 'לחץ על \"סיים\" להחלת המיזוג';

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
  String get backupNowAction => 'גבה עכשיו';

  @override
  String get weekdayOverCapWarning => 'מעבר למומלץ — שקול להפחית';
}
