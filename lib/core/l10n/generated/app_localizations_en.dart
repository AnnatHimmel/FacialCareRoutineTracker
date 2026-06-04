// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navToday => 'Today';

  @override
  String get navCalendar => 'Journal';

  @override
  String get navJournal => 'Skin Log';

  @override
  String get navProducts => 'My Products';

  @override
  String get navSettings => 'Settings';

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotEvening => 'Evening';

  @override
  String get productSelectionTitle => 'Select Products';

  @override
  String get scheduleTitle => 'Schedule Products';

  @override
  String get streakCurrent => 'Day Streak';

  @override
  String get streakLongest => 'Longest Streak';

  @override
  String get streakMissesThisWeek => 'Misses This Week';

  @override
  String streakMissesOf(Object current, Object max) {
    return '$current of $max';
  }

  @override
  String get warningDeprecated => 'No longer recommended';

  @override
  String get warningIncompatible => 'Not recommended to use together';

  @override
  String get warningMute => 'Mute';

  @override
  String get warningOverCap => 'More days selected than recommended';

  @override
  String get exportTitle => 'Export / Import';

  @override
  String get exportAction => 'Export Now';

  @override
  String get importAction => 'Import';

  @override
  String get importReplace => 'Replace';

  @override
  String get importMerge => 'Merge';

  @override
  String get aboutTitle => 'About / What\'s New';

  @override
  String get updateReviewTitle => 'Update Complete';

  @override
  String get backupReminderMessage => 'Back up your data';

  @override
  String get backupAction => 'Backup';

  @override
  String get skinLogPlaceholder => 'How is your skin today?';

  @override
  String get emptyRoutine => 'No products planned for today';

  @override
  String get emptyJournal => 'No photos in journal yet';

  @override
  String get continueAction => 'Continue';

  @override
  String get backAction => 'Back';

  @override
  String get saveAction => 'Save';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get resetOrder => 'Reset to recommended order';

  @override
  String get dataIntactConfirmation => 'All your data is saved and intact';

  @override
  String get before6amNote => 'Activity before 6:00 is logged to yesterday';

  @override
  String get chooseArchive => 'From backup';

  @override
  String get chooseDevice => 'From device';

  @override
  String get webStorageWarning =>
      'Photos are stored in limited space. Backup recommended.';

  @override
  String genericError(Object error) {
    return 'Error: $error';
  }

  @override
  String get homeTitle => 'Your Routine Today';

  @override
  String get homeTapImageToDone => 'Tap an image to mark as done';

  @override
  String get homeTapProductToDone => 'Tap a product to mark as done';

  @override
  String get homeEmptyToday => 'No products for today';

  @override
  String get homeAddProducts => 'Add Products';

  @override
  String homeDayLabel(Object day) {
    return '$day';
  }

  @override
  String homeDayLabelGreeting(Object day, Object name) {
    return 'Hi $name • $day';
  }

  @override
  String get homeViewListSemantics => 'List view active';

  @override
  String get homeViewImagesSemantics => 'Images view active';

  @override
  String get homeViewList => 'List';

  @override
  String get homeViewImages => 'Images';

  @override
  String get homeNamesToggleHide => 'Hide product names';

  @override
  String get homeNamesToggleShow => 'Show product names';

  @override
  String get homeNames => 'Names';

  @override
  String homeProductStepDone(Object name, Object step) {
    return '$name, step $step, done';
  }

  @override
  String homeProductStepNotDone(Object name, Object step) {
    return '$name, step $step, not done';
  }

  @override
  String get journalCtaTitle => 'How\'s your skin?';

  @override
  String get journalCtaSubtitle => 'Track your progress';

  @override
  String get journalCtaButton => 'Log Now';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingWelcome => 'Welcome';

  @override
  String get onboardingAppIntro => 'to The Glow Protocol';

  @override
  String get onboardingTagline =>
      'Your routine, your pace.\nDaily tracking, smart product scheduling, and consistent glow.';

  @override
  String get onboardingTakesMinute => 'Takes less than a minute';

  @override
  String get onboardingFeature1 => 'Daily routine tracking';

  @override
  String get onboardingFeature2 => 'Per-product weekly scheduling';

  @override
  String get onboardingFeature3 => 'Skin & mood journal';

  @override
  String get onboardingTellUs => 'Tell us about you';

  @override
  String get onboardingPrivacyDesc =>
      'We\'ll use these details to personalise your content and address you directly. Everything is stored on your device.';

  @override
  String get onboardingNamePrompt => 'What should we call you?';

  @override
  String get onboardingNameHint => 'Your name';

  @override
  String get onboardingGenderLabel => 'Gender';

  @override
  String get onboardingGenderFemale => 'Female';

  @override
  String get onboardingGenderMale => 'Male';

  @override
  String get onboardingPrivacyLock => 'Details are stored only on your device';

  @override
  String get onboardingYourProducts => 'Your Products';

  @override
  String get onboardingProductInstruction =>
      'Select the products you have in your cabinet. You can edit, add, and schedule them at any time.';

  @override
  String onboardingProductCount(Object count) {
    return '$count products selected';
  }

  @override
  String get onboardingCanAddLater => 'You can add more products later';

  @override
  String get onboardingFinish => 'Finish & Start';

  @override
  String get onboardingFrequencyDaily => 'Daily';

  @override
  String onboardingFrequencyWeekly(Object max) {
    return 'Up to $max times per week';
  }

  @override
  String get calendarDayAbbrevSun => 'Sun';

  @override
  String get calendarDayAbbrevMon => 'Mon';

  @override
  String get calendarDayAbbrevTue => 'Tue';

  @override
  String get calendarDayAbbrevWed => 'Wed';

  @override
  String get calendarDayAbbrevThu => 'Thu';

  @override
  String get calendarDayAbbrevFri => 'Fri';

  @override
  String get calendarDayAbbrevSat => 'Sat';

  @override
  String get calendarStateComplete => 'Complete';

  @override
  String get calendarStatePartial => 'Partial';

  @override
  String get calendarStateMissed => 'Missed';

  @override
  String get calendarStateNoData => 'No data';

  @override
  String get calendarMonthlyAvg => 'Monthly average';

  @override
  String get calendarProgress => 'Progress';

  @override
  String get calendarVsPrevMonth => 'vs. previous month';

  @override
  String get calendarNoComparison => 'No comparison data';

  @override
  String calendarDailyRecord(Object day, Object month) {
    return 'Daily record: $month $day';
  }

  @override
  String get calendarEdit => 'Edit';

  @override
  String get calendarSkinState => 'Skin state today';

  @override
  String get calendarNoNotes => 'No notes recorded';

  @override
  String get calendarTasksDone => 'Tasks you completed today:';

  @override
  String get journalNoPhotos => 'No photos yet';

  @override
  String get journalEmptyInstruction =>
      'Add photos in the daily skin log to track your progress';

  @override
  String get journalStartDocumenting => 'Start documenting';

  @override
  String journalDateFormat(Object day, Object month, Object year) {
    return '$month $day, $year';
  }

  @override
  String productSelStepCounter(Object step, Object total) {
    return 'Step $step of $total';
  }

  @override
  String get productSelSkipToSummary => 'Skip to summary';

  @override
  String get productSelToSummary => 'Summary';

  @override
  String get productSelSkipStep => 'Skip this step';

  @override
  String get productSelNoCategories => 'No categories found';

  @override
  String get productSelNoProducts => 'No products in this category';

  @override
  String get productSelSummaryTitle => 'Summary · Your Cabinet';

  @override
  String get productSelSummarySubtitle =>
      'Select a product once. Filter morning/evening to view each routine separately.';

  @override
  String get productSelContinueToSchedule => 'Continue to Schedule';

  @override
  String get productSelFilterAll => 'All';

  @override
  String productSelCategoryOptions(Object count) {
    return '$count options';
  }

  @override
  String productSelCategorySelected(Object count) {
    return '$count selected';
  }

  @override
  String get productSelFrequencyLabel => 'Recommended frequency: ';

  @override
  String get productSelTimingLabel => 'When?';

  @override
  String get catHintCleanser1 =>
      'Removes makeup and sunscreen — usually in the evening.';

  @override
  String get catHintCleanser2 => 'Gentle daily face cleanse.';

  @override
  String get catHintRetinoid => 'Skin renewal — evening only, gradually.';

  @override
  String get catHintToner => 'Balances skin and preps it for the next steps.';

  @override
  String get catHintSerum =>
      'Your active ingredients. Choose as many as you like.';

  @override
  String get catHintMoisturizer => 'Locks in moisture and soothes skin.';

  @override
  String get catHintOil => 'Final nourishing layer, usually in the evening.';

  @override
  String get catHintSpf => 'Sun protection — the last morning step, essential.';

  @override
  String get catUsageCleanser1 =>
      'Massage onto dry skin to dissolve makeup and sunscreen, then rinse with lukewarm water.';

  @override
  String get catUsageCleanser2 =>
      'Lather with a little water, gently massage in circular motions and rinse.';

  @override
  String get catUsageRetinoid =>
      'Pea-sized amount on dry skin, avoid the eye area. Evening only, gradually.';

  @override
  String get catUsageToner =>
      'Pat a few drops into your palms onto clean skin, before serums.';

  @override
  String get catUsageSerum =>
      'A few drops on clean skin. Wait for absorption before the next step.';

  @override
  String get catUsageMoisturizer =>
      'Apply an even layer to lock in moisture and soothe skin.';

  @override
  String get catUsageOil =>
      'Warm a few drops between your palms and press onto skin as the last step.';

  @override
  String get catUsageSpf =>
      'Generous amount (a finger-length) as the last morning step — even on cloudy days.';

  @override
  String get scheduleNoProducts => 'No products selected yet';

  @override
  String get scheduleConflictInMorning =>
      'There is a conflict in the morning routine — tap to fix';

  @override
  String get scheduleConflictInEvening =>
      'There is a conflict in the evening routine — tap to fix';

  @override
  String get scheduleOccasional => 'Not for daily use';

  @override
  String get scheduleDaily => 'Daily';

  @override
  String get scheduleWeeklyView => 'Weekly view';

  @override
  String get scheduleTapConflictDay => 'Tap a flagged day';

  @override
  String get scheduleProductsPerDay => 'Products per day';

  @override
  String get scheduleProductWillRemain =>
      'The product will remain on all other days — we won\'t block this if you keep it.';

  @override
  String scheduleConflictHeader(Object day) {
    return 'Not recommended combination on $day';
  }

  @override
  String get scheduleConflictInstruction =>
      'Tap «Remove» on one of them to resolve';

  @override
  String get scheduleClose => 'Close';

  @override
  String scheduleRemoveFrom(Object day) {
    return 'Remove from $day';
  }

  @override
  String get scheduleRemove => 'Remove';

  @override
  String get scheduleNoMix => 'Do not combine';

  @override
  String get scheduleRecommendedDaily => 'Recommended: every day';

  @override
  String scheduleRecommendedWeekly(Object max) {
    return 'Recommended: up to $max times per week';
  }

  @override
  String get scheduleCountEveryDay => 'Every day';

  @override
  String scheduleOverCap(Object max) {
    return 'Exceeds recommendation — consider reducing to $max days per week';
  }

  @override
  String get scheduleNoDaySelected =>
      'No day selected — product will not be scheduled';

  @override
  String get scheduleSaveFinish => 'Finish & Save Routine';

  @override
  String get orderInstruction => 'Drag products to reorder your routine';

  @override
  String get orderNoProducts => 'No products selected';

  @override
  String get orderResetToRecommended => 'Reset to recommended order';

  @override
  String get orderSaveFinish => 'Finish & Start';

  @override
  String get orderSaveNew => 'Save New Order';

  @override
  String get settingsGreeting => 'Hello';

  @override
  String get settingsWelcome => 'Welcome to The Glow Protocol';

  @override
  String get settingsSectionRoutine => 'My Skincare Routine';

  @override
  String get settingsOrderProducts => 'Product Order';

  @override
  String get settingsOrderSubtitle => 'Drag to personalise order';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsExportSubtitle => 'Local data backup';

  @override
  String get settingsSectionInfo => 'Info';

  @override
  String get settingsAbout => 'About & What\'s New';

  @override
  String settingsAboutSubtitle(Object version) {
    return 'Version $version • Changelog';
  }

  @override
  String get settingsCheckUpdates => 'Check for Updates';

  @override
  String get settingsCheckUpdatesSubtitle => 'Check for latest version';

  @override
  String get settingsPremium => 'Activate License';

  @override
  String get settingsPremiumSubtitle => 'Cloud backup & restore';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsLogout => 'Sign Out';

  @override
  String get settingsLogoutSubtitle => 'Reset profile and return to start';

  @override
  String get settingsLogoutConfirmContent =>
      'This will reset your profile and return you to the start screen. Your data will be preserved.';

  @override
  String get settingsLogoutConfirmBtn => 'Sign Out';

  @override
  String aboutVersionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutChangelog => 'What\'s New';

  @override
  String get exportDataTitle => 'Export Data';

  @override
  String get exportDataDesc =>
      'Save a backup of all your data as a ZIP archive';

  @override
  String get exportDataAction => 'Export';

  @override
  String get importDataTitle => 'Import Data';

  @override
  String get importDataDesc =>
      'Restore data from an existing backup (full replace or merge)';

  @override
  String get importDataAction => 'Import';

  @override
  String get exportSuccess => 'Export completed successfully';

  @override
  String exportError(Object error) {
    return 'Export error: $error';
  }

  @override
  String importError(Object error) {
    return 'Import error: $error';
  }

  @override
  String get importFileReadError => 'Cannot read the file';

  @override
  String get importInvalidFile => 'Invalid file';

  @override
  String get importDialogQuestion => 'How should existing data be handled?';

  @override
  String get importReplaceSuccess => 'Data replaced successfully';

  @override
  String get importMergeNoConflicts => 'Merge complete — no conflicts found';

  @override
  String get updateAllUpToDate => 'Everything is up to date';

  @override
  String get updateGoBack => 'Go back';

  @override
  String get updateDataIntact => 'Your data is saved and still exists';

  @override
  String get updateExportBefore => 'Before continuing:';

  @override
  String get updateBackupAction => 'Back up data';

  @override
  String updateNewProducts(Object count) {
    return 'New products ($count)';
  }

  @override
  String get updateNewProductsDesc =>
      'These products haven\'t been selected yet — add them in product selection';

  @override
  String updateDeprecated(Object count) {
    return 'Products no longer recommended ($count)';
  }

  @override
  String get updateDeprecatedDesc =>
      'These products are in your list but are no longer recommended';

  @override
  String get updateAcknowledge => 'Got it, continue';

  @override
  String get mergeNoData => 'No data to merge';

  @override
  String get mergeCompleting => 'Merging...';

  @override
  String get mergeFinish => 'Finish';

  @override
  String mergeProgressCounter(Object current, Object total) {
    return 'Conflict $current of $total';
  }

  @override
  String mergeRecordInfo(Object recordType, Object recordId) {
    return 'Type: $recordType  ·  ID: $recordId';
  }

  @override
  String get mergeChooseVersion => 'Choose which version to keep:';

  @override
  String get mergeKeepLocal => 'Keep local version';

  @override
  String get mergeKeepLocalDesc =>
      'Continue with the current data on this device';

  @override
  String get mergeUseArchive => 'Use backup version';

  @override
  String get mergeUseArchiveDesc => 'Replace with data from the backup file';

  @override
  String get mergeAllResolved => 'All conflicts resolved';

  @override
  String get mergeClickFinish => 'Press \"Finish\" to apply the merge';

  @override
  String get mergeSuccess => 'Merge completed successfully';

  @override
  String get premiumTitle => 'Cloud Backup — Coming Soon';

  @override
  String get premiumDescWeb =>
      'Enter an activation key to enable automatic backup and restore across devices';

  @override
  String get premiumDescAndroid =>
      'This feature is available in the web version only';

  @override
  String get premiumKeyLabel => 'Activation key';

  @override
  String get premiumActivate => 'Activate';

  @override
  String get skinLogNotesHint => 'Notes about your skin today...';

  @override
  String get skinLogAddPhotoLabel => 'Add a photo';

  @override
  String get skinLogTakePhoto => 'Take a photo';

  @override
  String get skinLogGallery => 'Choose from gallery';

  @override
  String get skinLogWebStorageWarning =>
      'Browser photos may be deleted by Safari. Back up your data.';

  @override
  String get dayDetailNoData => 'No data for this day';

  @override
  String get dayDetailJournalTooltip => 'Skin log';

  @override
  String get streakDaysInRow => 'streak days';

  @override
  String get streakOnTrack => 'On track for a perfect glow!';

  @override
  String get streakStartToday => 'Every day counts — let\'s start today ✨';

  @override
  String streakPersonalBest(Object days) {
    return 'Personal best · $days days';
  }

  @override
  String get streakNoGraces => 'No more \"oops, missed it...\"';

  @override
  String streakGracesLeft(Object count) {
    return '$count \"oops, missed it...\" left';
  }

  @override
  String streakSemanticDays(Object count) {
    return '$count streak days';
  }

  @override
  String get routineItemDone => 'Done';

  @override
  String get routineItemNotDone => 'Not done';

  @override
  String get routineItemFlexibleSlots => 'Morning • Evening';

  @override
  String get routineItemDeprecatedPill => 'Not recommended';

  @override
  String get routineItemDeprecatedWarning =>
      'This product is no longer recommended';

  @override
  String get backupReminderText => 'It is recommended to back up your data';

  @override
  String get backupNowAction => 'Back up';

  @override
  String get categoryItemsSuffix => 'items';

  @override
  String get fixedSlotMorningOnly => 'Morning only';

  @override
  String get fixedSlotEveningOnly => 'Evening only';

  @override
  String get skinStateCalm => 'Calm';

  @override
  String get skinStateMoist => 'Moist';

  @override
  String get skinStateOily => 'Oily';

  @override
  String get weekdayOverCapWarning => 'Over recommended — consider reducing';

  @override
  String get customProductTitle => 'Add Your Own Product';

  @override
  String get customProductPhotoLabel => 'Add photo (optional)';

  @override
  String get customProductNameLabel => 'Product name';

  @override
  String get customProductNameHint => 'e.g. Personal moisturising serum';

  @override
  String get customProductCategoryLabel => 'Category';

  @override
  String get customProductSlotLabel => 'Routine time';

  @override
  String get customProductSlotBoth => 'Morning + Evening';

  @override
  String get customProductFrequencyLabel => 'Frequency';

  @override
  String get customProductFrequencyWeekly => 'Non Daily';

  @override
  String get customProductTimesPerWeekLabel => 'Times per week:';

  @override
  String get customProductSave => 'Add to my routine';

  @override
  String get customProductEditButton => 'Edit product';

  @override
  String get customProductEditTitle => 'Edit Product';

  @override
  String get customProductEditSave => 'Save changes';

  @override
  String get customProductDeleteButton => 'Remove product';

  @override
  String get customProductDeleteConfirmTitle => 'Remove Product';

  @override
  String get customProductDeleteConfirmBody =>
      'The product will be permanently removed from your list. This action cannot be undone.';

  @override
  String get customProductDeleteConfirmAction => 'Remove';

  @override
  String get customProductCommentLabel => 'Note';

  @override
  String get customProductCommentHint =>
      'Personal note about this product (optional)';

  @override
  String customProductCommentLanguageNote(Object language) {
    return '(written in $language)';
  }

  @override
  String scheduleConflictWarning(Object slot) {
    return 'There are still conflict days in $slot';
  }

  @override
  String get slotMorningRoutine => 'Morning Routine';

  @override
  String get slotEveningRoutine => 'Evening Routine';

  @override
  String scheduleStepBadge(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get scheduleGuidedBothSlots =>
      'Schedule morning routine first, then we\'ll continue to the evening routine together. You can exceed the recommendation — we\'ll just remind you.';

  @override
  String scheduleGuidedSingleSlot(Object routine) {
    return 'Which days to use each product in $routine…';
  }

  @override
  String scheduleContinueTo(Object routine) {
    return 'Continue to $routine';
  }

  @override
  String scheduleNextStepPending(Object routine) {
    return 'One more step — $routine is waiting to be scheduled';
  }

  @override
  String scheduleConflictWarningCount(int count, Object label) {
    return 'There are still $count conflict days in $label';
  }

  @override
  String get scheduleCustomizeDays => 'Select days';

  @override
  String get scheduleDailyDefaultSuffix => '· every day by default';

  @override
  String get scheduleDailyCollapse => 'Collapse';

  @override
  String get scheduleBadgeNoneSelected => 'None selected';

  @override
  String get aboutDisclaimer =>
      'This app is intended for personal tracking only and does not constitute medical or cosmetic advice.';

  @override
  String get aboutPrivacyPolicyLink => 'Privacy Policy';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Hebrew / English';

  @override
  String get settingsLanguageHebrew => 'עברית';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get calendarDayFullSun => 'Sunday';

  @override
  String get calendarDayFullMon => 'Monday';

  @override
  String get calendarDayFullTue => 'Tuesday';

  @override
  String get calendarDayFullWed => 'Wednesday';

  @override
  String get calendarDayFullThu => 'Thursday';

  @override
  String get calendarDayFullFri => 'Friday';

  @override
  String get calendarDayFullSat => 'Saturday';

  @override
  String get settingsProfileEdit => 'Edit Profile';

  @override
  String get settingsProfileGuest => 'Guest';

  @override
  String get settingsProfileNameLabel => 'Your name';

  @override
  String get settingsProfileNameHint => 'Enter your name';

  @override
  String get settingsProfileSave => 'Save';

  @override
  String get backupNeverBacked => 'You have never backed up your data';

  @override
  String backupDaysAgo(int days) {
    return 'Last backup $days days ago';
  }

  @override
  String get onboardingSelectLanguage => 'Choose language';

  @override
  String get onboardingFrequencyWeeklyShort => 'Weekly';

  @override
  String get onboardingWelcomeNeutral => 'Welcome';

  @override
  String get onboardingTellUsNeutral => 'Tell us about you';

  @override
  String get onboardingStartNeutral => 'Let\'s Begin';

  @override
  String get continueActionNeutral => 'Continue';
}
