import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserData extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserData({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // in memory set for quick username uniqueness check
  final Set<String> _registeredUsernames = <String>{};

  // --- NEW METHOD ---
  // Call this when the app starts to get all existing usernames.
  Future<void> populateUsernames() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      for (final doc in snapshot.docs) {
        final username = doc.data()['username'] as String?;
        if (username != null) {
          _registeredUsernames.add(username.toLowerCase());
        }
      }
    } catch (e) {
      debugPrint("Failed to populate usernames: $e");
    }
  }

  Future<void> saveOutfit(DateTime date, List<String> itemIds) async {
    final user = _auth.currentUser;
    // --- MODIFIED: Throws an error instead of failing silently ---
    if (user == null) {
      throw Exception('User not logged in. Unable to save outfit.');
    }

    final outfitData = {
      'date': Timestamp.fromDate(date),
      'itemIds': itemIds,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('planned_outfits')
        .add(outfitData);
  }

  // username tracking helpers
  bool isUsernameTaken(String username) {
    return _registeredUsernames.contains(username.toLowerCase());
  }

  void addUsername(String username) {
    if (!_registeredUsernames.contains(username.toLowerCase())) {
      _registeredUsernames.add(username.toLowerCase());
      notifyListeners();
    }
  }

  // Renamed for clarity
  void _clearUsernames() {
    _registeredUsernames.clear();
  }

  // --- NEW METHOD ---
  // Call this on user logout.
  void clearAllData() {
    _clearUsernames();
    // Add any other state cleanup here
    notifyListeners();
  }

  // save pending profile to Firestore so backend/profile creation can be re-worn
  Future<void> savePendingProfile({
    required String uid,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    DateTime? createdAt,
  }) async {
    final docRef = _firestore.collection('pending_profiles').doc(uid);
    await docRef.set({
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
      'retryCount': 0,
    }, SetOptions(merge: true));
  }
}
