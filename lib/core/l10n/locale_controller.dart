import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// Current UI language (English / Tamil), remembered across launches.
class LocaleController extends ChangeNotifier {
  static final LocaleController instance = LocaleController._();
  LocaleController._();

  static const supported = [Locale('en'), Locale('ta')];
  static const _key = 'ui_language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isTamil => _locale.languageCode == 'ta';

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      if (saved == 'ta' || saved == 'en') _locale = Locale(saved!);
    } catch (_) {/* storage unavailable: stay on English */}
  }

  Future<void> setLanguage(String code) async {
    if (code == _locale.languageCode || (code != 'en' && code != 'ta')) return;
    _locale = Locale(code);
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, code);
    } catch (_) {}
  }
}

extension L10nContext on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);

  /// "5m ago" / "2h ago" in the current language.
  String timeAgo(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
    return t.daysAgo(diff.inDays);
  }

  String categoryName(String category) {
    switch (category.toLowerCase()) {
      case 'road': return t.catRoad;
      case 'electricity': return t.catElectricity;
      case 'water': return t.catWater;
      case 'govt': return t.catGovt;
      case 'traffic': return t.ncTraffic;
      case 'civic': return t.ncCivic;
      case 'health': return t.ncHealth;
      case 'education': return t.ncEducation;
      case 'community': return t.ncCommunity;
      case 'other': return t.ncOther;
      case 'cultural': return t.ecCultural;
      case 'sports': return t.ecSports;
      case 'religious': return t.ecReligious;
      case 'government': return t.ecGovernment;
      case 'business': return t.ecBusiness;
      case 'full_time': return t.jcFullTime;
      case 'part_time': return t.jcPartTime;
      case 'contract': return t.jcContract;
      case 'internship': return t.jcInternship;
      case 'daily_wage': return t.jcDailyWage;
      default: return category;
    }
  }
}
