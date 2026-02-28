import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
  AiService _aiService;

  Cpa? _currentCpa;
  Cpa? get currentCpa => _currentCpa;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  CpaProvider({
    CpaRepository? cpaRepo,
    CustomerRepository? customerRepo,
    EngagementRepository? engagementRepo,
    AiService? aiService,
  })  : _cpaRepo = cpaRepo ?? CpaRepository(),
        _customerRepo = customerRepo ?? CustomerRepository(),
        _engagementRepo = engagementRepo ?? EngagementRepository(),
        _aiService = aiService ?? AiService();

  Future<void> login(String uid) async {
    _currentCpa = await _cpaRepo.getCpa(uid);
    if (_currentCpa != null) {
      _setupCustomerListener();
    }
  }

  Future<void> register(Cpa cpa) async {
    if (cpa.uid != 'demo_user') {
      try {
        // Don't let Firestore hang the entire UI if it's slow/failing
        await _cpaRepo.saveCpa(cpa).timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Warning: saveCpa timed out, proceeding anyway');
        });
      } catch (e) {
        debugPrint('Error saving CPA: $e');
        // Still proceed to set _currentCpa so the user can see the UI
      }
    } else {
      // Create a demo-specific AI service
      _aiService = AiService(isDemo: true);
    }
    _currentCpa = cpa;
    notifyListeners();
    _setupCustomerListener();
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
    if (_currentCpa == null) return;
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
        }
      }
    } catch (e) {
      debugPrint('Error in proactive task discovery: $e');
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
    );
    await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
  }

  Future<void> receiveResponse(Customer customer, Engagement engagement, String response) async {
    if (_currentCpa == null) return;
    final poi = await _aiService.extractPointsOfInterest(response, customer.guidelines);
    final updatedDetails = await _aiService.updateCustomerDetails(customer.details, response);

    final updatedEngagement = engagement.copyWith(
      status: EngagementStatus.received,
      customerResponse: response,
      pointsOfInterest: poi,
    );
    await _engagementRepo.updateEngagement(_currentCpa!.uid, customer.customerId, updatedEngagement);

    final updatedCustomer = customer.copyWith(details: updatedDetails);
    await _customerRepo.updateCustomer(_currentCpa!.uid, updatedCustomer);
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
