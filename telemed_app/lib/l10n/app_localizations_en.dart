// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Telemed Chatbot';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to talk to your health assistant';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get login => 'Log in';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get createAccount => 'Create account';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get language => 'Language';

  @override
  String get phone => 'Phone';

  @override
  String get home => 'Home';

  @override
  String get logout => 'Log out';

  @override
  String hello(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get chatComingSoon => 'Chat screen coming soon';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get errEmail => 'Enter a valid email';

  @override
  String get errPasswordEmpty => 'Enter your password';

  @override
  String get errName => 'Enter your name';

  @override
  String get errPhone => 'Enter a valid Kenyan number (07… or 01…)';

  @override
  String get errPasswordShort => 'At least 8 characters';

  @override
  String get errPasswordMatch => 'Passwords do not match';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get navChat => 'Chat';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get healthAssistant => 'Health Assistant';

  @override
  String get disclaimer =>
      'AI assistant, not a doctor. In an emergency call 999 or 112.';

  @override
  String get chatWelcomeTitle => 'How are you feeling today?';

  @override
  String get chatWelcomeBody =>
      'Describe your symptoms in English or Kiswahili and I will suggest the right level of care.';

  @override
  String get chatTryExample => 'Try an example:';

  @override
  String get chatHint => 'Describe your symptoms…';

  @override
  String get thinking => 'Analysing your symptoms…';

  @override
  String get chatError => 'Sorry, something went wrong. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get newConsultation => 'New consultation';

  @override
  String get triageSelfCare => 'Self-care';

  @override
  String get triageSelfCareDesc =>
      'You can manage this at home. Monitor your symptoms.';

  @override
  String get triagePharmacy => 'Visit a pharmacy';

  @override
  String get triagePharmacyDesc =>
      'A pharmacist can advise you on suitable treatment.';

  @override
  String get triageClinic => 'Visit a clinic';

  @override
  String get triageClinicDesc =>
      'Please visit a clinic or health centre within 24 hours.';

  @override
  String get triageEmergency => 'Emergency';

  @override
  String get triageEmergencyDesc =>
      'Seek emergency care now. Call 999 or 112, or go to the nearest hospital.';

  @override
  String get historyEmpty => 'No consultations yet';

  @override
  String get historyEmptyBody => 'Your past consultations will appear here.';

  @override
  String get historyError => 'Could not load your history.';

  @override
  String get consultationDetails => 'Consultation details';

  @override
  String get personalInfo => 'Personal information';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get chronicConditions => 'Chronic conditions';

  @override
  String get chronicHint => 'e.g. diabetes, hypertension, asthma';

  @override
  String get notSet => 'Not set';

  @override
  String get save => 'Save';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get profileSaveFailed => 'Could not update profile';

  @override
  String get profileContextNote =>
      'Your profile helps the assistant give safer, more relevant advice.';

  @override
  String get settings => 'Settings';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody =>
      'You will need to log in again to use the assistant.';

  @override
  String get cancel => 'Cancel';

  @override
  String get statConsultations => 'Consultations';

  @override
  String get statAge => 'Age';

  @override
  String get statLastVisit => 'Last visit';

  @override
  String get assistantStatus => 'AI assistant · English & Kiswahili';

  @override
  String get careLevels => 'Care levels I can recommend';

  @override
  String get historySubtitle => 'Your consultation timeline';

  @override
  String get registerSubtitle =>
      'Join to get trusted health guidance in English or Kiswahili';

  @override
  String get findPharmacy => 'Find a pharmacy nearby';

  @override
  String get findClinic => 'Find a clinic nearby';

  @override
  String get findHospital => 'Find a hospital nearby';

  @override
  String get callEmergency => 'Call 999';

  @override
  String get openMapsError => 'Could not open maps on this device';

  @override
  String get smsSent => 'SMS summary sent to your phone';
}
