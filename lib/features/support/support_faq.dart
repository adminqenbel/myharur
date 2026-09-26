// ==============================================================================
// SUPPORT FAQ: the built-in answers of the support chat (English and Tamil).
// Everything here is local: no network, no personal data. Each entry has keywords (English, Tamil and common
// spellings people type) used to match a free-text question. If nothing matches, the chat offers the topic
// list, the AI assistant and an e-mail to support.
// Keep the answers in step with the app: they describe real screens and limits.
// ==============================================================================
class FaqEntry {
  final String id;
  final String topic; // account | posts | safety | app
  final String qEn;
  final String qTa;
  final String aEn;
  final String aTa;
  final List<String> keywords;

  const FaqEntry({
    required this.id,
    required this.topic,
    required this.qEn,
    required this.qTa,
    required this.aEn,
    required this.aTa,
    required this.keywords,
  });

  String question(String lang) => lang == 'ta' ? qTa : qEn;
  String answer(String lang) => lang == 'ta' ? aTa : aEn;
}

/// Short labels for the topic chips: (id, English, Tamil).
const supportTopics = <(String, String, String)>[
  ('account', 'Sign-in & account', 'உள்நுழைவு & கணக்கு'),
  ('posts', 'Reports & news', 'அறிக்கைகள் & செய்திகள்'),
  ('safety', 'Safety', 'பாதுகாப்பு'),
  ('app', 'The app', 'செயலி'),
];

