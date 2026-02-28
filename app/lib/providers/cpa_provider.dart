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
import '../services/ai_service.dart';

class CpaProvider with ChangeNotifier {
  final CpaRepository _cpaRepo;
  final CustomerRepository _customerRepo;
  final EngagementRepository _engagementRepo;
  final auth.FirebaseAuth _firebaseAuth;
  AiService _aiService;

  Cpa? _currentCpa;
  Cpa? get currentCpa => _currentCpa;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  bool _isProcessingResponse = false;
  bool get isProcessingResponse => _isProcessingResponse;

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
  }

  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    if (rememberMe) {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        _currentCpa = await _cpaRepo.getCpa(user.uid);
        if (_currentCpa != null) {
          notifyListeners();
          _setupCustomerListener();
        }
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
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', rememberMe);
          notifyListeners();
          _setupCustomerListener();
        } else {
          // If user exists in Auth but not in Firestore, we should still notify
          // or throw so the UI knows to stop loading.
          notifyListeners();
          throw 'CPA profile not found. Please register.';
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  Future<void> loginDemo() async {
    _currentCpa = const Cpa(
      uid: 'demo_user',
      name: 'Demo User',
      firmName: 'Demo Accounting Firm',
      email: 'demo@example.com',
    );
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
    _currentCpa = null;
    _customers = [];
    notifyListeners();
  }

  Future<void> deleteAccount() async {
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
      await _cpaRepo.saveCpa(updatedCpa);
      _currentCpa = updatedCpa;
      notifyListeners();
    }
  }

  void _setupCustomerListener() {
    if (_currentCpa == null) return;
    _customerRepo.getCustomers(_currentCpa!.uid).listen((customers) {
      _customers = customers;
      notifyListeners();
      _discoverProactiveTasks();
    });
  }

  Future<void> _discoverProactiveTasks() async {
    if (_currentCpa == null || _isDiscovering) return;
    _isDiscovering = true;
    notifyListeners();
    try {
      final dueCustomers = await _customerRepo.getCustomersDue(_currentCpa!.uid);
      for (var customer in dueCustomers) {
        final hasDraft = await _engagementRepo.hasDraft(_currentCpa!.uid, customer.customerId);
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
          await _engagementRepo.saveEngagement(_currentCpa!.uid, customer.customerId, engagement);
          
          // Update customer hasActiveDraft flag
          final updatedCustomer = customer.copyWith(hasActiveDraft: true);
          await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
        } else if (!customer.hasActiveDraft) {
          // If it has a draft in repo but the customer object doesn't show it (stale or out of sync)
          final updatedCustomer = customer.copyWith(hasActiveDraft: true);
          await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
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
    await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);

    final nextDate = DateTime.now().add(Duration(days: customer.engagementFrequencyDays));
    final updatedCustomer = customer.copyWith(
      lastEngagementDate: DateTime.now(),
      nextEngagementDate: nextDate,
      hasActiveDraft: false,
    );
    await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
  }

  Future<void> receiveResponse(Customer customer, Engagement engagement, String response) async {
    if (_currentCpa == null || _isProcessingResponse) return;
    _isProcessingResponse = true;
    notifyListeners();
    try {
      // AI processing
      final poi = await _aiService.extractPointsOfInterest(response, customer.guidelines);
      final updatedDetails = await _aiService.updateCustomerDetails(customer.details, response);

      final updatedEngagement = engagement.copyWith(
        status: EngagementStatus.received,
        customerResponse: response,
        pointsOfInterest: poi,
        updatedDetailsDiff: updatedDetails, // Storing the full suggested new state here for review
      );
      await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
    } finally {
      _isProcessingResponse = false;
      notifyListeners();
    }
  }

  Future<void> approveResponse(Customer customer, Engagement engagement) async {
    if (_currentCpa == null) return;

    // Update the customer with the suggested details from the engagement
    final updatedCustomer = customer.copyWith(details: engagement.updatedDetailsDiff);
    await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);

    // Mark the engagement as completed
    final updatedEngagement = engagement.copyWith(status: EngagementStatus.completed);
    await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);
  }

  Stream<List<Engagement>> getCustomerEngagements(String customerId) {
    if (_currentCpa == null) return Stream.value([]);
    return _engagementRepo.getEngagements(_currentCpa!.uid, customerId);
  }

  Future<void> addCustomer(Customer customer) async {
    if (_currentCpa == null) return;
    await _customerRepo.saveCustomer(_currentCpa!.uid, customer);
  }
}
