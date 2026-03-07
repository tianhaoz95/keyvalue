import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advisor.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../repositories/advisor_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/engagement_repository.dart';
import '../repositories/local_advisor_repository.dart';
import '../repositories/local_customer_repository.dart';
import '../repositories/local_engagement_repository.dart';
import '../services/ai_service.dart';
import '../services/sms_service.dart';
import 'ui_context_provider.dart';

class AdvisorProvider with ChangeNotifier {
  final AdvisorRepository _advisorRepo;
  final CustomerRepository _customerRepo;
  final EngagementRepository _engagementRepo;
  
  final LocalAdvisorRepository _localAdvisorRepo = LocalAdvisorRepository();
  final LocalCustomerRepository _localCustomerRepo = LocalCustomerRepository();
  final LocalEngagementRepository _localEngagementRepo = LocalEngagementRepository();

  final auth.FirebaseAuth _firebaseAuth;
  AiService _aiService;
  AiService get aiService => _aiService;

  final SmsService _smsService;
  SmsService get smsService => _smsService;

  UiContextProvider? _uiContext;

  Advisor? _currentAdvisor;
  Advisor? get currentAdvisor => _currentAdvisor;

  String get aiCapability => _currentAdvisor?.aiCapability ?? 'pro';

  bool get isExpressiveAiEnabled => _currentAdvisor?.isExpressiveAiEnabled ?? true;

  bool get isMultimodalAiEnabled => _currentAdvisor?.isMultimodalAiEnabled ?? false;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  bool _isProcessingResponse = false;
  bool get isProcessingResponse => _isProcessingResponse;

  bool _isGeneratingDraft = false;
  bool get isGeneratingDraft => _isGeneratingDraft;

  bool get isGuestMode => _currentAdvisor?.uid == 'local_user';

  AdvisorProvider({
    AdvisorRepository? advisorRepo,
    CustomerRepository? customerRepo,
    EngagementRepository? engagementRepo,
    AiService? aiService,
    SmsService? smsService,
    auth.FirebaseAuth? firebaseAuth,
    UiContextProvider? uiContext,
  })  : _advisorRepo = advisorRepo ?? AdvisorRepository(),
        _customerRepo = customerRepo ?? CustomerRepository(),
        _engagementRepo = engagementRepo ?? EngagementRepository(),
        _aiService = aiService ?? AiService(),
        _smsService = smsService ?? FakeSmsService(),
        _firebaseAuth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _uiContext = uiContext {
    _checkRememberedUser();
    _loadLocale();
  }

  void updateUiContext(UiContextProvider uiContext) {
    _uiContext = uiContext;
    _updateAiService();
  }

  Future<void> setExpressiveAiEnabled(bool enabled) async {
    if (_currentAdvisor != null) {
      final updated = _currentAdvisor!.copyWith(isExpressiveAiEnabled: enabled);
      await updateProfile(updated);
    }
  }

  Future<void> setMultimodalAiEnabled(bool enabled) async {
    if (_currentAdvisor != null) {
      final updated = _currentAdvisor!.copyWith(isMultimodalAiEnabled: enabled);
      await updateProfile(updated);
    }
  }

  void _updateAiService() {
    String modelName;
    switch (aiCapability) {
      case 'fast':
        modelName = 'gemini-2.5-flash-lite';
        break;
      case 'lite-preview':
        modelName = 'gemini-3.1-flash-lite-preview';
        break;
      case 'preview':
        modelName = 'gemini-3-flash-preview';
        break;
      case 'pro':
      default:
        modelName = 'gemini-2.5-flash';
        break;
    }
    
    _aiService = AiService(
      modelName: modelName, 
      isDemo: isGuestMode,
      uiContext: _uiContext?.toAiContext(),
    );
  }

  Future<void> setAiCapability(String capability) async {
    if (_currentAdvisor != null) {
      final updated = _currentAdvisor!.copyWith(aiCapability: capability);
      await updateProfile(updated);
      _updateAiService();
    }
  }

