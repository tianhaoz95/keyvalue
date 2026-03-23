import 'dart:developer' as developer;

abstract class SmsService {
  Future<void> sendSms({required String to, required String message});
}

class FakeSmsService implements SmsService {
  @override
  Future<void> sendSms({required String to, required String message}) async {
    developer.log('SIMULATED SMS to $to: $message');
    // In a real simulation, we might write this to a local log file or a special "simulated_sms" collection in Firestore
    await Future.delayed(const Duration(seconds: 1));
  }
}

class TwilioSmsService implements SmsService {
  final String accountSid;
  final String authToken;
  final String fromNumber;

  TwilioSmsService({
    required this.accountSid,
    required this.authToken,
    required this.fromNumber,
  });

  @override
  Future<void> sendSms({required String to, required String message}) async {
    // This would use http to call Twilio API
    // POST https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json
    // For now, it's a stub until we have the paid service and keys
    developer.log('TWILIO SMS to $to: $message (STUB)');
    throw UnimplementedError('Twilio API integration is pending paid service subscription.');
  }
}
