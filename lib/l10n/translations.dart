import 'package:flutter/foundation.dart';

class LanguageNotifier extends ChangeNotifier {
  static final LanguageNotifier instance = LanguageNotifier._();
  LanguageNotifier._();

  bool _isTamil = false;
  bool get isTamil => _isTamil;

  void toggleLanguage() {
    _isTamil = !_isTamil;
    notifyListeners();
  }

  void setTamil(bool value) {
    if (_isTamil != value) {
      _isTamil = value;
      notifyListeners();
    }
  }
}

const Map<String, String> _tamilDictionary = {
  // Navigation & Shell
  'Home': 'முகப்பு',
  'Explore': 'கண்டறிக',
  'Alerts': 'அறிவிப்புகள்',
  'Account': 'சுயவிவரம்',
  'Harur Digital Town': 'அரூர் டிஜிட்டல் நகரம்',
  'Your Connected Town': 'உங்கள் இணைக்கப்பட்ட நகரம்',
  'Vanakkam': 'வணக்கம்',

  // Top Modules & Services
  'DIGITAL SERVICES & BAZAAR': 'டிஜிட்டல் சேவைகள் & சந்தை',
  'Local Shops': 'உள்ளூர் கடைகள்',
  'Job Portal': 'வேலைவாய்ப்பு',
  'Mandi Rates': 'விவசாய சந்தை விலை',
  'Bus Timings': 'பேருந்து நேரம்',
  'Emergency SOS': 'அவசர உதவி 108',
  'Town Hall AI': 'குடிமக்கள் AI அரங்கம்',
  'Blood Donors': 'இரத்த தானம்',
  'Grievances': 'குறைதீர்ப்பு',
  'Marketplace': 'பொருட்கள் சந்தை',
  'Town Events': 'நகர நிகழ்வுகள்',
  'Leaderboard': 'மதிப்பீடு & விருதுகள்',
  'Govt Orders': 'அரசு ஆணைகள்',
  'Community Hub': 'சமூக மையம்',
  'Citizen Polls': 'மக்கள் கருத்துக்கணிப்பு',
  'Topic Rooms': 'விவாத அரங்குகள்',
  'Notifications': 'அறிவிப்புகள் மையம்',

  // Emergency & Hotlines
  '24/7 EMERGENCY HELPLINES': '24/7 அவசர உதவி எண்கள்',
  'Ambulance': 'ஆம்புலன்ஸ்',
  'Police Control': 'காவல்துறை',
  'Fire Station': 'தீயணைப்பு நிலையம்',
  'Need Immediate Assistance?': 'உடனடி உதவி தேவையா?',

  // Weather & Agriculture
  'LIVE WEATHER & AGRI ADVISORY': 'வானிலை & விவசாய ஆலோசனை',
  'Farmer & Crop Advisory': 'விவசாயிகள் & பயிர் ஆலோசனை',

  // Actions
  'Storefront': 'கடை விபரம்',
  'Register Shop': 'கடை பதிவு செய்',
  'Post Requirement': 'வேலை வாய்ப்பு பதிவிடு',
  'List Item for Sale': 'விற்பனைக்கு பதிவிடு',
  'Host Event': 'நிகழ்வு தொடங்கு',
  'Submit Civic Grievance': 'குறைதீர்ப்பு மனு அளி',
  'Report Content': 'புகார் செய்',
  'Close': 'மூடுக',
  'Submit': 'சமர்ப்பி',
};

String tr(String key) {
  if (!LanguageNotifier.instance.isTamil) return key;
  return _tamilDictionary[key] ?? key;
}
