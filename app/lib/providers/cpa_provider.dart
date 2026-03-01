import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cpa.dart';
import '../models/customer.dart';
import '../models/engagement.dart';
import '../repositories/cpa_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/engagement_repository.dart';
import '../repositories/local_cpa_repository.dart';
import '../repositories/local_customer_repository.dart';
import '../repositories/local_engagement_repository.dart';
import '../services/ai_service.dart';

class CpaProvider with ChangeNotifier {
  final CpaRepository _cpaRepo;
  final CustomerRepository _customerRepo;
  final EngagementRepository _engagementRepo;
  
  final LocalCpaRepository _localCpaRepo = LocalCpaRepository();
  final LocalCustomerRepository _localCustomerRepo = LocalCustomerRepository();
  final LocalEngagementRepository _localEngagementRepo = LocalEngagementRepository();

  final auth.FirebaseAuth _firebaseAuth;
  AiService _aiService;

  Cpa? _currentCpa;
  Cpa? get currentCpa => _currentCpa;

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

  bool get isGuestMode => _currentCpa?.uid == 'local_user';

  CpaProvider({
    CpaRepository? cpaRepo,
    CustomerRepository? customerRepo,
    EngagementRepository? engagementRepo,
    AiService? aiService,
    auth.FirebaseAuth? firebaseAuth,
  })  : _cpaRepo = cpaRepo ?? CpaRepository(),
        _customerRepo = customerRepo ?? CustomerRepository(),
        _engagementRepo = engagementRepo ?? EngagementRepository(),
        _aiService = aiService ?? AiService(),
        _firebaseAuth = firebaseAuth ?? auth.FirebaseAuth.instance {
    _checkRememberedUser();
    _loadLocale();
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
        _currentCpa = await _localCpaRepo.getCpa('local_user');
        _aiService = AiService(isDemo: true);
      } else {
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          _currentCpa = await _cpaRepo.getCpa(user.uid);
          _aiService = AiService(isDemo: false);
        }
      }

      if (_currentCpa != null) {
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
        _currentCpa = await _cpaRepo.getCpa(credential.user!.uid);
        if (_currentCpa != null) {
          _aiService = AiService(isDemo: false);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', rememberMe);
          await prefs.setString('lastLoginMethod', 'firebase');
          notifyListeners();
          _setupCustomerListener();
        } else {
          notifyListeners();
          throw 'CPA profile not found. Please register.';
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  Future<void> loginGuest({bool rememberMe = false}) async {
    final existing = await _localCpaRepo.getCpa('local_user');
    if (existing == null) {
      _currentCpa = const Cpa(
        uid: 'local_user',
        name: 'Guest CPA',
        firmName: 'My Local Firm',
        email: 'guest@local.app',
      );
      await _localCpaRepo.saveCpa(_currentCpa!);
    } else {
      _currentCpa = existing;
    }
    
    _aiService = AiService(isDemo: true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('lastLoginMethod', 'guest');
    
    notifyListeners();
    _setupCustomerListener();
  }

  Future<void> register(Cpa cpa, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cpa.email,
        password: password,
      );
      if (credential.user != null) {
        final newCpa = cpa.copyWith(uid: credential.user!.uid);
        await _cpaRepo.saveCpa(newCpa);
        _currentCpa = newCpa;
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
    _currentCpa = null;
    _customers = [];
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (isGuestMode) {
      await _localCpaRepo.deleteCpa('local_user');
      await _localCustomerRepo.clearAll();
      await _localEngagementRepo.clearAll();
      await logout();
      return;
    }
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final uid = user.uid;
      await _cpaRepo.deleteCpa(uid);
      await user.delete();
      await logout();
    }
  }

  Future<void> updateProfile(Cpa updatedCpa) async {
    if (_currentCpa != null) {
      if (isGuestMode) {
        await _localCpaRepo.saveCpa(updatedCpa);
      } else {
        await _cpaRepo.saveCpa(updatedCpa);
      }
      _currentCpa = updatedCpa;
      notifyListeners();
    }
  }

  void _setupCustomerListener() {
    if (_currentCpa == null) return;
    
    final stream = isGuestMode 
        ? _localCustomerRepo.getCustomers(_currentCpa!.uid)
        : _customerRepo.getCustomers(_currentCpa!.uid);

    stream.listen((customers) {
      _customers = customers;
      notifyListeners();
    });
  }

  Future<void> discoverProactiveTasks() async {
    if (_currentCpa == null || _isDiscovering) return;
    _isDiscovering = true;
    notifyListeners();
    try {
      if (_customers.isEmpty) {
        // Force a brief delay to show "Thinking"
        await Future.delayed(const Duration(seconds: 1));
        return;
      }

      var dueCustomers = isGuestMode 
          ? await _localCustomerRepo.getCustomersDue(_currentCpa!.uid)
          : await _customerRepo.getCustomersDue(_currentCpa!.uid);

      // If no one is strictly "due" by date, scan everyone who doesn't have a draft
      if (dueCustomers.isEmpty) {
        dueCustomers = _customers.where((c) => !c.hasActiveDraft).toList();
      }

      for (var customer in dueCustomers) {
        final hasDraft = isGuestMode
            ? await _localEngagementRepo.hasDraft(_currentCpa!.uid, customer.customerId)
            : await _engagementRepo.hasDraft(_currentCpa!.uid, customer.customerId);

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
            await _localEngagementRepo.saveEngagement(_currentCpa!.uid, customer.customerId, engagement);
            final updatedCustomer = customer.copyWith(hasActiveDraft: true);
            await _localCustomerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
          } else {
            await _engagementRepo.saveEngagement(_currentCpa!.uid, customer.customerId, engagement);
            final updatedCustomer = customer.copyWith(hasActiveDraft: true);
            await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
          }
          // Notify after each to show progress
          notifyListeners();
        } else if (!customer.hasActiveDraft) {
          final updatedCustomer = customer.copyWith(hasActiveDraft: true);
          if (isGuestMode) {
            await _localCustomerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
          } else {
            await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
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
    if (_currentCpa == null) return;
    final updatedEngagement = engagement.copyWith(
      status: EngagementStatus.sent,
      sentMessage: message,
    );
    
    if (isGuestMode) {
      await _localEngagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    } else {
      await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    }

    final nextDate = DateTime.now().add(Duration(days: customer.engagementFrequencyDays));
    final updatedCustomer = customer.copyWith(
      lastEngagementDate: DateTime.now(),
      nextEngagementDate: nextDate,
      hasActiveDraft: false,
    );
    
    if (isGuestMode) {
      await _localCustomerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
    } else {
      await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
    }
  }

  Future<void> receiveResponse(Customer customer, Engagement engagement, String response) async {
    if (_currentCpa == null || _isProcessingResponse) return;
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
        await _localEngagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
      } else {
        await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
      }
    } finally {
      _isProcessingResponse = false;
      notifyListeners();
    }
  }

  Future<void> approveResponse(Customer customer, Engagement engagement) async {
    if (_currentCpa == null) return;

    final updatedCustomer = customer.copyWith(details: engagement.updatedDetailsDiff);
    
    if (isGuestMode) {
      await _localCustomerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
      final updatedEngagement = engagement.copyWith(status: EngagementStatus.completed);
      await _localEngagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    } else {
      await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
      final updatedEngagement = engagement.copyWith(status: EngagementStatus.completed);
      await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    }
  }

  Future<void> dismissResponse(Customer customer, Engagement engagement) async {
    if (_currentCpa == null) return;
    
    final updatedEngagement = engagement.copyWith(status: EngagementStatus.completed);
    
    if (isGuestMode) {
      await _localEngagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    } else {
      await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    }
  }

  Stream<List<Engagement>> getCustomerEngagements(String customerId) {
    if (_currentCpa == null) return Stream.value([]);
    return isGuestMode 
        ? _localEngagementRepo.getEngagements(_currentCpa!.uid, customerId)
        : _engagementRepo.getEngagements(_currentCpa!.uid, customerId);
  }

  Future<String> getOnboardingResponse(List<ChatMessage> history) async {
    return _aiService.generateOnboardingResponse(history);
  }

  Future<Customer?> extractCustomerFromOnboarding(List<ChatMessage> history) async {
    return _aiService.processOnboardingConversation(history);
  }

  Future<String> getProfileRefinementResponse(Customer customer, List<ChatMessage> history) async {
    return _aiService.generateProfileRefinementResponse(customer, history);
  }

  Future<String> finalizeProfileRefinement(Customer customer, List<ChatMessage> history) async {
    return _aiService.finalizeProfileRefinement(customer, history);
  }

  Future<String> getGuidelinesRefinementResponse(Customer customer, List<ChatMessage> history) async {
    return _aiService.generateGuidelinesRefinementResponse(customer, history);
  }

  Future<String> finalizeGuidelinesRefinement(Customer customer, List<ChatMessage> history) async {
    return _aiService.finalizeGuidelinesRefinement(customer, history);
  }

  Future<void> addCustomer(Customer customer) async {
    if (_currentCpa == null) return;
    if (isGuestMode) {
      await _localCustomerRepo.saveCustomer(_currentCpa!.uid, customer);
    } else {
      await _customerRepo.saveCustomer(_currentCpa!.uid, customer);
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    if (_currentCpa == null) return;
    if (isGuestMode) {
      await _localCustomerRepo.deleteCustomer(_currentCpa!.uid, customerId);
      await _localEngagementRepo.clearCustomerEngagements(_currentCpa!.uid, customerId);
    } else {
      await _customerRepo.deleteCustomer(_currentCpa!.uid, customerId);
      await _engagementRepo.deleteCustomerEngagements(_currentCpa!.uid, customerId);
    }
  }

  Future<void> generateManualDraft(Customer customer) async {
    if (_currentCpa == null || _isGeneratingDraft || customer.hasActiveDraft) return;
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
        await _localEngagementRepo.saveEngagement(_currentCpa!.uid, customer.customerId, engagement);
        final updatedCustomer = customer.copyWith(hasActiveDraft: true);
        await _localCustomerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
      } else {
        await _engagementRepo.saveEngagement(_currentCpa!.uid, customer.customerId, engagement);
        final updatedCustomer = customer.copyWith(hasActiveDraft: true);
        await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
      }
    } catch (e) {
      debugPrint('Error generating manual draft: $e');
    } finally {
      _isGeneratingDraft = false;
      notifyListeners();
    }
  }
}
