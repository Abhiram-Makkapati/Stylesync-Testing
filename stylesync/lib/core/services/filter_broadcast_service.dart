import 'dart:async';
import 'package:flutter/foundation.dart';

/// Simple singleton service to broadcast filter maps across the app.
/// Emits a Map with keys: 'category' (String) and 'filters' (Map<String,dynamic>)
class FilterBroadcastService {
  FilterBroadcastService._internal();

  static final FilterBroadcastService _instance = FilterBroadcastService._internal();
  static FilterBroadcastService get instance => _instance;

  final StreamController<Map<String, dynamic>> _ctrl = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of broadcast events
  Stream<Map<String, dynamic>> get stream => _ctrl.stream;

  /// Publish a filter map for a category
  void publish(String category, Map<String, dynamic> filters) {
    try {
      // debug: announce publish
      // (use debugPrint so logs appear in Flutter console)
      // ignore: avoid_print
      debugPrint('FilterBroadcastService.publish: $category -> $filters');
      _ctrl.add({'category': category, 'filters': filters});
    } catch (e) {
      debugPrint('FilterBroadcastService.publish error: $e');
    }
  }

  void dispose() {
    _ctrl.close();
  }
}
