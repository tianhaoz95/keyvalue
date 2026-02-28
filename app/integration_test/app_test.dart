import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:keyvalue_app/providers/cpa_provider.dart';
import 'package:keyvalue_app/repositories/cpa_repository.dart';
import 'package:keyvalue_app/repositories/customer_repository.dart';
import 'package:keyvalue_app/repositories/engagement_repository.dart';
import 'package:keyvalue_app/services/ai_service.dart';
import 'package:keyvalue_app/models/cpa.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/engagement.dart';
import 'package:keyvalue_app/screens/login_screen.dart';

class MockCpaRepository extends Mock implements CpaRepository {}
class MockCustomerRepository extends Mock implements CustomerRepository {}
class MockEngagementRepository extends Mock implements EngagementRepository {}
class MockAiService extends Mock implements AiService {}

class CustomerFake extends Fake implements Customer {}
class EngagementFake extends Fake implements Engagement {}
class CpaFake extends Fake implements Cpa {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(CustomerFake());
    registerFallbackValue(EngagementFake());
    registerFallbackValue(CpaFake());
  });

  late MockCpaRepository mockCpaRepo;
  late MockCustomerRepository mockCustomerRepo;
  late MockEngagementRepository mockEngagementRepo;
  late MockAiService mockAiService;
  late StreamController<List<Customer>> customerStreamController;

  setUp(() {
    mockCpaRepo = MockCpaRepository();
    mockCustomerRepo = MockCustomerRepository();
    mockEngagementRepo = MockEngagementRepository();
    mockAiService = MockAiService();
    customerStreamController = StreamController<List<Customer>>.broadcast();

    final cpa = Cpa(uid: 'cpa123', name: 'John Doe', firmName: 'Doe CPAs', email: 'john@doe.com');
    final customer = Customer(
      customerId: 'cust123',
      name: 'Client A',
      email: 'client@a.com',
      details: 'A long description',
      guidelines: 'Engage monthly',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now().subtract(const Duration(days: 1)),
      lastEngagementDate: DateTime.now().subtract(const Duration(days: 31)),
    );

    when(() => mockCpaRepo.getCpa('cpa123')).thenAnswer((_) async => cpa);
    when(() => mockCustomerRepo.getCustomers('cpa123')).thenAnswer((_) => customerStreamController.stream);
    when(() => mockCustomerRepo.getCustomersDue('cpa123')).thenAnswer((_) async => [customer]);
    when(() => mockEngagementRepo.hasDraft('cpa123', 'cust123')).thenAnswer((_) async => false);
    when(() => mockAiService.generateDraftMessage(any())).thenAnswer((_) async => 'Hello from AI');
    when(() => mockEngagementRepo.saveEngagement(any(), any(), any())).thenAnswer((_) async => {});
    
    // For getCustomerEngagements
    when(() => mockEngagementRepo.getEngagements('cpa123', 'cust123')).thenAnswer((_) => Stream.value([]));
  });

  tearDown(() {
    customerStreamController.close();
  });

  testWidgets('Login and see dashboard', (WidgetTester tester) async {
    final cpaProvider = CpaProvider(
      cpaRepo: mockCpaRepo,
      customerRepo: mockCustomerRepo,
      engagementRepo: mockEngagementRepo,
      aiService: mockAiService,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CpaProvider>.value(value: cpaProvider),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    final customer = Customer(
      customerId: 'cust123',
      name: 'Client A',
      email: 'client@a.com',
      details: 'A long description',
      guidelines: 'Engage monthly',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now().subtract(const Duration(days: 1)),
      lastEngagementDate: DateTime.now().subtract(const Duration(days: 31)),
    );
    await tester.enterText(find.byType(TextField), 'cpa123');
    await tester.tap(find.byType(ElevatedButton));
    
    customerStreamController.add([customer]);

    await tester.pumpAndSettle();

    expect(find.text('Dashboard - John Doe'), findsOneWidget);
    expect(find.text('Client A'), findsOneWidget);
  });

  testWidgets('Add customer and see in list', (WidgetTester tester) async {
    final cpaProvider = CpaProvider(
      cpaRepo: mockCpaRepo,
      customerRepo: mockCustomerRepo,
      engagementRepo: mockEngagementRepo,
      aiService: mockAiService,
    );

    // Initial setup for the provider's login
    final cpa = Cpa(uid: 'cpa123', name: 'John Doe', firmName: 'Doe CPAs', email: 'john@doe.com');
    when(() => mockCpaRepo.getCpa('cpa123')).thenAnswer((_) async => cpa);
    customerStreamController.add([]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CpaProvider>.value(value: cpaProvider),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'cpa123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard - John Doe'), findsOneWidget);

    when(() => mockCustomerRepo.saveCustomer(any(), any())).thenAnswer((_) async => {});
    when(() => mockCustomerRepo.getCustomersDue('cpa123')).thenAnswer((_) async => []);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'New Client');
    
    await tester.tap(find.text('Add'));
    
    // Simulate updating the stream after save
    final newCustomer = Customer(
      customerId: 'new123',
      name: 'New Client',
      email: 'new@client.com',
      details: '',
      guidelines: '',
      engagementFrequencyDays: 30,
      nextEngagementDate: DateTime.now(),
      lastEngagementDate: DateTime.now(),
    );
    customerStreamController.add([newCustomer]);
    
    await tester.pumpAndSettle();

    expect(find.text('New Client'), findsAtLeast(1));
  });
}
