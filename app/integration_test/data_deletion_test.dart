import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/repositories/advisor_repository.dart';
import 'package:keyvalue_app/repositories/customer_repository.dart';
import 'package:keyvalue_app/repositories/engagement_repository.dart';
import 'package:keyvalue_app/models/customer.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'package:keyvalue_app/models/engagement.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Data Deletion Integration Test', () {
    late MockFirebaseAuth auth;
    late FakeFirebaseFirestore firestore;
    late AdvisorProvider advisorProvider;
    late AdvisorRepository advisorRepo;
    late CustomerRepository customerRepo;
    late EngagementRepository engagementRepo;

    setUpAll(() async {
      // Initialize Hive once for all tests in this group
      final tempDir = await getTemporaryDirectory();
      final hivePath = '${tempDir.path}/hive_test_deletion';
      final dir = Directory(hivePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
      
      Hive.init(hivePath);
      
      // Register adapters if they haven't been registered yet
      try {
        Hive.registerAdapter(AdvisorAdapter());
        Hive.registerAdapter(CustomerAdapter());
        Hive.registerAdapter(EngagementStatusAdapter());
        Hive.registerAdapter(EngagementAdapter());
        Hive.registerAdapter(EngagementScheduleAdapter());
      } catch (e) {
        // Adapters already registered
      }
    });

    setUp(() {
      auth = MockFirebaseAuth();
      firestore = FakeFirebaseFirestore();
      
      advisorRepo = AdvisorRepository(firestore: firestore);
      customerRepo = CustomerRepository(firestore: firestore);
      engagementRepo = EngagementRepository(firestore: firestore);

      advisorProvider = AdvisorProvider(
        advisorRepo: advisorRepo,
        customerRepo: customerRepo,
        engagementRepo: engagementRepo,
        firebaseAuth: auth,
      );
    });

    testWidgets('deleteAccount performs cascading delete of all Firestore data', (WidgetTester tester) async {
      // 1. Setup: Register and login an advisor
      final advisor = Advisor(
        uid: 'advisor_123',
        name: 'Test Advisor',
        email: 'test@example.com',
        firmName: 'Test Firm',
      );
      await advisorProvider.register(advisor, 'password123');
      await advisorProvider.login('test@example.com', 'password123');
      
      final uid = auth.currentUser!.uid;

      // 2. Setup: Add a customer and an engagement
      final customer = Customer(
        customerId: 'cust_1',
        name: 'John Doe',
        email: 'john@example.com',
        details: 'Test details',
        guidelines: 'Test guidelines',
        engagementFrequencyDays: 30,
        nextEngagementDate: DateTime.now(),
        lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      await advisorProvider.addCustomer(customer);

      final engagement = Engagement(
        engagementId: 'eng_1',
        status: EngagementStatus.draft,
        draftMessage: 'Hello John',
        sentMessage: '',
        customerResponse: '',
        pointsOfInterest: [],
        updatedDetailsDiff: '',
        createdAt: DateTime.now(),
      );
      
      // Manual save to ensure it's in Firestore correctly for testing
      await engagementRepo.saveEngagement(uid, customer.customerId, engagement);

      // 3. Verify data exists before deletion
      final advisorDoc = await firestore.collection('advisors').doc(uid).get();
      expect(advisorDoc.exists, isTrue);

      final customerDoc = await firestore.collection('advisors').doc(uid).collection('customers').doc(customer.customerId).get();
      expect(customerDoc.exists, isTrue);

      final engagementDoc = await firestore.collection('advisors').doc(uid)
          .collection('customers').doc(customer.customerId)
          .collection('engagements').doc(engagement.engagementId).get();
      expect(engagementDoc.exists, isTrue);

      // 4. Perform Account Deletion
      await advisorProvider.deleteAccount();

      // 5. Verify ALL data is gone
      
      // Check Auth User
      expect(auth.currentUser, isNull);

      // Check Advisor Doc
      final advisorDocAfter = await firestore.collection('advisors').doc(uid).get();
      expect(advisorDocAfter.exists, isFalse);

      // Check Customer Doc
      final customerDocAfter = await firestore.collection('advisors').doc(uid).collection('customers').doc(customer.customerId).get();
      expect(customerDocAfter.exists, isFalse);

      // Check Engagement Doc
      final engagementDocAfter = await firestore.collection('advisors').doc(uid)
          .collection('customers').doc(customer.customerId)
          .collection('engagements').doc(engagement.engagementId).get();
      expect(engagementDocAfter.exists, isFalse);
      
      // Verify sub-collections are empty
      final customersSnapshot = await firestore.collection('advisors').doc(uid).collection('customers').get();
      expect(customersSnapshot.docs, isEmpty);
    });

    testWidgets('deleteAccount clears local storage repositories', (WidgetTester tester) async {
      await advisorProvider.deleteAccount();
      expect(advisorProvider.currentAdvisor, isNull);
    });
  });
}
