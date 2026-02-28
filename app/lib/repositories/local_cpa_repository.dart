import 'package:hive_flutter/hive_flutter.dart';
import '../models/cpa.dart';

class LocalCpaRepository {
  static const String boxName = 'cpa_profile';

  Future<Box<Cpa>> get _box async => await Hive.openBox<Cpa>(boxName);

  Future<void> saveCpa(Cpa cpa) async {
    final box = await _box;
    await box.put('current', cpa);
  }

  Future<Cpa?> getCpa(String uid) async {
    final box = await _box;
    return box.get('current');
  }

  Future<void> deleteCpa(String uid) async {
    final box = await _box;
    await box.delete('current');
  }
}
