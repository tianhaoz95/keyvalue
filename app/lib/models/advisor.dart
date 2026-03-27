import 'package:hive/hive.dart';

part 'advisor.g.dart';

@HiveType(typeId: 0)
class Advisor {
  @HiveField(0)
  final String uid;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String firmName;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String aiCapability;
  @HiveField(5)
  final bool isExpressiveAiEnabled;
  @HiveField(6)
  final bool isMultimodalAiEnabled;
  @HiveField(15)
  final bool preferOnDeviceAi;
  @HiveField(7)
  final String subscriptionPlan;
  @HiveField(8)
  final String cardHolderName;
  @HiveField(9)
  final String cardNumber;
  @HiveField(10)
  final String expiryDate;
  @HiveField(11)
  final String cvv;
  @HiveField(12)
  final String zipCode;
  @HiveField(13)
  final DateTime? nextBillingDate;
  @HiveField(14)
  final String firmPhoneNumber;
  @HiveField(18)
  final String firmEmailAddress;
  @HiveField(16)
  final String twilioAccountSid;
  @HiveField(17)
  final String twilioAuthToken;
  @HiveField(19)
  final String sendgridApiKey;
  @HiveField(20)
  final String sendgridVerifiedSender;
  @HiveField(21)
  final String? stripeCustomerId;
  @HiveField(22)
  final String? subscriptionId;
  @HiveField(23)
  final String subscriptionStatus; // 'active', 'past_due', 'canceled', 'incomplete', 'none'

  const Advisor({
    required this.uid,
    required this.name,
    required this.firmName,
    required this.email,
    this.aiCapability = 'pro',
    this.isExpressiveAiEnabled = true,
    this.isMultimodalAiEnabled = false,
    this.preferOnDeviceAi = false,
    this.subscriptionPlan = 'Starter',
    this.cardHolderName = '',
    this.cardNumber = '',
    this.expiryDate = '',
    this.cvv = '',
    this.zipCode = '',
    this.nextBillingDate,
    this.firmPhoneNumber = '',
    this.firmEmailAddress = '',
    this.twilioAccountSid = '',
    this.twilioAuthToken = '',
    this.sendgridApiKey = '',
    this.sendgridVerifiedSender = '',
    this.stripeCustomerId,
    this.subscriptionId,
    this.subscriptionStatus = 'none',
  });

  Advisor copyWith({
    String? uid,
    String? name,
    String? firmName,
    String? email,
    String? aiCapability,
    bool? isExpressiveAiEnabled,
    bool? isMultimodalAiEnabled,
    bool? preferOnDeviceAi,
    String? subscriptionPlan,
    String? cardHolderName,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    String? zipCode,
    DateTime? nextBillingDate,
    String? firmPhoneNumber,
    String? firmEmailAddress,
    String? twilioAccountSid,
    String? twilioAuthToken,
    String? sendgridApiKey,
    String? sendgridVerifiedSender,
    String? stripeCustomerId,
    String? subscriptionId,
    String? subscriptionStatus,
  }) {
    return Advisor(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firmName: firmName ?? this.firmName,
      email: email ?? this.email,
      aiCapability: aiCapability ?? this.aiCapability,
      isExpressiveAiEnabled: isExpressiveAiEnabled ?? this.isExpressiveAiEnabled,
      isMultimodalAiEnabled: isMultimodalAiEnabled ?? this.isMultimodalAiEnabled,
      preferOnDeviceAi: preferOnDeviceAi ?? this.preferOnDeviceAi,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      zipCode: zipCode ?? this.zipCode,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      firmPhoneNumber: firmPhoneNumber ?? this.firmPhoneNumber,
      firmEmailAddress: firmEmailAddress ?? this.firmEmailAddress,
      twilioAccountSid: twilioAccountSid ?? this.twilioAccountSid,
      twilioAuthToken: twilioAuthToken ?? this.twilioAuthToken,
      sendgridApiKey: sendgridApiKey ?? this.sendgridApiKey,
      sendgridVerifiedSender: sendgridVerifiedSender ?? this.sendgridVerifiedSender,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'firmName': firmName,
      'email': email,
      'aiCapability': aiCapability,
      'isExpressiveAiEnabled': isExpressiveAiEnabled,
      'isMultimodalAiEnabled': isMultimodalAiEnabled,
      'preferOnDeviceAi': preferOnDeviceAi,
      'subscriptionPlan': subscriptionPlan,
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'zipCode': zipCode,
      'nextBillingDate': nextBillingDate?.toIso8601String(),
      'firmPhoneNumber': firmPhoneNumber,
      'firmEmailAddress': firmEmailAddress,
      'twilioAccountSid': twilioAccountSid,
      'twilioAuthToken': twilioAuthToken,
      'sendgridApiKey': sendgridApiKey,
      'sendgridVerifiedSender': sendgridVerifiedSender,
      'stripeCustomerId': stripeCustomerId,
      'subscriptionId': subscriptionId,
      'subscriptionStatus': subscriptionStatus,
    };
  }

  factory Advisor.fromMap(Map<String, dynamic> map) {
    return Advisor(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      firmName: map['firmName'] ?? '',
      email: map['email'] ?? '',
      aiCapability: map['aiCapability'] ?? 'pro',
      isExpressiveAiEnabled: map['isExpressiveAiEnabled'] ?? true,
      isMultimodalAiEnabled: map['isMultimodalAiEnabled'] ?? false,
      preferOnDeviceAi: map['preferOnDeviceAi'] ?? false,
      subscriptionPlan: map['subscriptionPlan'] ?? 'Starter',
      cardHolderName: map['cardHolderName'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      cvv: map['cvv'] ?? '',
      zipCode: map['zipCode'] ?? '',
      nextBillingDate: map['nextBillingDate'] != null 
          ? DateTime.tryParse(map['nextBillingDate']) 
          : null,
      firmPhoneNumber: map['firmPhoneNumber'] ?? '',
      firmEmailAddress: map['firmEmailAddress'] ?? '',
      twilioAccountSid: map['twilioAccountSid'] ?? '',
      twilioAuthToken: map['twilioAuthToken'] ?? '',
      sendgridApiKey: map['sendgridApiKey'] ?? '',
      sendgridVerifiedSender: map['sendgridVerifiedSender'] ?? '',
      stripeCustomerId: map['stripeCustomerId'],
      subscriptionId: map['subscriptionId'],
      subscriptionStatus: map['subscriptionStatus'] ?? 'none',
    );
  }

}
