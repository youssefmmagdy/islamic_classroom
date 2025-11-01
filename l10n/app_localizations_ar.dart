// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دار القرآن';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get aboutUs => 'من نحن';

  @override
  String get courses => 'الدورات';

  @override
  String get homeworks => 'الواجبات';

  @override
  String get attendance => 'الحضور';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }
}
