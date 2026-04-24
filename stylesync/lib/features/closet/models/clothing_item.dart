import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingItem {
  final String id; // Document ID from Firestore
  final String? name; // Optional name for the item

  // Core Filterable Attributes
  final String category; // e.g., 'Tops', 'Bottoms', 'Shoes'
  final String itemType; // e.g., 'Shirts', 'Jeans', 'Sneakers' - more general classification
  final String style; // e.g., 'T-shirt', 'Straight', 'Slip-ons' - more specific style within the itemType
  final List<String>? specificStyles; // Optional modifiers/details: e.g., ['Graphic/Printed', 'Cropped'], ['Wide-leg', 'Barrel']
  final List<String> colors; // All colors for the item: e.g., ['Black', 'Red', 'Multi', 'Emerald Green']
  final List<String> occasions; // e.g., ['Casual', 'Work', 'Night Out'] - an item can fit multiple

  // Other Item Details
  final String imageUrl;
  final String? brand;
  final String? size;
  final String? notes;
  final DateTime createdAt;
  final List<String>? tags; // For truly free-form, non-categorized tags if needed

  ClothingItem({
    required this.id,
    this.name,
    required this.category,
    required this.itemType,
    required this.style,
    this.specificStyles, // Make nullable
    required this.colors,
    required this.occasions,
    required this.imageUrl,
    this.brand,
    this.size,
    this.notes,
    required this.createdAt,
    this.tags,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      // 'id': id, // Typically, the document ID is not stored as a field within the document
      'name': name,
      'category': category,
      'itemType': itemType,
      'style': style,
      'specificStyles': specificStyles, // Will be null if not provided
      'colors': colors,
      'occasions': occasions,
      'imageUrl': imageUrl,
      'brand': brand,
      'size': size,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags ?? [], // Ensure tags is an empty list if null
    };
  }

  // Create from Firestore document
  factory ClothingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Handle null data if document doesn't exist
    if (data == null) {
      throw StateError('Missing data for ClothingItem document with ID: ${doc.id}');
    }

    return ClothingItem(
      id: doc.id,
      name: data['name'] as String?,
      category: data['category'] as String? ?? '', // Default to empty string if null
      itemType: data['itemType'] as String? ?? '',
      style: data['style'] as String? ?? '',
      // Map dynamic list to List<String>, handle null
      specificStyles: (data['specificStyles'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      colors: (data['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[], // Default to empty list
      occasions: (data['occasions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[], // Default to empty list
      imageUrl: data['imageUrl'] as String? ?? '',
      brand: data['brand'] as String?,
      size: data['size'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(), // Can be null
    );
  }

  // Backwards-compatible constructor name used elsewhere in the codebase
  factory ClothingItem.fromSnapshot(DocumentSnapshot doc) => ClothingItem.fromFirestore(doc);
}
