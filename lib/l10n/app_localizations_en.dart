// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MyHarur';

  @override
  String get tabHome => 'Home';

  @override
  String get tabNews => 'News';

  @override
  String get tabWeather => 'Weather';

  @override
  String get tabAccount => 'Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get continueLabel => 'Continue';

  @override
  String get getStarted => 'Get started';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get delete => 'Delete';

  @override
  String get notSet => 'Not set';

  @override
  String get saveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get loading => 'Loading…';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get authFooter => 'A QenBel product';

  @override
  String get noBackend => 'Can\'t reach the server right now.';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get obUsernameTitle => 'Choose a username';

  @override
  String get obUsernameSub =>
      'This is your public handle in MyHarur. You can\'t change it later.';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Letters, numbers and underscores only.';

  @override
  String get usernameShort => 'Use at least 3 characters.';

  @override
  String get usernameLong => 'Use 30 characters or fewer.';

  @override
  String get usernameChars => 'Use letters, numbers and _ only.';

  @override
  String get usernameReserved => 'That username is reserved.';

  @override
  String get usernameBad => 'That username isn\'t allowed.';

  @override
  String get usernameTaken => 'That username is taken. Try another.';

  @override
  String get obProfileTitle => 'About you';

  @override
  String get obProfileSub =>
      'Your name helps neighbours recognise your reports.';

  @override
  String get fullName => 'Full name';

  @override
  String get nameRequired => 'Enter your name.';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get bloodGroupOptional => 'Blood group (optional)';

  @override
  String get obOccupationTitle => 'What do you do?';

  @override
  String get obOccupationSub => 'This helps us show what matters to you.';

  @override
  String get occStudent => 'Student';

  @override
  String get occShopOwner => 'Shop owner';

  @override
  String get occEmployee => 'Employee';

  @override
  String get occGovtEmployee => 'Government employee';

  @override
  String get occFarmer => 'Farmer';

  @override
  String get occOther => 'Other';

  @override
  String get greetMorning => 'Good morning';

  @override
  String get greetAfternoon => 'Good afternoon';

  @override
  String get greetEvening => 'Good evening';

  @override
  String get catAll => 'All';

  @override
  String get catRoad => 'Road';

  @override
  String get catElectricity => 'Electricity';

  @override
  String get catWater => 'Water';

  @override
  String get catGovt => 'Government';

  @override
  String get alertsEmptyTitle => 'No alerts right now';

  @override
  String get alertsEmptyBody =>
      'Nothing has been reported. Tap + to report an issue.';

  @override
  String get alertsErrorTitle => 'Couldn\'t load alerts';

  @override
  String get alertsErrorBody => 'Check your connection and try again.';

  @override
  String get report => 'Report';

  @override
  String get official => 'Official';

  @override
  String get emergency => 'Emergency';

  @override
  String get location => 'Location';

  @override
  String get source => 'Source';

  @override
  String reviewWaiting(int count) {
    return '$count waiting for review';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String hoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String daysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get submitTitle => 'Report an issue';

  @override
  String get categoryLabel => 'Category';

  @override
  String get titleHint => 'What\'s happening?';

  @override
  String get detailsHint => 'Where, how serious, and since when?';

  @override
  String get titleMin => 'Add a short title (5 or more characters).';

  @override
  String get detailsMin => 'Add a little more detail (10 or more characters).';

  @override
  String get markEmergency => 'Mark as emergency';

  @override
  String get emergencyNote =>
      'Reviewed first. False reports cost you this option.';

  @override
  String get emergencyRevoked =>
      'Emergency tagging is off for your account after repeated false reports.';

  @override
  String get submitReport => 'Submit report';

  @override
  String get submittedMsg =>
      'Thanks. Your report was sent for review and will appear once approved.';

  @override
  String get errAutoRejected =>
      'This report contains language that isn\'t allowed. Please reword it and try again.';

  @override
  String get errRateLimited =>
      'You\'ve sent several reports recently. Please wait a while before sending another.';

  @override
  String get errInvalidLength =>
      'Title needs 5 to 100 characters and details 10 to 500.';

  @override
  String get errAccount =>
      'Your account can\'t submit reports right now. Please sign in again.';

  @override
  String get errSubmitFailed =>
      'The report didn\'t send. Check your connection and try again.';

  @override
  String get weatherTitle => 'Weather';

  @override
  String get locHarur => 'Harur';

  @override
  String get locDharmapuri => 'Dharmapuri';

  @override
  String feelsLike(int temp) {
    return 'Feels like $temp°';
  }

  @override
  String highLow(int high, int low) {
    return 'H $high°  L $low°';
  }

  @override
  String get hourlyTitle => 'Next 24 hours';

  @override
  String get dailyTitle => '7-day forecast';

  @override
  String get detailsTitle => 'Details';

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get rainChance => 'Chance of rain';

  @override
  String get uvIndex => 'UV index';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get today => 'Today';

  @override
  String get now => 'Now';

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get weatherErrorTitle => 'Couldn\'t load the forecast';

  @override
  String get weatherErrorBody =>
      'Check your connection and pull down to try again.';

  @override
  String rainAlert(int chance) {
    return 'Rain likely today: $chance% chance';
  }

  @override
  String heatAlert(int temp) {
    return 'Hot day ahead: up to $temp°';
  }

  @override
  String get weatherCredit => 'Weather data by Open-Meteo.com';

  @override
  String get wxClear => 'Clear';

  @override
  String get wxMostlyClear => 'Mostly clear';

  @override
  String get wxPartlyCloudy => 'Partly cloudy';

  @override
  String get wxOvercast => 'Overcast';

  @override
  String get wxFog => 'Fog';

  @override
  String get wxDrizzle => 'Drizzle';

  @override
  String get wxRain => 'Rain';

  @override
  String get wxHeavyRain => 'Heavy rain';

  @override
  String get wxShowers => 'Showers';

  @override
  String get wxThunderstorm => 'Thunderstorm';

  @override
  String get wxUnknown => 'Unsettled';

  @override
  String get newsTitle => 'News';

  @override
  String get newsAll => 'All';

  @override
  String get newsTraffic => 'Traffic';

  @override
  String get newsWeather => 'Weather';

  @override
  String get newsCivic => 'Civic';

  @override
  String get newsFarming => 'Farming';

  @override
  String get newsGeneral => 'Local';

  @override
  String get areaAll => 'All areas';

  @override
  String get newsEmptyTitle => 'No stories yet';

  @override
  String get newsEmptyBody =>
      'Local headlines appear here and refresh about every 30 minutes.';

  @override
  String get newsErrorTitle => 'Couldn\'t load the news';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpSubtitle => 'Tap a number to call.';

  @override
  String get helpEmergency => 'Emergency';

  @override
  String get helpCivic => 'Civic and safety';

  @override
  String get helpNote =>
      'These are national and state helplines. Numbers work from any phone.';

  @override
  String get hlAmbulance => 'Ambulance';

  @override
  String get hlAmbulanceDesc => 'Emergency medical response, 24 hours';

  @override
  String get hlPolice => 'Police';

  @override
  String get hlPoliceDesc => 'Report a crime or emergency';

  @override
  String get hlFire => 'Fire and rescue';

  @override
  String get hlFireDesc => 'Fire, rescue and accidents';

  @override
  String get hlUnified => 'All-in-one emergency';

  @override
  String get hlUnifiedDesc => 'Police, fire and ambulance';

  @override
  String get hlPower => 'Electricity complaints';

  @override
  String get hlPowerDesc => 'Power cuts and line faults (TANGEDCO)';

  @override
  String get hlDisaster => 'Disaster management';

  @override
  String get hlDisasterDesc => 'Floods, storms and relief';

  @override
  String get hlWomen => 'Women helpline';

  @override
  String get hlWomenDesc => 'Support and safety, 24 hours';

  @override
  String get hlChild => 'Childline';

  @override
  String get hlChildDesc => 'Help for children in need';

  @override
  String get hlHighway => 'Highway helpline';

  @override
  String get hlHighwayDesc => 'Breakdowns and accidents on national highways';

  @override
  String get accountTitle => 'Account';

  @override
  String get staffTools => 'Staff tools';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get profileSection => 'Profile';

  @override
  String get memberId => 'Member ID';

  @override
  String get phone => 'Phone';

  @override
  String get bloodGroup => 'Blood group';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String get emergencyContactName => 'Contact name';

  @override
  String get emergencyContactPhone => 'Contact phone';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordRules =>
      'At least 10 characters, with letters and numbers.';

  @override
  String get passwordWeak =>
      'Use at least 10 characters with letters and numbers.';

  @override
  String get passwordMismatch => 'The passwords don\'t match.';

  @override
  String passwordSaved(String username) {
    return 'Password saved. You can now sign in with $username.';
  }

  @override
  String get passwordFailed =>
      'Couldn\'t save the password. Sign in again and retry.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of MyHarur?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteTitle => 'Delete your account?';

  @override
  String get deleteBody =>
      'This permanently deletes your login and profile. Reports that are already live stay visible but are no longer linked to you. This can\'t be undone.';

  @override
  String get deleteFailed =>
      'Couldn\'t delete your account. Check your connection and try again.';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get appVersion => 'MyHarur · A QenBel product';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminOverview => 'Overview';

  @override
  String get statUsers => 'Users';

  @override
  String get statStaff => 'Staff';

  @override
  String get statPending => 'Waiting for review';

  @override
  String get statPublished => 'Published alerts';

  @override
  String get statAutoRejected => 'Auto-rejected';

  @override
  String get statNews => 'News stories';

  @override
  String get adminUsers => 'Users and roles';

  @override
  String get adminUsersSub => 'Find people and manage their roles.';

  @override
  String get searchUsers => 'Search name, username or email';

  @override
  String get noResults => 'No matching users';

  @override
  String get roleResident => 'Resident';

  @override
  String get roleModerator => 'Moderator';

  @override
  String get roleGovt => 'Government official';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleSuperadmin => 'Super admin';

  @override
  String get roleFailed => 'That change isn\'t allowed or didn\'t save.';

  @override
  String rolesFor(String name) {
    return 'Roles for $name';
  }

  @override
  String get adminFilters => 'Word filters';

  @override
  String get adminFiltersSub => 'Blocked and flagged words for reports.';

  @override
  String get blockedWords => 'Blocked words';

  @override
  String get blockedWordsNote =>
      'Reports containing these are rejected automatically.';

  @override
  String get flaggedWords => 'Flagged words';

  @override
  String get flaggedWordsNote =>
      'Reports containing these go to review with a warning.';

  @override
  String get addWord => 'Add a word';

  @override
  String get addWordHint => 'Word or phrase';

  @override
  String get wordFailed => 'Couldn\'t add that word.';

  @override
  String get tamilTanglish => 'Tamil (Tanglish)';

  @override
  String get tamilScript => 'Tamil script';

  @override
  String get englishWord => 'English';

  @override
  String get noWords => 'No words yet';

  @override
  String get reviewTitle => 'Review queue';

  @override
  String reviewCount(int count) {
    return '$count waiting for review';
  }

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get rejectTitle => 'Reject this report';

  @override
  String get reasonSpam => 'Spam';

  @override
  String get reasonFalse => 'False or misleading';

  @override
  String get reasonDuplicate => 'Duplicate';

  @override
  String get reasonLowQuality => 'Too vague';

  @override
  String get reasonInappropriate => 'Inappropriate';

  @override
  String get rejectStrikeNote =>
      'This was tagged Emergency. Choosing False or Spam adds a strike to the author.';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get nothingWaiting => 'No reports are waiting for review.';

  @override
  String get reviewLoadFailed => 'Couldn\'t load the queue';

  @override
  String get decisionFailed =>
      'Couldn\'t save that decision. It may already have been reviewed.';

  @override
  String get flagDangerous => 'Dangerous wording';

  @override
  String get flagLink => 'Contains a link';

  @override
  String get flagPhone => 'Contains a phone number';

  @override
  String get staffAuthor => 'Staff author';

  @override
  String get address => 'Address';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get locationOptional => 'Location (optional)';

  @override
  String get noLocation => 'No location';

  @override
  String get addressDetails => 'Address details';

  @override
  String get addressHint => 'House, street or landmark';

  @override
  String get searchPlace => 'Search a place or address';

  @override
  String get noPlacesFound =>
      'No places found. Try different words, or drag the map.';

  @override
  String get searchFailed =>
      'Search isn\'t available right now. You can still drag the map.';

  @override
  String get useThisLocation => 'Use this location';

  @override
  String get saveTextOnly => 'Save without a map pin';

  @override
  String get removeLocation => 'Remove';

  @override
  String get locationOff =>
      'Location is switched off. Turn it on to use your current location.';

  @override
  String get locationDenied =>
      'Location permission was denied. You can still search or drag the map.';

  @override
  String get locationDeniedForever =>
      'Location is blocked for MyHarur. Allow it in Settings to use this.';

  @override
  String get locationTimeout =>
      'Couldn\'t get your location. Try again or drag the map.';

  @override
  String get mapCredit => '© OpenStreetMap contributors';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get getDirections => 'Directions';

  @override
  String get tabSignIn => 'Sign in';

  @override
  String get tabRegister => 'Register';

  @override
  String get signInExplain =>
      'Sign in with Google, or with your username and password.';

  @override
  String get registerWelcome => 'Create your account';

  @override
  String get registerExplain =>
      'Registration uses Google, so there is no password to remember. You can add a username and password afterwards.';

  @override
  String get registerWithGoogle => 'Register with Google';

  @override
  String get usernameSignIn => 'Sign in with username';

  @override
  String get usernameField => 'Username';

  @override
  String get wrongCredentials => 'Wrong username or password.';

  @override
  String tooManyAttempts(int minutes) {
    return 'Too many attempts. Try again in $minutes min.';
  }

  @override
  String get noPasswordYet =>
      'No password yet? Sign in with Google, then add one in Account.';

  @override
  String get orDivider => 'or';

  @override
  String get obPasswordTitle => 'Add a password?';

  @override
  String get obPasswordSub =>
      'Optional. With a password you can sign in with your username as well as Google.';

  @override
  String get passwordForUsername => 'Username password';

  @override
  String get passwordForUsernameSub =>
      'Sign in with your @username and a password, as well as Google.';

  @override
  String get signInSection => 'Sign-in';

  @override
  String get mfaTitle => 'Two-factor sign-in';

  @override
  String get mfaRequired =>
      'Admins and super admins must protect their account with an authenticator app.';

  @override
  String get mfaScan =>
      'Scan this code with an authenticator app such as Google Authenticator, Microsoft Authenticator or Aegis.';

  @override
  String get mfaManualKey => 'Or type this key into the app';

  @override
  String get copied => 'Copied';

  @override
  String get mfaEnterCode => '6-digit code';

  @override
  String get mfaVerify => 'Verify';

  @override
  String get mfaBadCode =>
      'That code isn\'t right. Check the code and try again.';

  @override
  String get mfaEnabled => 'Two-factor is on';

  @override
  String get mfaChallengeTitle => 'Enter your code';

  @override
  String get mfaChallengeSub =>
      'Open your authenticator app and enter the 6-digit code for MyHarur.';

  @override
  String get mfaSetupFailed =>
      'Couldn\'t start two-factor setup. Check your connection and try again.';

  @override
  String get crashTitle => 'Something went wrong';

  @override
  String get crashBody =>
      'MyHarur hit a problem and had to stop. Your data is safe.';

  @override
  String get restartApp => 'Restart';

  @override
  String get reportProblem => 'Report this problem';

  @override
  String get problemReported => 'Thanks. The problem was reported.';

  @override
  String get authFailedTitle => 'Couldn\'t sign you in';

  @override
  String get authCancelled => 'Sign-in was cancelled.';

  @override
  String get authFailedBody =>
      'Something went wrong while signing in. Nothing was changed on your account.';

  @override
  String get authTimeout => 'Sign-in took too long. Please try again.';

  @override
  String get authNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get useUsernameInstead => 'Use username instead';

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get offlineBody => 'Reconnect to the internet to continue.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundBody => 'That page doesn\'t exist or has moved.';

  @override
  String get goHome => 'Go to Home';

  @override
  String get tabReports => 'Services';

  @override
  String get tabReview => 'Review';

  @override
  String get seeAll => 'See all';

  @override
  String get railWeather => 'Weather';

  @override
  String get railReports => 'Latest reports';

  @override
  String get railNews => 'Latest news';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get emergencyHelplines => 'Emergency and helplines';

  @override
  String get emergencyHelplinesSub => 'Ambulance, police, fire and more';

  @override
  String get helpAndSupport => 'Help and support';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get noNewsYet => 'No news yet';

  @override
  String get qenSharTitle => 'Security by QenShar';

  @override
  String get qenSharSub => 'How your details are protected';

  @override
  String get privacyTitle => 'Privacy and protection';

  @override
  String get prot1 => 'Everything is sent over encrypted HTTPS.';

  @override
  String get prot2 =>
      'Your sign-in is kept in your phone\'s encrypted storage.';

  @override
  String get prot3 =>
      'Your phone number, blood group, emergency contact and address are visible only to you and to admins.';

  @override
  String get prot4 => 'Admins and super admins must use two-factor sign-in.';

  @override
  String get prot5 => 'Security reviewed and hardened by QenShar.';

  @override
  String get whatWeStore => 'What we store';

  @override
  String get whatWeStoreBody =>
      'Your name, photo and e-mail from Google, your username, optional phone, blood group, emergency contact and address, and the reports you send.';

  @override
  String get whoCanSee => 'Who can see it';

  @override
  String get whoCanSeeBody =>
      'Your name and the reports you publish are public. Everything else in your profile is private.';

  @override
  String get yourControl => 'Your control';

  @override
  String get yourControlBody =>
      'Edit or clear any detail in Account. Delete Account removes your profile and sign-in.';

  @override
  String get servicesWeUse => 'Services we use';

  @override
  String get servicesWeUseBody =>
      'Google (sign-in), Supabase (secure database), OpenStreetMap (maps and address search), Open-Meteo (weather).';

  @override
  String get developedBy => 'Developed and managed by';

  @override
  String passwordLoginPaused(String time) {
    return 'Password sign-in is paused until $time. Sign in with Google instead.';
  }

  @override
  String get passwordLoginOff =>
      'Password sign-in is turned off for this account after too many wrong attempts. Sign in with Google, or contact support to recover it.';

  @override
  String get forcePwTitle => 'Choose a new password';

  @override
  String get forcePwSub =>
      'Your password was reset by a super admin. Set your own password to continue.';

  @override
  String get adminLocked => 'Locked sign-ins';

  @override
  String get adminLockedSub => 'Accounts whose password sign-in was paused';

  @override
  String get lockedNone => 'No locked accounts.';

  @override
  String lockedPaused(String time) {
    return 'Paused until $time';
  }

  @override
  String get lockedOff => 'Off until recovered';

  @override
  String get recoverTitle => 'Recover account';

  @override
  String get recoverBody =>
      'This unlocks password sign-in, signs the person out everywhere and creates a one-time password. Your reason is saved in the audit log.';

  @override
  String get recoverReason => 'Reason (required, 10+ characters)';

  @override
  String get recoverAction => 'Recover and create password';

  @override
  String get recoverErrAal2 =>
      'Set up two-factor sign-in and enter the code first.';

  @override
  String get recoverErrReason => 'Write a reason of at least 10 characters.';

  @override
  String get recoverErrGeneric => 'Couldn\'t recover the account. Try again.';

  @override
  String get tempPasswordTitle => 'Temporary password';

  @override
  String get tempPasswordBody =>
      'Share it privately with the person. It is shown only once. They must choose a new password when they sign in.';

  @override
  String get copyAction => 'Copy';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of MyHarur is no longer supported. Update to keep using the app.';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateAvailableBody =>
      'A newer version of MyHarur is ready with fixes and improvements.';

  @override
  String get updateNow => 'Update';

  @override
  String get updateLater => 'Not now';

  @override
  String get switchAccount => 'Switch account';

  @override
  String get switchAccountSub => 'Use another account on this phone';

  @override
  String get addAccount => 'Add another account';

  @override
  String get accountsLimit =>
      'You can keep up to 3 accounts on this phone. Remove one first.';

  @override
  String get removeFromPhone => 'Remove from this phone';

  @override
  String get switchFailed =>
      'That account\'s sign-in has expired. Add it again to use it.';

  @override
  String get closeAction => 'Close';

  @override
  String get submitNewsTitle => 'Share news';

  @override
  String get submitNewsBtn => 'Submit news';

  @override
  String get submittedNewsMsg => 'News submitted. It appears after review.';

  @override
  String get ncTraffic => 'Traffic';

  @override
  String get ncCivic => 'Civic';

  @override
  String get ncHealth => 'Health';

  @override
  String get ncEducation => 'Education';

  @override
  String get ncCommunity => 'Community';

  @override
  String get ncOther => 'Other';

  @override
  String get photosLabel => 'Photos (optional)';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoLimit => 'You can add up to 3 photos.';

  @override
  String get photoFailed => 'Couldn\'t add that photo. Try another one.';

  @override
  String get photosNote =>
      'Location data is removed from your photos before they are uploaded.';

  @override
  String get uploadingPhotos => 'Uploading photos…';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get linkOptional => 'Link (optional)';

  @override
  String get linkHint => 'https://…';

  @override
  String get linkInvalid => 'Use a link that starts with https://';

  @override
  String get errCooldown =>
      'Posting is paused after several posts were blocked. Try again tomorrow.';

  @override
  String get errRestricted =>
      'Your account is restricted while our team reviews reports, so you can\'t post right now.';

  @override
  String get errPhoto =>
      'One of your photos was refused. Remove it and try again.';

  @override
  String get tabHeadlines => 'Headlines';

  @override
  String get tabCommunity => 'Community';

  @override
  String get shareNews => 'Share news';

  @override
  String get communityEmptyTitle => 'No community news yet';

  @override
  String get communityEmptyBody =>
      'Be the first to share something happening in Harur.';

  @override
  String get tagCommunity => 'Community';

  @override
  String get tagNews => 'News';

  @override
  String get openLink => 'Open link';

  @override
  String get postActions => 'More';

  @override
  String get deletePost => 'Delete post';

  @override
  String get deletePostBody => 'Delete this post? This can\'t be undone.';

  @override
  String get postDeleted => 'Post deleted.';

  @override
  String get deleteReasonLabel => 'Reason for removal (required)';

  @override
  String get deleteFailed2 => 'Couldn\'t delete the post. Try again.';

  @override
  String get reportPost => 'Report post';

  @override
  String get reportWhy => 'Why are you reporting this?';

  @override
  String get reportedMsg => 'Thanks. Our team will review it.';

  @override
  String get reportLimit => 'You\'ve reached today\'s limit for reports.';

  @override
  String get reportFailed => 'Couldn\'t send the report. Try again.';

  @override
  String get rrSpam => 'Spam';

  @override
  String get rrFalse => 'False information';

  @override
  String get rrAbuse => 'Abusive';

  @override
  String get rrHarassment => 'Harassment';

  @override
  String get rrInappropriate => 'Inappropriate';

  @override
  String get rrOther => 'Something else';

  @override
  String get blockAuthor => 'Hide posts from this author';

  @override
  String get blockBody =>
      'You won\'t see their posts any more. You can undo this in Account, under Blocked authors.';

  @override
  String get blockedMsg => 'Hidden. Undo it in Account > Blocked authors.';

  @override
  String get blockFailed => 'Couldn\'t hide that author. Try again.';

  @override
  String get myPosts => 'My posts';

  @override
  String get myPostsSub => 'Reports and news you submitted';

  @override
  String get myPostsEmpty => 'You haven\'t posted anything yet.';

  @override
  String get statusPending => 'Waiting for review';

  @override
  String get statusPublished => 'Live';

  @override
  String get statusRejected => 'Not approved';

  @override
  String get statusExpired => 'Expired';

  @override
  String get blockedAuthors => 'Blocked authors';

  @override
  String get blockedAuthorsSub => 'People whose posts you hid';

  @override
  String get blockedEmpty => 'You haven\'t blocked anyone.';

  @override
  String get unblock => 'Unblock';

  @override
  String get safetySection => 'Your posts and safety';

  @override
  String get reportBug => 'Report a bug';

  @override
  String get reportBugSub => 'Tell us what went wrong';

  @override
  String get bugTitleHint => 'What went wrong? (short)';

  @override
  String get bugDetailsHint => 'What did you do, and what happened?';

  @override
  String get bugSent => 'Thanks. We\'ll look into it.';

  @override
  String get bugNote =>
      'Your app version and phone model are attached. Nothing personal.';

  @override
  String get bugTooShort => 'Add a short title and a few details.';

  @override
  String get bugLimit => 'You\'ve reached today\'s limit for bug reports.';

  @override
  String get send => 'Send';

  @override
  String get reportedUsers => 'Reported users';

  @override
  String get reportedUsersSub => 'Users flagged by residents';

  @override
  String get ruNone => 'No reported users.';

  @override
  String ruReporters(int n) {
    return '$n reporters';
  }

  @override
  String get ruRestricted => 'Restricted';

  @override
  String get ruBanned => 'Banned';

  @override
  String get ruDismiss => 'Dismiss reports';

  @override
  String get ruWarn => 'Warn';

  @override
  String get ruRestrict => 'Restrict';

  @override
  String get ruBan => 'Ban';

  @override
  String get ruReinstate => 'Reinstate';

  @override
  String get ruNoteLabel => 'Note (required to restrict, ban or reinstate)';

  @override
  String get ruNeedNote => 'Write a short note first.';

  @override
  String get ruSuperOnly => 'Only a super admin can act on staff accounts.';

  @override
  String get ruFailed => 'Couldn\'t save that decision. Try again.';

  @override
  String get bugReports => 'Bug reports';

  @override
  String get bugReportsSub => 'Reports sent by users and crashes';

  @override
  String get bugNone => 'No bug reports.';

  @override
  String get bugNew => 'New';

  @override
  String get bugSeen => 'Seen';

  @override
  String get bugFixed => 'Fixed';

  @override
  String get suspendedTitle => 'Account suspended';

  @override
  String get suspendedBody =>
      'Your account was suspended after reports of misuse. If you think this is a mistake, contact support.';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get supportChat => 'Support chat';

  @override
  String get supportChatSub => 'Get help, or reach the team';

  @override
  String get supportGreeting =>
      'Hi! I\'m the MyHarur help assistant. Pick a topic or type your question.';

  @override
  String get supportPickQuestion => 'Which one is closest?';

  @override
  String get supportInputHint => 'Type your question';

  @override
  String get supportNoMatch =>
      'I couldn\'t find that in our help topics. You can ask the AI assistant, or e-mail the team.';

  @override
  String get supportYes => 'Yes, thanks';

  @override
  String get supportNo => 'Not really';

  @override
  String get supportGlad => 'Glad that helped! Anything else?';

  @override
  String get supportMoreHelp =>
      'Sorry about that. You can ask the AI assistant, or e-mail the team.';

  @override
  String get supportAskAi => 'Ask the AI assistant';

  @override
  String get supportEmail => 'E-mail support';

  @override
  String get supportTopicsBtn => 'Back to topics';

  @override
  String get supportAiNote =>
      'AI answers can be wrong. Your question is sent to Google\'s Gemini service, so don\'t include personal details.';

  @override
  String get supportAiThinking => 'Thinking…';

  @override
  String get supportAiRate =>
      'You\'ve used today\'s AI questions. E-mail the team and we\'ll help.';

  @override
  String get supportAiBusy =>
      'The AI assistant is busy right now. Try again later, or e-mail the team.';

  @override
  String get supportAiDown =>
      'The AI assistant isn\'t available right now. E-mail the team and we\'ll help.';

  @override
  String get supportAiOffline =>
      'You seem to be offline. Check your connection and try again.';

  @override
  String get supportNeedQuestion =>
      'Type your question first, then tap Ask the AI assistant.';

  @override
  String get supportMailIntro =>
      'Please describe your problem above this line.';

  @override
  String get supportMailAuto =>
      'Details added automatically (no passwords or tokens):';

  @override
  String get supportMailSubject => 'MyHarur support';

  @override
  String get supportMailFailed =>
      'Couldn\'t open your e-mail app. Write to adminqenbel@gmail.com or connectwithhemapriyan@gmail.com.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSub => 'Daily report summary and event alerts';

  @override
  String get notifMaster => 'Allow notifications';

  @override
  String get notifReports => 'New reports (daily summary)';

  @override
  String get notifEvents => 'Events (coming soon)';

  @override
  String get notifCaps =>
      'At most one report summary a day and two event alerts a week. Quiet from 10 pm to 7 am.';

  @override
  String get notifUnavailable =>
      'Notifications aren\'t set up in this version of the app yet.';

  @override
  String get notifDenied =>
      'Notifications are blocked for MyHarur. Allow them in your phone\'s settings, then try again.';

  @override
  String get notifPromptTitle => 'Stay in the loop?';

  @override
  String get notifPromptBody =>
      'Get one short summary a day when new reports are published in Harur. You can change this any time in Account.';

  @override
  String get notifPromptYes => 'Turn on';

  @override
  String get notifPromptNo => 'Not now';

  @override
  String get ecCultural => 'Cultural';

  @override
  String get ecSports => 'Sports';

  @override
  String get ecReligious => 'Religious';

  @override
  String get ecGovernment => 'Government';

  @override
  String get ecBusiness => 'Business';

  @override
  String get jcFullTime => 'Full-time';

  @override
  String get jcPartTime => 'Part-time';

  @override
  String get jcContract => 'Contract';

  @override
  String get jcInternship => 'Internship';

  @override
  String get jcDailyWage => 'Daily wage';

  @override
  String get tabEvents => 'Events';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get railEvents => 'Upcoming events';

  @override
  String get railJobs => 'Latest jobs';

  @override
  String get eventsEmptyTitle => 'No upcoming events';

  @override
  String get eventsEmptyBody => 'Be the first to post one for Harur.';

  @override
  String get jobsEmptyTitle => 'No jobs posted yet';

  @override
  String get jobsEmptyBody => 'Be the first to post an opening.';

  @override
  String get addEvent => 'Add event';

  @override
  String get postJob => 'Post a job';

  @override
  String get tagEvent => 'Event';

  @override
  String get tagJob => 'Job';

  @override
  String get submitEventTitle => 'Post an event';

  @override
  String get submitEventBtn => 'Submit event';

  @override
  String get eventStarts => 'Starts';

  @override
  String get eventEnds => 'Ends (optional)';

  @override
  String get eventAllDay => 'All day';

  @override
  String get eventPaid => 'Ticketed (not free)';

  @override
  String get eventVenueLabel => 'Venue';

  @override
  String get eventVenueRequired =>
      'Add a venue: pin it on the map, type it, or both.';

  @override
  String get eventRegLink => 'Registration link (optional)';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get pickTime => 'Pick a time';

  @override
  String get errStartsRequired => 'Choose when the event starts.';

  @override
  String get errVenueRequired => 'Add a venue for the event.';

  @override
  String get submitJobTitle => 'Post a job';

  @override
  String get submitJobBtn => 'Submit job';

  @override
  String get jobEmployer => 'Employer';

  @override
  String get jobContact => 'Contact (phone or e-mail)';

  @override
  String get jobPay => 'Pay (optional)';

  @override
  String get jobClosing => 'Closing date';

  @override
  String get jobApplyLink => 'Apply link (optional)';

  @override
  String get jobScamWarning =>
      'Never pay to apply for a job. Report any listing that asks for money.';

  @override
  String get errEmployerContactRequired =>
      'Add the employer and a way to contact them.';

  @override
  String get errClosingRequired => 'Choose a closing date in the future.';

  @override
  String get eventDetails => 'Event details';

  @override
  String get jobDetails => 'Job details';

  @override
  String get closesOn => 'Closes';

  @override
  String get featureFlags => 'Feature flags';

  @override
  String get featureFlagsSub => 'Turn modules on or off for everyone';

  @override
  String get flagEvents => 'Events';

  @override
  String get flagEventsSub => 'The Events tab, submitting and browsing events';

  @override
  String get flagJobs => 'Jobs';

  @override
  String get flagJobsSub => 'The Jobs tab, submitting and browsing jobs';

  @override
  String get flagOtherNote =>
      'Other modules listed here are not built into the app yet, so they are left out until they are.';

  @override
  String get flagChangeFailed => 'Couldn\'t change that. Try again.';

  @override
  String get adsAdmin => 'Ads';

  @override
  String get adsAdminSub => 'Sponsored cards shown in the app';

  @override
  String get adCreate => 'New ad';

  @override
  String get adTitleLabel => 'Title';

  @override
  String get adBodyLabel => 'Text';

  @override
  String get adLinkLabel => 'Link (https)';

  @override
  String get adPlacementLabel => 'Where it shows';

  @override
  String get adPriorityLabel => 'Priority (higher shows first)';

  @override
  String get adStartsLabel => 'Starts';

  @override
  String get adEndsLabel => 'Ends (optional)';

  @override
  String get adImageOptional => 'Image (optional)';

  @override
  String get adPlacementHome => 'Home';

  @override
  String get adPlacementNews => 'News';

  @override
  String get adPlacementReports => 'Reports';

  @override
  String get adStatusDraft => 'Draft';

  @override
  String get adStatusActive => 'Active';

  @override
  String get adStatusPaused => 'Paused';

  @override
  String get adActivate => 'Activate';

  @override
  String get adPause => 'Pause';

  @override
  String get adDelete => 'Delete ad';

  @override
  String get adDeleteConfirm => 'Delete this ad? This can\'t be undone.';

  @override
  String get adNone => 'No ads yet.';

  @override
  String adStats(int impressions, int clicks) {
    return '$impressions views · $clicks taps';
  }

  @override
  String get sponsored => 'Sponsored';

  @override
  String get adCreateFailed =>
      'Couldn\'t create the ad. Check the details and try again.';

  @override
  String get submittedEventMsg =>
      'Thanks. Your event was sent for review and will appear once approved.';

  @override
  String get submittedJobMsg =>
      'Thanks. Your job post was sent for review and will appear once approved.';
}
