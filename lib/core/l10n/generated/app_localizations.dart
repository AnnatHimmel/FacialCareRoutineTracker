import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
    Locale('he'),
    Locale('he', 'MA'),
  ];

  /// No description provided for @appName.
  ///
  /// In he, this message translates to:
  /// **'מעקב שגרת טיפוח'**
  String get appName;

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

  /// No description provided for @orderTitle.
  ///
  /// In he, this message translates to:
  /// **'סדר מוצרים'**
  String get orderTitle;

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
  /// **'השתק'**
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

  /// No description provided for @settingsTitle.
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settingsTitle;

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

  /// No description provided for @skinLogTitle.
  ///
  /// In he, this message translates to:
  /// **'יומן עור'**
  String get skinLogTitle;

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
  /// **'המשך'**
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

  /// No description provided for @resetOrder.
  ///
  /// In he, this message translates to:
  /// **'אפס לסדר מומלץ'**
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

  /// No description provided for @conflictChooserTitle.
  ///
  /// In he, this message translates to:
  /// **'התנגשות {current} מתוך {total}'**
  String conflictChooserTitle(Object current, Object total);

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
  /// **'הוסף מוצרים'**
  String get homeAddProducts;

  /// No description provided for @homeDayLabel.
  ///
  /// In he, this message translates to:
  /// **'יום {day}'**
  String homeDayLabel(Object day);

  /// No description provided for @homeDayLabelGreeting.
  ///
  /// In he, this message translates to:
  /// **'יום {day} • שלום {name}'**
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
  /// **'הסתר שמות מוצרים'**
  String get homeNamesToggleHide;

  /// No description provided for @homeNamesToggleShow.
  ///
  /// In he, this message translates to:
  /// **'הצג שמות מוצרים'**
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
  /// **'תיעוד עכשיו'**
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
  /// **'עד {max}× בשבוע'**
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
  /// **'ערוך'**
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
  /// **'משימות שביצעו היום:'**
  String get calendarTasksDone;

  /// No description provided for @calendarAddPhoto.
  ///
  /// In he, this message translates to:
  /// **'הוסף תמונה'**
  String get calendarAddPhoto;

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
  /// **'התחלי לתעד'**
  String get journalStartDocumenting;

  /// No description provided for @journalDateFormat.
  ///
  /// In he, this message translates to:
  /// **'{day} ב{month} {year}'**
  String journalDateFormat(Object day, Object month, Object year);
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
      <String>['he'].contains(locale.languageCode);

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
