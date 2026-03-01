// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get createAccount => 'CREATE AN ACCOUNT';

  @override
  String get continueAsGuest => 'CONTINUE AS GUEST';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String portfolioStats(int count) {
    return 'Your portfolio consists of $count clients';
  }

  @override
  String get clients => 'Clients';

  @override
  String get pendingActions => 'PENDING ACTIONS';

  @override
  String get reviewNow => 'REVIEW NOW';

  @override
  String get aiOnboarding => 'AI ONBOARDING';

  @override
  String get addClient => 'Add Client';

  @override
  String get settings => 'SETTINGS';

  @override
  String get profile => 'PROFILE';

  @override
  String get account => 'ACCOUNT';

  @override
  String get logout => 'LOGOUT';

  @override
  String get deleteAccount => 'DELETE ACCOUNT';

  @override
  String get language => 'Language';

  @override
  String get saveChanges => 'SAVE CHANGES';
}
