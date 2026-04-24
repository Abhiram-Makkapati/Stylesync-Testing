import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/clothing_item.dart';

class ClosetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get user's clothin items
  Stream<List<ClothingItem>> getUserClothingItems() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing_items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClothingItem.fromFirestore(doc))
              .toList(),
        );
  }

  // adding clothing item
  Future<void> addClothingItem(ClothingItem item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing_items')
        .add(item.toFirestore());
  }

  // update clothing item
  Future<void> updateClothingItem(String itemId, ClothingItem item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing_items')
        .doc(itemId)
        .update(item.toFirestore());
  }

  // delete clothing item
  Future<void> deleteClothingItem(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing_items')
        .doc(itemId)
        .delete();
  }

  // update only tags for an item
Future<void> updateItemTags(String itemId, List<String> tags) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) throw Exception('User not authenticated');

  await _firestore
      .collection('users')
      .doc(userId)
      .collection('clothing_items')
      .doc(itemId)
      .update({'tags': tags});
}

  // get items by category
  Stream<List<ClothingItem>> getItemsByCategory(String category) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

        return _firestore
            .collection('users')
            .doc(userId)
            .collection('clothing_items')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
          final lower = category.trim().toLowerCase();
          return snapshot.docs
              .map((doc) => ClothingItem.fromFirestore(doc))
              .where((item) {
                final itemCat = item.category.trim().toLowerCase();
                if (itemCat.isEmpty) return false;
                // Exact match
                if (itemCat == lower) return true;
                // singular/plural tolerant: shoe <-> shoes
                if (itemCat.endsWith('s') && itemCat.substring(0, itemCat.length - 1) == lower) return true;
                if (lower.endsWith('s') && lower.substring(0, lower.length - 1) == itemCat) return true;
                // contains match to handle variants like 'men shoes' or 'running shoes'
                if (itemCat.contains(lower) || lower.contains(itemCat)) return true;
                return false;
              })
              .toList();
        });
  }

  // One-time query: returns matching items as a Future
  Future<List<ClothingItem>> queryItemsByCategoryAndOccasion({
    required String category,
    required String occasion,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Note: Firestore may require a composite index for queries with multiple where/order clauses.
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing_items')
        .where('category', isEqualTo: category)
        .where('occasions', arrayContains: occasion)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((d) => ClothingItem.fromFirestore(d)).toList();
  }

  // Live query: returns a Stream that updates when matching documents change
  Stream<List<ClothingItem>> watchItemsByCategoryAndOccasion({
    required String category,
    required String occasion,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing_items')
        .where('category', isEqualTo: category)
        .where('occasions', arrayContains: occasion)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ClothingItem.fromFirestore(d)).toList());
  }
}

