import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';

class LocalCustomerRepository {
  static const String boxName = 'customers';

  Future<Box<Customer>> get _box async => await Hive.openBox<Customer>(boxName);

  Future<void> saveCustomer(String advisorUid, Customer customer) async {
    final box = await _box;
    await box.put(customer.customerId, customer);
  }

  Stream<List<Customer>> getCustomers(String advisorUid) async* {
    final box = await _box;
    yield box.values.toList();
    yield* box.watch().map((_) => box.values.toList());
  }

  Future<List<Customer>> getCustomersDue(String advisorUid) async {
    final box = await _box;
    final now = DateTime.now();
    return box.values.where((c) => c.nextEngagementDate.isBefore(now) || c.nextEngagementDate.isAtSameMomentAs(now)).toList();
  }

  Future<void> updateCustomer(String advisorUid, Customer customer) async {
    final box = await _box;
    await box.put(customer.customerId, customer);
  }

  Future<void> deleteCustomer(String advisorUid, String customerId) async {
    final box = await _box;
    await box.delete(customerId);
  }

  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
