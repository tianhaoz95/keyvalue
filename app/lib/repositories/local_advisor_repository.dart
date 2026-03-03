import 'package:hive_flutter/hive_flutter.dart';
import '../models/advisor.dart';

class LocalAdvisorRepository {
  static const String boxName = 'advisor_profile';

  Future<Box<Advisor>> get _box async => await Hive.openBox<Advisor>(boxName);

  Future<void> saveAdvisor(Advisor advisor) async {
    final box = await _box;
    await box.put('current', advisor);
  }

  Future<Advisor?> getAdvisor(String uid) async {
    final box = await _box;
    return box.get('current');
  }

  Future<void> deleteAdvisor(String uid) async {
    final box = await _box;
    await box.delete('current');
  }
}
