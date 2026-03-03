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
    return 'You have $count clients in your list';
  }

  @override
  String get clients => 'Clients';

  @override
  String get pendingActions => 'URGENT REVIEWS';

  @override
  String get reviewNow => 'REVIEW';

  @override
  String get aiOnboarding => 'AI CLIENT ONBOARDING';

  @override
  String get addClient => 'Add New Client';

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

  @override
  String get engagement => 'ENGAGEMENT';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetLink => 'SEND RESET LINK';

  @override
  String get enterEmailToReset =>
      'Enter your email to receive a password reset link.';

  @override
  String get resetLinkSent => 'Password reset link sent to your email.';

  @override
  String errorSendingReset(String error) {
    return 'Failed to send reset link: $error';
  }
}
