import 'package:hive_flutter/hive_flutter.dart';
import '../models/engagement.dart';

class LocalEngagementRepository {
  static const String boxName = 'engagements';

  Future<Box<List>> get _box async => await Hive.openBox<List>(boxName);

  Future<void> saveEngagement(String cpaUid, String customerId, Engagement engagement) async {
    final box = await _box;
    final list = box.get(customerId)?.cast<Engagement>() ?? [];
    list.add(engagement);
    await box.put(customerId, list);
  }

  Stream<List<Engagement>> getEngagements(String cpaUid, String customerId) async* {
    final box = await _box;
    yield box.get(customerId)?.cast<Engagement>() ?? [];
    yield* box.watch(key: customerId).map((event) => (event.value as List).cast<Engagement>());
  }

  Future<bool> hasDraft(String cpaUid, String customerId) async {
    final box = await _box;
    final list = box.get(customerId)?.cast<Engagement>() ?? [];
    return list.any((e) => e.status == EngagementStatus.draft);
  }

  Future<void> updateEngagement(String cpaUid, String customerId, Engagement updatedEngagement) async {
    final box = await _box;
    final list = box.get(customerId)?.cast<Engagement>() ?? [];
    final index = list.indexWhere((e) => e.engagementId == updatedEngagement.engagementId);
    if (index != -1) {
      list[index] = updatedEngagement;
      await box.put(customerId, list);
    }
  }

  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
