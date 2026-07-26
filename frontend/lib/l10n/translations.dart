import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

const Map<String, String> _tamilDict = {
  // Navigation
  'Home': 'முகப்பு',
  'Market': 'சந்தை',
  'Community': 'சமூகம்',
  'Report': 'புகார்',
  'Profile': 'சுயவிவரம்',
  
  // Dashboard Services
  'Daily Deals': 'தினசரி சலுகைகள்',
  'Jobs Nearby': 'அருகிலுள்ள வேலைகள்',
  'Buy/Sell': 'வாங்க/விற்க',
  'Events': 'நிகழ்வுகள்',
  'Polls': 'வாக்கெடுப்பு',
  'Services': 'சேவைகள்',
  'Leaderboard': 'தரவரிசை',
  'Town Map': 'நகர வரைபடம்',

  // Headers
  'Dharmapuri Region': 'தருமபுரி பகுதி',
  'Outside Service Area': 'சேவை பகுதிக்கு வெளியே',
  'Town Feed': 'நகர செய்திகள்',
  'Marketplace': 'சந்தை',
  'Community Hub': 'சமூக மையம்',
  'Citizen Report & SOS': 'குடிமக்கள் அறிக்கை & SOS',
  
  // General
  'Tap map to refine location': 'இடத்தை மாற்ற வரைபடத்தைத் தட்டவும்',
  'Fetching GPS...': 'GPS பெறப்படுகிறது...',
  'Police (100)': 'காவல்துறை (100)',
  'Medical (108)': 'மருத்துவம் (108)',
  'Report Issue': 'புகார் செய்',
  'My Rewards': 'எனது வெகுமதிகள்',
};

String l(WidgetRef ref, String key) {
  final isEng = ref.watch(isEnglishProvider);
  if (isEng) return key;
  return _tamilDict[key] ?? key;
}