  Future<void> setSubscriptionPlan(String plan) async {
    if (_currentAdvisor != null) {
      String firmPhone = _currentAdvisor!.firmPhoneNumber;
      
      // If upgrading to Pro/Enterprise and no number exists, generate one
      if ((plan == 'Pro' || plan == 'Enterprise') && firmPhone.isEmpty) {
        firmPhone = _generateRandomPhoneNumber();
      } 
      // If downgrading to Starter, remove the number
      else if (plan == 'Starter') {
        firmPhone = '';
      }

      final updated = _currentAdvisor!.copyWith(
        subscriptionPlan: plan,
        firmPhoneNumber: firmPhone,
      );
      await updateProfile(updated);
    }
  }

  String _generateRandomPhoneNumber() {
    final random = math.Random();
    final areaCode = 200 + random.nextInt(700);
    final prefix = 200 + random.nextInt(700);
    final line = 1000 + random.nextInt(8999);
    return '$areaCode-$prefix-$line';
  }

  Future<void> updateBillingInfo({
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String zipCode,
  }) async {
    if (_currentAdvisor != null) {
      final updated = _currentAdvisor!.copyWith(
        cardHolderName: cardHolderName,
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        zipCode: zipCode,
      );
      await updateProfile(updated);
    }
  }

  Future<void> setFirmPhoneNumber(String phoneNumber) async {
    if (_currentAdvisor != null) {
      final updated = _currentAdvisor!.copyWith(firmPhoneNumber: phoneNumber);
      await updateProfile(updated);
    }
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    notifyListeners();
  }

  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    final lastLoginMethod = prefs.getString('lastLoginMethod');

    if (rememberMe) {
      if (lastLoginMethod == 'guest') {
        _currentAdvisor = await _localAdvisorRepo.getAdvisor('local_user');
      } else {
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          _currentAdvisor = await _advisorRepo.getAdvisor(user.uid);
        }
      }

