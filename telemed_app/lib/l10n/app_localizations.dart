import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('sw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Telemed Chatbot'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to talk to your health assistant'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String hello(String name);

  /// No description provided for @chatComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat screen coming soon'**
  String get chatComingSoon;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @errEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get errEmail;

  /// No description provided for @errPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get errPasswordEmpty;

  /// No description provided for @errName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get errName;

  /// No description provided for @errPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Kenyan number (07… or 01…)'**
  String get errPhone;

  /// No description provided for @errPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get errPasswordShort;

  /// No description provided for @errPasswordMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errPasswordMatch;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @healthAssistant.
  ///
  /// In en, this message translates to:
  /// **'Health Assistant'**
  String get healthAssistant;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI assistant, not a doctor. In an emergency call 999 or 112.'**
  String get disclaimer;

  /// No description provided for @chatWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get chatWelcomeTitle;

  /// No description provided for @chatWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms in English or Kiswahili and I will suggest the right level of care.'**
  String get chatWelcomeBody;

  /// No description provided for @chatTryExample.
  ///
  /// In en, this message translates to:
  /// **'Try an example:'**
  String get chatTryExample;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms…'**
  String get chatHint;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Analysing your symptoms…'**
  String get thinking;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong. Please try again.'**
  String get chatError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @newConsultation.
  ///
  /// In en, this message translates to:
  /// **'New consultation'**
  String get newConsultation;

  /// No description provided for @triageSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Self-care'**
  String get triageSelfCare;

  /// No description provided for @triageSelfCareDesc.
  ///
  /// In en, this message translates to:
  /// **'You can manage this at home. Monitor your symptoms.'**
  String get triageSelfCareDesc;

  /// No description provided for @triagePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Visit a pharmacy'**
  String get triagePharmacy;

  /// No description provided for @triagePharmacyDesc.
  ///
  /// In en, this message translates to:
  /// **'A pharmacist can advise you on suitable treatment.'**
  String get triagePharmacyDesc;

  /// No description provided for @triageClinic.
  ///
  /// In en, this message translates to:
  /// **'Visit a clinic'**
  String get triageClinic;

  /// No description provided for @triageClinicDesc.
  ///
  /// In en, this message translates to:
  /// **'Please visit a clinic or health centre within 24 hours.'**
  String get triageClinicDesc;

  /// No description provided for @triageEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get triageEmergency;

  /// No description provided for @triageEmergencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Seek emergency care now. Call 999 or 112, or go to the nearest hospital.'**
  String get triageEmergencyDesc;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No consultations yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your past consultations will appear here.'**
  String get historyEmptyBody;

  /// No description provided for @historyError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your history.'**
  String get historyError;

  /// No description provided for @consultationDetails.
  ///
  /// In en, this message translates to:
  /// **'Consultation details'**
  String get consultationDetails;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @chronicConditions.
  ///
  /// In en, this message translates to:
  /// **'Chronic conditions'**
  String get chronicConditions;

  /// No description provided for @chronicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. diabetes, hypertension, asthma'**
  String get chronicHint;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile'**
  String get profileSaveFailed;

  /// No description provided for @profileContextNote.
  ///
  /// In en, this message translates to:
  /// **'Your profile helps the assistant give safer, more relevant advice.'**
  String get profileContextNote;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again to use the assistant.'**
  String get logoutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @statConsultations.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get statConsultations;

  /// No description provided for @statAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get statAge;

  /// No description provided for @statLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get statLastVisit;

  /// No description provided for @assistantStatus.
  ///
  /// In en, this message translates to:
  /// **'AI assistant · English & Kiswahili'**
  String get assistantStatus;

  /// No description provided for @careLevels.
  ///
  /// In en, this message translates to:
  /// **'Care levels I can recommend'**
  String get careLevels;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your consultation timeline'**
  String get historySubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join to get trusted health guidance in English or Kiswahili'**
  String get registerSubtitle;

  /// No description provided for @findPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Find a pharmacy nearby'**
  String get findPharmacy;

  /// No description provided for @findClinic.
  ///
  /// In en, this message translates to:
  /// **'Find a clinic nearby'**
  String get findClinic;

  /// No description provided for @findHospital.
  ///
  /// In en, this message translates to:
  /// **'Find a hospital nearby'**
  String get findHospital;

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call 999'**
  String get callEmergency;

  /// No description provided for @openMapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps on this device'**
  String get openMapsError;

  /// No description provided for @smsSent.
  ///
  /// In en, this message translates to:
  /// **'SMS summary sent to your phone'**
  String get smsSent;
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
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
