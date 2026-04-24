import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/closet/models/clothing_item.dart';

class HistoryList extends StatefulWidget {
  final ClothingItem item;
  const HistoryList({Key? key, required this.item}) : super(key: key);

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _history = []; // list of {source, doc, id, date}
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLastWorn();
  }

  Future<void> _loadLastWorn() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final List<Map<String, dynamic>> found = [];

    // Try top-level outfits (may be blocked by security rules). Guard each query so permission errors
    // don't abort the rest of the loader.
    try {
      final outfitsRef = _firestore.collection('outfits').where('userId', isEqualTo: uid);

      try {
        final qTop = await outfitsRef.where('topId', isEqualTo: widget.item.id).get();
        for (final d in qTop.docs) {
          final ts = d.data()['createdAt'];
          if (ts is Timestamp) found.add({'source': 'outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
        }
      } catch (e) {
        debugPrint('Top-level outfits topId query failed (ignored): $e');
      }

      try {
        final qBottom = await outfitsRef.where('bottomId', isEqualTo: widget.item.id).get();
        for (final d in qBottom.docs) {
          final ts = d.data()['createdAt'];
          if (ts is Timestamp) found.add({'source': 'outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
        }
      } catch (e) {
        debugPrint('Top-level outfits bottomId query failed (ignored): $e');
      }

      try {
        final qShoe = await outfitsRef.where('shoeId', isEqualTo: widget.item.id).get();
        for (final d in qShoe.docs) {
          final ts = d.data()['createdAt'];
          if (ts is Timestamp) found.add({'source': 'outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
        }
      } catch (e) {
        debugPrint('Top-level outfits shoeId query failed (ignored): $e');
      }
    } catch (e) {
      debugPrint('Top-level outfits queries aborted (ignored): $e');
    }

    // Per-user outfits subcollection (some variants store outfits here)
    try {
      final userOutfitsRef = _firestore.collection('users').doc(uid).collection('outfits');
      try {
        final uTop = await userOutfitsRef.where('topId', isEqualTo: widget.item.id).get();
        for (final d in uTop.docs) {
          final ts = d.data()['createdAt'];
          if (ts is Timestamp) found.add({'source': 'users_outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
        }
      } catch (e) {
        debugPrint('users/{uid}/outfits topId query failed (ignored): $e');
      }

      try {
        final uBottom = await userOutfitsRef.where('bottomId', isEqualTo: widget.item.id).get();
        for (final d in uBottom.docs) {
          final ts = d.data()['createdAt'];
          if (ts is Timestamp) found.add({'source': 'users_outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
        }
      } catch (e) {
        debugPrint('users/{uid}/outfits bottomId query failed (ignored): $e');
      }

      try {
        final uShoe = await userOutfitsRef.where('shoeId', isEqualTo: widget.item.id).get();
        for (final d in uShoe.docs) {
          final ts = d.data()['createdAt'];
          if (ts is Timestamp) found.add({'source': 'users_outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
        }
      } catch (e) {
        debugPrint('users/{uid}/outfits shoeId query failed (ignored): $e');
      }
    } catch (e) {
      debugPrint('Per-user outfits queries aborted (ignored): $e');
    }

    // Check planned_outfits under users/{uid}/planned_outfits where itemIds contains this id
    try {
      final plannedRef = _firestore.collection('users').doc(uid).collection('planned_outfits');
      final qPlanned = await plannedRef.where('itemIds', arrayContains: widget.item.id).get();
      for (final d in qPlanned.docs) {
        final ts = d.data()['date'];
        if (ts is Timestamp) found.add({'source': 'planned_outfits', 'doc': d.data(), 'id': d.id, 'date': ts.toDate()});
      }
    } catch (e) {
      debugPrint('Planned outfits query failed (ignored): $e');
    }

    // sort by date desc
    found.sort((a, b) {
      final da = a['date'] as DateTime;
      final db = b['date'] as DateTime;
      return db.compareTo(da);
    });

    debugPrint('HistoryList: found ${found.length} entries for item ${widget.item.id}');

    if (mounted) {
      setState(() {
        _history = found;
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOutfitItems(Map<String, dynamic> outfit) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final List<String> ids = [];
    if (outfit['source'] == 'outfits' || outfit['source'] == 'users_outfits') {
      final doc = outfit['doc'] as Map<String, dynamic>;
      if (doc['topId'] != null) ids.add(doc['topId'] as String);
      if (doc['bottomId'] != null) ids.add(doc['bottomId'] as String);
      if (doc['shoeId'] != null) ids.add(doc['shoeId'] as String);
    } else {
      final doc = outfit['doc'] as Map<String, dynamic>;
      final list = (doc['itemIds'] as List?) ?? [];
      for (final v in list) if (v is String) ids.add(v);
    }

    final results = <Map<String, dynamic>>[];
    for (final id in ids) {
      final doc = await _firestore.collection('users').doc(uid).collection('clothing_items').doc(id).get();
      if (doc.exists) results.add({'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return results;
  }

  String _formatDate(DateTime d) {
    try {
      final l = d.toLocal();
      return '${l.year.toString().padLeft(4, '0')}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return d.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: widget.item.imageUrl.isNotEmpty
                        ? Image.network(widget.item.imageUrl)
                        : const Icon(Icons.checkroom, size: 120),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.itemType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_history.isEmpty)
                        const Text('No wear history found for this item.')
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wear history:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                itemCount: _history.length,
                                itemBuilder: (ctx, idx) {
                                  final rec = _history[idx];
                                  final dt = rec['date'] as DateTime;
                                  return ListTile(
                                    dense: true,
                                    title: Text(_formatDate(dt)),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      final items = await _fetchOutfitItems(rec);
                                      if (!mounted) return;
                                      showDialog(
                                        context: context,
                                        builder: (dlg) => AlertDialog(
                                          title: Text('Outfit on ${_formatDate(dt)}'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: items
                                                  .map((m) => Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                        child: Column(
                                                          children: [
                                                            if ((m['imageUrl'] as String?)?.isNotEmpty == true)
                                                              Image.network(m['imageUrl'], height: 80),
                                                            Text(m['itemType'] ?? m['name'] ?? '(item)')
                                                          ],
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                          actions: [TextButton(onPressed: () => Navigator.of(dlg).pop(), child: const Text('Close'))],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

