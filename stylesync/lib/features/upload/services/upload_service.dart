// returns a download URL to save to Firestore
import 'dart:io';
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../closet/models/clothing_item.dart';
import 'background_removal_service.dart';

/*
  When implementing GraphQL, this file will be responsible for:
    - removing background from iamge using _bgRemovalClient
    - uploading the processed image to firebase storage
    - obtaining the downloadUrl from firebase storage
    - deleting images from firebase storage when an item is removed

  What changes:
    - parts of our service that interact directly with fire store (addClothingItemWithImage & deleteClothingItem's firestore calls)
      will be replaced by calls to GraphQL API through the generated Data Connect client SDK
*/

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://outfit-planner-7485e.firebasestorage.app',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  final ApiClient _bgRemovalClient = ApiClient();

  // upload image to firebase storage with background removal
  Future<String> uploadImage(File imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    debugPrint("Uploading image for user: $userId");
    debugPrint("Image path: ${imageFile.path}");
    debugPrint("File exists: ${await imageFile.exists()}");
    debugPrint("Storage bucket: ${_storage.bucket}");

    try {
      // remove background from the image
      debugPrint('Removing background from image...');
      final Uint8List processedImageBytes =
          await _bgRemovalClient.removeBgApi(imageFile.path);

      // create temporary file from processed image bytes

      final String tempPath =
          '${imageFile.parent.path}/processed_${_uuid.v4()}.png';
      final File processedImageFile = File(tempPath);
      await processedImageFile.writeAsBytes(processedImageBytes);

      debugPrint(
          'Background removed successfully. Processed image saved at: $tempPath');

      final String fileName = '${_uuid.v4()}.png'; // png for transparency
      final Reference ref =
          _storage.ref().child('clothing_images').child(userId).child(fileName);

      debugPrint(
          'Uploading processed image to path: clothing_images/$userId/$fileName');

      // Add metadata for PNG with transparency
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/png',
      );

      // Wrap putFile in try/catch for network/permission errors
      final UploadTask uploadTask = ref.putFile(processedImageFile, metadata);

      uploadTask.snapshotEvents.listen((event) {
        debugPrint(
            'Upload progress: ${event.bytesTransferred}/${event.totalBytes}');
      }, onError: (e) {
        debugPrint('Upload error: $e');
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // clean up temporary file
      try {
        await processedImageFile.delete();
        debugPrint('Temporary processed file cleaned up');
      } catch (e) {
        debugPrint('Warning: Could not delete temporary file: $e');
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      throw Exception('Storage upload failed: ${e.message}');
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // add clothing item with image
  Future<void> addClothingItemWithImage({
    required File imageFile,
    String? name,
    required String category,
    required String itemType,
    required String style,
    List<String>? colors,
    List<String>? occasions,
    List<String>? specificStyles,
    String? brand,
    String? size,
    String? notes,
  }) async {
    try {
      // upload image first
      final String imageUrl = await uploadImage(imageFile);

      // create clothing item using the updated model
      final ClothingItem item = ClothingItem(
        id: _uuid.v4(),
        name: name,
        category: category,
        itemType: itemType,
        style: style,
        specificStyles: specificStyles,
        colors: colors ?? <String>[],
        occasions: occasions ?? <String>[],
        imageUrl: imageUrl,
        brand: brand,
        size: size,
        notes: notes,
        createdAt: DateTime.now(),
      );
      // save to Firestore
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('clothing_items')
          .doc(item.id)
          .set(item.toFirestore());
    } catch (e) {
      throw Exception('Failed to upload clothing item: $e');
    }
  }

// delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);

      // deleting image from storage
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  // deleting clothing item completely (both Firestore and Storage)
  Future<void> deleteClothingItem(String itemId, String imageUrl) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // delete image from firebase storage first
      await deleteImage(imageUrl);

      // delete item from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('clothing_items')
          .doc(itemId)
          .delete();

      debugPrint('Clothing item and image deleted successfully');
    } catch (e) {
      throw Exception('Failed to delete clothing item: $e');
    }
  }
}
