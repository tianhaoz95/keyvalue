import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore;

  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _customersRef(String advisorUid) {
    return _firestore.collection('advisors').doc(advisorUid).collection('customers');
  }

  Future<void> saveCustomer(String advisorUid, Customer customer) async {
    if (advisorUid == 'demo_user') return;
    await _customersRef(advisorUid).doc(customer.customerId).set(customer.toMap());
  }

  Stream<List<Customer>> getCustomers(String advisorUid) {
    if (advisorUid == 'demo_user') {
      return Stream.value([
        Customer(
          customerId: 'demo_1',
          name: 'TechCorp Solutions',
          email: 'finance@techcorp.com',
          details: '# TechCorp Overview\nGrowing SaaS company with 50 employees. Recently closed Series B.\n- **Tax Status**: Quarterly filer\n- **Key Interests**: R&D Tax Credits, expansion to EU.',
          guidelines: 'Focus on growth milestones and potential tax savings from R&D.',
          engagementFrequencyDays: 30,
          nextEngagementDate: DateTime.now(),
          lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Customer(
          customerId: 'demo_2',
          name: 'Sarah Jenkins (Freelance)',
          email: 'sarah.j@example.com',
          details: 'Individual consultant. High income, looking for retirement planning advice.',
          guidelines: 'Keep it personal and casual. Mention upcoming tax deadlines.',
          engagementFrequencyDays: 30,
          nextEngagementDate: DateTime.now().add(const Duration(days: 5)),
          lastEngagementDate: DateTime.now().subtract(const Duration(days: 25)),
        ),
      ]);
    }
    return _customersRef(advisorUid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<List<Customer>> getCustomersDue(String advisorUid) async {
    if (advisorUid == 'demo_user') {
      return [
        Customer(
          customerId: 'demo_1',
          name: 'TechCorp Solutions',
          email: 'finance@techcorp.com',
          details: '# TechCorp Overview\nGrowing SaaS company with 50 employees. Recently closed Series B.\n- **Tax Status**: Quarterly filer\n- **Key Interests**: R&D Tax Credits, expansion to EU.',
          guidelines: 'Focus on growth milestones and potential tax savings from R&D.',
          engagementFrequencyDays: 30,
          nextEngagementDate: DateTime.now(),
          lastEngagementDate: DateTime.now().subtract(const Duration(days: 30)),
        )
      ];
    }
    final now = DateTime.now();
    final snapshot = await _customersRef(advisorUid)
        .where('nextEngagementDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();
    return snapshot.docs.map((doc) => Customer.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> updateCustomer(String advisorUid, Customer customer) async {
    if (advisorUid == 'demo_user') return;
    await _customersRef(advisorUid).doc(customer.customerId).set(customer.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCustomer(String advisorUid, String customerId) async {
    if (advisorUid == 'demo_user') return;
    await _customersRef(advisorUid).doc(customerId).delete();
  }

  Future<List<String>> getAllCustomerIds(String advisorUid) async {
    if (advisorUid == 'demo_user') return [];
    final snapshot = await _customersRef(advisorUid).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
