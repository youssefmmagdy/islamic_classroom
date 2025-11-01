// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dar Al-Arqam';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get aboutUs => 'About Us';

  @override
  String get courses => 'Courses';

  @override
  String get homeworks => 'Homeworks';

  @override
  String get attendance => 'Attendance';

  @override
  String version(String version) {
    return 'Version $version';
  }
}