      if (_currentAdvisor != null) {
        _updateAiService();
        notifyListeners();
        _setupCustomerListener();
      }
    }
  }

  Future<void> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        _currentAdvisor = await _advisorRepo.getAdvisor(credential.user!.uid);
        if (_currentAdvisor != null) {
          _updateAiService();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', rememberMe);
          await prefs.setString('lastLoginMethod', 'firebase');
          notifyListeners();
          _setupCustomerListener();
        } else {
          notifyListeners();
          throw 'Advisor profile not found. Please register.';
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to send password reset email';
    }
  }

  Future<void> loginGuest({bool rememberMe = false}) async {
    final existing = await _localAdvisorRepo.getAdvisor('local_user');
    if (existing == null) {
      _currentAdvisor = const Advisor(
        uid: 'local_user',
        name: 'Guest Advisor',
        firmName: 'My Local Business',
        email: 'guest@local.app',
      );
      await _localAdvisorRepo.saveAdvisor(_currentAdvisor!);
    } else {
      _currentAdvisor = existing;
    }
    
    _updateAiService();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('lastLoginMethod', 'guest');
    
    notifyListeners();
    _setupCustomerListener();
  }

  Future<void> register(Advisor advisor, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: advisor.email,
        password: password,
      );
      if (credential.user != null) {
        final newAdvisor = advisor.copyWith(uid: credential.user!.uid);
        await _advisorRepo.saveAdvisor(newAdvisor);
        _currentAdvisor = newAdvisor;
        notifyListeners();
        _setupCustomerListener();
      }
    } on auth.FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await prefs.remove('lastLoginMethod');
    _currentAdvisor = null;
    _customers = [];
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (isGuestMode) {
      await _localAdvisorRepo.deleteAdvisor('local_user');
      await _localCustomerRepo.clearAll();
      await _localEngagementRepo.clearAll();
      await logout();
      return;
    }
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final uid = user.uid;
      await _advisorRepo.deleteAdvisor(uid);
      await user.delete();
      await logout();
    }
  }

  Future<void> updateProfile(Advisor updatedAdvisor) async {
    if (_currentAdvisor != null) {
      if (isGuestMode) {
        await _localAdvisorRepo.saveAdvisor(updatedAdvisor);
      } else {
        await _advisorRepo.saveAdvisor(updatedAdvisor);
      }
      _currentAdvisor = updatedAdvisor;
      notifyListeners();
    }
  }

  Future<void> submitFeedback(String text, String screenName) async {
    if (_currentAdvisor == null) return;
    
    final db = FirebaseFirestore.instance;
    await db.collection('feedbacks').add({
      'advisorUid': _currentAdvisor!.uid,
      'advisorName': _currentAdvisor!.name,
      'text': text,
      'screenName': screenName,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _setupCustomerListener() {
    if (_currentAdvisor == null) return;
    
    final stream = isGuestMode 
        ? _localCustomerRepo.getCustomers(_currentAdvisor!.uid)
        : _customerRepo.getCustomers(_currentAdvisor!.uid);

    stream.listen((customers) {
      _customers = customers;
      notifyListeners();
    });
  }

  Future<void> discoverProactiveTasks() async {
    if (_currentAdvisor == null || _isDiscovering) return;
    _isDiscovering = true;
    notifyListeners();
    try {
      if (_customers.isEmpty) {
        // Force a brief delay to show "Thinking"
        await Future.delayed(const Duration(seconds: 1));
        return;
      }

      var dueCustomers = isGuestMode 
          ? await _localCustomerRepo.getCustomersDue(_currentAdvisor!.uid)
          : await _customerRepo.getCustomersDue(_currentAdvisor!.uid);

      // If no one is strictly "due" by date, scan everyone who doesn't have a draft
      if (dueCustomers.isEmpty) {
        dueCustomers = _customers.where((c) => !c.hasActiveDraft).toList();
      }

      for (var customer in dueCustomers) {
        final hasDraft = isGuestMode
            ? await _localEngagementRepo.hasDraft(_currentAdvisor!.uid, customer.customerId)
            : await _engagementRepo.hasDraft(_currentAdvisor!.uid, customer.customerId);

        if (!hasDraft) {
          final draft = await _aiService.generateDraftMessage(customer);
          final engagement = Engagement(
            engagementId: const Uuid().v4(),
            status: EngagementStatus.draft,
            draftMessage: draft,
            sentMessage: '',
            customerResponse: '',
            pointsOfInterest: [],
            updatedDetailsDiff: '',
            createdAt: DateTime.now(),
          );
          
          if (isGuestMode) {
            await _localEngagementRepo.saveEngagement(_currentAdvisor!.uid, customer.customerId, engagement);
            final updatedCustomer = customer.copyWith(hasActiveDraft: true);
            await _localCustomerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
          } else {
            await _engagementRepo.saveEngagement(_currentAdvisor!.uid, customer.customerId, engagement);
            final updatedCustomer = customer.copyWith(hasActiveDraft: true);
            await _customerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
          }
          // Notify after each to show progress
          notifyListeners();
        } else if (!customer.hasActiveDraft) {
          final updatedCustomer = customer.copyWith(hasActiveDraft: true);
          if (isGuestMode) {
            await _localCustomerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
          } else {
            await _customerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error in proactive task discovery: $e');
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<void> sendEngagement(Customer customer, Engagement engagement, String message) async {
    if (_currentAdvisor == null) return;

    // Send the actual SMS via the service
    await _smsService.sendSms(to: customer.phoneNumber, message: message);

    final updatedEngagement = engagement.copyWith(
      status: EngagementStatus.sent,
      sentMessage: message,
    );
    
    if (isGuestMode) {
      await _localEngagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
    } else {
      await _engagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
    }

    final now = DateTime.now();
    final nextDate = customer.calculateNextEngagementDate(now);
    final updatedCustomer = customer.copyWith(
      lastEngagementDate: now,
      nextEngagementDate: nextDate,
      hasActiveDraft: false,
    );
    
    await addCustomer(updatedCustomer);
  }

  Future<void> receiveResponse(Customer customer, Engagement engagement, String response) async {
    if (_currentAdvisor == null || _isProcessingResponse) return;
    _isProcessingResponse = true;
    notifyListeners();
    try {
      final poi = await _aiService.extractPointsOfInterest(response, customer.guidelines);
      final updatedDetails = await _aiService.updateCustomerDetails(customer.details, response);

      final updatedEngagement = engagement.copyWith(
        status: EngagementStatus.received,
        customerResponse: response,
        pointsOfInterest: poi,
        updatedDetailsDiff: updatedDetails,
      );
      
      if (isGuestMode) {
        await _localEngagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
      } else {
        await _engagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
      }
    } finally {
      _isProcessingResponse = false;
      notifyListeners();
    }
  }

  Future<void> approveResponse(Customer customer, Engagement engagement) async {
    if (_currentAdvisor == null) return;

    final updatedCustomer = customer.copyWith(details: engagement.updatedDetailsDiff);
    
    final updatedEngagement = engagement.copyWith(status: EngagementStatus.completed);
    if (isGuestMode) {
      await _localEngagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
    } else {
      await _engagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
    }
    await addCustomer(updatedCustomer);
  }

  Future<void> approveProposedDetails(Customer customer) async {
    if (_currentAdvisor == null || customer.proposedDetails == null) return;
    final updated = customer.copyWith(
      details: customer.proposedDetails,
      proposedDetails: null,
    );
    await addCustomer(updated);
  }

  Future<void> approveProposedGuidelines(Customer customer) async {
    if (_currentAdvisor == null || customer.proposedGuidelines == null) return;
    final updated = customer.copyWith(
      guidelines: customer.proposedGuidelines,
      proposedGuidelines: null,
    );
    await addCustomer(updated);
  }

  Future<void> dismissProposedDetails(Customer customer) async {
    if (_currentAdvisor == null) return;
    final updated = customer.copyWith(proposedDetails: null);
    await addCustomer(updated);
  }

  Future<void> dismissProposedGuidelines(Customer customer) async {
    if (_currentAdvisor == null) return;
    final updated = customer.copyWith(proposedGuidelines: null);
    await addCustomer(updated);
  }

  Future<void> dismissResponse(Customer customer, Engagement engagement) async {
    if (_currentAdvisor == null) return;
    
    final updatedEngagement = engagement.copyWith(status: EngagementStatus.completed);
    
    if (isGuestMode) {
      await _localEngagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
    } else {
      await _engagementRepo.updateEngagement(_currentAdvisor!.uid, customer.customerId, updatedEngagement);
    }
    notifyListeners();
  }

  Future<void> deleteEngagement(Customer customer, Engagement engagement) async {
    if (_currentAdvisor == null) return;
    
    if (isGuestMode) {
      await _localEngagementRepo.deleteEngagement(_currentAdvisor!.uid, customer.customerId, engagement.engagementId);
    } else {
      await _engagementRepo.deleteEngagement(_currentAdvisor!.uid, customer.customerId, engagement.engagementId);
    }

    // If it was a draft, update customer flag
    if (engagement.status == EngagementStatus.draft) {
      final updatedCustomer = customer.copyWith(hasActiveDraft: false);
      if (isGuestMode) {
        await _localCustomerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
      } else {
        await _customerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
      }
    }
  }

  Stream<List<Engagement>> getCustomerEngagements(String customerId) {
    if (_currentAdvisor == null) return Stream.value([]);
    return isGuestMode 
        ? _localEngagementRepo.getEngagements(_currentAdvisor!.uid, customerId)
        : _engagementRepo.getEngagements(_currentAdvisor!.uid, customerId);
  }

  Future<String> getProfileRefinementResponse(Customer customer, List<AiChatMessage> history) async {
    return _aiService.generateProfileRefinementResponse(customer, history);
  }

  Future<String> finalizeProfileRefinement(Customer customer, List<AiChatMessage> history) async {
    return _aiService.finalizeProfileRefinement(customer, history);
  }

  Future<String> getGuidelinesRefinementResponse(Customer customer, List<AiChatMessage> history) async {
    return _aiService.generateGuidelinesRefinementResponse(customer, history);
  }

  Future<String> finalizeGuidelinesRefinement(Customer customer, List<AiChatMessage> history) async {
    return _aiService.finalizeGuidelinesRefinement(customer, history);
  }

  Future<String> getDraftRefinementResponse(Customer customer, String currentDraft, List<AiChatMessage> history) async {
    return _aiService.generateDraftRefinementResponse(customer, currentDraft, history);
  }

  Future<String> finalizeDraftRefinement(Customer customer, String currentDraft, List<AiChatMessage> history) async {
    return _aiService.finalizeDraftRefinement(customer, currentDraft, history);
  }

  Future<void> updateDraft(String customerId, String refinedDraft, {String? engagementId}) async {
    if (_currentAdvisor == null) return;
    
    // 1. Get engagements for this customer
    final stream = getCustomerEngagements(customerId);
    final engagements = await stream.first;
    
    // 2. Find the target draft
    int draftIndex;
    if (engagementId != null) {
      draftIndex = engagements.indexWhere((e) => e.engagementId == engagementId);
    } else {
      draftIndex = engagements.indexWhere((e) => e.status == EngagementStatus.draft);
    }

    if (draftIndex != -1) {
      final updatedDraft = engagements[draftIndex].copyWith(draftMessage: refinedDraft);
      if (isGuestMode) {
        await _localEngagementRepo.updateEngagement(_currentAdvisor!.uid, customerId, updatedDraft);
      } else {
        await _engagementRepo.updateEngagement(_currentAdvisor!.uid, customerId, updatedDraft);
      }
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    if (_currentAdvisor == null) return;
    
    // Optimistic local update
    final index = _customers.indexWhere((c) => c.customerId == customer.customerId);
    if (index != -1) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    notifyListeners();

    if (isGuestMode) {
      await _localCustomerRepo.saveCustomer(_currentAdvisor!.uid, customer);
    } else {
      await _customerRepo.saveCustomer(_currentAdvisor!.uid, customer);
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    if (_currentAdvisor == null) return;
    if (isGuestMode) {
      await _localCustomerRepo.deleteCustomer(_currentAdvisor!.uid, customerId);
      await _localEngagementRepo.clearCustomerEngagements(_currentAdvisor!.uid, customerId);
    } else {
      await _customerRepo.deleteCustomer(_currentAdvisor!.uid, customerId);
      await _engagementRepo.deleteCustomerEngagements(_currentAdvisor!.uid, customerId);
    }
  }

  Future<void> generateManualDraft(Customer customer) async {
    if (_currentAdvisor == null || _isGeneratingDraft) return;
    _isGeneratingDraft = true;
    notifyListeners();
    try {
      final draft = await _aiService.generateDraftMessage(customer);
      final engagement = Engagement(
        engagementId: const Uuid().v4(),
        status: EngagementStatus.draft,
        draftMessage: draft,
        sentMessage: '',
        customerResponse: '',
        pointsOfInterest: [],
        updatedDetailsDiff: '',
        createdAt: DateTime.now(),
      );
      
      if (isGuestMode) {
        await _localEngagementRepo.saveEngagement(_currentAdvisor!.uid, customer.customerId, engagement);
        final updatedCustomer = customer.copyWith(hasActiveDraft: true);
        await _localCustomerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
      } else {
        await _engagementRepo.saveEngagement(_currentAdvisor!.uid, customer.customerId, engagement);
        final updatedCustomer = customer.copyWith(hasActiveDraft: true);
        await _customerRepo.updateCustomer(_currentAdvisor!.uid, updatedCustomer);
      }
    } catch (e) {
      debugPrint('Error generating manual draft: $e');
    } finally {
      _isGeneratingDraft = false;
      notifyListeners();
    }
  }
}
