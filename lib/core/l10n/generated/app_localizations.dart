import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
    Locale('he', 'MA'),
  ];

  /// No description provided for @navToday.
  ///
  /// In he, this message translates to:
  /// **'היום'**
  String get navToday;

  /// No description provided for @navCalendar.
  ///
  /// In he, this message translates to:
  /// **'יומן'**
  String get navCalendar;

  /// No description provided for @navJournal.
  ///
  /// In he, this message translates to:
  /// **'יומן עור'**
  String get navJournal;

  /// No description provided for @navProducts.
  ///
  /// In he, this message translates to:
  /// **'המוצרים שלי'**
  String get navProducts;

  /// No description provided for @navSettings.
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get navSettings;

  /// No description provided for @slotMorning.
  ///
  /// In he, this message translates to:
  /// **'בוקר'**
  String get slotMorning;

  /// No description provided for @slotEvening.
  ///
  /// In he, this message translates to:
  /// **'ערב'**
  String get slotEvening;

  /// No description provided for @productSelectionTitle.
  ///
  /// In he, this message translates to:
  /// **'בחירת מוצרים'**
  String get productSelectionTitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In he, this message translates to:
  /// **'תזמון מוצרים'**
  String get scheduleTitle;

  /// No description provided for @streakCurrent.
  ///
  /// In he, this message translates to:
  /// **'ימי רצף'**
  String get streakCurrent;

  /// No description provided for @streakLongest.
  ///
  /// In he, this message translates to:
  /// **'הרצף הארוך'**
  String get streakLongest;

  /// No description provided for @streakMissesThisWeek.
  ///
  /// In he, this message translates to:
  /// **'החסרות השבוע'**
  String get streakMissesThisWeek;

  /// No description provided for @streakMissesOf.
  ///
  /// In he, this message translates to:
  /// **'{current} מתוך {max}'**
  String streakMissesOf(Object current, Object max);

  /// No description provided for @warningDeprecated.
  ///
  /// In he, this message translates to:
  /// **'לא מומלץ עוד'**
  String get warningDeprecated;

  /// No description provided for @warningIncompatible.
  ///
  /// In he, this message translates to:
  /// **'לא מומלץ לשימוש יחד'**
  String get warningIncompatible;

  /// No description provided for @warningMute.
  ///
  /// In he, this message translates to:
  /// **'השתיקי'**
  String get warningMute;

  /// No description provided for @warningOverCap.
  ///
  /// In he, this message translates to:
  /// **'נבחרו יותר ימים מההמלצה'**
  String get warningOverCap;

  /// No description provided for @exportTitle.
  ///
  /// In he, this message translates to:
  /// **'ייצוא / ייבוא'**
  String get exportTitle;

  /// No description provided for @exportAction.
  ///
  /// In he, this message translates to:
  /// **'ייצא עכשיו'**
  String get exportAction;

  /// No description provided for @importAction.
  ///
  /// In he, this message translates to:
  /// **'ייבא'**
  String get importAction;

  /// No description provided for @importReplace.
  ///
  /// In he, this message translates to:
  /// **'החלפה'**
  String get importReplace;

  /// No description provided for @importMerge.
  ///
  /// In he, this message translates to:
  /// **'מיזוג'**
  String get importMerge;

  /// No description provided for @aboutTitle.
  ///
  /// In he, this message translates to:
  /// **'אודות / מה חדש'**
  String get aboutTitle;

  /// No description provided for @updateReviewTitle.
  ///
  /// In he, this message translates to:
  /// **'עדכון הושלם'**
  String get updateReviewTitle;

  /// No description provided for @backupReminderMessage.
  ///
  /// In he, this message translates to:
  /// **'גבי את הנתונים שלך'**
  String get backupReminderMessage;

  /// No description provided for @backupAction.
  ///
  /// In he, this message translates to:
  /// **'גיבוי'**
  String get backupAction;

  /// No description provided for @skinLogPlaceholder.
  ///
  /// In he, this message translates to:
  /// **'איך העור שלך היום?'**
  String get skinLogPlaceholder;

  /// No description provided for @emptyRoutine.
  ///
  /// In he, this message translates to:
  /// **'אין מוצרים מתוכננים להיום'**
  String get emptyRoutine;

  /// No description provided for @emptyJournal.
  ///
  /// In he, this message translates to:
  /// **'עדיין אין תמונות ביומן'**
  String get emptyJournal;

  /// No description provided for @continueAction.
  ///
  /// In he, this message translates to:
  /// **'המשיכי'**
  String get continueAction;

  /// No description provided for @backAction.
  ///
  /// In he, this message translates to:
  /// **'חזרה'**
  String get backAction;

  /// No description provided for @saveAction.
  ///
  /// In he, this message translates to:
  /// **'שמור'**
  String get saveAction;

  /// No description provided for @cancelAction.
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancelAction;

  /// No description provided for @resetOrder.
  ///
  /// In he, this message translates to:
  /// **'אפסי לסדר מומלץ'**
  String get resetOrder;

  /// No description provided for @dataIntactConfirmation.
  ///
  /// In he, this message translates to:
  /// **'כל הנתונים שלך שמורים ובשלמותם'**
  String get dataIntactConfirmation;

  /// No description provided for @before6amNote.
  ///
  /// In he, this message translates to:
  /// **'פעילות לפני 6:00 נרשמת ליום אמש'**
  String get before6amNote;

  /// No description provided for @chooseArchive.
  ///
  /// In he, this message translates to:
  /// **'מהגיבוי'**
  String get chooseArchive;

  /// No description provided for @chooseDevice.
  ///
  /// In he, this message translates to:
  /// **'מהמכשיר'**
  String get chooseDevice;

  /// No description provided for @webStorageWarning.
  ///
  /// In he, this message translates to:
  /// **'תמונות מאוחסנות בנפח מוגבל. גיבוי מומלץ.'**
  String get webStorageWarning;

  /// No description provided for @genericError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {error}'**
  String genericError(Object error);

  /// No description provided for @homeTitle.
  ///
  /// In he, this message translates to:
  /// **'השגרה שלך היום'**
  String get homeTitle;

  /// No description provided for @homeTapImageToDone.
  ///
  /// In he, this message translates to:
  /// **'הקישי על התמונה לסימון בוצע'**
  String get homeTapImageToDone;

  /// No description provided for @homeTapProductToDone.
  ///
  /// In he, this message translates to:
  /// **'הקישי על מוצר לסימון בוצע'**
  String get homeTapProductToDone;

  /// No description provided for @homeEmptyToday.
  ///
  /// In he, this message translates to:
  /// **'אין מוצרים להיום'**
  String get homeEmptyToday;

  /// No description provided for @homeAddProducts.
  ///
  /// In he, this message translates to:
  /// **'הוסיפי מוצרים'**
  String get homeAddProducts;

  /// No description provided for @homeDayLabel.
  ///
  /// In he, this message translates to:
  /// **'יום {day}'**
  String homeDayLabel(Object day);

  /// No description provided for @homeDayLabelGreeting.
  ///
  /// In he, this message translates to:
  /// **'שלום {name} • יום {day}'**
  String homeDayLabelGreeting(Object day, Object name);

  /// No description provided for @homeViewListSemantics.
  ///
  /// In he, this message translates to:
  /// **'תצוגת רשימה פעילה'**
  String get homeViewListSemantics;

  /// No description provided for @homeViewImagesSemantics.
  ///
  /// In he, this message translates to:
  /// **'תצוגת תמונות פעילה'**
  String get homeViewImagesSemantics;

  /// No description provided for @homeViewList.
  ///
  /// In he, this message translates to:
  /// **'רשימה'**
  String get homeViewList;

  /// No description provided for @homeViewImages.
  ///
  /// In he, this message translates to:
  /// **'תמונות'**
  String get homeViewImages;

  /// No description provided for @homeNamesToggleHide.
  ///
  /// In he, this message translates to:
  /// **'הסתירי שמות מוצרים'**
  String get homeNamesToggleHide;

  /// No description provided for @homeNamesToggleShow.
  ///
  /// In he, this message translates to:
  /// **'הציגי שמות מוצרים'**
  String get homeNamesToggleShow;

  /// No description provided for @homeNames.
  ///
  /// In he, this message translates to:
  /// **'שמות'**
  String get homeNames;

  /// No description provided for @homeProductStepDone.
  ///
  /// In he, this message translates to:
  /// **'{name}, שלב {step}, בוצע'**
  String homeProductStepDone(Object name, Object step);

  /// No description provided for @homeProductStepNotDone.
  ///
  /// In he, this message translates to:
  /// **'{name}, שלב {step}, לא בוצע'**
  String homeProductStepNotDone(Object name, Object step);

  /// No description provided for @journalCtaTitle.
  ///
  /// In he, this message translates to:
  /// **'איך העור מרגיש?'**
  String get journalCtaTitle;

  /// No description provided for @journalCtaSubtitle.
  ///
  /// In he, this message translates to:
  /// **'תעדי את התקדמותך'**
  String get journalCtaSubtitle;

  /// No description provided for @journalCtaButton.
  ///
  /// In he, this message translates to:
  /// **'תעדי עכשיו'**
  String get journalCtaButton;

  /// No description provided for @onboardingSkip.
  ///
  /// In he, this message translates to:
  /// **'דלגי'**
  String get onboardingSkip;

  /// No description provided for @onboardingWelcome.
  ///
  /// In he, this message translates to:
  /// **'ברוכה הבאה'**
  String get onboardingWelcome;

  /// No description provided for @onboardingAppIntro.
  ///
  /// In he, this message translates to:
  /// **'ל־The Glow Protocol'**
  String get onboardingAppIntro;

  /// No description provided for @onboardingTagline.
  ///
  /// In he, this message translates to:
  /// **'השגרה שלך, בקצב שלך.\nתיעוד יומי, תזמון חכם של מוצרים, וזוהר עקבי.'**
  String get onboardingTagline;

  /// No description provided for @onboardingStart.
  ///
  /// In he, this message translates to:
  /// **'בואי נתחיל'**
  String get onboardingStart;

  /// No description provided for @onboardingTakesMinute.
  ///
  /// In he, this message translates to:
  /// **'לוקח פחות מדקה'**
  String get onboardingTakesMinute;

  /// No description provided for @onboardingFeature1.
  ///
  /// In he, this message translates to:
  /// **'מעקב יומי אחר השגרה'**
  String get onboardingFeature1;

  /// No description provided for @onboardingFeature2.
  ///
  /// In he, this message translates to:
  /// **'תזמון שבועי לפי המוצר'**
  String get onboardingFeature2;

  /// No description provided for @onboardingFeature3.
  ///
  /// In he, this message translates to:
  /// **'יומן עור ומצב רוח'**
  String get onboardingFeature3;

  /// No description provided for @onboardingTellUs.
  ///
  /// In he, this message translates to:
  /// **'ספרי לנו עלייך'**
  String get onboardingTellUs;

  /// No description provided for @onboardingPrivacyDesc.
  ///
  /// In he, this message translates to:
  /// **'נשתמש בפרטים האלה כדי להתאים לך תוכן ולפנות אלייך אישית. הכל נשמר על המכשיר שלך.'**
  String get onboardingPrivacyDesc;

  /// No description provided for @onboardingNamePrompt.
  ///
  /// In he, this message translates to:
  /// **'איך לקרוא לך?'**
  String get onboardingNamePrompt;

  /// No description provided for @onboardingNameHint.
  ///
  /// In he, this message translates to:
  /// **'השם שלך'**
  String get onboardingNameHint;

  /// No description provided for @onboardingGenderLabel.
  ///
  /// In he, this message translates to:
  /// **'מגדר'**
  String get onboardingGenderLabel;

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In he, this message translates to:
  /// **'נקבה'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In he, this message translates to:
  /// **'זכר'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingPrivacyLock.
  ///
  /// In he, this message translates to:
  /// **'הפרטים נשמרים רק אצלך'**
  String get onboardingPrivacyLock;

  /// No description provided for @onboardingYourProducts.
  ///
  /// In he, this message translates to:
  /// **'המוצרים שלך'**
  String get onboardingYourProducts;

  /// No description provided for @onboardingProductInstruction.
  ///
  /// In he, this message translates to:
  /// **'סמני את המוצרים שיש לך בארון. תוכלי לערוך, להוסיף ולתזמן אותם בכל זמן.'**
  String get onboardingProductInstruction;

  /// No description provided for @onboardingProductCount.
  ///
  /// In he, this message translates to:
  /// **'נבחרו {count} מוצרים'**
  String onboardingProductCount(Object count);

  /// No description provided for @onboardingCanAddLater.
  ///
  /// In he, this message translates to:
  /// **'תוכלי להוסיף מוצרים גם בהמשך'**
  String get onboardingCanAddLater;

  /// No description provided for @onboardingFinish.
  ///
  /// In he, this message translates to:
  /// **'סיום והתחלה'**
  String get onboardingFinish;

  /// No description provided for @onboardingFrequencyDaily.
  ///
  /// In he, this message translates to:
  /// **'יומי'**
  String get onboardingFrequencyDaily;

  /// No description provided for @onboardingFrequencyWeekly.
  ///
  /// In he, this message translates to:
  /// **'עד {max} פעמים בשבוע'**
  String onboardingFrequencyWeekly(Object max);

  /// No description provided for @calendarDayAbbrevSun.
  ///
  /// In he, this message translates to:
  /// **'א׳'**
  String get calendarDayAbbrevSun;

  /// No description provided for @calendarDayAbbrevMon.
  ///
  /// In he, this message translates to:
  /// **'ב׳'**
  String get calendarDayAbbrevMon;

  /// No description provided for @calendarDayAbbrevTue.
  ///
  /// In he, this message translates to:
  /// **'ג׳'**
  String get calendarDayAbbrevTue;

  /// No description provided for @calendarDayAbbrevWed.
  ///
  /// In he, this message translates to:
  /// **'ד׳'**
  String get calendarDayAbbrevWed;

  /// No description provided for @calendarDayAbbrevThu.
  ///
  /// In he, this message translates to:
  /// **'ה׳'**
  String get calendarDayAbbrevThu;

  /// No description provided for @calendarDayAbbrevFri.
  ///
  /// In he, this message translates to:
  /// **'ו׳'**
  String get calendarDayAbbrevFri;

  /// No description provided for @calendarDayAbbrevSat.
  ///
  /// In he, this message translates to:
  /// **'ש׳'**
  String get calendarDayAbbrevSat;

  /// No description provided for @calendarStateComplete.
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get calendarStateComplete;

  /// No description provided for @calendarStatePartial.
  ///
  /// In he, this message translates to:
  /// **'חלקי'**
  String get calendarStatePartial;

  /// No description provided for @calendarStateMissed.
  ///
  /// In he, this message translates to:
  /// **'הוחמץ'**
  String get calendarStateMissed;

  /// No description provided for @calendarStateNoData.
  ///
  /// In he, this message translates to:
  /// **'ללא נתונים'**
  String get calendarStateNoData;

  /// No description provided for @calendarMonthlyAvg.
  ///
  /// In he, this message translates to:
  /// **'ממוצע חודשי'**
  String get calendarMonthlyAvg;

  /// No description provided for @calendarProgress.
  ///
  /// In he, this message translates to:
  /// **'התקדמות'**
  String get calendarProgress;

  /// No description provided for @calendarVsPrevMonth.
  ///
  /// In he, this message translates to:
  /// **'לעומת חודש קודם'**
  String get calendarVsPrevMonth;

  /// No description provided for @calendarNoComparison.
  ///
  /// In he, this message translates to:
  /// **'אין נתוני השוואה'**
  String get calendarNoComparison;

  /// No description provided for @calendarDailyRecord.
  ///
  /// In he, this message translates to:
  /// **'תיעוד יומי: {day} ב{month}'**
  String calendarDailyRecord(Object day, Object month);

  /// No description provided for @calendarEdit.
  ///
  /// In he, this message translates to:
  /// **'ערכי'**
  String get calendarEdit;

  /// No description provided for @calendarSkinState.
  ///
  /// In he, this message translates to:
  /// **'מצב העור היום'**
  String get calendarSkinState;

  /// No description provided for @calendarNoNotes.
  ///
  /// In he, this message translates to:
  /// **'לא נרשמו הערות'**
  String get calendarNoNotes;

  /// No description provided for @calendarTasksDone.
  ///
  /// In he, this message translates to:
  /// **'משימות שביצעת היום:'**
  String get calendarTasksDone;

  /// No description provided for @journalNoPhotos.
  ///
  /// In he, this message translates to:
  /// **'אין תמונות עדיין'**
  String get journalNoPhotos;

  /// No description provided for @journalEmptyInstruction.
  ///
  /// In he, this message translates to:
  /// **'הוסיפי תמונות ביומן העור היומי כדי לעקוב אחר ההתקדמות שלך'**
  String get journalEmptyInstruction;

  /// No description provided for @journalStartDocumenting.
  ///
  /// In he, this message translates to:
  /// **'התחילי לתעד'**
  String get journalStartDocumenting;

  /// No description provided for @journalDateFormat.
  ///
  /// In he, this message translates to:
  /// **'{day} ב{month} {year}'**
  String journalDateFormat(Object day, Object month, Object year);

  /// No description provided for @productSelStepCounter.
  ///
  /// In he, this message translates to:
  /// **'שלב {step} מתוך {total}'**
  String productSelStepCounter(Object step, Object total);

  /// No description provided for @productSelSkipToSummary.
  ///
  /// In he, this message translates to:
  /// **'דלגי לסיכום'**
  String get productSelSkipToSummary;

  /// No description provided for @productSelToSummary.
  ///
  /// In he, this message translates to:
  /// **'לסיכום'**
  String get productSelToSummary;

  /// No description provided for @productSelSkipStep.
  ///
  /// In he, this message translates to:
  /// **'דלגי על השלב'**
  String get productSelSkipStep;

  /// No description provided for @productSelNoCategories.
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו קטגוריות'**
  String get productSelNoCategories;

  /// No description provided for @productSelNoProducts.
  ///
  /// In he, this message translates to:
  /// **'אין מוצרים בקטגוריה זו'**
  String get productSelNoProducts;

  /// No description provided for @productSelSummaryTitle.
  ///
  /// In he, this message translates to:
  /// **'סיכום · הארון שלך'**
  String get productSelSummaryTitle;

  /// No description provided for @productSelSummarySubtitle.
  ///
  /// In he, this message translates to:
  /// **'בחרי מוצר פעם אחת. סנני בוקר/ערב כדי לראות כל שגרה בנפרד.'**
  String get productSelSummarySubtitle;

  /// No description provided for @productSelContinueToSchedule.
  ///
  /// In he, this message translates to:
  /// **'המשיכי לתזמון'**
  String get productSelContinueToSchedule;

  /// No description provided for @productSelFilterAll.
  ///
  /// In he, this message translates to:
  /// **'הכל'**
  String get productSelFilterAll;

  /// No description provided for @productSelCategoryOptions.
  ///
  /// In he, this message translates to:
  /// **'{count} אפשרויות'**
  String productSelCategoryOptions(Object count);

  /// No description provided for @productSelCategorySelected.
  ///
  /// In he, this message translates to:
  /// **'{count} נבחרו'**
  String productSelCategorySelected(Object count);

  /// No description provided for @productSelFrequencyLabel.
  ///
  /// In he, this message translates to:
  /// **'תדירות מומלצת: '**
  String get productSelFrequencyLabel;

  /// No description provided for @productSelTimingLabel.
  ///
  /// In he, this message translates to:
  /// **'מתי?'**
  String get productSelTimingLabel;

  /// No description provided for @catHintCleanser1.
  ///
  /// In he, this message translates to:
  /// **'הסרת איפור ומסנני הגנה — לרוב בערב.'**
  String get catHintCleanser1;

  /// No description provided for @catHintCleanser2.
  ///
  /// In he, this message translates to:
  /// **'ניקוי פנים יומיומי ועדין.'**
  String get catHintCleanser2;

  /// No description provided for @catHintRetinoid.
  ///
  /// In he, this message translates to:
  /// **'חידוש העור — ערב בלבד, בהדרגה.'**
  String get catHintRetinoid;

  /// No description provided for @catHintToner.
  ///
  /// In he, this message translates to:
  /// **'איזון העור והכנה לספיגת השלבים הבאים.'**
  String get catHintToner;

  /// No description provided for @catHintSerum.
  ///
  /// In he, this message translates to:
  /// **'החומרים הפעילים שלך. אפשר לבחור כמה שתרצי.'**
  String get catHintSerum;

  /// No description provided for @catHintMoisturizer.
  ///
  /// In he, this message translates to:
  /// **'נעילת הלחות והרגעת העור.'**
  String get catHintMoisturizer;

  /// No description provided for @catHintOil.
  ///
  /// In he, this message translates to:
  /// **'שכבת הזנה אחרונה, לרוב בערב.'**
  String get catHintOil;

  /// No description provided for @catHintSpf.
  ///
  /// In he, this message translates to:
  /// **'הגנה מהשמש — שלב הבוקר האחרון, חובה.'**
  String get catHintSpf;

  /// No description provided for @catUsageCleanser1.
  ///
  /// In he, this message translates to:
  /// **'עסי על עור יבש להמסת איפור ומסנני הגנה, ושטפי במים פושרים.'**
  String get catUsageCleanser1;

  /// No description provided for @catUsageCleanser2.
  ///
  /// In he, this message translates to:
  /// **'הקציפי עם מעט מים, עסי בעדינות בתנועות מעגליות ושטפי.'**
  String get catUsageCleanser2;

  /// No description provided for @catUsageRetinoid.
  ///
  /// In he, this message translates to:
  /// **'כמות בגודל אפונה על עור יבש, הימנעי מאזור העיניים. ערב בלבד, בהדרגה.'**
  String get catUsageRetinoid;

  /// No description provided for @catUsageToner.
  ///
  /// In he, this message translates to:
  /// **'טפחי כמה טיפות בכפות הידיים על עור נקי, לפני הסרומים.'**
  String get catUsageToner;

  /// No description provided for @catUsageSerum.
  ///
  /// In he, this message translates to:
  /// **'כמה טיפות על עור נקי. המתיני לספיגה לפני השלב הבא.'**
  String get catUsageSerum;

  /// No description provided for @catUsageMoisturizer.
  ///
  /// In he, this message translates to:
  /// **'מרחי שכבה אחידה לנעילת הלחות והרגעת העור.'**
  String get catUsageMoisturizer;

  /// No description provided for @catUsageOil.
  ///
  /// In he, this message translates to:
  /// **'חממי כמה טיפות בין כפות הידיים ולחצי על העור כשלב אחרון.'**
  String get catUsageOil;

  /// No description provided for @catUsageSpf.
  ///
  /// In he, this message translates to:
  /// **'כמות נדיבה (אורך אצבע) כשלב אחרון בבוקר — גם ביום מעונן.'**
  String get catUsageSpf;

  /// No description provided for @scheduleNoProducts.
  ///
  /// In he, this message translates to:
  /// **'לא נבחרו מוצרים עדיין'**
  String get scheduleNoProducts;

  /// No description provided for @scheduleConflictInMorning.
  ///
  /// In he, this message translates to:
  /// **'יש התנגשות בשגרת בוקר — הקישי לתיקון'**
  String get scheduleConflictInMorning;

  /// No description provided for @scheduleConflictInEvening.
  ///
  /// In he, this message translates to:
  /// **'יש התנגשות בשגרת ערב — הקישי לתיקון'**
  String get scheduleConflictInEvening;

  /// No description provided for @scheduleOccasional.
  ///
  /// In he, this message translates to:
  /// **'לא לשימוש יומי'**
  String get scheduleOccasional;

  /// No description provided for @scheduleDaily.
  ///
  /// In he, this message translates to:
  /// **'יומיים'**
  String get scheduleDaily;

  /// No description provided for @scheduleWeeklyView.
  ///
  /// In he, this message translates to:
  /// **'מבט שבועי'**
  String get scheduleWeeklyView;

  /// No description provided for @scheduleTapConflictDay.
  ///
  /// In he, this message translates to:
  /// **'הקישי על יום מסומן'**
  String get scheduleTapConflictDay;

  /// No description provided for @scheduleProductsPerDay.
  ///
  /// In he, this message translates to:
  /// **'מספר מוצרים ביום'**
  String get scheduleProductsPerDay;

  /// No description provided for @scheduleProductWillRemain.
  ///
  /// In he, this message translates to:
  /// **'המוצר יישאר בכל שאר הימים — לא נחסום אם תשאירי כך.'**
  String get scheduleProductWillRemain;

  /// No description provided for @scheduleConflictHeader.
  ///
  /// In he, this message translates to:
  /// **'שילוב לא מומלץ ביום {day}'**
  String scheduleConflictHeader(Object day);

  /// No description provided for @scheduleConflictInstruction.
  ///
  /// In he, this message translates to:
  /// **'הקישי «הסר» על אחד מהם כדי לפתור'**
  String get scheduleConflictInstruction;

  /// No description provided for @scheduleClose.
  ///
  /// In he, this message translates to:
  /// **'סגור'**
  String get scheduleClose;

  /// No description provided for @scheduleRemoveFrom.
  ///
  /// In he, this message translates to:
  /// **'הסר מ{day}'**
  String scheduleRemoveFrom(Object day);

  /// No description provided for @scheduleNoMix.
  ///
  /// In he, this message translates to:
  /// **'לא לשלב יחד'**
  String get scheduleNoMix;

  /// No description provided for @scheduleRecommendedDaily.
  ///
  /// In he, this message translates to:
  /// **'מומלץ: כל יום'**
  String get scheduleRecommendedDaily;

  /// No description provided for @scheduleRecommendedWeekly.
  ///
  /// In he, this message translates to:
  /// **'מומלץ: עד {max} פעמים בשבוע'**
  String scheduleRecommendedWeekly(Object max);

  /// No description provided for @scheduleCountEveryDay.
  ///
  /// In he, this message translates to:
  /// **'כל יום'**
  String get scheduleCountEveryDay;

  /// No description provided for @scheduleOverCap.
  ///
  /// In he, this message translates to:
  /// **'מעבר למומלץ — שקלי להפחית ל־{max} ימים'**
  String scheduleOverCap(Object max);

  /// No description provided for @scheduleNoDaySelected.
  ///
  /// In he, this message translates to:
  /// **'לא נבחר יום — המוצר לא ישובץ'**
  String get scheduleNoDaySelected;

  /// No description provided for @scheduleSaveFinish.
  ///
  /// In he, this message translates to:
  /// **'סיום ושמירת השגרה'**
  String get scheduleSaveFinish;

  /// No description provided for @orderInstruction.
  ///
  /// In he, this message translates to:
  /// **'גררו את המוצרים כדי לסדר את השגרה שלכם'**
  String get orderInstruction;

  /// No description provided for @orderNoProducts.
  ///
  /// In he, this message translates to:
  /// **'לא נבחרו מוצרים'**
  String get orderNoProducts;

  /// No description provided for @orderResetToRecommended.
  ///
  /// In he, this message translates to:
  /// **'איפוס לסדר המומלץ'**
  String get orderResetToRecommended;

  /// No description provided for @orderSaveFinish.
  ///
  /// In he, this message translates to:
  /// **'סיום והתחלה'**
  String get orderSaveFinish;

  /// No description provided for @orderSaveNew.
  ///
  /// In he, this message translates to:
  /// **'שמירת הסדר החדש'**
  String get orderSaveNew;

  /// No description provided for @settingsGreeting.
  ///
  /// In he, this message translates to:
  /// **'שלום'**
  String get settingsGreeting;

  /// No description provided for @settingsWelcome.
  ///
  /// In he, this message translates to:
  /// **'ברוכה הבאה ל־The Glow Protocol'**
  String get settingsWelcome;

  /// No description provided for @settingsSectionRoutine.
  ///
  /// In he, this message translates to:
  /// **'שגרת הטיפוח שלי'**
  String get settingsSectionRoutine;

  /// No description provided for @settingsOrderProducts.
  ///
  /// In he, this message translates to:
  /// **'סדר מוצרים'**
  String get settingsOrderProducts;

  /// No description provided for @settingsOrderSubtitle.
  ///
  /// In he, this message translates to:
  /// **'גררי לסידור אישי'**
  String get settingsOrderSubtitle;

  /// No description provided for @settingsSectionData.
  ///
  /// In he, this message translates to:
  /// **'נתונים'**
  String get settingsSectionData;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In he, this message translates to:
  /// **'גיבוי מקומי של הנתונים'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In he, this message translates to:
  /// **'מידע'**
  String get settingsSectionInfo;

  /// No description provided for @settingsAbout.
  ///
  /// In he, this message translates to:
  /// **'אודות ומה חדש'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In he, this message translates to:
  /// **'גרסה {version} • יומן שינויים'**
  String settingsAboutSubtitle(Object version);

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In he, this message translates to:
  /// **'בדוק עדכונים'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsCheckUpdatesSubtitle.
  ///
  /// In he, this message translates to:
  /// **'בדיקת גרסה עדכנית'**
  String get settingsCheckUpdatesSubtitle;

  /// No description provided for @settingsPremium.
  ///
  /// In he, this message translates to:
  /// **'הפעלת רישיון'**
  String get settingsPremium;

  /// No description provided for @settingsPremiumSubtitle.
  ///
  /// In he, this message translates to:
  /// **'גיבוי ושחזור בענן'**
  String get settingsPremiumSubtitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In he, this message translates to:
  /// **'חשבון'**
  String get settingsSectionAccount;

  /// No description provided for @settingsLogout.
  ///
  /// In he, this message translates to:
  /// **'התנתקות'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutSubtitle.
  ///
  /// In he, this message translates to:
  /// **'איפוס פרופיל וחזרה להתחלה'**
  String get settingsLogoutSubtitle;

  /// No description provided for @settingsLogoutConfirmContent.
  ///
  /// In he, this message translates to:
  /// **'פעולה זו תאפס את הפרופיל שלך ותחזיר אותך למסך ההתחלה. הנתונים שלך יישמרו.'**
  String get settingsLogoutConfirmContent;

  /// No description provided for @settingsLogoutConfirmBtn.
  ///
  /// In he, this message translates to:
  /// **'התנתקי'**
  String get settingsLogoutConfirmBtn;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In he, this message translates to:
  /// **'גרסה {version}'**
  String aboutVersionLabel(Object version);

  /// No description provided for @aboutChangelog.
  ///
  /// In he, this message translates to:
  /// **'מה חדש'**
  String get aboutChangelog;

  /// No description provided for @exportDataTitle.
  ///
  /// In he, this message translates to:
  /// **'ייצוא נתונים'**
  String get exportDataTitle;

  /// No description provided for @exportDataDesc.
  ///
  /// In he, this message translates to:
  /// **'שמור גיבוי של כל הנתונים שלך כארכיון ZIP'**
  String get exportDataDesc;

  /// No description provided for @exportDataAction.
  ///
  /// In he, this message translates to:
  /// **'ייצוא'**
  String get exportDataAction;

  /// No description provided for @importDataTitle.
  ///
  /// In he, this message translates to:
  /// **'ייבוא נתונים'**
  String get importDataTitle;

  /// No description provided for @importDataDesc.
  ///
  /// In he, this message translates to:
  /// **'שחזר נתונים מגיבוי קיים (החלפה מלאה או מיזוג)'**
  String get importDataDesc;

  /// No description provided for @importDataAction.
  ///
  /// In he, this message translates to:
  /// **'ייבוא'**
  String get importDataAction;

  /// No description provided for @exportSuccess.
  ///
  /// In he, this message translates to:
  /// **'הייצוא הושלם בהצלחה'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בייצוא: {error}'**
  String exportError(Object error);

  /// No description provided for @importError.
  ///
  /// In he, this message translates to:
  /// **'שגיאה בייבוא: {error}'**
  String importError(Object error);

  /// No description provided for @importFileReadError.
  ///
  /// In he, this message translates to:
  /// **'לא ניתן לקרוא את הקובץ'**
  String get importFileReadError;

  /// No description provided for @importInvalidFile.
  ///
  /// In he, this message translates to:
  /// **'קובץ לא תקין'**
  String get importInvalidFile;

  /// No description provided for @importDialogQuestion.
  ///
  /// In he, this message translates to:
  /// **'כיצד לטפל בנתונים הקיימים?'**
  String get importDialogQuestion;

  /// No description provided for @importReplaceSuccess.
  ///
  /// In he, this message translates to:
  /// **'הנתונים הוחלפו בהצלחה'**
  String get importReplaceSuccess;

  /// No description provided for @importMergeNoConflicts.
  ///
  /// In he, this message translates to:
  /// **'המיזוג הושלם — לא נמצאו התנגשויות'**
  String get importMergeNoConflicts;

  /// No description provided for @updateAllUpToDate.
  ///
  /// In he, this message translates to:
  /// **'הכל מעודכן'**
  String get updateAllUpToDate;

  /// No description provided for @updateGoBack.
  ///
  /// In he, this message translates to:
  /// **'חזור'**
  String get updateGoBack;

  /// No description provided for @updateDataIntact.
  ///
  /// In he, this message translates to:
  /// **'הנתונים שלך שמורים ועדיין קיימים'**
  String get updateDataIntact;

  /// No description provided for @updateExportBefore.
  ///
  /// In he, this message translates to:
  /// **'לפני ההמשך:'**
  String get updateExportBefore;

  /// No description provided for @updateBackupAction.
  ///
  /// In he, this message translates to:
  /// **'גבה נתונים'**
  String get updateBackupAction;

  /// No description provided for @updateNewProducts.
  ///
  /// In he, this message translates to:
  /// **'מוצרים חדשים ({count})'**
  String updateNewProducts(Object count);

  /// No description provided for @updateNewProductsDesc.
  ///
  /// In he, this message translates to:
  /// **'מוצרים אלה לא נבחרו עדיין — הוסיפי אותם בבחירת המוצרים'**
  String get updateNewProductsDesc;

  /// No description provided for @updateDeprecated.
  ///
  /// In he, this message translates to:
  /// **'מוצרים שאינם מומלצים עוד ({count})'**
  String updateDeprecated(Object count);

  /// No description provided for @updateDeprecatedDesc.
  ///
  /// In he, this message translates to:
  /// **'מוצרים אלה נמצאים ברשימה שלך אך אינם מומלצים עוד'**
  String get updateDeprecatedDesc;

  /// No description provided for @updateAcknowledge.
  ///
  /// In he, this message translates to:
  /// **'הבנתי, המשך'**
  String get updateAcknowledge;

  /// No description provided for @mergeNoData.
  ///
  /// In he, this message translates to:
  /// **'אין נתונים למיזוג'**
  String get mergeNoData;

  /// No description provided for @mergeCompleting.
  ///
  /// In he, this message translates to:
  /// **'ממזג...'**
  String get mergeCompleting;

  /// No description provided for @mergeFinish.
  ///
  /// In he, this message translates to:
  /// **'סיים'**
  String get mergeFinish;

  /// No description provided for @mergeProgressCounter.
  ///
  /// In he, this message translates to:
  /// **'התנגשות {current} מתוך {total}'**
  String mergeProgressCounter(Object current, Object total);

  /// No description provided for @mergeRecordInfo.
  ///
  /// In he, this message translates to:
  /// **'סוג: {recordType}  ·  מזהה: {recordId}'**
  String mergeRecordInfo(Object recordType, Object recordId);

  /// No description provided for @mergeChooseVersion.
  ///
  /// In he, this message translates to:
  /// **'בחרי איזו גרסה לשמור:'**
  String get mergeChooseVersion;

  /// No description provided for @mergeKeepLocal.
  ///
  /// In he, this message translates to:
  /// **'שמור גרסה מקומית'**
  String get mergeKeepLocal;

  /// No description provided for @mergeKeepLocalDesc.
  ///
  /// In he, this message translates to:
  /// **'המשיכי עם הנתונים הנוכחיים במכשיר'**
  String get mergeKeepLocalDesc;

  /// No description provided for @mergeUseArchive.
  ///
  /// In he, this message translates to:
  /// **'השתמשי בגרסת הגיבוי'**
  String get mergeUseArchive;

  /// No description provided for @mergeUseArchiveDesc.
  ///
  /// In he, this message translates to:
  /// **'החלף עם הנתונים מקובץ הגיבוי'**
  String get mergeUseArchiveDesc;

  /// No description provided for @mergeAllResolved.
  ///
  /// In he, this message translates to:
  /// **'כל ההתנגשויות נפתרו'**
  String get mergeAllResolved;

  /// No description provided for @mergeClickFinish.
  ///
  /// In he, this message translates to:
  /// **'לחצי על \"סיים\" להחלת המיזוג'**
  String get mergeClickFinish;

  /// No description provided for @mergeSuccess.
  ///
  /// In he, this message translates to:
  /// **'המיזוג הושלם בהצלחה'**
  String get mergeSuccess;

  /// No description provided for @premiumTitle.
  ///
  /// In he, this message translates to:
  /// **'גיבוי לענן — בקרוב'**
  String get premiumTitle;

  /// No description provided for @premiumDescWeb.
  ///
  /// In he, this message translates to:
  /// **'הזן מפתח הפעלה כדי לאפשר גיבוי ושחזור אוטומטי בין מכשירים'**
  String get premiumDescWeb;

  /// No description provided for @premiumDescAndroid.
  ///
  /// In he, this message translates to:
  /// **'תכונה זו זמינה בגרסת הווב בלבד'**
  String get premiumDescAndroid;

  /// No description provided for @premiumKeyLabel.
  ///
  /// In he, this message translates to:
  /// **'מפתח הפעלה'**
  String get premiumKeyLabel;

  /// No description provided for @premiumActivate.
  ///
  /// In he, this message translates to:
  /// **'הפעל'**
  String get premiumActivate;

  /// No description provided for @skinLogNotesHint.
  ///
  /// In he, this message translates to:
  /// **'הערות על העור היום...'**
  String get skinLogNotesHint;

  /// No description provided for @skinLogAddPhotoLabel.
  ///
  /// In he, this message translates to:
  /// **'הוסיפי תמונה'**
  String get skinLogAddPhotoLabel;

  /// No description provided for @skinLogTakePhoto.
  ///
  /// In he, this message translates to:
  /// **'צלמי תמונה'**
  String get skinLogTakePhoto;

  /// No description provided for @skinLogGallery.
  ///
  /// In he, this message translates to:
  /// **'בחרי מהגלריה'**
  String get skinLogGallery;

  /// No description provided for @skinLogWebStorageWarning.
  ///
  /// In he, this message translates to:
  /// **'תמונות בדפדפן עשויות להימחק על ידי Safari. גבי את הנתונים שלך.'**
  String get skinLogWebStorageWarning;

  /// No description provided for @dayDetailNoData.
  ///
  /// In he, this message translates to:
  /// **'אין נתונים ליום זה'**
  String get dayDetailNoData;

  /// No description provided for @dayDetailJournalTooltip.
  ///
  /// In he, this message translates to:
  /// **'יומן עור'**
  String get dayDetailJournalTooltip;

  /// No description provided for @streakDaysInRow.
  ///
  /// In he, this message translates to:
  /// **'ימים ברצף'**
  String get streakDaysInRow;

  /// No description provided for @streakOnTrack.
  ///
  /// In he, this message translates to:
  /// **'את בדרך הנכונה לזוהר מושלם!'**
  String get streakOnTrack;

  /// No description provided for @streakStartToday.
  ///
  /// In he, this message translates to:
  /// **'כל יום נחשב — נתחיל היום ✨'**
  String get streakStartToday;

  /// No description provided for @streakPersonalBest.
  ///
  /// In he, this message translates to:
  /// **'שיא אישי · {days} ימים'**
  String streakPersonalBest(Object days);

  /// No description provided for @streakNoGraces.
  ///
  /// In he, this message translates to:
  /// **'אין עוד \" אופס, פיספסתי...\"'**
  String get streakNoGraces;

  /// No description provided for @streakGracesLeft.
  ///
  /// In he, this message translates to:
  /// **'נשארו {count} \"אופס, פיספסתי...\"'**
  String streakGracesLeft(Object count);

  /// No description provided for @streakSemanticDays.
  ///
  /// In he, this message translates to:
  /// **'{count} ימים ברצף'**
  String streakSemanticDays(Object count);

  /// No description provided for @routineItemDone.
  ///
  /// In he, this message translates to:
  /// **'בוצע'**
  String get routineItemDone;

  /// No description provided for @routineItemNotDone.
  ///
  /// In he, this message translates to:
  /// **'לא בוצע'**
  String get routineItemNotDone;

  /// No description provided for @routineItemFlexibleSlots.
  ///
  /// In he, this message translates to:
  /// **'בוקר • ערב'**
  String get routineItemFlexibleSlots;

  /// No description provided for @routineItemDeprecatedPill.
  ///
  /// In he, this message translates to:
  /// **'לא מומלץ'**
  String get routineItemDeprecatedPill;

  /// No description provided for @routineItemDeprecatedWarning.
  ///
  /// In he, this message translates to:
  /// **'מוצר זה אינו מומלץ עוד'**
  String get routineItemDeprecatedWarning;

  /// No description provided for @backupReminderText.
  ///
  /// In he, this message translates to:
  /// **'מומלץ לגבות את הנתונים שלך'**
  String get backupReminderText;

  /// No description provided for @backupNowAction.
  ///
  /// In he, this message translates to:
  /// **'גבי עכשיו'**
  String get backupNowAction;

  /// No description provided for @categoryItemsSuffix.
  ///
  /// In he, this message translates to:
  /// **'פריטים'**
  String get categoryItemsSuffix;

  /// No description provided for @fixedSlotMorningOnly.
  ///
  /// In he, this message translates to:
  /// **'בוקר בלבד'**
  String get fixedSlotMorningOnly;

  /// No description provided for @fixedSlotEveningOnly.
  ///
  /// In he, this message translates to:
  /// **'ערב בלבד'**
  String get fixedSlotEveningOnly;

  /// No description provided for @skinStateCalm.
  ///
  /// In he, this message translates to:
  /// **'רגוע'**
  String get skinStateCalm;

  /// No description provided for @skinStateMoist.
  ///
  /// In he, this message translates to:
  /// **'לח'**
  String get skinStateMoist;

  /// No description provided for @skinStateOily.
  ///
  /// In he, this message translates to:
  /// **'שומני'**
  String get skinStateOily;

  /// No description provided for @weekdayOverCapWarning.
  ///
  /// In he, this message translates to:
  /// **'מעבר למומלץ — שקלי להפחית'**
  String get weekdayOverCapWarning;

  /// No description provided for @customProductTitle.
  ///
  /// In he, this message translates to:
  /// **'הוספת מוצר משלי'**
  String get customProductTitle;

  /// No description provided for @customProductPhotoLabel.
  ///
  /// In he, this message translates to:
  /// **'הוספת תמונה (לא חובה)'**
  String get customProductPhotoLabel;

  /// No description provided for @customProductNameLabel.
  ///
  /// In he, this message translates to:
  /// **'שם המוצר'**
  String get customProductNameLabel;

  /// No description provided for @customProductNameHint.
  ///
  /// In he, this message translates to:
  /// **'לדוגמה: סרם לחות אישי'**
  String get customProductNameHint;

  /// No description provided for @customProductCategoryLabel.
  ///
  /// In he, this message translates to:
  /// **'קטגוריה'**
  String get customProductCategoryLabel;

  /// No description provided for @customProductSlotLabel.
  ///
  /// In he, this message translates to:
  /// **'זמן שגרה'**
  String get customProductSlotLabel;

  /// No description provided for @customProductSlotBoth.
  ///
  /// In he, this message translates to:
  /// **'בוקר + ערב'**
  String get customProductSlotBoth;

  /// No description provided for @customProductFrequencyLabel.
  ///
  /// In he, this message translates to:
  /// **'תדירות'**
  String get customProductFrequencyLabel;

  /// No description provided for @customProductFrequencyWeekly.
  ///
  /// In he, this message translates to:
  /// **'כמה פעמים בשבוע'**
  String get customProductFrequencyWeekly;

  /// No description provided for @customProductTimesPerWeekLabel.
  ///
  /// In he, this message translates to:
  /// **'פעמים בשבוע:'**
  String get customProductTimesPerWeekLabel;

  /// No description provided for @customProductSave.
  ///
  /// In he, this message translates to:
  /// **'הוספה לשגרה שלי'**
  String get customProductSave;

  /// No description provided for @customProductEditButton.
  ///
  /// In he, this message translates to:
  /// **'עריכת מוצר'**
  String get customProductEditButton;

  /// No description provided for @customProductEditTitle.
  ///
  /// In he, this message translates to:
  /// **'עריכת מוצר'**
  String get customProductEditTitle;

  /// No description provided for @customProductEditSave.
  ///
  /// In he, this message translates to:
  /// **'שמירת שינויים'**
  String get customProductEditSave;

  /// No description provided for @customProductDeleteButton.
  ///
  /// In he, this message translates to:
  /// **'הסרת מוצר'**
  String get customProductDeleteButton;

  /// No description provided for @customProductDeleteConfirmTitle.
  ///
  /// In he, this message translates to:
  /// **'הסרת מוצר'**
  String get customProductDeleteConfirmTitle;

  /// No description provided for @customProductDeleteConfirmBody.
  ///
  /// In he, this message translates to:
  /// **'המוצר יוסר לצמיתות מהרשימה שלך. פעולה זו אינה הפיכה.'**
  String get customProductDeleteConfirmBody;

  /// No description provided for @customProductDeleteConfirmAction.
  ///
  /// In he, this message translates to:
  /// **'הסרה'**
  String get customProductDeleteConfirmAction;

  /// No description provided for @scheduleConflictWarning.
  ///
  /// In he, this message translates to:
  /// **'עדיין יש ימי התנגשות ב{slot}'**
  String scheduleConflictWarning(Object slot);

  /// No description provided for @slotMorningRoutine.
  ///
  /// In he, this message translates to:
  /// **'שגרת בוקר'**
  String get slotMorningRoutine;

  /// No description provided for @slotEveningRoutine.
  ///
  /// In he, this message translates to:
  /// **'שגרת ערב'**
  String get slotEveningRoutine;

  /// No description provided for @scheduleStepBadge.
  ///
  /// In he, this message translates to:
  /// **'שלב {n} מתוך {total}'**
  String scheduleStepBadge(int n, int total);

  /// No description provided for @scheduleGuidedBothSlots.
  ///
  /// In he, this message translates to:
  /// **'תזמני קודם את שגרת הבוקר, וכך נמשיך יחד גם לשגרת הערב. אפשר לחרוג מהמומלץ — רק נזכיר.'**
  String get scheduleGuidedBothSlots;

  /// No description provided for @scheduleGuidedSingleSlot.
  ///
  /// In he, this message translates to:
  /// **'באילו ימים להשתמש בכל מוצר ב{routine}…'**
  String scheduleGuidedSingleSlot(Object routine);

  /// No description provided for @scheduleContinueTo.
  ///
  /// In he, this message translates to:
  /// **'המשיכי ל{routine}'**
  String scheduleContinueTo(Object routine);

  /// No description provided for @scheduleNextStepPending.
  ///
  /// In he, this message translates to:
  /// **'נשאר עוד שלב — {routine} מחכה לתזמון'**
  String scheduleNextStepPending(Object routine);

  /// No description provided for @scheduleConflictWarningCount.
  ///
  /// In he, this message translates to:
  /// **'עדיין יש {count} ימי התנגשות ב{label}'**
  String scheduleConflictWarningCount(int count, Object label);

  /// No description provided for @scheduleCustomizeDays.
  ///
  /// In he, this message translates to:
  /// **'בחירת ימים'**
  String get scheduleCustomizeDays;

  /// No description provided for @scheduleDailyDefaultSuffix.
  ///
  /// In he, this message translates to:
  /// **'· כברירת מחדל כל יום'**
  String get scheduleDailyDefaultSuffix;

  /// No description provided for @scheduleDailyCollapse.
  ///
  /// In he, this message translates to:
  /// **'סגירה'**
  String get scheduleDailyCollapse;

  /// No description provided for @scheduleBadgeNoneSelected.
  ///
  /// In he, this message translates to:
  /// **'לא נבחר'**
  String get scheduleBadgeNoneSelected;

  /// No description provided for @aboutDisclaimer.
  ///
  /// In he, this message translates to:
  /// **'האפליקציה מיועדת למעקב אישי בלבד ואינה מהווה ייעוץ רפואי או קוסמטי.'**
  String get aboutDisclaimer;

  /// No description provided for @aboutPrivacyPolicyLink.
  ///
  /// In he, this message translates to:
  /// **'מדיניות פרטיות'**
  String get aboutPrivacyPolicyLink;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsLanguage.
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In he, this message translates to:
  /// **'עברית / אנגלית'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageHebrew.
  ///
  /// In he, this message translates to:
  /// **'עברית'**
  String get settingsLanguageHebrew;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In he, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @calendarDayFullSun.
  ///
  /// In he, this message translates to:
  /// **'ראשון'**
  String get calendarDayFullSun;

  /// No description provided for @calendarDayFullMon.
  ///
  /// In he, this message translates to:
  /// **'שני'**
  String get calendarDayFullMon;

  /// No description provided for @calendarDayFullTue.
  ///
  /// In he, this message translates to:
  /// **'שלישי'**
  String get calendarDayFullTue;

  /// No description provided for @calendarDayFullWed.
  ///
  /// In he, this message translates to:
  /// **'רביעי'**
  String get calendarDayFullWed;

  /// No description provided for @calendarDayFullThu.
  ///
  /// In he, this message translates to:
  /// **'חמישי'**
  String get calendarDayFullThu;

  /// No description provided for @calendarDayFullFri.
  ///
  /// In he, this message translates to:
  /// **'שישי'**
  String get calendarDayFullFri;

  /// No description provided for @calendarDayFullSat.
  ///
  /// In he, this message translates to:
  /// **'שבת'**
  String get calendarDayFullSat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'he':
      {
        switch (locale.countryCode) {
          case 'MA':
            return AppLocalizationsHeMa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
