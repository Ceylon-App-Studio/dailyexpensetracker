import 'package:hive/hive.dart';
import '../models/subscription.dart';

class SubscriptionHiveService {
  static const String _boxName = 'subscription';
  static const String _key = 'current';

  static Box<Subscription> get _box =>
      Hive.box<Subscription>(_boxName);

  static Subscription? getSubscription() {
    return _box.get(_key);
  }

  static Future<void> saveSubscription(Subscription subscription) async {
    await _box.put(_key, subscription);
  }

  static Future<void> clearSubscription() async {
    await _box.delete(_key);
  }
}
