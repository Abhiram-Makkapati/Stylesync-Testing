import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestionLimiterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveSettings(String userId, Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(userId)
        .collection("settings")
        .doc("suggestionLimiter")
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadSettings(String userId) async {
    final doc = await _db
        .collection("users")
        .doc(userId)
        .collection("settings")
        .doc("suggestionLimiter")
        .get();

    return doc.data();
  }
}
