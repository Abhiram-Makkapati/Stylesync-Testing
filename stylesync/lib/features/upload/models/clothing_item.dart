// focus: creating/uploading items
import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingItem {
  final String id;
  final String? name;
  final String category;
  final String type;
  final String color;
  final String imageUrl;
  final String? brand;
  final String? size;
  final String? notes;
  final DateTime createdAt;

  ClothingItem({
    required this.id,
    this.name,
    required this.category,
    required this.type,
    required this.color,
    required this.imageUrl,
    this.brand,
    this.size,
    this.notes,
    required this.createdAt,
  });

  // convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'type': type,
      'color': color,
      'imageUrl': imageUrl,
      'brand': brand,
      'size': size,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // create from Firestore document
  static ClothingItem fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClothingItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      color: data['color'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      brand: data['brand'],
      size: data['size'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}