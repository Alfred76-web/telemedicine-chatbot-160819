// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Telemed Chatbot';

  @override
  String get welcomeBack => 'Karibu tena';

  @override
  String get loginSubtitle => 'Ingia ili kuzungumza na msaidizi wako wa afya';

  @override
  String get email => 'Barua pepe';

  @override
  String get password => 'Nenosiri';

  @override
  String get confirmPassword => 'Thibitisha nenosiri';

  @override
  String get login => 'Ingia';

  @override
  String get noAccount => 'Huna akaunti? Jisajili';

  @override
  String get createAccount => 'Fungua akaunti';

  @override
  String get fullName => 'Jina kamili';

  @override
  String get phoneNumber => 'Nambari ya simu';

  @override
  String get preferredLanguage => 'Lugha unayopendelea';

  @override
  String get language => 'Lugha';

  @override
  String get phone => 'Simu';

  @override
  String get home => 'Nyumbani';

  @override
  String get logout => 'Toka';

  @override
  String hello(String name) {
    return 'Habari, $name 👋';
  }

  @override
  String get chatComingSoon => 'Skrini ya mazungumzo inakuja hivi karibuni';

  @override
  String get comingSoon => 'Inakuja hivi karibuni';

  @override
  String get errEmail => 'Weka barua pepe sahihi';

  @override
  String get errPasswordEmpty => 'Weka nenosiri lako';

  @override
  String get errName => 'Weka jina lako';

  @override
  String get errPhone => 'Weka nambari sahihi ya Kenya (07… au 01…)';

  @override
  String get errPasswordShort => 'Angalau herufi 8';

  @override
  String get errPasswordMatch => 'Manenosiri hayalingani';

  @override
  String get loginFailed => 'Imeshindikana kuingia';

  @override
  String get registrationFailed => 'Usajili umeshindikana';

  @override
  String get navChat => 'Mazungumzo';

  @override
  String get navHistory => 'Historia';

  @override
  String get navProfile => 'Wasifu';

  @override
  String get healthAssistant => 'Msaidizi wa Afya';

  @override
  String get disclaimer =>
      'Msaidizi wa AI, si daktari. Katika dharura piga 999 au 112.';

  @override
  String get chatWelcomeTitle => 'Unajisikiaje leo?';

  @override
  String get chatWelcomeBody =>
      'Eleza dalili zako kwa Kiingereza au Kiswahili nami nitakushauri kiwango sahihi cha huduma.';

  @override
  String get chatTryExample => 'Jaribu mfano:';

  @override
  String get chatHint => 'Eleza dalili zako…';

  @override
  String get thinking => 'Inachambua dalili zako…';

  @override
  String get chatError => 'Samahani, kuna hitilafu. Tafadhali jaribu tena.';

  @override
  String get retry => 'Jaribu tena';

  @override
  String get newConsultation => 'Mashauriano mapya';

  @override
  String get triageSelfCare => 'Kujitunza';

  @override
  String get triageSelfCareDesc =>
      'Unaweza kujitunza nyumbani. Fuatilia dalili zako.';

  @override
  String get triagePharmacy => 'Tembelea duka la dawa';

  @override
  String get triagePharmacyDesc =>
      'Mfamasia anaweza kukushauri kuhusu matibabu yanayofaa.';

  @override
  String get triageClinic => 'Tembelea kliniki';

  @override
  String get triageClinicDesc =>
      'Tafadhali tembelea kliniki au kituo cha afya ndani ya saa 24.';

  @override
  String get triageEmergency => 'Dharura';

  @override
  String get triageEmergencyDesc =>
      'Tafuta huduma ya dharura sasa. Piga 999 au 112, au nenda hospitali iliyo karibu.';

  @override
  String get historyEmpty => 'Bado hakuna mashauriano';

  @override
  String get historyEmptyBody => 'Mashauriano yako ya awali yataonekana hapa.';

  @override
  String get historyError => 'Imeshindikana kupakia historia yako.';

  @override
  String get consultationDetails => 'Maelezo ya mashauriano';

  @override
  String get personalInfo => 'Taarifa binafsi';

  @override
  String get editProfile => 'Hariri wasifu';

  @override
  String get dateOfBirth => 'Tarehe ya kuzaliwa';

  @override
  String get gender => 'Jinsia';

  @override
  String get genderMale => 'Mwanaume';

  @override
  String get genderFemale => 'Mwanamke';

  @override
  String get genderOther => 'Nyingine';

  @override
  String get chronicConditions => 'Magonjwa sugu';

  @override
  String get chronicHint => 'mf. kisukari, shinikizo la damu, pumu';

  @override
  String get notSet => 'Haijawekwa';

  @override
  String get save => 'Hifadhi';

  @override
  String get profileSaved => 'Wasifu umesasishwa';

  @override
  String get profileSaveFailed => 'Imeshindikana kusasisha wasifu';

  @override
  String get profileContextNote =>
      'Wasifu wako humsaidia msaidizi kutoa ushauri salama na unaofaa zaidi.';

  @override
  String get settings => 'Mipangilio';

  @override
  String get logoutConfirmTitle => 'Toka?';

  @override
  String get logoutConfirmBody =>
      'Utahitaji kuingia tena ili kutumia msaidizi.';

  @override
  String get cancel => 'Ghairi';

  @override
  String get statConsultations => 'Mashauriano';

  @override
  String get statAge => 'Umri';

  @override
  String get statLastVisit => 'Ziara ya mwisho';

  @override
  String get assistantStatus => 'Msaidizi wa AI · Kiingereza na Kiswahili';

  @override
  String get careLevels => 'Viwango vya huduma ninavyoweza kupendekeza';

  @override
  String get historySubtitle => 'Historia ya mashauriano yako';

  @override
  String get registerSubtitle =>
      'Jisajili upate ushauri wa afya unaoaminika kwa Kiingereza au Kiswahili';

  @override
  String get findPharmacy => 'Tafuta duka la dawa karibu';

  @override
  String get findClinic => 'Tafuta kliniki karibu';

  @override
  String get findHospital => 'Tafuta hospitali karibu';

  @override
  String get callEmergency => 'Piga 999';

  @override
  String get openMapsError => 'Imeshindikana kufungua ramani kwenye kifaa hiki';

  @override
  String get smsSent => 'Muhtasari umetumwa kwa SMS kwenye simu yako';
}
