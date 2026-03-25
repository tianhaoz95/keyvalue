import 'package:flutter/material.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/engagement.dart';
import 'package:keyvalue_app/services/ai_service.dart';
import 'package:keyvalue_app/services/sms_service.dart';

class DummyAiService extends AiService {
  DummyAiService() : super(isDemo: true);
}

class DummySmsService extends SmsService {
  @override
  Future<void> sendSms({required String to, required String message}) async {}
}

class MockAdvisorProvider extends ChangeNotifier implements AdvisorProvider {
  Advisor? _currentAdvisor;
  List<Customer> _customers = [];
  bool _isProcessingResponse = false;
  bool _isGeneratingDraft = false;
  Locale _locale = const Locale('en');

  MockAdvisorProvider({
    Advisor? currentAdvisor,
    List<Customer> customers = const [],
  }) : _currentAdvisor = currentAdvisor,
       _customers = customers;

  @override
  Advisor? get currentAdvisor => _currentAdvisor;

  @override
  List<Customer> get customers => _customers;

  @override
  bool get isProcessingResponse => _isProcessingResponse;

  @override
  bool get isGeneratingDraft => _isGeneratingDraft;

  @override
  Locale get locale => _locale;

  @override
  String get aiCapability => _currentAdvisor?.aiCapability ?? 'pro';

  @override
  bool get isExpressiveAiEnabled => _currentAdvisor?.isExpressiveAiEnabled ?? true;

  @override
  bool get isMultimodalAiEnabled => _currentAdvisor?.isMultimodalAiEnabled ?? false;

  @override
  bool get preferOnDeviceAi => _currentAdvisor?.preferOnDeviceAi ?? false;

  @override
  bool get isDemoMode => _currentAdvisor?.uid == 'local_user';

  @override
  bool get isDiscovering => false;

  @override
  AiService get aiService => DummyAiService();

  @override
  SmsService get smsService => DummySmsService();

  @override
  Future<void> login(String email, String password, {bool rememberMe = false}) async {}

  @override
  Future<void> loginDemo({bool rememberMe = false}) async {}

  @override
  Future<void> logout() async {
    _currentAdvisor = null;
    notifyListeners();
  }

  @override
  Future<void> register(Advisor advisor, String password) async {}

  @override
  Future<void> updateProfile(Advisor updatedAdvisor) async {
    _currentAdvisor = updatedAdvisor;
    notifyListeners();
  }

  @override
  Future<void> setAiCapability(String capability) async {
    if (_currentAdvisor != null) {
      _currentAdvisor = _currentAdvisor!.copyWith(aiCapability: capability);
      notifyListeners();
    }
  }

  @override
  Future<void> setExpressiveAiEnabled(bool enabled) async {
    if (_currentAdvisor != null) {
      _currentAdvisor = _currentAdvisor!.copyWith(isExpressiveAiEnabled: enabled);
      notifyListeners();
    }
  }

  @override
  Future<void> setMultimodalAiEnabled(bool enabled) async {
    if (_currentAdvisor != null) {
      _currentAdvisor = _currentAdvisor!.copyWith(isMultimodalAiEnabled: enabled);
      notifyListeners();
    }
  }

  @override
  Future<void> setPreferOnDeviceAi(bool enabled) async {
    if (_currentAdvisor != null) {
      _currentAdvisor = _currentAdvisor!.copyWith(preferOnDeviceAi: enabled);
      notifyListeners();
    }
  }

  @override
  Future<void> setSubscriptionPlan(String plan) async {
    if (_currentAdvisor != null) {
      _currentAdvisor = _currentAdvisor!.copyWith(subscriptionPlan: plan);
      notifyListeners();
    }
  }

  @override
  Future<void> updateBillingInfo({
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String zipCode,
  }) async {
    if (_currentAdvisor != null) {
      _currentAdvisor = _currentAdvisor!.copyWith(
        cardHolderName: cardHolderName,
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        zipCode: zipCode,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    final index = _customers.indexWhere((c) => c.customerId == customer.customerId);
    if (index != -1) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    notifyListeners();
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    _customers.removeWhere((c) => c.customerId == customerId);
    notifyListeners();
  }

  @override
  Stream<List<Engagement>> getCustomerEngagements(String customerId) {
    return Stream.value([]);
  }

  @override
  Future<void> sendEngagement(Customer customer, Engagement engagement, String message) async {}

  @override
  Future<void> receiveResponse(Customer customer, Engagement engagement, String response) async {}

  @override
  Future<void> approveResponse(Customer customer, Engagement engagement) async {}

  @override
  Future<void> dismissResponse(Customer customer, Engagement engagement) async {}

  @override
  Future<void> deleteEngagement(Customer customer, Engagement engagement) async {}

  @override
  Future<void> discoverProactiveTasks() async {}

  @override
  Future<void> generateManualDraft(Customer customer) async {}

  @override
  Future<void> setFirmPhoneNumber(String phoneNumber) async {}

  @override
  Future<void> submitFeedback(String text, String screenName) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> prepareOnDeviceModel() async {}

  @override
  Future<String> checkOnDeviceStatus() async => 'Ready';

  @override
  void updateUiContext(dynamic uiContext) {}

  @override
  Future<void> approveProposedDetails(Customer customer) async {}

  @override
  Future<void> approveProposedGuidelines(Customer customer) async {}

  @override
  Future<void> dismissProposedDetails(Customer customer) async {}

  @override
  Future<void> dismissProposedGuidelines(Customer customer) async {}

  @override
  Future<String> getProfileRefinementResponse(Customer customer, List<dynamic> history) async => '';

  @override
  Future<String> finalizeProfileRefinement(Customer customer, List<dynamic> history) async => '';

  @override
  Future<String> getGuidelinesRefinementResponse(Customer customer, List<dynamic> history) async => '';

  @override
  Future<String> finalizeGuidelinesRefinement(Customer customer, List<dynamic> history) async => '';

  @override
  Future<String> getDraftRefinementResponse(Customer customer, String currentDraft, List<dynamic> history) async => '';

  @override
  Future<String> finalizeDraftRefinement(Customer customer, String currentDraft, List<dynamic> history) async => '';

  @override
  Future<void> updateDraft(String customerId, String refinedDraft, {String? engagementId}) async {}
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}
