import 'package:flutter_test/flutter_test.dart';
import 'package:keyvalue_app/providers/advisor_provider.dart';
import 'package:keyvalue_app/models/advisor.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:keyvalue_app/repositories/advisor_repository.dart';
import 'package:keyvalue_app/repositories/customer_repository.dart';
import 'package:keyvalue_app/repositories/engagement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AdvisorProvider - Prefer On-Device AI', () {
    late AdvisorProvider provider;
    late AdvisorRepository advisorRepo;
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth();
      advisorRepo = AdvisorRepository(firestore: firestore);
      
      provider = AdvisorProvider(
        advisorRepo: advisorRepo,
        customerRepo: CustomerRepository(firestore: firestore),
        engagementRepo: EngagementRepository(firestore: firestore),
        firebaseAuth: auth,
      );

      // Setup mock auth user first to get the UID
      final credential = await auth.createUserWithEmailAndPassword(email: 'test@example.com', password: 'password');
      final uid = credential.user!.uid;

      // Create and login a mock advisor with the correct UID
      final advisor = Advisor(
        uid: uid,
        name: 'Test Advisor',
        firmName: 'Test Firm',
        email: 'test@example.com',
      );
      await advisorRepo.saveAdvisor(advisor);
      
      await provider.login('test@example.com', 'password');
    });

    test('Initial preferOnDeviceAi should be false', () {
      expect(provider.preferOnDeviceAi, isFalse);
    });

    test('setPreferOnDeviceAi should update the value and advisor profile', () async {
      final uid = auth.currentUser!.uid;
      await provider.setPreferOnDeviceAi(true);
      expect(provider.preferOnDeviceAi, isTrue);
      
      final updatedAdvisor = await advisorRepo.getAdvisor(uid);
      expect(updatedAdvisor?.preferOnDeviceAi, isTrue);
    });
  });
}
