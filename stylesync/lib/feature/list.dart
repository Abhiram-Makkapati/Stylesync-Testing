import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';


// STUB MODELS & SERVICE INTERFACES (replace with your real ones)

class ClothingItem {
  final String id;
  final String name;
  final String category; // 'Top', 'Bottom', 'Shoe', ...
  final String imageUrl;
  ClothingItem({required this.id, required this.name, required this.category, required this.imageUrl});
}

class ClothingHistoryEntry {
  final DateTime date;
  final String? outfitId; // optional
  final String? note;     // optional
  ClothingHistoryEntry({required this.date, this.outfitId, this.note});
}

class Outfit {
  final String id;
  final List<ClothingItem> items;
  Outfit({required this.id, required this.items});
}

/// Replace this with your real ClosetService implementation.
abstract class ClosetService {
  Stream<List<ClothingItem>> getItemsByCategory(String category);
  Stream<List<ClothingHistoryEntry>> getItemHistory(String itemId);
  Future<Outfit> getOutfitById(String outfitId);
  Future<Outfit> getOutfitByDate(DateTime date);
}

// ------------------------------------------------------------------
// HOME (NewHome) - shows three rows and navigates to history on tap
// ------------------------------------------------------------------
class NewHome extends StatefulWidget {
  final ClosetService closetService;
  const NewHome({super.key, required this.closetService});

  @override
  State<NewHome> createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> {
  List<ClothingItem> tops = [];
  List<ClothingItem> bottoms = [];
  List<ClothingItem> shoes = [];

  int topIndex = 0;
  int bottomIndex = 0;
  int shoesIndex = 0;

  bool _isLoading = true;
  String? _error;

  StreamSubscription<List<ClothingItem>>? _topsSub;
  StreamSubscription<List<ClothingItem>>? _bottomsSub;
  StreamSubscription<List<ClothingItem>>? _shoesSub;

  ClosetService get _closetService => widget.closetService;

  @override
  void initState() {
    super.initState();
    _subscribeToClothing();
  }

  void _subscribeToClothing() {
    setState(() => _isLoading = true);

    _topsSub = _closetService.getItemsByCategory('Top').listen((items) {
      if (!mounted) return;
      setState(() {
        tops = items;
        topIndex = items.isEmpty ? 0 : math.min(topIndex, items.length - 1);
        _isLoading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    });

    _bottomsSub = _closetService.getItemsByCategory('Bottom').listen((items) {
      if (!mounted) return;
      setState(() {
        bottoms = items;
        bottomIndex = items.isEmpty ? 0 : math.min(bottomIndex, items.length - 1);
        _isLoading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    });

    _shoesSub = _closetService.getItemsByCategory('Shoe').listen((items) {
      if (!mounted) return;
      setState(() {
        shoes = items;
        shoesIndex = items.isEmpty ? 0 : math.min(shoesIndex, items.length - 1);
        _isLoading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    });
  }

  @override
  void dispose() {
    _topsSub?.cancel();
    _bottomsSub?.cancel();
    _shoesSub?.cancel();
    super.dispose();
  }

  Widget _buildClothingRow({
    required List<ClothingItem> items,
    required int currentIndex,
    required void Function(int) onIndexChanged,
    required String label,
  }) {
    if (items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('No $label available', style: const TextStyle(color: Colors.black54))),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onIndexChanged((currentIndex - 1 + items.length) % items.length),
        ),
        Expanded(
          child: SizedBox(
            height: 250,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClothingHistoryScreen(
                      item: items[currentIndex],
                      closetService: _closetService,
                    ),
                  ),
                );
              },
              child: Image.network(
                items[currentIndex].imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final total = loadingProgress.expectedTotalBytes;
                  final loaded = loadingProgress.cumulativeBytesLoaded;
                  return Center(
                    child: CircularProgressIndicator(value: total != null && total > 0 ? loaded / total : null),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onIndexChanged((currentIndex + 1) % items.length),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StyleSync'), backgroundColor: const Color(0xFF2E8B57)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildClothingRow(
              items: tops,
              currentIndex: topIndex,
              onIndexChanged: (i) => setState(() => topIndex = i),
              label: 'Tops',
            ),
            _buildClothingRow(
              items: bottoms,
              currentIndex: bottomIndex,
              onIndexChanged: (i) => setState(() => bottomIndex = i),
              label: 'Bottoms',
            ),
            _buildClothingRow(
              items: shoes,
              currentIndex: shoesIndex,
              onIndexChanged: (i) => setState(() => shoesIndex = i),
              label: 'Shoes',
            ),
          ],
        ),
      ),
    );
  }
}


// HISTORY - list of dates an item was worn

class ClothingHistoryScreen extends StatelessWidget {
  final ClothingItem item;
  final ClosetService closetService;
  const ClothingHistoryScreen({super.key, required this.item, required this.closetService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${item.name} history')),
      body: StreamBuilder<List<ClothingHistoryEntry>>(
        stream: closetService.getItemHistory(item.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final entries = snapshot.data ?? const [];
          if (entries.isEmpty) {
            return const Center(child: Text('No wear history yet.'));
          }

          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              final dateStr = _formatDate(e.date);
              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(dateStr),
                subtitle: e.note == null ? null : Text(e.note!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OutfitDetailScreen(
                        title: dateStr,
                        outfitFuture: e.outfitId != null
                            ? closetService.getOutfitById(e.outfitId!)
                            : closetService.getOutfitByDate(e.date),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final wd = weekdays[d.weekday - 1];
    final m = months[d.month - 1];
    return '$wd, $m ${d.day}, ${d.year}';
  }
}


// OUTFIT DETAIL - grouped items with thumbnails

class OutfitDetailScreen extends StatelessWidget {
  final String title;
  final Future<Outfit> outfitFuture;
  const OutfitDetailScreen({super.key, required this.title, required this.outfitFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Outfit • $title')),
      body: FutureBuilder<Outfit>(
        future: outfitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final outfit = snapshot.data;
          if (outfit == null || outfit.items.isEmpty) {
            return const Center(child: Text('No items recorded for this day.'));
          }

          final groups = <String, List<ClothingItem>>{};
          for (final it in outfit.items) {
            groups.putIfAbsent(it.category, () => []).add(it);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: groups.entries.map((e) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: e.value.map((item) => _ItemTile(item: item)).toList(),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ClothingItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0x11000000),
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
