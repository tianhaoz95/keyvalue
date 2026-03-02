// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get login => '登录';

  @override
  String get email => '电子邮件';

  @override
  String get password => '密码';

  @override
  String get rememberMe => '记住我';

  @override
  String get createAccount => '创建账户';

  @override
  String get continueAsGuest => '以访客身份继续';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String portfolioStats(int count) {
    return '您的投资组合包含 $count 位客户';
  }

  @override
  String get clients => '客户';

  @override
  String get pendingActions => '待处理事项';

  @override
  String get reviewNow => '立即查看';

  @override
  String get aiOnboarding => 'AI 辅助开户';

  @override
  String get addClient => '添加客户';

  @override
  String get settings => '设置';

  @override
  String get profile => '个人资料';

  @override
  String get account => '账户';

  @override
  String get logout => '退出登录';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get language => '语言';

  @override
  String get saveChanges => '保存更改';

  @override
  String get engagement => '互动';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get resetPassword => '重置密码';

  @override
  String get sendResetLink => '发送重置链接';

  @override
  String get enterEmailToReset => '请输入您的电子邮件以接收密码重置链接。';

  @override
  String get resetLinkSent => '密码重置链接已发送到您的邮箱。';

  @override
  String errorSendingReset(String error) {
    return '发送重置链接失败：$error';
  }
}
