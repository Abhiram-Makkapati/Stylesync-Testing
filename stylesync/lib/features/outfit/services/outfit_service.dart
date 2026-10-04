import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  OutfitService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> saveOutfit({
    required String topId,
    required String bottomId,
    required String shoeId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('outfits').add({
      'userId': user.uid,
      'topId': topId,
      'bottomId': bottomId,
      'shoeId': shoeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserOutfits() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore
        .collection('outfits')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
}
