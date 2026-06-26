import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LOCALIZATION SERVICE — Multi-Language Support & i18n
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;

class SupportedLocale {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool rtl;

  const SupportedLocale({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.rtl = false,
  });
}

class LocalizationService with ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  bool _initialized = false;
  String _currentLocale = 'en';
  final Map<String, Map<String, String>> _translations = {};

  static const _prefKey = 'user_locale';

  static const supportedLocales = [
    // ── Americas ─────────────────────────────────────────────
    SupportedLocale(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    SupportedLocale(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    SupportedLocale(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇧🇷',
    ),
    SupportedLocale(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),

    // ── Europe ───────────────────────────────────────────────
    SupportedLocale(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    SupportedLocale(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    SupportedLocale(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      flag: '🇳🇱',
    ),
    SupportedLocale(
      code: 'pl',
      name: 'Polish',
      nativeName: 'Polski',
      flag: '🇵🇱',
    ),
    SupportedLocale(
      code: 'ro',
      name: 'Romanian',
      nativeName: 'Română',
      flag: '🇷🇴',
    ),
    SupportedLocale(
      code: 'el',
      name: 'Greek',
      nativeName: 'Ελληνικά',
      flag: '🇬🇷',
    ),
    SupportedLocale(
      code: 'cs',
      name: 'Czech',
      nativeName: 'Čeština',
      flag: '🇨🇿',
    ),
    SupportedLocale(
      code: 'sv',
      name: 'Swedish',
      nativeName: 'Svenska',
      flag: '🇸🇪',
    ),
    SupportedLocale(
      code: 'da',
      name: 'Danish',
      nativeName: 'Dansk',
      flag: '🇩🇰',
    ),
    SupportedLocale(
      code: 'fi',
      name: 'Finnish',
      nativeName: 'Suomi',
      flag: '🇫🇮',
    ),
    SupportedLocale(
      code: 'no',
      name: 'Norwegian',
      nativeName: 'Norsk',
      flag: '🇳🇴',
    ),
    SupportedLocale(
      code: 'hu',
      name: 'Hungarian',
      nativeName: 'Magyar',
      flag: '🇭🇺',
    ),
    SupportedLocale(
      code: 'uk',
      name: 'Ukrainian',
      nativeName: 'Українська',
      flag: '🇺🇦',
    ),
    SupportedLocale(
      code: 'hr',
      name: 'Croatian',
      nativeName: 'Hrvatski',
      flag: '🇭🇷',
    ),
    SupportedLocale(
      code: 'sr',
      name: 'Serbian',
      nativeName: 'Srpski',
      flag: '🇷🇸',
    ),
    SupportedLocale(
      code: 'bg',
      name: 'Bulgarian',
      nativeName: 'Български',
      flag: '🇧🇬',
    ),
    SupportedLocale(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),

    // ── Middle East & Central Asia ───────────────────────────
    SupportedLocale(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      rtl: true,
    ),
    SupportedLocale(
      code: 'he',
      name: 'Hebrew',
      nativeName: 'עברית',
      flag: '🇮🇱',
      rtl: true,
    ),
    SupportedLocale(
      code: 'fa',
      name: 'Persian',
      nativeName: 'فارسی',
      flag: '🇮🇷',
      rtl: true,
    ),
    SupportedLocale(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      flag: '🇹🇷',
    ),
    SupportedLocale(
      code: 'ur',
      name: 'Urdu',
      nativeName: 'اردو',
      flag: '🇵🇰',
      rtl: true,
    ),
    SupportedLocale(
      code: 'ps',
      name: 'Pashto',
      nativeName: 'پښتو',
      flag: '🇦🇫',
      rtl: true,
    ),
    SupportedLocale(
      code: 'ku',
      name: 'Kurdish',
      nativeName: 'Kurdî',
      flag: '🇮🇶',
    ),
    SupportedLocale(
      code: 'uz',
      name: 'Uzbek',
      nativeName: 'Oʻzbekcha',
      flag: '🇺🇿',
    ),
    SupportedLocale(
      code: 'kk',
      name: 'Kazakh',
      nativeName: 'Қазақша',
      flag: '🇰🇿',
    ),

    // ── South Asia ───────────────────────────────────────────
    SupportedLocale(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
    SupportedLocale(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      flag: '🇧🇩',
    ),
    SupportedLocale(
      code: 'ta',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      flag: '🇮🇳',
    ),
    SupportedLocale(
      code: 'te',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      flag: '🇮🇳',
    ),
    SupportedLocale(
      code: 'mr',
      name: 'Marathi',
      nativeName: 'मराठी',
      flag: '🇮🇳',
    ),
    SupportedLocale(
      code: 'si',
      name: 'Sinhala',
      nativeName: 'සිංහල',
      flag: '🇱🇰',
    ),
    SupportedLocale(
      code: 'ne',
      name: 'Nepali',
      nativeName: 'नेपाली',
      flag: '🇳🇵',
    ),

    // ── East Asia ────────────────────────────────────────────
    SupportedLocale(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    SupportedLocale(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    SupportedLocale(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
    SupportedLocale(
      code: 'mn',
      name: 'Mongolian',
      nativeName: 'Монгол',
      flag: '🇲🇳',
    ),

    // ── Southeast Asia ───────────────────────────────────────
    SupportedLocale(code: 'th', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
    SupportedLocale(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flag: '🇻🇳',
    ),
    SupportedLocale(
      code: 'id',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flag: '🇮🇩',
    ),
    SupportedLocale(
      code: 'ms',
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
      flag: '🇲🇾',
    ),
    SupportedLocale(
      code: 'tl',
      name: 'Filipino',
      nativeName: 'Tagalog',
      flag: '🇵🇭',
    ),
    SupportedLocale(
      code: 'my',
      name: 'Burmese',
      nativeName: 'မြန်မာ',
      flag: '🇲🇲',
    ),
    SupportedLocale(
      code: 'km',
      name: 'Khmer',
      nativeName: 'ខ្មែរ',
      flag: '🇰🇭',
    ),

    // ── Africa ───────────────────────────────────────────────
    SupportedLocale(
      code: 'sw',
      name: 'Swahili',
      nativeName: 'Kiswahili',
      flag: '🇰🇪',
    ),
    SupportedLocale(
      code: 'am',
      name: 'Amharic',
      nativeName: 'አማርኛ',
      flag: '🇪🇹',
    ),
    SupportedLocale(
      code: 'ha',
      name: 'Hausa',
      nativeName: 'Hausa',
      flag: '🇳🇬',
    ),
    SupportedLocale(
      code: 'yo',
      name: 'Yoruba',
      nativeName: 'Yorùbá',
      flag: '🇳🇬',
    ),
    SupportedLocale(
      code: 'zu',
      name: 'Zulu',
      nativeName: 'isiZulu',
      flag: '🇿🇦',
    ),
    SupportedLocale(
      code: 'af',
      name: 'Afrikaans',
      nativeName: 'Afrikaans',
      flag: '🇿🇦',
    ),

    // ── Oceania ──────────────────────────────────────────────
    SupportedLocale(
      code: 'mi',
      name: 'Māori',
      nativeName: 'Te Reo Māori',
      flag: '🇳🇿',
    ),
    SupportedLocale(
      code: 'sm',
      name: 'Samoan',
      nativeName: 'Gagana Sāmoa',
      flag: '🇼🇸',
    ),
    SupportedLocale(
      code: 'to',
      name: 'Tongan',
      nativeName: 'Lea Faka-Tonga',
      flag: '🇹🇴',
    ),
  ];

  bool get initialized => _initialized;
  String get currentLocale => _currentLocale;
  bool get isRTL => supportedLocales
      .firstWhere(
        (l) => l.code == _currentLocale,
        orElse: () => supportedLocales.first,
      )
      .rtl;

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('🌍 LocalizationService: Initializing...');

    // Load user preference
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString(_prefKey) ?? _detectDeviceLocale();

    // Load translations for current locale
    await _loadTranslations(_currentLocale);

    // Also preload English as fallback
    if (_currentLocale != 'en') {
      await _loadTranslations('en');
    }

    _initialized = true;
    notifyListeners();
  }

  String _detectDeviceLocale() {
    try {
      final deviceLocale = PlatformDispatcher.instance.locale.languageCode;
      final supported = supportedLocales.any((l) => l.code == deviceLocale);
      return supported ? deviceLocale : 'en';
    } catch (_) {
      return 'en';
    }
  }

  Future<void> _loadTranslations(String locale) async {
    if (_translations.containsKey(locale)) return;

    try {
      final doc = await _firestore.collection('translations').doc(locale).get();
      if (doc.exists) {
        _translations[locale] = Map<String, String>.from(doc.data() ?? {});
      } else {
        _translations[locale] = _getBuiltInTranslations(locale);
      }
    } catch (e) {
      debugPrint('LocalizationService: Load $locale failed: $e');
      _translations[locale] = _getBuiltInTranslations(locale);
    }
  }

  Map<String, String> _getBuiltInTranslations(String locale) {
    return _allBuiltInTranslations[locale] ?? _enTranslations;
  }

  Future<void> setLocale(String locale) async {
    if (!supportedLocales.any((l) => l.code == locale)) return;
    if (locale == _currentLocale) return;

    _currentLocale = locale;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale);

    // Load translations if not cached
    await _loadTranslations(locale);

    notifyListeners();
  }

  /// Get translated string
  String tr(String key, {Map<String, String>? args}) {
    // Try current locale, then fallback to English
    String? value = _translations[_currentLocale]?[key];
    value ??= _translations['en']?[key];
    value ??= key; // Return key as last fallback

    // Replace placeholders
    if (args != null) {
      args.forEach((placeholder, replacement) {
        value = value!.replaceAll('{$placeholder}', replacement);
      });
    }

    return value!;
  }

  /// Get plural translation
  String trPlural(String key, int count, {Map<String, String>? args}) {
    final pluralKey = count == 1 ? '${key}_one' : '${key}_other';
    return tr(pluralKey, args: {...?args, 'count': count.toString()});
  }

  /// Get translation with gender
  String trGender(String key, String gender, {Map<String, String>? args}) {
    final genderKey = '${key}_$gender';
    return tr(genderKey, args: args);
  }

  SupportedLocale getCurrentLocaleInfo() {
    return supportedLocales.firstWhere(
      (l) => l.code == _currentLocale,
      orElse: () => supportedLocales.first,
    );
  }
}

// Built-in translations

const _enTranslations = {
  // Navigation
  'nav_home': 'Home',
  'nav_feed': 'Feed',
  'nav_fights': 'Fights',
  'nav_profile': 'Profile',
  'nav_settings': 'Settings',

  // Common
  'app_name': 'Data Fight Central',
  'loading': 'Loading...',
  'error': 'Error',
  'retry': 'Retry',
  'cancel': 'Cancel',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'search': 'Search',
  'share': 'Share',
  'close': 'Close',
  'ok': 'OK',

  // Auth
  'sign_in': 'Sign In',
  'sign_out': 'Sign Out',
  'sign_up': 'Sign Up',
  'email': 'Email',
  'password': 'Password',
  'forgot_password': 'Forgot Password?',

  // Fights
  'live_now': 'LIVE NOW',
  'upcoming': 'Upcoming',
  'results': 'Results',
  'watch_ppv': 'Watch PPV',
  'buy_ppv': 'Buy PPV',
  'round': 'Round',
  'fighters': 'Fighters',
  'fighter_stats': 'Fighter Stats',
  'fight_card': 'Fight Card',
  'main_event': 'Main Event',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Decision',

  // Social
  'post': 'Post',
  'comment': 'Comment',
  'comments_count_one': '{count} comment',
  'comments_count_other': '{count} comments',
  'likes_count_one': '{count} like',
  'likes_count_other': '{count} likes',
  'share_post': 'Share Post',
  'follow': 'Follow',
  'following': 'Following',
  'followers': 'Followers',

  // Dashboard
  'my_stats': 'My Stats',
  'win_rate': 'Win Rate',
  'total_fights': 'Total Fights',
  'predictions': 'Predictions',
  'leaderboard': 'Leaderboard',

  // Accessibility
  'accessibility_options': 'Accessibility Options',
  'high_contrast': 'High Contrast',
  'text_size': 'Text Size',
  'screen_reader': 'Screen Reader Support',
};

const _esTranslations = {
  'nav_home': 'Inicio',
  'nav_feed': 'Noticias',
  'nav_fights': 'Peleas',
  'nav_profile': 'Perfil',
  'nav_settings': 'Configuración',
  'app_name': 'Data Fight Central',
  'loading': 'Cargando...',
  'error': 'Error',
  'retry': 'Reintentar',
  'cancel': 'Cancelar',
  'save': 'Guardar',
  'sign_in': 'Iniciar sesión',
  'sign_out': 'Cerrar sesión',
  'sign_up': 'Registrarse',
  'live_now': 'EN VIVO',
  'upcoming': 'Próximamente',
  'results': 'Resultados',
  'watch_ppv': 'Ver PPV',
  'buy_ppv': 'Comprar PPV',
  'round': 'Round',
  'fighters': 'Peleadores',
  'knockout': 'Nocaut',
  'submission': 'Sumisión',
  'decision': 'Decisión',
  'post': 'Publicar',
  'comment': 'Comentario',
  'follow': 'Seguir',
  'following': 'Siguiendo',
  'followers': 'Seguidores',
};

const _ptTranslations = {
  'nav_home': 'Início',
  'nav_feed': 'Feed',
  'nav_fights': 'Lutas',
  'nav_profile': 'Perfil',
  'nav_settings': 'Configurações',
  'app_name': 'Data Fight Central',
  'loading': 'Carregando...',
  'error': 'Erro',
  'retry': 'Tentar novamente',
  'cancel': 'Cancelar',
  'save': 'Salvar',
  'sign_in': 'Entrar',
  'sign_out': 'Sair',
  'sign_up': 'Cadastrar',
  'live_now': 'AO VIVO',
  'upcoming': 'Em breve',
  'results': 'Resultados',
  'watch_ppv': 'Assistir PPV',
  'buy_ppv': 'Comprar PPV',
  'round': 'Round',
  'fighters': 'Lutadores',
  'knockout': 'Nocaute',
  'submission': 'Finalização',
  'decision': 'Decisão',
  'post': 'Publicar',
  'comment': 'Comentário',
  'follow': 'Seguir',
  'following': 'Seguindo',
  'followers': 'Seguidores',
};

const _jaTranslations = {
  'nav_home': 'ホーム',
  'nav_feed': 'フィード',
  'nav_fights': '試合',
  'nav_profile': 'プロフィール',
  'nav_settings': '設定',
  'app_name': 'Data Fight Central',
  'loading': '読み込み中...',
  'error': 'エラー',
  'retry': '再試行',
  'cancel': 'キャンセル',
  'save': '保存',
  'sign_in': 'サインイン',
  'sign_out': 'サインアウト',
  'sign_up': '登録',
  'live_now': 'ライブ配信中',
  'upcoming': '近日開催',
  'results': '結果',
  'watch_ppv': 'PPVを見る',
  'buy_ppv': 'PPVを購入',
  'round': 'ラウンド',
  'fighters': 'ファイター',
  'knockout': 'ノックアウト',
  'submission': 'サブミッション',
  'decision': '判定',
  'post': '投稿',
  'comment': 'コメント',
  'follow': 'フォロー',
  'following': 'フォロー中',
  'followers': 'フォロワー',
};

// ── Korean ───────────────────────────────────────────────────────────────────
const _koTranslations = {
  'nav_home': '홈',
  'nav_feed': '피드',
  'nav_fights': '경기',
  'nav_profile': '프로필',
  'nav_settings': '설정',
  'app_name': 'Data Fight Central',
  'loading': '로딩 중...',
  'error': '오류',
  'retry': '재시도',
  'cancel': '취소',
  'save': '저장',
  'sign_in': '로그인',
  'sign_out': '로그아웃',
  'sign_up': '회원가입',
  'live_now': '라이브',
  'upcoming': '예정',
  'results': '결과',
  'fighters': '파이터',
  'knockout': '녹아웃',
  'submission': '서브미션',
  'decision': '판정',
  'post': '게시',
  'comment': '댓글',
  'follow': '팔로우',
  'following': '팔로잉',
  'followers': '팔로워',
};

// ── Chinese ──────────────────────────────────────────────────────────────────
const _zhTranslations = {
  'nav_home': '首页',
  'nav_feed': '动态',
  'nav_fights': '比赛',
  'nav_profile': '个人资料',
  'nav_settings': '设置',
  'app_name': 'Data Fight Central',
  'loading': '加载中...',
  'error': '错误',
  'retry': '重试',
  'cancel': '取消',
  'save': '保存',
  'sign_in': '登录',
  'sign_out': '退出',
  'sign_up': '注册',
  'live_now': '直播中',
  'upcoming': '即将开始',
  'results': '结果',
  'fighters': '选手',
  'knockout': '击倒',
  'submission': '降服',
  'decision': '判定',
  'post': '发布',
  'comment': '评论',
  'follow': '关注',
  'following': '已关注',
  'followers': '粉丝',
};

// ── Russian ──────────────────────────────────────────────────────────────────
const _ruTranslations = {
  'nav_home': 'Главная',
  'nav_feed': 'Лента',
  'nav_fights': 'Бои',
  'nav_profile': 'Профиль',
  'nav_settings': 'Настройки',
  'app_name': 'Data Fight Central',
  'loading': 'Загрузка...',
  'error': 'Ошибка',
  'retry': 'Повторить',
  'cancel': 'Отмена',
  'save': 'Сохранить',
  'sign_in': 'Войти',
  'sign_out': 'Выйти',
  'sign_up': 'Регистрация',
  'live_now': 'ПРЯМОЙ ЭФИР',
  'upcoming': 'Скоро',
  'results': 'Результаты',
  'fighters': 'Бойцы',
  'knockout': 'Нокаут',
  'submission': 'Сабмишн',
  'decision': 'Решение',
  'post': 'Пост',
  'comment': 'Комментарий',
  'follow': 'Подписаться',
  'following': 'Подписки',
  'followers': 'Подписчики',
};

// ── Arabic ───────────────────────────────────────────────────────────────────
const _arTranslations = {
  'nav_home': 'الرئيسية',
  'nav_feed': 'الأخبار',
  'nav_fights': 'المعارك',
  'nav_profile': 'الملف الشخصي',
  'nav_settings': 'الإعدادات',
  'app_name': 'Data Fight Central',
  'loading': 'جاري التحميل...',
  'error': 'خطأ',
  'retry': 'إعادة المحاولة',
  'cancel': 'إلغاء',
  'save': 'حفظ',
  'sign_in': 'تسجيل الدخول',
  'sign_out': 'تسجيل الخروج',
  'sign_up': 'إنشاء حساب',
  'live_now': 'مباشر الآن',
  'upcoming': 'قادم',
  'results': 'النتائج',
  'fighters': 'المقاتلون',
  'knockout': 'ضربة قاضية',
  'submission': 'استسلام',
  'decision': 'قرار',
  'post': 'نشر',
  'comment': 'تعليق',
  'follow': 'متابعة',
  'following': 'يتابع',
  'followers': 'متابعون',
};

// ── Thai ─────────────────────────────────────────────────────────────────────
const _thTranslations = {
  'nav_home': 'หน้าแรก',
  'nav_feed': 'ฟีด',
  'nav_fights': 'การต่อสู้',
  'nav_profile': 'โปรไฟล์',
  'nav_settings': 'ตั้งค่า',
  'app_name': 'Data Fight Central',
  'loading': 'กำลังโหลด...',
  'error': 'ข้อผิดพลาด',
  'retry': 'ลองอีกครั้ง',
  'cancel': 'ยกเลิก',
  'save': 'บันทึก',
  'sign_in': 'เข้าสู่ระบบ',
  'sign_out': 'ออกจากระบบ',
  'sign_up': 'สมัครสมาชิก',
  'live_now': 'ถ่ายทอดสด',
  'upcoming': 'กำลังจะมาถึง',
  'results': 'ผลลัพธ์',
  'fighters': 'นักสู้',
  'knockout': 'น็อกเอาต์',
  'submission': 'ซับมิชชั่น',
  'decision': 'คำตัดสิน',
  'post': 'โพสต์',
  'comment': 'ความคิดเห็น',
  'follow': 'ติดตาม',
  'following': 'กำลังติดตาม',
  'followers': 'ผู้ติดตาม',
};

// ── Vietnamese ───────────────────────────────────────────────────────────────
const _viTranslations = {
  'nav_home': 'Trang chủ',
  'nav_feed': 'Bảng tin',
  'nav_fights': 'Trận đấu',
  'nav_profile': 'Hồ sơ',
  'nav_settings': 'Cài đặt',
  'app_name': 'Data Fight Central',
  'loading': 'Đang tải...',
  'error': 'Lỗi',
  'retry': 'Thử lại',
  'cancel': 'Hủy',
  'save': 'Lưu',
  'sign_in': 'Đăng nhập',
  'sign_out': 'Đăng xuất',
  'sign_up': 'Đăng ký',
  'live_now': 'TRỰC TIẾP',
  'upcoming': 'Sắp diễn ra',
  'results': 'Kết quả',
  'fighters': 'Võ sĩ',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Quyết định',
  'post': 'Đăng',
  'comment': 'Bình luận',
  'follow': 'Theo dõi',
  'following': 'Đang theo dõi',
  'followers': 'Người theo dõi',
};

// ── French ───────────────────────────────────────────────────────────────────
const _frTranslations = {
  'nav_home': 'Accueil',
  'nav_feed': 'Fil',
  'nav_fights': 'Combats',
  'nav_profile': 'Profil',
  'nav_settings': 'Paramètres',
  'app_name': 'Data Fight Central',
  'loading': 'Chargement...',
  'error': 'Erreur',
  'retry': 'Réessayer',
  'cancel': 'Annuler',
  'save': 'Enregistrer',
  'sign_in': 'Connexion',
  'sign_out': 'Déconnexion',
  'sign_up': 'Inscription',
  'live_now': 'EN DIRECT',
  'upcoming': 'À venir',
  'results': 'Résultats',
  'fighters': 'Combattants',
  'knockout': 'KO',
  'submission': 'Soumission',
  'decision': 'Décision',
  'post': 'Publier',
  'comment': 'Commentaire',
  'follow': 'Suivre',
  'following': 'Abonnements',
  'followers': 'Abonnés',
};

// ── German ───────────────────────────────────────────────────────────────────
const _deTranslations = {
  'nav_home': 'Startseite',
  'nav_feed': 'Feed',
  'nav_fights': 'Kämpfe',
  'nav_profile': 'Profil',
  'nav_settings': 'Einstellungen',
  'app_name': 'Data Fight Central',
  'loading': 'Laden...',
  'error': 'Fehler',
  'retry': 'Erneut versuchen',
  'cancel': 'Abbrechen',
  'save': 'Speichern',
  'sign_in': 'Anmelden',
  'sign_out': 'Abmelden',
  'sign_up': 'Registrieren',
  'live_now': 'LIVE',
  'upcoming': 'Demnächst',
  'results': 'Ergebnisse',
  'fighters': 'Kämpfer',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Entscheidung',
  'post': 'Posten',
  'comment': 'Kommentar',
  'follow': 'Folgen',
  'following': 'Folge ich',
  'followers': 'Follower',
};

// ── Italian ──────────────────────────────────────────────────────────────────
const _itTranslations = {
  'nav_home': 'Home',
  'nav_feed': 'Feed',
  'nav_fights': 'Combattimenti',
  'nav_profile': 'Profilo',
  'nav_settings': 'Impostazioni',
  'app_name': 'Data Fight Central',
  'loading': 'Caricamento...',
  'error': 'Errore',
  'retry': 'Riprova',
  'cancel': 'Annulla',
  'save': 'Salva',
  'sign_in': 'Accedi',
  'sign_out': 'Esci',
  'sign_up': 'Registrati',
  'live_now': 'IN DIRETTA',
  'upcoming': 'In arrivo',
  'results': 'Risultati',
  'fighters': 'Combattenti',
  'knockout': 'Knockout',
  'submission': 'Sottomissione',
  'decision': 'Decisione',
  'post': 'Pubblica',
  'comment': 'Commento',
  'follow': 'Segui',
  'following': 'Seguiti',
  'followers': 'Follower',
};

// ── Dutch ────────────────────────────────────────────────────────────────────
const _nlTranslations = {
  'nav_home': 'Home',
  'nav_feed': 'Feed',
  'nav_fights': 'Gevechten',
  'nav_profile': 'Profiel',
  'nav_settings': 'Instellingen',
  'app_name': 'Data Fight Central',
  'loading': 'Laden...',
  'error': 'Fout',
  'retry': 'Opnieuw',
  'cancel': 'Annuleren',
  'save': 'Opslaan',
  'sign_in': 'Inloggen',
  'sign_out': 'Uitloggen',
  'sign_up': 'Registreren',
  'live_now': 'LIVE',
  'upcoming': 'Aankomend',
  'results': 'Resultaten',
  'fighters': 'Vechters',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Beslissing',
  'post': 'Plaatsen',
  'comment': 'Reactie',
  'follow': 'Volgen',
  'following': 'Volgend',
  'followers': 'Volgers',
};

// ── Polish ───────────────────────────────────────────────────────────────────
const _plTranslations = {
  'nav_home': 'Strona główna',
  'nav_feed': 'Aktualności',
  'nav_fights': 'Walki',
  'nav_profile': 'Profil',
  'nav_settings': 'Ustawienia',
  'app_name': 'Data Fight Central',
  'loading': 'Ładowanie...',
  'error': 'Błąd',
  'retry': 'Ponów',
  'cancel': 'Anuluj',
  'save': 'Zapisz',
  'sign_in': 'Zaloguj',
  'sign_out': 'Wyloguj',
  'sign_up': 'Rejestracja',
  'live_now': 'NA ŻYWO',
  'upcoming': 'Nadchodzące',
  'results': 'Wyniki',
  'fighters': 'Zawodnicy',
  'knockout': 'Nokaut',
  'submission': 'Poddanie',
  'decision': 'Decyzja',
  'post': 'Opublikuj',
  'comment': 'Komentarz',
  'follow': 'Obserwuj',
  'following': 'Obserwowani',
  'followers': 'Obserwujący',
};

// ── Turkish ──────────────────────────────────────────────────────────────────
const _trTranslations = {
  'nav_home': 'Ana Sayfa',
  'nav_feed': 'Akış',
  'nav_fights': 'Dövüşler',
  'nav_profile': 'Profil',
  'nav_settings': 'Ayarlar',
  'app_name': 'Data Fight Central',
  'loading': 'Yükleniyor...',
  'error': 'Hata',
  'retry': 'Tekrar dene',
  'cancel': 'İptal',
  'save': 'Kaydet',
  'sign_in': 'Giriş yap',
  'sign_out': 'Çıkış yap',
  'sign_up': 'Kayıt ol',
  'live_now': 'CANLI',
  'upcoming': 'Yakında',
  'results': 'Sonuçlar',
  'fighters': 'Dövüşçüler',
  'knockout': 'Nakavt',
  'submission': 'Teslim',
  'decision': 'Karar',
  'post': 'Paylaş',
  'comment': 'Yorum',
  'follow': 'Takip et',
  'following': 'Takip edilen',
  'followers': 'Takipçiler',
};

// ── Hindi ────────────────────────────────────────────────────────────────────
const _hiTranslations = {
  'nav_home': 'होम',
  'nav_feed': 'फीड',
  'nav_fights': 'लड़ाई',
  'nav_profile': 'प्रोफ़ाइल',
  'nav_settings': 'सेटिंग्स',
  'app_name': 'Data Fight Central',
  'loading': 'लोड हो रहा है...',
  'error': 'त्रुटि',
  'retry': 'पुनः प्रयास',
  'cancel': 'रद्द करें',
  'save': 'सहेजें',
  'sign_in': 'साइन इन',
  'sign_out': 'साइन आउट',
  'sign_up': 'साइन अप',
  'live_now': 'लाइव',
  'upcoming': 'आगामी',
  'results': 'परिणाम',
  'fighters': 'लड़ाके',
  'knockout': 'नॉकआउट',
  'submission': 'सबमिशन',
  'decision': 'फ़ैसला',
  'post': 'पोस्ट',
  'comment': 'टिप्पणी',
  'follow': 'फॉलो',
  'following': 'फॉलो कर रहे',
  'followers': 'फॉलोअर्स',
};

// ── Bengali ──────────────────────────────────────────────────────────────────
const _bnTranslations = {
  'nav_home': 'হোম',
  'nav_feed': 'ফিড',
  'nav_fights': 'লড়াই',
  'nav_profile': 'প্রোফাইল',
  'nav_settings': 'সেটিংস',
  'app_name': 'Data Fight Central',
  'loading': 'লোড হচ্ছে...',
  'error': 'ত্রুটি',
  'retry': 'আবার চেষ্টা',
  'cancel': 'বাতিল',
  'save': 'সংরক্ষণ',
  'sign_in': 'সাইন ইন',
  'sign_out': 'সাইন আউট',
  'sign_up': 'নিবন্ধন',
  'live_now': 'সরাসরি',
  'upcoming': 'আসন্ন',
  'results': 'ফলাফল',
  'fighters': 'যোদ্ধা',
  'knockout': 'নকআউট',
  'submission': 'সাবমিশন',
  'decision': 'সিদ্ধান্ত',
  'post': 'পোস্ট',
  'comment': 'মন্তব্য',
  'follow': 'অনুসরণ',
  'following': 'অনুসরণ করছেন',
  'followers': 'অনুসারী',
};

// ── Indonesian ───────────────────────────────────────────────────────────────
const _idTranslations = {
  'nav_home': 'Beranda',
  'nav_feed': 'Feed',
  'nav_fights': 'Pertarungan',
  'nav_profile': 'Profil',
  'nav_settings': 'Pengaturan',
  'app_name': 'Data Fight Central',
  'loading': 'Memuat...',
  'error': 'Kesalahan',
  'retry': 'Coba lagi',
  'cancel': 'Batal',
  'save': 'Simpan',
  'sign_in': 'Masuk',
  'sign_out': 'Keluar',
  'sign_up': 'Daftar',
  'live_now': 'LANGSUNG',
  'upcoming': 'Akan datang',
  'results': 'Hasil',
  'fighters': 'Petarung',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Keputusan',
  'post': 'Kirim',
  'comment': 'Komentar',
  'follow': 'Ikuti',
  'following': 'Mengikuti',
  'followers': 'Pengikut',
};

// ── Malay ────────────────────────────────────────────────────────────────────
const _msTranslations = {
  'nav_home': 'Laman Utama',
  'nav_feed': 'Suapan',
  'nav_fights': 'Pertarungan',
  'nav_profile': 'Profil',
  'nav_settings': 'Tetapan',
  'app_name': 'Data Fight Central',
  'loading': 'Memuatkan...',
  'error': 'Ralat',
  'retry': 'Cuba semula',
  'cancel': 'Batal',
  'save': 'Simpan',
  'sign_in': 'Log masuk',
  'sign_out': 'Log keluar',
  'sign_up': 'Daftar',
  'live_now': 'LANGSUNG',
  'upcoming': 'Akan datang',
  'results': 'Keputusan',
  'fighters': 'Pejuang',
  'knockout': 'KO',
  'submission': 'Penyerahan',
  'decision': 'Keputusan',
  'post': 'Hantar',
  'comment': 'Komen',
  'follow': 'Ikuti',
  'following': 'Mengikuti',
  'followers': 'Pengikut',
};

// ── Filipino ─────────────────────────────────────────────────────────────────
const _tlTranslations = {
  'nav_home': 'Home',
  'nav_feed': 'Feed',
  'nav_fights': 'Laban',
  'nav_profile': 'Profile',
  'nav_settings': 'Settings',
  'app_name': 'Data Fight Central',
  'loading': 'Naglo-load...',
  'error': 'Error',
  'retry': 'Subukan muli',
  'cancel': 'Kanselahin',
  'save': 'I-save',
  'sign_in': 'Mag-sign in',
  'sign_out': 'Mag-sign out',
  'sign_up': 'Mag-sign up',
  'live_now': 'LIVE NA',
  'upcoming': 'Paparating',
  'results': 'Resulta',
  'fighters': 'Mga Mandirigma',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Desisyon',
  'post': 'I-post',
  'comment': 'Komento',
  'follow': 'Sundan',
  'following': 'Sinusundan',
  'followers': 'Mga tagasunod',
};

// ── Hebrew ───────────────────────────────────────────────────────────────────
const _heTranslations = {
  'nav_home': 'בית',
  'nav_feed': 'פיד',
  'nav_fights': 'קרבות',
  'nav_profile': 'פרופיל',
  'nav_settings': 'הגדרות',
  'app_name': 'Data Fight Central',
  'loading': 'טוען...',
  'error': 'שגיאה',
  'retry': 'נסה שוב',
  'cancel': 'ביטול',
  'save': 'שמור',
  'sign_in': 'התחברות',
  'sign_out': 'התנתקות',
  'sign_up': 'הרשמה',
  'live_now': 'שידור חי',
  'upcoming': 'בקרוב',
  'results': 'תוצאות',
  'fighters': 'לוחמים',
  'knockout': 'נוקאאוט',
  'submission': 'הכנעה',
  'decision': 'החלטה',
  'post': 'פרסם',
  'comment': 'תגובה',
  'follow': 'עקוב',
  'following': 'עוקב',
  'followers': 'עוקבים',
};

// ── Persian ──────────────────────────────────────────────────────────────────
const _faTranslations = {
  'nav_home': 'خانه',
  'nav_feed': 'فید',
  'nav_fights': 'مبارزات',
  'nav_profile': 'پروفایل',
  'nav_settings': 'تنظیمات',
  'app_name': 'Data Fight Central',
  'loading': 'در حال بارگذاری...',
  'error': 'خطا',
  'retry': 'تلاش مجدد',
  'cancel': 'لغو',
  'save': 'ذخیره',
  'sign_in': 'ورود',
  'sign_out': 'خروج',
  'sign_up': 'ثبت نام',
  'live_now': 'زنده',
  'upcoming': 'آینده',
  'results': 'نتایج',
  'fighters': 'مبارزان',
  'knockout': 'ناک اوت',
  'submission': 'تسلیم',
  'decision': 'تصمیم',
  'post': 'ارسال',
  'comment': 'نظر',
  'follow': 'دنبال کردن',
  'following': 'دنبال شده',
  'followers': 'دنبال‌کنندگان',
};

// ── Urdu ─────────────────────────────────────────────────────────────────────
const _urTranslations = {
  'nav_home': 'ہوم',
  'nav_feed': 'فیڈ',
  'nav_fights': 'لڑائیاں',
  'nav_profile': 'پروفائل',
  'nav_settings': 'ترتیبات',
  'app_name': 'Data Fight Central',
  'loading': 'لوڈ ہو رہا ہے...',
  'error': 'خرابی',
  'retry': 'دوبارہ کوشش',
  'cancel': 'منسوخ',
  'save': 'محفوظ',
  'sign_in': 'سائن ان',
  'sign_out': 'سائن آؤٹ',
  'sign_up': 'سائن اپ',
  'live_now': 'براہ راست',
  'upcoming': 'آنے والا',
  'results': 'نتائج',
  'fighters': 'جنگجو',
  'knockout': 'ناک آؤٹ',
  'submission': 'سبمشن',
  'decision': 'فیصلہ',
  'post': 'پوسٹ',
  'comment': 'تبصرہ',
  'follow': 'فالو',
  'following': 'فالو کر رہے',
  'followers': 'فالوورز',
};

// ── Swahili ──────────────────────────────────────────────────────────────────
const _swTranslations = {
  'nav_home': 'Nyumbani',
  'nav_feed': 'Mlisho',
  'nav_fights': 'Mapigano',
  'nav_profile': 'Wasifu',
  'nav_settings': 'Mipangilio',
  'app_name': 'Data Fight Central',
  'loading': 'Inapakia...',
  'error': 'Hitilafu',
  'retry': 'Jaribu tena',
  'cancel': 'Ghairi',
  'save': 'Hifadhi',
  'sign_in': 'Ingia',
  'sign_out': 'Ondoka',
  'sign_up': 'Jisajili',
  'live_now': 'MOJA KWA MOJA',
  'upcoming': 'Inakuja',
  'results': 'Matokeo',
  'fighters': 'Wapiganaji',
  'knockout': 'Knockout',
  'submission': 'Kujisalimisha',
  'decision': 'Uamuzi',
  'post': 'Chapisha',
  'comment': 'Maoni',
  'follow': 'Fuata',
  'following': 'Unafuata',
  'followers': 'Wafuasi',
};

// ── Amharic ──────────────────────────────────────────────────────────────────
const _amTranslations = {
  'nav_home': 'መነሻ',
  'nav_feed': 'ፊድ',
  'nav_fights': 'ውጊያዎች',
  'nav_profile': 'መገለጫ',
  'nav_settings': 'ቅንብሮች',
  'app_name': 'Data Fight Central',
  'loading': 'በመጫን ላይ...',
  'error': 'ስህተት',
  'retry': 'እንደገና ሞክር',
  'cancel': 'ይቅር',
  'save': 'አስቀምጥ',
  'sign_in': 'ግባ',
  'sign_out': 'ውጣ',
  'sign_up': 'ተመዝገብ',
  'live_now': 'በቀጥታ',
  'upcoming': 'በቅርብ',
  'results': 'ውጤቶች',
  'fighters': 'ተዋጊዎች',
  'knockout': 'ኖክአውት',
  'submission': 'ሰብሚሽን',
  'decision': 'ውሳኔ',
  'post': 'ለጥፍ',
  'comment': 'አስተያየት',
  'follow': 'ተከተል',
  'following': 'እየተከተሉ',
  'followers': 'ተከታዮች',
};

// ── Ukrainian ────────────────────────────────────────────────────────────────
const _ukTranslations = {
  'nav_home': 'Головна',
  'nav_feed': 'Стрічка',
  'nav_fights': 'Бої',
  'nav_profile': 'Профіль',
  'nav_settings': 'Налаштування',
  'app_name': 'Data Fight Central',
  'loading': 'Завантаження...',
  'error': 'Помилка',
  'retry': 'Повторити',
  'cancel': 'Скасувати',
  'save': 'Зберегти',
  'sign_in': 'Увійти',
  'sign_out': 'Вийти',
  'sign_up': 'Реєстрація',
  'live_now': 'НАЖИВО',
  'upcoming': 'Незабаром',
  'results': 'Результати',
  'fighters': 'Бійці',
  'knockout': 'Нокаут',
  'submission': 'Сабмішн',
  'decision': 'Рішення',
  'post': 'Пост',
  'comment': 'Коментар',
  'follow': 'Стежити',
  'following': 'Стежу',
  'followers': 'Підписники',
};

// ── Māori ────────────────────────────────────────────────────────────────────
const _miTranslations = {
  'nav_home': 'Kāinga',
  'nav_feed': 'Whāngai',
  'nav_fights': 'Whawhai',
  'nav_profile': 'Kōtaha',
  'nav_settings': 'Tautuhinga',
  'app_name': 'Data Fight Central',
  'loading': 'E uta ana...',
  'error': 'Hapa',
  'retry': 'Ngana anō',
  'cancel': 'Whakakore',
  'save': 'Tiaki',
  'sign_in': 'Takiuru',
  'sign_out': 'Takiputa',
  'sign_up': 'Rēhita',
  'live_now': 'ORA',
  'upcoming': 'E haere mai ana',
  'results': 'Ngā hua',
  'fighters': 'Ngā kaiwhakatete',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Whakatau',
  'post': 'Tuku',
  'comment': 'Kōrero',
  'follow': 'Whai',
  'following': 'E whai ana',
  'followers': 'Ngā kaiwhai',
};

// ── Samoan ───────────────────────────────────────────────────────────────────
const _smTranslations = {
  'nav_home': 'Aiga',
  'nav_feed': 'Fafaga',
  'nav_fights': 'Fusuaga',
  'nav_profile': 'Faʻamatalaga',
  'nav_settings': 'Faʻatulagaina',
  'app_name': 'Data Fight Central',
  'loading': 'O loʻo utaina...',
  'error': 'Sesē',
  'retry': 'Toe taumafai',
  'cancel': 'Faʻaleaogaina',
  'save': 'Sefe',
  'sign_in': 'Saini i totonu',
  'sign_out': 'Saini i fafo',
  'sign_up': 'Lesitala',
  'live_now': 'OLA NEI',
  'upcoming': 'O loʻo alu mai',
  'results': 'Iʻuga',
  'fighters': 'Tagata fusuʻa',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Faʻaiʻuga',
  'post': 'Tuʻuina',
  'comment': 'Faamatalaga',
  'follow': 'Mulimuli',
  'following': 'O loʻo mulimuli',
  'followers': 'Tagata mulimuli',
};

// ── Tongan ───────────────────────────────────────────────────────────────────
const _toTranslations = {
  'nav_home': 'ʻApi',
  'nav_feed': 'Fafanga',
  'nav_fights': 'Tau',
  'nav_profile': 'Fakamatala',
  'nav_settings': 'Fili',
  'app_name': 'Data Fight Central',
  'loading': 'Lolotonga hiki...',
  'error': 'Fehalaaki',
  'retry': 'Toe feinga',
  'cancel': 'Kaniseli',
  'save': 'Hilifaki',
  'sign_in': 'Hū',
  'sign_out': 'Hū kituʻa',
  'sign_up': 'Lēsisita',
  'live_now': 'MOʻUI',
  'upcoming': 'Haʻu',
  'results': 'Ngaahi ola',
  'fighters': 'Kau tau',
  'knockout': 'Knockout',
  'submission': 'Submission',
  'decision': 'Fakamaau',
  'post': 'Tuku atu',
  'comment': 'Fakamatala',
  'follow': 'Muimui',
  'following': 'Muimui',
  'followers': 'Kau muimui',
};

// ── Romanian ─────────────────────────────────────────────────────────────────
const _roTranslations = {
  'nav_home': 'Acasă',
  'nav_feed': 'Flux',
  'nav_fights': 'Lupte',
  'nav_profile': 'Profil',
  'nav_settings': 'Setări',
  'loading': 'Se încarcă...',
  'error': 'Eroare',
  'retry': 'Reîncercați',
  'cancel': 'Anulare',
  'save': 'Salvează',
  'sign_in': 'Conectare',
  'sign_out': 'Deconectare',
  'fighters': 'Luptători',
  'knockout': 'Knockout',
  'decision': 'Decizie',
  'follow': 'Urmărește',
  'following': 'Urmărești',
  'followers': 'Urmăritori',
};

// ── Greek ────────────────────────────────────────────────────────────────────
const _elTranslations = {
  'nav_home': 'Αρχική',
  'nav_feed': 'Ροή',
  'nav_fights': 'Μάχες',
  'nav_profile': 'Προφίλ',
  'nav_settings': 'Ρυθμίσεις',
  'loading': 'Φόρτωση...',
  'error': 'Σφάλμα',
  'retry': 'Επανάληψη',
  'cancel': 'Ακύρωση',
  'save': 'Αποθήκευση',
  'sign_in': 'Σύνδεση',
  'sign_out': 'Αποσύνδεση',
  'fighters': 'Μαχητές',
  'knockout': 'Νοκ-άουτ',
  'decision': 'Απόφαση',
  'follow': 'Ακολούθησε',
  'following': 'Ακολουθείτε',
  'followers': 'Ακόλουθοι',
};

// ── Czech ────────────────────────────────────────────────────────────────────
const _csTranslations = {
  'nav_home': 'Domů',
  'nav_feed': 'Feed',
  'nav_fights': 'Zápasy',
  'nav_profile': 'Profil',
  'nav_settings': 'Nastavení',
  'loading': 'Načítání...',
  'error': 'Chyba',
  'retry': 'Zkusit znovu',
  'cancel': 'Zrušit',
  'save': 'Uložit',
  'sign_in': 'Přihlásit',
  'sign_out': 'Odhlásit',
  'fighters': 'Bojovníci',
  'knockout': 'Knockout',
  'decision': 'Rozhodnutí',
  'follow': 'Sledovat',
  'following': 'Sleduji',
  'followers': 'Sledující',
};

// ── Swedish ──────────────────────────────────────────────────────────────────
const _svTranslations = {
  'nav_home': 'Hem',
  'nav_feed': 'Flöde',
  'nav_fights': 'Matcher',
  'nav_profile': 'Profil',
  'nav_settings': 'Inställningar',
  'loading': 'Laddar...',
  'error': 'Fel',
  'retry': 'Försök igen',
  'cancel': 'Avbryt',
  'save': 'Spara',
  'sign_in': 'Logga in',
  'sign_out': 'Logga ut',
  'fighters': 'Fighters',
  'knockout': 'Knockout',
  'decision': 'Beslut',
  'follow': 'Följ',
  'following': 'Följer',
  'followers': 'Följare',
};

// ── Danish ───────────────────────────────────────────────────────────────────
const _daTranslations = {
  'nav_home': 'Hjem',
  'nav_feed': 'Feed',
  'nav_fights': 'Kampe',
  'nav_profile': 'Profil',
  'nav_settings': 'Indstillinger',
  'loading': 'Indlæser...',
  'error': 'Fejl',
  'cancel': 'Annuller',
  'save': 'Gem',
  'sign_in': 'Log ind',
  'sign_out': 'Log ud',
  'fighters': 'Kæmpere',
  'knockout': 'Knockout',
  'decision': 'Afgørelse',
  'follow': 'Følg',
  'following': 'Følger',
  'followers': 'Følgere',
};

// ── Finnish ──────────────────────────────────────────────────────────────────
const _fiTranslations = {
  'nav_home': 'Koti',
  'nav_feed': 'Syöte',
  'nav_fights': 'Ottelut',
  'nav_profile': 'Profiili',
  'nav_settings': 'Asetukset',
  'loading': 'Ladataan...',
  'error': 'Virhe',
  'cancel': 'Peruuta',
  'save': 'Tallenna',
  'sign_in': 'Kirjaudu',
  'sign_out': 'Kirjaudu ulos',
  'fighters': 'Taistelijat',
  'knockout': 'Tyrmäys',
  'decision': 'Tuomio',
  'follow': 'Seuraa',
  'following': 'Seuraat',
  'followers': 'Seuraajat',
};

// ── Norwegian ────────────────────────────────────────────────────────────────
const _noTranslations = {
  'nav_home': 'Hjem',
  'nav_feed': 'Feed',
  'nav_fights': 'Kamper',
  'nav_profile': 'Profil',
  'nav_settings': 'Innstillinger',
  'loading': 'Laster...',
  'error': 'Feil',
  'cancel': 'Avbryt',
  'save': 'Lagre',
  'sign_in': 'Logg inn',
  'sign_out': 'Logg ut',
  'fighters': 'Kjempere',
  'knockout': 'Knockout',
  'decision': 'Avgjørelse',
  'follow': 'Følg',
  'following': 'Følger',
  'followers': 'Følgere',
};

// ── Hungarian ────────────────────────────────────────────────────────────────
const _huTranslations = {
  'nav_home': 'Kezdőlap',
  'nav_feed': 'Hírfolyam',
  'nav_fights': 'Meccsek',
  'nav_profile': 'Profil',
  'nav_settings': 'Beállítások',
  'loading': 'Betöltés...',
  'error': 'Hiba',
  'cancel': 'Mégse',
  'save': 'Mentés',
  'sign_in': 'Bejelentkezés',
  'sign_out': 'Kijelentkezés',
  'fighters': 'Harcosok',
  'knockout': 'Kiütés',
  'decision': 'Pontozás',
  'follow': 'Követés',
  'following': 'Követem',
  'followers': 'Követők',
};

// ── Mongolian ────────────────────────────────────────────────────────────────
const _mnTranslations = {
  'nav_home': 'Нүүр',
  'nav_feed': 'Мэдээ',
  'nav_fights': 'Тулаанууд',
  'nav_profile': 'Профайл',
  'nav_settings': 'Тохиргоо',
  'loading': 'Ачааллаж байна...',
  'error': 'Алдаа',
  'cancel': 'Болих',
  'save': 'Хадгалах',
  'sign_in': 'Нэвтрэх',
  'sign_out': 'Гарах',
  'fighters': 'Тулаанчид',
  'knockout': 'Нокаут',
  'decision': 'Шийдвэр',
  'follow': 'Дагах',
  'following': 'Дагаж байна',
  'followers': 'Дагагчид',
};

// ── Lookup map for all built-in translations ─────────────────────────────────
const _allBuiltInTranslations = <String, Map<String, String>>{
  'en': _enTranslations,
  'es': _esTranslations,
  'pt': _ptTranslations,
  'ja': _jaTranslations,
  'ko': _koTranslations,
  'zh': _zhTranslations,
  'ru': _ruTranslations,
  'ar': _arTranslations,
  'th': _thTranslations,
  'vi': _viTranslations,
  'fr': _frTranslations,
  'de': _deTranslations,
  'it': _itTranslations,
  'nl': _nlTranslations,
  'pl': _plTranslations,
  'tr': _trTranslations,
  'hi': _hiTranslations,
  'bn': _bnTranslations,
  'id': _idTranslations,
  'ms': _msTranslations,
  'tl': _tlTranslations,
  'he': _heTranslations,
  'fa': _faTranslations,
  'ur': _urTranslations,
  'sw': _swTranslations,
  'am': _amTranslations,
  'uk': _ukTranslations,
  'mi': _miTranslations,
  'sm': _smTranslations,
  'to': _toTranslations,
  'ro': _roTranslations,
  'el': _elTranslations,
  'cs': _csTranslations,
  'sv': _svTranslations,
  'da': _daTranslations,
  'fi': _fiTranslations,
  'no': _noTranslations,
  'hu': _huTranslations,
  'mn': _mnTranslations,
};
