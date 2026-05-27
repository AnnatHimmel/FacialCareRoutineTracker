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
  static const List<Locale> supportedLocales = <Locale>[Locale('he')];

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
  /// **'לוח שנה'**
  String get navCalendar;

  /// No description provided for @navJournal.
  ///
  /// In he, this message translates to:
  /// **'יומן עור'**
  String get navJournal;

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