const faqEntries = <FaqEntry>[
  FaqEntry(
    id: 'signin',
    topic: 'account',
    qEn: 'How do I sign in?',
    qTa: 'எப்படி உள்நுழைவது?',
    aEn: 'Tap "Continue with Google" on the first screen and choose your Google account. There is no separate e-mail sign-up. New here? Use the Register tab, which also uses Google.',
    aTa: 'முதல் திரையில் "Google மூலம் தொடர்க" என்பதைத் தொட்டு உங்கள் Google கணக்கைத் தேர்வுசெய்யவும். தனி மின்னஞ்சல் பதிவு இல்லை. புதியவரா? பதிவு தாவலைப் பயன்படுத்தவும்; அதுவும் Google-ஐ பயன்படுத்தும்.',
    keywords: ['sign in', 'signin', 'log in', 'login', 'google', 'register', 'sign up', 'signup', 'create account', 'உள்நுழை', 'பதிவு', 'லாகின்'],
  ),
  FaqEntry(
    id: 'username',
    topic: 'account',
    qEn: 'Can I sign in with a username?',
    qTa: 'பயனர்பெயரால் உள்நுழையலாமா?',
    aEn: 'Yes, after you have signed in with Google once. Open Account > "Username password" and choose a password (at least 10 characters, with letters and numbers). Then you can sign in with your @username and that password.',
    aTa: 'ஆம், ஒருமுறை Google மூலம் உள்நுழைந்த பிறகு. கணக்கு > "பயனர்பெயர் கடவுச்சொல்" என்பதைத் திறந்து கடவுச்சொல்லை (குறைந்தது 10 எழுத்துகள், எழுத்தும் எண்ணும்) அமைக்கவும். பிறகு @பயனர்பெயர் மற்றும் அந்தக் கடவுச்சொல்லால் உள்நுழையலாம்.',
    keywords: ['username', 'user name', 'set password', 'add password', 'create password', '@', 'பயனர்பெயர்'],
  ),
  FaqEntry(
    id: 'forgot',
    topic: 'account',
    qEn: 'I forgot my password',
    qTa: 'கடவுச்சொல்லை மறந்துவிட்டேன்',
    aEn: 'Sign in with Google (it always works), then open Account > "Username password" and set a new password.',
    aTa: 'Google மூலம் உள்நுழையவும் (அது எப்போதும் வேலை செய்யும்). பிறகு கணக்கு > "பயனர்பெயர் கடவுச்சொல்" என்பதில் புதிய கடவுச்சொல்லை அமைக்கவும்.',
    keywords: ['forgot', 'forget', 'reset password', 'lost password', 'password', 'மறந்த', 'மறந்து', 'கடவுச்சொல்', 'ரீசெட்'],
  ),
  FaqEntry(
    id: 'locked',
    topic: 'account',
    qEn: 'It says password sign-in is paused',
    qTa: 'கடவுச்சொல் உள்நுழைவு நிறுத்தப்பட்டுள்ளதாகக் காட்டுகிறது',
    aEn: 'After 5 wrong passwords in a row, password sign-in pauses for 24 hours. Google sign-in still works. If it happens repeatedly, password sign-in is switched off until a super admin recovers it: e-mail support and we will help.',
    aTa: 'தொடர்ச்சியாக 5 முறை தவறான கடவுச்சொல் கொடுத்தால் 24 மணி நேரம் கடவுச்சொல் உள்நுழைவு நிறுத்தப்படும். Google உள்நுழைவு தொடர்ந்து வேலை செய்யும். மீண்டும் மீண்டும் நடந்தால், சூப்பர் அட்மின் மீட்கும் வரை அது முடக்கப்படும்: ஆதரவுக்கு மின்னஞ்சல் அனுப்புங்கள்.',
    keywords: ['paused', 'locked', 'lock', 'too many', 'blocked login', 'wrong password', 'நிறுத்தப்பட்ட', 'பூட்டு', 'தவறான கடவுச்சொல்'],
  ),
  FaqEntry(
    id: 'switch',
    topic: 'account',
    qEn: 'Can I use two accounts?',
    qTa: 'இரண்டு கணக்குகளைப் பயன்படுத்தலாமா?',
    aEn: 'Yes. Account > "Switch account" keeps up to 3 accounts on this phone. Tap one to switch, or "Add another account" to sign in with a different one.',
    aTa: 'ஆம். கணக்கு > "கணக்கை மாற்று" இந்த தொலைபேசியில் 3 கணக்குகள் வரை வைத்திருக்கும். ஒன்றைத் தொட்டு மாறவும், அல்லது "மற்றொரு கணக்கைச் சேர்" மூலம் வேறொன்றில் உள்நுழையவும்.',
    keywords: ['switch', 'two accounts', 'another account', 'multiple accounts', 'change account', 'கணக்கை மாற்று', 'இரண்டு கணக்கு'],
  ),
  FaqEntry(
    id: 'delete_account',
    topic: 'account',
    qEn: 'How do I delete my account?',
    qTa: 'என் கணக்கை எப்படி நீக்குவது?',
    aEn: 'Account > "Delete account". This removes your profile and sign-in. Posts that were already published stay up but are no longer linked to you.',
    aTa: 'கணக்கு > "கணக்கை நீக்கு". இது உங்கள் சுயவிவரத்தையும் உள்நுழைவையும் நீக்கும். ஏற்கெனவே வெளியான பதிவுகள் இருக்கும், ஆனால் உங்களுடன் இணைக்கப்படாது.',
    keywords: ['delete account', 'remove account', 'close account', 'கணக்கை நீக்கு', 'கணக்கு நீக்க'],
  ),
  FaqEntry(
    id: 'two_factor',
    topic: 'account',
    qEn: 'What is two-factor sign-in?',
    qTa: 'இரு-படி உள்நுழைவு என்றால் என்ன?',
    aEn: 'Admins and super admins must use an authenticator app (a 6-digit code) on top of Google sign-in. Set it up under Account > Two-factor sign-in. If you lose your phone, another super admin can reset it.',
    aTa: 'அட்மின்களும் சூப்பர் அட்மின்களும் Google உள்நுழைவுடன் ஒரு authenticator செயலியை (6 இலக்கக் குறியீடு) பயன்படுத்த வேண்டும். கணக்கு > இரு-படி உள்நுழைவில் அமைக்கவும். தொலைபேசி தொலைந்தால் மற்றொரு சூப்பர் அட்மின் மீட்டமைக்கலாம்.',
    keywords: ['two-factor', 'two factor', '2fa', 'authenticator', 'otp', 'code', 'qr', 'இரு-படி', 'குறியீடு'],
  ),
  FaqEntry(
    id: 'report_how',
    topic: 'posts',
    qEn: 'How do I report a problem?',
    qTa: 'ஒரு பிரச்சினையை எப்படிப் புகாரளிப்பது?',
    aEn: 'Open Reports and tap +. Pick a category (road, electricity, water or government), write a short title and details, and add photos or a place if you like. Then tap Submit.',
    aTa: 'அறிக்கைகள் பகுதியைத் திறந்து + தொடவும். வகையைத் (சாலை, மின்சாரம், தண்ணீர், அரசு) தேர்வுசெய்து, சிறு தலைப்பும் விவரமும் எழுதவும்; விரும்பினால் படங்களையோ இடத்தையோ சேர்க்கவும். பிறகு அனுப்பு.',
    keywords: ['report', 'complaint', 'issue', 'problem', 'pothole', 'submit', 'புகார்', 'அறிக்கை', 'பிரச்சினை'],
  ),
  FaqEntry(
    id: 'review',
    topic: 'posts',
    qEn: 'Why is my post not showing?',
    qTa: 'என் பதிவு ஏன் தெரியவில்லை?',
    aEn: 'Every post is checked automatically and then reviewed by a moderator or admin before it appears. A post nobody reviews within 24 hours expires. See Account > My posts: it shows "Waiting for review", "Live" or "Not approved".',
    aTa: 'ஒவ்வொரு பதிவும் தானாகச் சரிபார்க்கப்பட்டு, வெளியாகும் முன் ஒரு மதிப்பாய்வாளர் அல்லது அட்மினால் பார்க்கப்படும். 24 மணி நேரத்தில் யாரும் பார்க்காவிட்டால் அது காலாவதியாகும். கணக்கு > என் பதிவுகளில் "மதிப்பாய்வுக்குக் காத்திருக்கிறது", "நேரலை" அல்லது "ஏற்கப்படவில்லை" எனத் தெரியும்.',
    keywords: ['not showing', 'not visible', 'pending', 'waiting', 'approve', 'review', 'not appear', 'where is my', 'தெரியவில்லை', 'மதிப்பாய்வு', 'காத்திருக்க'],
  ),
  FaqEntry(
    id: 'rejected',
    topic: 'posts',
    qEn: 'My post was not approved',
    qTa: 'என் பதிவு ஏற்கப்படவில்லை',
    aEn: 'Posts with abusive words, dangerous content, or that look like spam or false information are rejected. You can submit a corrected post. If several posts are blocked in one day, posting pauses until the next day.',
    aTa: 'அவதூறு சொற்கள், ஆபத்தான உள்ளடக்கம், ஸ்பேம் அல்லது தவறான தகவல் போலத் தோன்றும் பதிவுகள் நிராகரிக்கப்படும். திருத்திய பதிவை மீண்டும் அனுப்பலாம். ஒரே நாளில் பல பதிவுகள் தடுக்கப்பட்டால் அடுத்த நாள் வரை பதிவிடுவது நிறுத்தப்படும்.',
    keywords: ['rejected', 'not approved', 'declined', 'blocked post', 'cooldown', 'ஏற்கப்பட', 'நிராகரி'],
  ),
  FaqEntry(
    id: 'news_share',
    topic: 'posts',
    qEn: 'How do I share news?',
    qTa: 'செய்தியை எப்படிப் பகிர்வது?',
    aEn: 'Open News and tap +. Choose a category, write the story, and add an https link or up to 3 photos if you like. It appears under Community after review.',
    aTa: 'செய்திகள் பகுதியைத் திறந்து + தொடவும். வகையைத் தேர்வுசெய்து செய்தியை எழுதவும்; விரும்பினால் https இணைப்போ 3 படங்கள் வரையோ சேர்க்கவும். மதிப்பாய்வுக்குப் பின் சமூகம் பிரிவில் வெளியாகும்.',
    keywords: ['share news', 'post news', 'add news', 'community news', 'செய்தி பகிர', 'செய்தியைப் பகிர'],
  ),
  FaqEntry(
    id: 'photos',
    topic: 'posts',
    qEn: 'Can I add photos?',
    qTa: 'படங்களைச் சேர்க்கலாமா?',
    aEn: 'Yes, up to 3 per post. Location and camera details inside a photo are removed on your phone before it uploads. Photos stay private until the post is approved.',
    aTa: 'ஆம், ஒரு பதிவுக்கு 3 படங்கள் வரை. படத்திலுள்ள இருப்பிடம், கேமரா விவரங்கள் பதிவேற்றும் முன் உங்கள் தொலைபேசியிலேயே நீக்கப்படும். பதிவு ஏற்கப்படும் வரை படங்கள் தனிப்பட்டதாகவே இருக்கும்.',
    keywords: ['photo', 'photos', 'picture', 'image', 'camera', 'upload', 'படம்', 'புகைப்படம்'],
  ),
  FaqEntry(
    id: 'location',
    topic: 'posts',
    qEn: 'How do I add a place?',
    qTa: 'இடத்தை எப்படிச் சேர்ப்பது?',
    aEn: 'In the form tap "Location (optional)". Drop a pin on the map (it opens on Harur), type an address, or use your current location. You can open the saved place in Google Maps from the post.',
    aTa: 'படிவத்தில் "இடம் (விருப்பம்)" என்பதைத் தொடவும். வரைபடத்தில் (அது அரூரில் திறக்கும்) பின் இடவும், முகவரியை எழுதவும், அல்லது தற்போதைய இருப்பிடத்தைப் பயன்படுத்தவும். பதிவிலிருந்து அந்த இடத்தை Google Maps-இல் திறக்கலாம்.',
    keywords: ['location', 'place', 'map', 'address', 'pin', 'gps', 'directions', 'இடம்', 'வரைபடம்', 'முகவரி', 'இருப்பிடம்'],
  ),
  FaqEntry(
    id: 'delete_post',
    topic: 'posts',
    qEn: 'How do I delete my post?',
    qTa: 'என் பதிவை எப்படி நீக்குவது?',
    aEn: 'Account > "My posts", open the post, tap the ⋯ menu and choose "Delete post". It disappears at once.',
    aTa: 'கணக்கு > "என் பதிவுகள்" என்பதில் பதிவைத் திறந்து ⋯ மெனுவைத் தொட்டு "பதிவை நீக்கு" என்பதைத் தேர்வுசெய்யவும். அது உடனே மறையும்.',
    keywords: ['delete post', 'remove post', 'delete my post', 'edit post', 'பதிவை நீக்கு', 'பதிவு நீக்க'],
  ),
  FaqEntry(
    id: 'report_post',
    topic: 'safety',
    qEn: 'How do I report or hide someone\'s post?',
    qTa: 'ஒருவரின் பதிவை எப்படிப் புகாரளிப்பது அல்லது மறைப்பது?',
    aEn: 'Open the post, tap ⋯, then "Report post" or "Hide posts from this author". Three different people reporting the same author restricts the account until our team reviews it. You can undo hiding under Account > Blocked authors.',
    aTa: 'பதிவைத் திறந்து ⋯ தொட்டு "பதிவைப் புகாரளி" அல்லது "இந்த எழுத்தாளரின் பதிவுகளை மறை" என்பதைத் தேர்வுசெய்யவும். ஒரே எழுத்தாளரை மூவர் புகாரளித்தால் எங்கள் குழு பார்க்கும் வரை அவர் கணக்கு கட்டுப்படுத்தப்படும். மறைத்ததை கணக்கு > தடுக்கப்பட்டவர்கள் பகுதியில் மீட்டெடுக்கலாம்.',
    keywords: ['report post', 'report user', 'abuse', 'harass', 'block', 'hide', 'spam', 'fake', 'புகாரளி', 'மறை', 'தடு'],
  ),
  FaqEntry(
    id: 'emergency',
    topic: 'safety',
    qEn: 'Emergency numbers',
    qTa: 'அவசர எண்கள்',
    aEn: 'Call 112 for any emergency, 100 for police, 101 for fire and 108 for an ambulance. MyHarur is not an emergency service. More numbers: Reports > "Emergency and helplines".',
    aTa: 'எந்த அவசரத்துக்கும் 112, காவல்துறைக்கு 100, தீயணைப்புக்கு 101, ஆம்புலன்சுக்கு 108 அழைக்கவும். MyHarur அவசர சேவை அல்ல. மேலும் எண்கள்: அறிக்கைகள் > "அவசரம் மற்றும் உதவி எண்கள்".',
    keywords: ['emergency', 'ambulance', 'police', 'fire', 'helpline', 'urgent', '112', '108', 'அவசர', 'ஆம்புலன்ஸ்', 'காவல்'],
  ),
  FaqEntry(
    id: 'privacy',
    topic: 'safety',
    qEn: 'Is my data safe?',
    qTa: 'என் தரவு பாதுகாப்பானதா?',
    aEn: 'Your profile details are optional and only you (and admins for moderation) can see them. Your sign-in is stored encrypted on the phone. See Account > "Security by QenShar" for exactly what is stored and how to delete it.',
    aTa: 'உங்கள் சுயவிவர விவரங்கள் விருப்பமானவை; நீங்களும் (மதிப்பாய்வுக்காக) அட்மின்களும் மட்டுமே பார்க்க முடியும். உங்கள் உள்நுழைவு தொலைபேசியில் மறையாக்கம் செய்யப்பட்டு சேமிக்கப்படுகிறது. என்ன சேமிக்கப்படுகிறது, எப்படி நீக்குவது என்பதற்கு கணக்கு > "QenShar வழங்கும் பாதுகாப்பு" பார்க்கவும்.',
    keywords: ['privacy', 'data', 'safe', 'secure', 'security', 'personal', 'qenshar', 'தனியுரிமை', 'பாதுகாப்பு', 'தரவு'],
  ),
  FaqEntry(
    id: 'language',
    topic: 'app',
    qEn: 'How do I change the language?',
    qTa: 'மொழியை எப்படி மாற்றுவது?',
    aEn: 'Use the English | தமிழ் switch at the top of the sign-in screen, or Account > Language.',
    aTa: 'உள்நுழைவுத் திரையின் மேலே உள்ள English | தமிழ் சுவிட்சை, அல்லது கணக்கு > மொழி என்பதைப் பயன்படுத்தவும்.',
    keywords: ['language', 'tamil', 'english', 'translate', 'மொழி', 'தமிழ்'],
  ),
  FaqEntry(
    id: 'weather',
    topic: 'app',
    qEn: 'Where does the weather come from?',
    qTa: 'வானிலை எங்கிருந்து வருகிறது?',
    aEn: 'From the Open-Meteo forecast service for Harur and Dharmapuri. Pull down on the Weather tab to refresh.',
    aTa: 'அரூர், தர்மபுரிக்கான Open-Meteo முன்னறிவிப்பு சேவையிலிருந்து. புதுப்பிக்க வானிலை தாவலில் கீழே இழுக்கவும்.',
    keywords: ['weather', 'rain', 'temperature', 'forecast', 'வானிலை', 'மழை'],
  ),
  FaqEntry(
    id: 'headlines',
    topic: 'app',
    qEn: 'Where do the news headlines come from?',
    qTa: 'செய்தித் தலைப்புகள் எங்கிருந்து வருகின்றன?',
    aEn: 'They are collected every 30 minutes from local publishers about Harur and Dharmapuri. Each card links to the publisher\'s own page.',
    aTa: 'அரூர், தர்மபுரி பற்றி உள்ளூர் வெளியீட்டாளர்களிடமிருந்து ஒவ்வொரு 30 நிமிடத்துக்கும் சேகரிக்கப்படுகின்றன. ஒவ்வொரு அட்டையும் வெளியீட்டாளரின் பக்கத்துக்கு இணைக்கும்.',
    keywords: ['headlines', 'news source', 'publisher', 'crawler', 'செய்தி எங்கிருந்து', 'தலைப்பு'],
  ),
  FaqEntry(
    id: 'bug',
    topic: 'app',
    qEn: 'The app crashed or something is broken',
    qTa: 'செயலி செயலிழந்தது அல்லது ஏதோ பழுது',
    aEn: 'Sorry about that. Restart the app first. If it keeps happening, use Account > "Report a bug": it sends your app version and phone model to the developers. Nothing personal is included.',
    aTa: 'மன்னிக்கவும். முதலில் செயலியை மீண்டும் தொடங்கவும். தொடர்ந்து நடந்தால் கணக்கு > "பிழையைப் புகாரளி" பயன்படுத்தவும்: இது உங்கள் செயலிப் பதிப்பையும் தொலைபேசி மாடலையும் டெவலப்பர்களுக்கு அனுப்பும். தனிப்பட்ட தகவல் எதுவும் இல்லை.',
    keywords: ['crash', 'bug', 'broken', 'not working', 'error', 'freeze', 'stuck', 'slow', 'செயலிழ', 'பிழை', 'வேலை செய்யவில்லை'],
  ),
];

/// The entry that best matches [text], or null. Score = number of keywords found in the text; ties go to the
/// entry with the longer matching keyword (more specific).
FaqEntry? bestFaqMatch(String text) {
  final ranked = rankFaq(text);
  return ranked.isEmpty ? null : ranked.first;
}

/// Entries with at least one keyword hit, best first.
List<FaqEntry> rankFaq(String text) {
  final q = text.toLowerCase().trim();
  if (q.length < 2) return const [];
  final scored = <(FaqEntry, int)>[];
  for (final e in faqEntries) {
    var score = 0;
    for (final k in e.keywords) {
      if (q.contains(k.toLowerCase())) score += 10 + k.length;
    }
    if (score > 0) scored.add((e, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.map((s) => s.$1).toList();
}

List<FaqEntry> faqForTopic(String topic) => faqEntries.where((e) => e.topic == topic).toList();
