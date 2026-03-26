import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

abstract class SmsService {
  Future<void> sendSms({required String to, required String message});
  Future<List<String>> searchAvailableNumbers({String areaCode = '201'});
  Future<String> provisionNumber(String phoneNumber);
}

class FakeSmsService implements SmsService {
  @override
  Future<void> sendSms({required String to, required String message}) async {
    developer.log('SIMULATED SMS to $to: $message');
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<List<String>> searchAvailableNumbers({String areaCode = '201'}) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      '+1$areaCode' '5550101',
      '+1$areaCode' '5550102',
      '+1$areaCode' '5550103',
    ];
  }

  @override
  Future<String> provisionNumber(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 1));
    return phoneNumber;
  }
}

class TwilioSmsService implements SmsService {
  final String accountSid;
  final String authToken;
  final String? fromNumber;

  TwilioSmsService({
    required this.accountSid,
    required this.authToken,
    this.fromNumber,
  });

  bool get isConfigured => accountSid.isNotEmpty && authToken.isNotEmpty;

  @override
  Future<void> sendSms({required String to, required String message}) async {
    if (!isConfigured) {
      developer.log('Twilio not configured. Skipping SMS.');
      return;
    }
    
    if (fromNumber == null || fromNumber!.isEmpty) {
      throw Exception('Twilio From Number is not configured.');
    }

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
      body: {
        'From': fromNumber,
        'To': to,
        'Body': message,
      },
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception('Failed to send SMS: ${error['message'] ?? response.body}');
    }

    developer.log('Twilio SMS sent to $to');
  }

  @override
  Future<List<String>> searchAvailableNumbers({String areaCode = '201'}) async {
    if (!isConfigured) {
      throw Exception('Twilio credentials not provided.');
    }

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/AvailablePhoneNumbers/US/Local.json?AreaCode=$areaCode');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List numbers = data['available_phone_numbers'] ?? [];
      return numbers.map((n) => n['phone_number'] as String).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Failed to search numbers: ${error['message'] ?? response.body}');
    }
  }

  @override
  Future<String> provisionNumber(String phoneNumber) async {
    if (!isConfigured) {
      throw Exception('Twilio credentials not provided.');
    }

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/IncomingPhoneNumbers.json');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
      body: {
        'PhoneNumber': phoneNumber,
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['phone_number'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Failed to provision number: ${error['message'] ?? response.body}');
    }
  }
}
