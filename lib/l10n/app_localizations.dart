import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

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
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MyHarur'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get tabNews;

  /// No description provided for @tabWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get tabWeather;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get saveFailed;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

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

  /// No description provided for @authFooter.
  ///
  /// In en, this message translates to:
  /// **'A QenBel product'**
  String get authFooter;

  /// No description provided for @noBackend.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server right now.'**
  String get noBackend;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @obUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get obUsernameTitle;

  /// No description provided for @obUsernameSub.
  ///
  /// In en, this message translates to:
  /// **'This is your public handle in MyHarur. You can\'t change it later.'**
  String get obUsernameSub;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers and underscores only.'**
  String get usernameHint;

  /// No description provided for @usernameShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 3 characters.'**
  String get usernameShort;

  /// No description provided for @usernameLong.
  ///
  /// In en, this message translates to:
  /// **'Use 30 characters or fewer.'**
  String get usernameLong;

  /// No description provided for @usernameChars.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers and _ only.'**
  String get usernameChars;

  /// No description provided for @usernameReserved.
  ///
  /// In en, this message translates to:
  /// **'That username is reserved.'**
  String get usernameReserved;

  /// No description provided for @usernameBad.
  ///
  /// In en, this message translates to:
  /// **'That username isn\'t allowed.'**
  String get usernameBad;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken. Try another.'**
  String get usernameTaken;

  /// No description provided for @obProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get obProfileTitle;

  /// No description provided for @obProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Your name helps neighbours recognise your reports.'**
  String get obProfileSub;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get nameRequired;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @bloodGroupOptional.
  ///
  /// In en, this message translates to:
  /// **'Blood group (optional)'**
  String get bloodGroupOptional;

  /// No description provided for @obOccupationTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you do?'**
  String get obOccupationTitle;

  /// No description provided for @obOccupationSub.
  ///
  /// In en, this message translates to:
  /// **'This helps us show what matters to you.'**
  String get obOccupationSub;

  /// No description provided for @occStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get occStudent;

  /// No description provided for @occShopOwner.
  ///
  /// In en, this message translates to:
  /// **'Shop owner'**
  String get occShopOwner;

  /// No description provided for @occEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get occEmployee;

  /// No description provided for @occGovtEmployee.
  ///
  /// In en, this message translates to:
  /// **'Government employee'**
  String get occGovtEmployee;

  /// No description provided for @occFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get occFarmer;

  /// No description provided for @occOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get occOther;

  /// No description provided for @greetMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetMorning;

  /// No description provided for @greetAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetAfternoon;

  /// No description provided for @greetEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetEvening;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get catRoad;

  /// No description provided for @catElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get catElectricity;

  /// No description provided for @catWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get catWater;

  /// No description provided for @catGovt.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get catGovt;

  /// No description provided for @alertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts right now'**
  String get alertsEmptyTitle;

  /// No description provided for @alertsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been reported. Tap + to report an issue.'**
  String get alertsEmptyBody;

  /// No description provided for @alertsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load alerts'**
  String get alertsErrorTitle;

  /// No description provided for @alertsErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get alertsErrorBody;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @official.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get official;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @reviewWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for review'**
  String reviewWaiting(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String daysAgo(int n);

  /// No description provided for @submitTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get submitTitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get titleHint;

  /// No description provided for @detailsHint.
  ///
  /// In en, this message translates to:
  /// **'Where, how serious, and since when?'**
  String get detailsHint;

  /// No description provided for @titleMin.
  ///
  /// In en, this message translates to:
  /// **'Add a short title (5 or more characters).'**
  String get titleMin;

  /// No description provided for @detailsMin.
  ///
  /// In en, this message translates to:
  /// **'Add a little more detail (10 or more characters).'**
  String get detailsMin;

  /// No description provided for @markEmergency.
  ///
  /// In en, this message translates to:
  /// **'Mark as emergency'**
  String get markEmergency;

  /// No description provided for @emergencyNote.
  ///
  /// In en, this message translates to:
  /// **'Reviewed first. False reports cost you this option.'**
  String get emergencyNote;

  /// No description provided for @emergencyRevoked.
  ///
  /// In en, this message translates to:
  /// **'Emergency tagging is off for your account after repeated false reports.'**
  String get emergencyRevoked;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @submittedMsg.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Your report was sent for review and will appear once approved.'**
  String get submittedMsg;

  /// No description provided for @errAutoRejected.
  ///
  /// In en, this message translates to:
  /// **'This report contains language that isn\'t allowed. Please reword it and try again.'**
  String get errAutoRejected;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent several reports recently. Please wait a while before sending another.'**
  String get errRateLimited;

  /// No description provided for @errInvalidLength.
  ///
  /// In en, this message translates to:
  /// **'Title needs 5 to 100 characters and details 10 to 500.'**
  String get errInvalidLength;

  /// No description provided for @errAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account can\'t submit reports right now. Please sign in again.'**
  String get errAccount;

  /// No description provided for @errSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'The report didn\'t send. Check your connection and try again.'**
  String get errSubmitFailed;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @locHarur.
  ///
  /// In en, this message translates to:
  /// **'Harur'**
  String get locHarur;

  /// No description provided for @locDharmapuri.
  ///
  /// In en, this message translates to:
  /// **'Dharmapuri'**
  String get locDharmapuri;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}°'**
  String feelsLike(int temp);

  /// No description provided for @highLow.
  ///
  /// In en, this message translates to:
  /// **'H {high}°  L {low}°'**
  String highLow(int high, int low);

  /// No description provided for @hourlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Next 24 hours'**
  String get hourlyTitle;

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'7-day forecast'**
  String get dailyTitle;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @rainChance.
  ///
  /// In en, this message translates to:
  /// **'Chance of rain'**
  String get rainChance;

  /// No description provided for @uvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV index'**
  String get uvIndex;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAt(String time);

  /// No description provided for @weatherErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the forecast'**
  String get weatherErrorTitle;

  /// No description provided for @weatherErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and pull down to try again.'**
  String get weatherErrorBody;

  /// No description provided for @rainAlert.
  ///
  /// In en, this message translates to:
  /// **'Rain likely today: {chance}% chance'**
  String rainAlert(int chance);

  /// No description provided for @heatAlert.
  ///
  /// In en, this message translates to:
  /// **'Hot day ahead: up to {temp}°'**
  String heatAlert(int temp);

  /// No description provided for @weatherCredit.
  ///
  /// In en, this message translates to:
  /// **'Weather data by Open-Meteo.com'**
  String get weatherCredit;

  /// No description provided for @wxClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wxClear;

  /// No description provided for @wxMostlyClear.
  ///
  /// In en, this message translates to:
  /// **'Mostly clear'**
  String get wxMostlyClear;

  /// No description provided for @wxPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get wxPartlyCloudy;

  /// No description provided for @wxOvercast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get wxOvercast;

  /// No description provided for @wxFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get wxFog;

  /// No description provided for @wxDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get wxDrizzle;

  /// No description provided for @wxRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get wxRain;

  /// No description provided for @wxHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get wxHeavyRain;

  /// No description provided for @wxShowers.
  ///
  /// In en, this message translates to:
  /// **'Showers'**
  String get wxShowers;

  /// No description provided for @wxThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get wxThunderstorm;

  /// No description provided for @wxUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get wxUnknown;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsTitle;

  /// No description provided for @newsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get newsAll;

  /// No description provided for @newsTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get newsTraffic;

  /// No description provided for @newsWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get newsWeather;

  /// No description provided for @newsCivic.
  ///
  /// In en, this message translates to:
  /// **'Civic'**
  String get newsCivic;

  /// No description provided for @newsFarming.
  ///
  /// In en, this message translates to:
  /// **'Farming'**
  String get newsFarming;

  /// No description provided for @newsGeneral.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get newsGeneral;

  /// No description provided for @areaAll.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get areaAll;

  /// No description provided for @newsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get newsEmptyTitle;

  /// No description provided for @newsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Local headlines appear here and refresh about every 30 minutes.'**
  String get newsEmptyBody;

  /// No description provided for @newsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the news'**
  String get newsErrorTitle;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a number to call.'**
  String get helpSubtitle;

  /// No description provided for @helpEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get helpEmergency;

  /// No description provided for @helpCivic.
  ///
  /// In en, this message translates to:
  /// **'Civic and safety'**
  String get helpCivic;

  /// No description provided for @helpNote.
  ///
  /// In en, this message translates to:
  /// **'These are national and state helplines. Numbers work from any phone.'**
  String get helpNote;

  /// No description provided for @hlAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get hlAmbulance;

  /// No description provided for @hlAmbulanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Emergency medical response, 24 hours'**
  String get hlAmbulanceDesc;

  /// No description provided for @hlPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get hlPolice;

  /// No description provided for @hlPoliceDesc.
  ///
  /// In en, this message translates to:
  /// **'Report a crime or emergency'**
  String get hlPoliceDesc;

  /// No description provided for @hlFire.
  ///
  /// In en, this message translates to:
  /// **'Fire and rescue'**
  String get hlFire;

  /// No description provided for @hlFireDesc.
  ///
  /// In en, this message translates to:
  /// **'Fire, rescue and accidents'**
  String get hlFireDesc;

  /// No description provided for @hlUnified.
  ///
  /// In en, this message translates to:
  /// **'All-in-one emergency'**
  String get hlUnified;

  /// No description provided for @hlUnifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Police, fire and ambulance'**
  String get hlUnifiedDesc;

  /// No description provided for @hlPower.
  ///
  /// In en, this message translates to:
  /// **'Electricity complaints'**
  String get hlPower;

  /// No description provided for @hlPowerDesc.
  ///
  /// In en, this message translates to:
  /// **'Power cuts and line faults (TANGEDCO)'**
  String get hlPowerDesc;

  /// No description provided for @hlDisaster.
  ///
  /// In en, this message translates to:
  /// **'Disaster management'**
  String get hlDisaster;

  /// No description provided for @hlDisasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Floods, storms and relief'**
  String get hlDisasterDesc;

  /// No description provided for @hlWomen.
  ///
  /// In en, this message translates to:
  /// **'Women helpline'**
  String get hlWomen;

  /// No description provided for @hlWomenDesc.
  ///
  /// In en, this message translates to:
  /// **'Support and safety, 24 hours'**
  String get hlWomenDesc;

  /// No description provided for @hlChild.
  ///
  /// In en, this message translates to:
  /// **'Childline'**
  String get hlChild;

  /// No description provided for @hlChildDesc.
  ///
  /// In en, this message translates to:
  /// **'Help for children in need'**
  String get hlChildDesc;

  /// No description provided for @hlHighway.
  ///
  /// In en, this message translates to:
  /// **'Highway helpline'**
  String get hlHighway;

  /// No description provided for @hlHighwayDesc.
  ///
  /// In en, this message translates to:
  /// **'Breakdowns and accidents on national highways'**
  String get hlHighwayDesc;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @staffTools.
  ///
  /// In en, this message translates to:
  /// **'Staff tools'**
  String get staffTools;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanel;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @memberId.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get memberId;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get bloodGroup;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @emergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get emergencyContactName;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get emergencyContactPhone;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters, with letters and numbers.'**
  String get passwordRules;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters with letters and numbers.'**
  String get passwordWeak;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get passwordMismatch;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved. You can now sign in with {username}.'**
  String passwordSaved(String username);

  /// No description provided for @passwordFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the password. Sign in again and retry.'**
  String get passwordFailed;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of MyHarur?'**
  String get signOutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your login and profile. Reports that are already live stay visible but are no longer linked to you. This can\'t be undone.'**
  String get deleteBody;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Check your connection and try again.'**
  String get deleteFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'MyHarur · A QenBel product'**
  String get appVersion;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @statUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get statUsers;

  /// No description provided for @statStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get statStaff;

  /// No description provided for @statPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get statPending;

  /// No description provided for @statPublished.
  ///
  /// In en, this message translates to:
  /// **'Published alerts'**
  String get statPublished;

  /// No description provided for @statAutoRejected.
  ///
  /// In en, this message translates to:
  /// **'Auto-rejected'**
  String get statAutoRejected;

  /// No description provided for @statNews.
  ///
  /// In en, this message translates to:
  /// **'News stories'**
  String get statNews;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users and roles'**
  String get adminUsers;

  /// No description provided for @adminUsersSub.
  ///
  /// In en, this message translates to:
  /// **'Find people and manage their roles.'**
  String get adminUsersSub;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search name, username or email'**
  String get searchUsers;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching users'**
  String get noResults;

  /// No description provided for @roleResident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get roleResident;

  /// No description provided for @roleModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get roleModerator;

  /// No description provided for @roleGovt.
  ///
  /// In en, this message translates to:
  /// **'Government official'**
  String get roleGovt;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleSuperadmin.
  ///
  /// In en, this message translates to:
  /// **'Super admin'**
  String get roleSuperadmin;

  /// No description provided for @roleFailed.
  ///
  /// In en, this message translates to:
  /// **'That change isn\'t allowed or didn\'t save.'**
  String get roleFailed;

  /// No description provided for @rolesFor.
  ///
  /// In en, this message translates to:
  /// **'Roles for {name}'**
  String rolesFor(String name);

  /// No description provided for @adminFilters.
  ///
  /// In en, this message translates to:
  /// **'Word filters'**
  String get adminFilters;

  /// No description provided for @adminFiltersSub.
  ///
  /// In en, this message translates to:
  /// **'Blocked and flagged words for reports.'**
  String get adminFiltersSub;

  /// No description provided for @blockedWords.
  ///
  /// In en, this message translates to:
  /// **'Blocked words'**
  String get blockedWords;

  /// No description provided for @blockedWordsNote.
  ///
  /// In en, this message translates to:
  /// **'Reports containing these are rejected automatically.'**
  String get blockedWordsNote;

  /// No description provided for @flaggedWords.
  ///
  /// In en, this message translates to:
  /// **'Flagged words'**
  String get flaggedWords;

  /// No description provided for @flaggedWordsNote.
  ///
  /// In en, this message translates to:
  /// **'Reports containing these go to review with a warning.'**
  String get flaggedWordsNote;

  /// No description provided for @addWord.
  ///
  /// In en, this message translates to:
  /// **'Add a word'**
  String get addWord;

  /// No description provided for @addWordHint.
  ///
  /// In en, this message translates to:
  /// **'Word or phrase'**
  String get addWordHint;

  /// No description provided for @wordFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add that word.'**
  String get wordFailed;

  /// No description provided for @tamilTanglish.
  ///
  /// In en, this message translates to:
  /// **'Tamil (Tanglish)'**
  String get tamilTanglish;

  /// No description provided for @tamilScript.
  ///
  /// In en, this message translates to:
  /// **'Tamil script'**
  String get tamilScript;

  /// No description provided for @englishWord.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishWord;

  /// No description provided for @noWords.
  ///
  /// In en, this message translates to:
  /// **'No words yet'**
  String get noWords;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get reviewTitle;

  /// No description provided for @reviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for review'**
  String reviewCount(int count);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this report'**
  String get rejectTitle;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reasonSpam;

  /// No description provided for @reasonFalse.
  ///
  /// In en, this message translates to:
  /// **'False or misleading'**
  String get reasonFalse;

  /// No description provided for @reasonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get reasonDuplicate;

  /// No description provided for @reasonLowQuality.
  ///
  /// In en, this message translates to:
  /// **'Too vague'**
  String get reasonLowQuality;

  /// No description provided for @reasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get reasonInappropriate;

  /// No description provided for @rejectStrikeNote.
  ///
  /// In en, this message translates to:
  /// **'This was tagged Emergency. Choosing False or Spam adds a strike to the author.'**
  String get rejectStrikeNote;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @nothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'No reports are waiting for review.'**
  String get nothingWaiting;

  /// No description provided for @reviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the queue'**
  String get reviewLoadFailed;

  /// No description provided for @decisionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that decision. It may already have been reviewed.'**
  String get decisionFailed;

  /// No description provided for @flagDangerous.
  ///
  /// In en, this message translates to:
  /// **'Dangerous wording'**
  String get flagDangerous;

  /// No description provided for @flagLink.
  ///
  /// In en, this message translates to:
  /// **'Contains a link'**
  String get flagLink;

  /// No description provided for @flagPhone.
  ///
  /// In en, this message translates to:
  /// **'Contains a phone number'**
  String get flagPhone;

  /// No description provided for @staffAuthor.
  ///
  /// In en, this message translates to:
  /// **'Staff author'**
  String get staffAuthor;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get locationOptional;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocation;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get addressDetails;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'House, street or landmark'**
  String get addressHint;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search a place or address'**
  String get searchPlace;

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found. Try different words, or drag the map.'**
  String get noPlacesFound;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t available right now. You can still drag the map.'**
  String get searchFailed;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLocation;

  /// No description provided for @saveTextOnly.
  ///
  /// In en, this message translates to:
  /// **'Save without a map pin'**
  String get saveTextOnly;

  /// No description provided for @removeLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLocation;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off. Turn it on to use your current location.'**
  String get locationOff;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. You can still search or drag the map.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for MyHarur. Allow it in Settings to use this.'**
  String get locationDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Try again or drag the map.'**
  String get locationTimeout;

  /// No description provided for @mapCredit.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapCredit;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get getDirections;

  /// No description provided for @tabSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get tabSignIn;

  /// No description provided for @tabRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get tabRegister;

  /// No description provided for @signInExplain.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google, or with your username and password.'**
  String get signInExplain;

  /// No description provided for @registerWelcome.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerWelcome;

  /// No description provided for @registerExplain.
  ///
  /// In en, this message translates to:
  /// **'Registration uses Google, so there is no password to remember. You can add a username and password afterwards.'**
  String get registerExplain;

  /// No description provided for @registerWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Register with Google'**
  String get registerWithGoogle;

  /// No description provided for @usernameSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with username'**
  String get usernameSignIn;

  /// No description provided for @usernameField.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameField;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get wrongCredentials;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {minutes} min.'**
  String tooManyAttempts(int minutes);

  /// No description provided for @noPasswordYet.
  ///
  /// In en, this message translates to:
  /// **'No password yet? Sign in with Google, then add one in Account.'**
  String get noPasswordYet;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @obPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a password?'**
  String get obPasswordTitle;

  /// No description provided for @obPasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Optional. With a password you can sign in with your username as well as Google.'**
  String get obPasswordSub;

  /// No description provided for @passwordForUsername.
  ///
  /// In en, this message translates to:
  /// **'Username password'**
  String get passwordForUsername;

  /// No description provided for @passwordForUsernameSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your @username and a password, as well as Google.'**
  String get passwordForUsernameSub;

  /// No description provided for @signInSection.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get signInSection;

  /// No description provided for @mfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in'**
  String get mfaTitle;

  /// No description provided for @mfaRequired.
  ///
  /// In en, this message translates to:
  /// **'Admins and super admins must protect their account with an authenticator app.'**
  String get mfaRequired;

  /// No description provided for @mfaScan.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with an authenticator app such as Google Authenticator, Microsoft Authenticator or Aegis.'**
  String get mfaScan;

  /// No description provided for @mfaManualKey.
  ///
  /// In en, this message translates to:
  /// **'Or type this key into the app'**
  String get mfaManualKey;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @mfaEnterCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get mfaEnterCode;

  /// No description provided for @mfaVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get mfaVerify;

  /// No description provided for @mfaBadCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Check the code and try again.'**
  String get mfaBadCode;

  /// No description provided for @mfaEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor is on'**
  String get mfaEnabled;

  /// No description provided for @mfaChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get mfaChallengeTitle;

  /// No description provided for @mfaChallengeSub.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app and enter the 6-digit code for MyHarur.'**
  String get mfaChallengeSub;

  /// No description provided for @mfaSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start two-factor setup. Check your connection and try again.'**
  String get mfaSetupFailed;

  /// No description provided for @crashTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get crashTitle;

  /// No description provided for @crashBody.
  ///
  /// In en, this message translates to:
  /// **'MyHarur hit a problem and had to stop. Your data is safe.'**
  String get crashBody;

  /// No description provided for @restartApp.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartApp;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report this problem'**
  String get reportProblem;

  /// No description provided for @problemReported.
  ///
  /// In en, this message translates to:
  /// **'Thanks. The problem was reported.'**
  String get problemReported;

  /// No description provided for @authFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign you in'**
  String get authFailedTitle;

  /// No description provided for @authCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authCancelled;

  /// No description provided for @authFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while signing in. Nothing was changed on your account.'**
  String get authFailedBody;

  /// No description provided for @authTimeout.
  ///
  /// In en, this message translates to:
  /// **'Sign-in took too long. Please try again.'**
  String get authTimeout;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get authNetwork;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @useUsernameInstead.
  ///
  /// In en, this message translates to:
  /// **'Use username instead'**
  String get useUsernameInstead;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to the internet to continue.'**
  String get offlineBody;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'That page doesn\'t exist or has moved.'**
  String get notFoundBody;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goHome;

  /// No description provided for @tabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tabReports;

  /// No description provided for @tabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get tabReview;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @railWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get railWeather;

  /// No description provided for @railReports.
  ///
  /// In en, this message translates to:
  /// **'Latest reports'**
  String get railReports;

  /// No description provided for @railNews.
  ///
  /// In en, this message translates to:
  /// **'Latest news'**
  String get railNews;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @emergencyHelplines.
  ///
  /// In en, this message translates to:
  /// **'Emergency and helplines'**
  String get emergencyHelplines;

  /// No description provided for @emergencyHelplinesSub.
  ///
  /// In en, this message translates to:
  /// **'Ambulance, police, fire and more'**
  String get emergencyHelplinesSub;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get helpAndSupport;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @noNewsYet.
  ///
  /// In en, this message translates to:
  /// **'No news yet'**
  String get noNewsYet;

  /// No description provided for @qenSharTitle.
  ///
  /// In en, this message translates to:
  /// **'Security by QenShar'**
  String get qenSharTitle;

  /// No description provided for @qenSharSub.
  ///
  /// In en, this message translates to:
  /// **'How your details are protected'**
  String get qenSharSub;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and protection'**
  String get privacyTitle;

  /// No description provided for @prot1.
  ///
  /// In en, this message translates to:
  /// **'Everything is sent over encrypted HTTPS.'**
  String get prot1;

  /// No description provided for @prot2.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in is kept in your phone\'s encrypted storage.'**
  String get prot2;

  /// No description provided for @prot3.
  ///
  /// In en, this message translates to:
  /// **'Your phone number, blood group, emergency contact and address are visible only to you and to admins.'**
  String get prot3;

  /// No description provided for @prot4.
  ///
  /// In en, this message translates to:
  /// **'Admins and super admins must use two-factor sign-in.'**
  String get prot4;

  /// No description provided for @prot5.
  ///
  /// In en, this message translates to:
  /// **'Security reviewed and hardened by QenShar.'**
  String get prot5;

  /// No description provided for @whatWeStore.
  ///
  /// In en, this message translates to:
  /// **'What we store'**
  String get whatWeStore;

  /// No description provided for @whatWeStoreBody.
  ///
  /// In en, this message translates to:
  /// **'Your name, photo and e-mail from Google, your username, optional phone, blood group, emergency contact and address, and the reports you send.'**
  String get whatWeStoreBody;

  /// No description provided for @whoCanSee.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get whoCanSee;

  /// No description provided for @whoCanSeeBody.
  ///
  /// In en, this message translates to:
  /// **'Your name and the reports you publish are public. Everything else in your profile is private.'**
  String get whoCanSeeBody;

  /// No description provided for @yourControl.
  ///
  /// In en, this message translates to:
  /// **'Your control'**
  String get yourControl;

  /// No description provided for @yourControlBody.
  ///
  /// In en, this message translates to:
  /// **'Edit or clear any detail in Account. Delete Account removes your profile and sign-in.'**
  String get yourControlBody;

  /// No description provided for @servicesWeUse.
  ///
  /// In en, this message translates to:
  /// **'Services we use'**
  String get servicesWeUse;

  /// No description provided for @servicesWeUseBody.
  ///
  /// In en, this message translates to:
  /// **'Google (sign-in), Supabase (secure database), OpenStreetMap (maps and address search), Open-Meteo (weather).'**
  String get servicesWeUseBody;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed and managed by'**
  String get developedBy;

  /// No description provided for @passwordLoginPaused.
  ///
  /// In en, this message translates to:
  /// **'Password sign-in is paused until {time}. Sign in with Google instead.'**
  String passwordLoginPaused(String time);

  /// No description provided for @passwordLoginOff.
  ///
  /// In en, this message translates to:
  /// **'Password sign-in is turned off for this account after too many wrong attempts. Sign in with Google, or contact support to recover it.'**
  String get passwordLoginOff;

  /// No description provided for @forcePwTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get forcePwTitle;

  /// No description provided for @forcePwSub.
  ///
  /// In en, this message translates to:
  /// **'Your password was reset by a super admin. Set your own password to continue.'**
  String get forcePwSub;

  /// No description provided for @adminLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked sign-ins'**
  String get adminLocked;

  /// No description provided for @adminLockedSub.
  ///
  /// In en, this message translates to:
  /// **'Accounts whose password sign-in was paused'**
  String get adminLockedSub;

  /// No description provided for @lockedNone.
  ///
  /// In en, this message translates to:
  /// **'No locked accounts.'**
  String get lockedNone;

  /// No description provided for @lockedPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused until {time}'**
  String lockedPaused(String time);

  /// No description provided for @lockedOff.
  ///
  /// In en, this message translates to:
  /// **'Off until recovered'**
  String get lockedOff;

  /// No description provided for @recoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover account'**
  String get recoverTitle;

  /// No description provided for @recoverBody.
  ///
  /// In en, this message translates to:
  /// **'This unlocks password sign-in, signs the person out everywhere and creates a one-time password. Your reason is saved in the audit log.'**
  String get recoverBody;

  /// No description provided for @recoverReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (required, 10+ characters)'**
  String get recoverReason;

  /// No description provided for @recoverAction.
  ///
  /// In en, this message translates to:
  /// **'Recover and create password'**
  String get recoverAction;

  /// No description provided for @recoverErrAal2.
  ///
  /// In en, this message translates to:
  /// **'Set up two-factor sign-in and enter the code first.'**
  String get recoverErrAal2;

  /// No description provided for @recoverErrReason.
  ///
  /// In en, this message translates to:
  /// **'Write a reason of at least 10 characters.'**
  String get recoverErrReason;

  /// No description provided for @recoverErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t recover the account. Try again.'**
  String get recoverErrGeneric;

  /// No description provided for @tempPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get tempPasswordTitle;

  /// No description provided for @tempPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Share it privately with the person. It is shown only once. They must choose a new password when they sign in.'**
  String get tempPasswordBody;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of MyHarur is no longer supported. Update to keep using the app.'**
  String get updateRequiredBody;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version of MyHarur is ready with fixes and improvements.'**
  String get updateAvailableBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get updateLater;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccount;

  /// No description provided for @switchAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Use another account on this phone'**
  String get switchAccountSub;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add another account'**
  String get addAccount;

  /// No description provided for @accountsLimit.
  ///
  /// In en, this message translates to:
  /// **'You can keep up to 3 accounts on this phone. Remove one first.'**
  String get accountsLimit;

  /// No description provided for @removeFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Remove from this phone'**
  String get removeFromPhone;

  /// No description provided for @switchFailed.
  ///
  /// In en, this message translates to:
  /// **'That account\'s sign-in has expired. Add it again to use it.'**
  String get switchFailed;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @submitNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share news'**
  String get submitNewsTitle;

  /// No description provided for @submitNewsBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit news'**
  String get submitNewsBtn;

  /// No description provided for @submittedNewsMsg.
  ///
  /// In en, this message translates to:
  /// **'News submitted. It appears after review.'**
  String get submittedNewsMsg;

  /// No description provided for @ncTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get ncTraffic;

  /// No description provided for @ncCivic.
  ///
  /// In en, this message translates to:
  /// **'Civic'**
  String get ncCivic;

  /// No description provided for @ncHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get ncHealth;

  /// No description provided for @ncEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get ncEducation;

  /// No description provided for @ncCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get ncCommunity;

  /// No description provided for @ncOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ncOther;

  /// No description provided for @photosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional)'**
  String get photosLabel;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @photoFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoFromCamera;

  /// No description provided for @photoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoFromGallery;

  /// No description provided for @photoLimit.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 3 photos.'**
  String get photoLimit;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add that photo. Try another one.'**
  String get photoFailed;

  /// No description provided for @photosNote.
  ///
  /// In en, this message translates to:
  /// **'Location data is removed from your photos before they are uploaded.'**
  String get photosNote;

  /// No description provided for @uploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get uploadingPhotos;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @linkOptional.
  ///
  /// In en, this message translates to:
  /// **'Link (optional)'**
  String get linkOptional;

  /// No description provided for @linkHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get linkHint;

  /// No description provided for @linkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a link that starts with https://'**
  String get linkInvalid;

  /// No description provided for @errCooldown.
  ///
  /// In en, this message translates to:
  /// **'Posting is paused after several posts were blocked. Try again tomorrow.'**
  String get errCooldown;

  /// No description provided for @errRestricted.
  ///
  /// In en, this message translates to:
  /// **'Your account is restricted while our team reviews reports, so you can\'t post right now.'**
  String get errRestricted;

  /// No description provided for @errPhoto.
  ///
  /// In en, this message translates to:
  /// **'One of your photos was refused. Remove it and try again.'**
  String get errPhoto;

  /// No description provided for @tabHeadlines.
  ///
  /// In en, this message translates to:
  /// **'Headlines'**
  String get tabHeadlines;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @shareNews.
  ///
  /// In en, this message translates to:
  /// **'Share news'**
  String get shareNews;

  /// No description provided for @communityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No community news yet'**
  String get communityEmptyTitle;

  /// No description provided for @communityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share something happening in Harur.'**
  String get communityEmptyBody;

  /// No description provided for @tagCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tagCommunity;

  /// No description provided for @tagNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get tagNews;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @postActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get postActions;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @deletePostBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this post? This can\'t be undone.'**
  String get deletePostBody;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted.'**
  String get postDeleted;

  /// No description provided for @deleteReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for removal (required)'**
  String get deleteReasonLabel;

  /// No description provided for @deleteFailed2.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the post. Try again.'**
  String get deleteFailed2;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPost;

  /// No description provided for @reportWhy.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get reportWhy;

  /// No description provided for @reportedMsg.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Our team will review it.'**
  String get reportedMsg;

  /// No description provided for @reportLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit for reports.'**
  String get reportLimit;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report. Try again.'**
  String get reportFailed;

  /// No description provided for @rrSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get rrSpam;

  /// No description provided for @rrFalse.
  ///
  /// In en, this message translates to:
  /// **'False information'**
  String get rrFalse;

  /// No description provided for @rrAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abusive'**
  String get rrAbuse;

  /// No description provided for @rrHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get rrHarassment;

  /// No description provided for @rrInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get rrInappropriate;

  /// No description provided for @rrOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get rrOther;

  /// No description provided for @blockAuthor.
  ///
  /// In en, this message translates to:
  /// **'Hide posts from this author'**
  String get blockAuthor;

  /// No description provided for @blockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see their posts any more. You can undo this in Account, under Blocked authors.'**
  String get blockBody;

  /// No description provided for @blockedMsg.
  ///
  /// In en, this message translates to:
  /// **'Hidden. Undo it in Account > Blocked authors.'**
  String get blockedMsg;

  /// No description provided for @blockFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t hide that author. Try again.'**
  String get blockFailed;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get myPosts;

  /// No description provided for @myPostsSub.
  ///
  /// In en, this message translates to:
  /// **'Reports and news you submitted'**
  String get myPostsSub;

  /// No description provided for @myPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted anything yet.'**
  String get myPostsEmpty;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get statusPending;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get statusPublished;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get statusRejected;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @blockedAuthors.
  ///
  /// In en, this message translates to:
  /// **'Blocked authors'**
  String get blockedAuthors;

  /// No description provided for @blockedAuthorsSub.
  ///
  /// In en, this message translates to:
  /// **'People whose posts you hid'**
  String get blockedAuthorsSub;

  /// No description provided for @blockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone.'**
  String get blockedEmpty;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @safetySection.
  ///
  /// In en, this message translates to:
  /// **'Your posts and safety'**
  String get safetySection;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @reportBugSub.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong'**
  String get reportBugSub;

  /// No description provided for @bugTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What went wrong? (short)'**
  String get bugTitleHint;

  /// No description provided for @bugDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'What did you do, and what happened?'**
  String get bugDetailsHint;

  /// No description provided for @bugSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We\'ll look into it.'**
  String get bugSent;

  /// No description provided for @bugNote.
  ///
  /// In en, this message translates to:
  /// **'Your app version and phone model are attached. Nothing personal.'**
  String get bugNote;

  /// No description provided for @bugTooShort.
  ///
  /// In en, this message translates to:
  /// **'Add a short title and a few details.'**
  String get bugTooShort;

  /// No description provided for @bugLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit for bug reports.'**
  String get bugLimit;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reportedUsers.
  ///
  /// In en, this message translates to:
  /// **'Reported users'**
  String get reportedUsers;

  /// No description provided for @reportedUsersSub.
  ///
  /// In en, this message translates to:
  /// **'Users flagged by residents'**
  String get reportedUsersSub;

  /// No description provided for @ruNone.
  ///
  /// In en, this message translates to:
  /// **'No reported users.'**
  String get ruNone;

  /// No description provided for @ruReporters.
  ///
  /// In en, this message translates to:
  /// **'{n} reporters'**
  String ruReporters(int n);

  /// No description provided for @ruRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get ruRestricted;

  /// No description provided for @ruBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get ruBanned;

  /// No description provided for @ruDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss reports'**
  String get ruDismiss;

  /// No description provided for @ruWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get ruWarn;

  /// No description provided for @ruRestrict.
  ///
  /// In en, this message translates to:
  /// **'Restrict'**
  String get ruRestrict;

  /// No description provided for @ruBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get ruBan;

  /// No description provided for @ruReinstate.
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get ruReinstate;

  /// No description provided for @ruNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (required to restrict, ban or reinstate)'**
  String get ruNoteLabel;

  /// No description provided for @ruNeedNote.
  ///
  /// In en, this message translates to:
  /// **'Write a short note first.'**
  String get ruNeedNote;

  /// No description provided for @ruSuperOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a super admin can act on staff accounts.'**
  String get ruSuperOnly;

  /// No description provided for @ruFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that decision. Try again.'**
  String get ruFailed;

  /// No description provided for @bugReports.
  ///
  /// In en, this message translates to:
  /// **'Bug reports'**
  String get bugReports;

  /// No description provided for @bugReportsSub.
  ///
  /// In en, this message translates to:
  /// **'Reports sent by users and crashes'**
  String get bugReportsSub;

  /// No description provided for @bugNone.
  ///
  /// In en, this message translates to:
  /// **'No bug reports.'**
  String get bugNone;

  /// No description provided for @bugNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get bugNew;

  /// No description provided for @bugSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get bugSeen;

  /// No description provided for @bugFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get bugFixed;

  /// No description provided for @suspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get suspendedTitle;

  /// No description provided for @suspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account was suspended after reports of misuse. If you think this is a mistake, contact support.'**
  String get suspendedBody;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @supportChat.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get supportChat;

  /// No description provided for @supportChatSub.
  ///
  /// In en, this message translates to:
  /// **'Get help, or reach the team'**
  String get supportChatSub;

  /// No description provided for @supportGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m the MyHarur help assistant. Pick a topic or type your question.'**
  String get supportGreeting;

  /// No description provided for @supportPickQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which one is closest?'**
  String get supportPickQuestion;

  /// No description provided for @supportInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get supportInputHint;

  /// No description provided for @supportNoMatch.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t find that in our help topics. You can ask the AI assistant, or e-mail the team.'**
  String get supportNoMatch;

  /// No description provided for @supportYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, thanks'**
  String get supportYes;

  /// No description provided for @supportNo.
  ///
  /// In en, this message translates to:
  /// **'Not really'**
  String get supportNo;

  /// No description provided for @supportGlad.
  ///
  /// In en, this message translates to:
  /// **'Glad that helped! Anything else?'**
  String get supportGlad;

  /// No description provided for @supportMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Sorry about that. You can ask the AI assistant, or e-mail the team.'**
  String get supportMoreHelp;

  /// No description provided for @supportAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI assistant'**
  String get supportAskAi;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'E-mail support'**
  String get supportEmail;

  /// No description provided for @supportTopicsBtn.
  ///
  /// In en, this message translates to:
  /// **'Back to topics'**
  String get supportTopicsBtn;

  /// No description provided for @supportAiNote.
  ///
  /// In en, this message translates to:
  /// **'AI answers can be wrong. Your question is sent to Google\'s Gemini service, so don\'t include personal details.'**
  String get supportAiNote;

  /// No description provided for @supportAiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get supportAiThinking;

  /// No description provided for @supportAiRate.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s AI questions. E-mail the team and we\'ll help.'**
  String get supportAiRate;

  /// No description provided for @supportAiBusy.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant is busy right now. Try again later, or e-mail the team.'**
  String get supportAiBusy;

  /// No description provided for @supportAiDown.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant isn\'t available right now. E-mail the team and we\'ll help.'**
  String get supportAiDown;

  /// No description provided for @supportAiOffline.
  ///
  /// In en, this message translates to:
  /// **'You seem to be offline. Check your connection and try again.'**
  String get supportAiOffline;

  /// No description provided for @supportNeedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type your question first, then tap Ask the AI assistant.'**
  String get supportNeedQuestion;

  /// No description provided for @supportMailIntro.
  ///
  /// In en, this message translates to:
  /// **'Please describe your problem above this line.'**
  String get supportMailIntro;

  /// No description provided for @supportMailAuto.
  ///
  /// In en, this message translates to:
  /// **'Details added automatically (no passwords or tokens):'**
  String get supportMailAuto;

  /// No description provided for @supportMailSubject.
  ///
  /// In en, this message translates to:
  /// **'MyHarur support'**
  String get supportMailSubject;

  /// No description provided for @supportMailFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your e-mail app. Write to adminqenbel@gmail.com or connectwithhemapriyan@gmail.com.'**
  String get supportMailFailed;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Daily report summary and event alerts'**
  String get notificationsSub;

  /// No description provided for @notifMaster.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notifMaster;

  /// No description provided for @notifReports.
  ///
  /// In en, this message translates to:
  /// **'New reports (daily summary)'**
  String get notifReports;

  /// No description provided for @notifEvents.
  ///
  /// In en, this message translates to:
  /// **'Events (coming soon)'**
  String get notifEvents;

  /// No description provided for @notifCaps.
  ///
  /// In en, this message translates to:
  /// **'At most one report summary a day and two event alerts a week. Quiet from 10 pm to 7 am.'**
  String get notifCaps;

  /// No description provided for @notifUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t set up in this version of the app yet.'**
  String get notifUnavailable;

  /// No description provided for @notifDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for MyHarur. Allow them in your phone\'s settings, then try again.'**
  String get notifDenied;

  /// No description provided for @notifPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop?'**
  String get notifPromptTitle;

  /// No description provided for @notifPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Get one short summary a day when new reports are published in Harur. You can change this any time in Account.'**
  String get notifPromptBody;

  /// No description provided for @notifPromptYes.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notifPromptYes;

  /// No description provided for @notifPromptNo.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifPromptNo;

  /// No description provided for @ecCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get ecCultural;

  /// No description provided for @ecSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get ecSports;

  /// No description provided for @ecReligious.
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get ecReligious;

  /// No description provided for @ecGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get ecGovernment;

  /// No description provided for @ecBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get ecBusiness;

  /// No description provided for @jcFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get jcFullTime;

  /// No description provided for @jcPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get jcPartTime;

  /// No description provided for @jcContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get jcContract;

  /// No description provided for @jcInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get jcInternship;

  /// No description provided for @jcDailyWage.
  ///
  /// In en, this message translates to:
  /// **'Daily wage'**
  String get jcDailyWage;

  /// No description provided for @tabEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get tabEvents;

  /// No description provided for @tabJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get tabJobs;

  /// No description provided for @railEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get railEvents;

  /// No description provided for @railJobs.
  ///
  /// In en, this message translates to:
  /// **'Latest jobs'**
  String get railJobs;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post one for Harur.'**
  String get eventsEmptyBody;

  /// No description provided for @jobsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet'**
  String get jobsEmptyTitle;

  /// No description provided for @jobsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post an opening.'**
  String get jobsEmptyBody;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postJob;

  /// No description provided for @tagEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get tagEvent;

  /// No description provided for @tagJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get tagJob;

  /// No description provided for @submitEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Post an event'**
  String get submitEventTitle;

  /// No description provided for @submitEventBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit event'**
  String get submitEventBtn;

  /// No description provided for @eventStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventStarts;

  /// No description provided for @eventEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends (optional)'**
  String get eventEnds;

  /// No description provided for @eventAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get eventAllDay;

  /// No description provided for @eventPaid.
  ///
  /// In en, this message translates to:
  /// **'Ticketed (not free)'**
  String get eventPaid;

  /// No description provided for @eventVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get eventVenueLabel;

  /// No description provided for @eventVenueRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a venue: pin it on the map, type it, or both.'**
  String get eventVenueRequired;

  /// No description provided for @eventRegLink.
  ///
  /// In en, this message translates to:
  /// **'Registration link (optional)'**
  String get eventRegLink;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get pickTime;

  /// No description provided for @errStartsRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose when the event starts.'**
  String get errStartsRequired;

  /// No description provided for @errVenueRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a venue for the event.'**
  String get errVenueRequired;

  /// No description provided for @submitJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get submitJobTitle;

  /// No description provided for @submitJobBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit job'**
  String get submitJobBtn;

  /// No description provided for @jobEmployer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get jobEmployer;

  /// No description provided for @jobContact.
  ///
  /// In en, this message translates to:
  /// **'Contact (phone or e-mail)'**
  String get jobContact;

  /// No description provided for @jobPay.
  ///
  /// In en, this message translates to:
  /// **'Pay (optional)'**
  String get jobPay;

  /// No description provided for @jobClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing date'**
  String get jobClosing;

  /// No description provided for @jobApplyLink.
  ///
  /// In en, this message translates to:
  /// **'Apply link (optional)'**
  String get jobApplyLink;

  /// No description provided for @jobScamWarning.
  ///
  /// In en, this message translates to:
  /// **'Never pay to apply for a job. Report any listing that asks for money.'**
  String get jobScamWarning;

  /// No description provided for @errEmployerContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Add the employer and a way to contact them.'**
  String get errEmployerContactRequired;

  /// No description provided for @errClosingRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a closing date in the future.'**
  String get errClosingRequired;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get eventDetails;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobDetails;

  /// No description provided for @closesOn.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closesOn;

  /// No description provided for @featureFlags.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get featureFlags;

  /// No description provided for @featureFlagsSub.
  ///
  /// In en, this message translates to:
  /// **'Turn modules on or off for everyone'**
  String get featureFlagsSub;

  /// No description provided for @flagEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get flagEvents;

  /// No description provided for @flagEventsSub.
  ///
  /// In en, this message translates to:
  /// **'The Events tab, submitting and browsing events'**
  String get flagEventsSub;

  /// No description provided for @flagJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get flagJobs;

  /// No description provided for @flagJobsSub.
  ///
  /// In en, this message translates to:
  /// **'The Jobs tab, submitting and browsing jobs'**
  String get flagJobsSub;

  /// No description provided for @flagOtherNote.
  ///
  /// In en, this message translates to:
  /// **'Other modules listed here are not built into the app yet, so they are left out until they are.'**
  String get flagOtherNote;

  /// No description provided for @flagChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change that. Try again.'**
  String get flagChangeFailed;

  /// No description provided for @adsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get adsAdmin;

  /// No description provided for @adsAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Sponsored cards shown in the app'**
  String get adsAdminSub;

  /// No description provided for @adCreate.
  ///
  /// In en, this message translates to:
  /// **'New ad'**
  String get adCreate;

  /// No description provided for @adTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adTitleLabel;

  /// No description provided for @adBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get adBodyLabel;

  /// No description provided for @adLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link (https)'**
  String get adLinkLabel;

  /// No description provided for @adPlacementLabel.
  ///
  /// In en, this message translates to:
  /// **'Where it shows'**
  String get adPlacementLabel;

  /// No description provided for @adPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority (higher shows first)'**
  String get adPriorityLabel;

  /// No description provided for @adStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get adStartsLabel;

  /// No description provided for @adEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends (optional)'**
  String get adEndsLabel;

  /// No description provided for @adImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Image (optional)'**
  String get adImageOptional;

  /// No description provided for @adPlacementHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get adPlacementHome;

  /// No description provided for @adPlacementNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get adPlacementNews;

  /// No description provided for @adPlacementReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adPlacementReports;

  /// No description provided for @adStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adStatusDraft;

  /// No description provided for @adStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adStatusActive;

  /// No description provided for @adStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get adStatusPaused;

  /// No description provided for @adActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get adActivate;

  /// No description provided for @adPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get adPause;

  /// No description provided for @adDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete ad'**
  String get adDelete;

  /// No description provided for @adDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this ad? This can\'t be undone.'**
  String get adDeleteConfirm;

  /// No description provided for @adNone.
  ///
  /// In en, this message translates to:
  /// **'No ads yet.'**
  String get adNone;

  /// No description provided for @adStats.
  ///
  /// In en, this message translates to:
  /// **'{impressions} views · {clicks} taps'**
  String adStats(int impressions, int clicks);

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsored;

  /// No description provided for @adCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the ad. Check the details and try again.'**
  String get adCreateFailed;

  /// No description provided for @submittedEventMsg.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Your event was sent for review and will appear once approved.'**
  String get submittedEventMsg;

  /// No description provided for @submittedJobMsg.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Your job post was sent for review and will appear once approved.'**
  String get submittedJobMsg;
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
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
