import 'package:flutter/material.dart';
import '../../features/closet/models/clothing_item.dart';

import '../../features/closet/services/closet_service.dart';
import '../../features/closet/presentation/category_screen.dart';

// TEMPORARY FILE FOR OUTFIT PLANNING. WILL INTEGRATE WITH home_screen.dart LATER

class NewHome extends StatefulWidget {
  const NewHome({super.key});

  @override
  _NewHomeState createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> {
  final ClosetService _closetService = ClosetService();
  List<ClothingItem> tops = [];
  List<ClothingItem> bottoms = [];
  List<ClothingItem> shoes = [];

  int topIndex = 0;
  int bottomIndex = 0;
  int shoesIndex = 0;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchClothing();
  }

  Future<void> _fetchClothing() async {
    try {
      final results = await Future.wait([
        _closetService.getItemsByCategory('Top').first,
        _closetService.getItemsByCategory('Bottom').first,
        _closetService.getItemsByCategory('Shoe').first,
      ]);

      if (mounted) {
        setState(() {
          tops = results[0];
          bottoms = results[1];
          shoes = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildClothingRow(
      List<ClothingItem> items,
      int currentIndex,
      void Function(int) onIndexChanged,
      String categoryName,
      ) {
    if (items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('No $categoryName available')),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: () {
            setState(() {
              onIndexChanged((currentIndex - 1 + items.length) % items.length);
            });
          },
        ),
        Expanded(
          child: SizedBox(
            height: 250,
            child: InkWell(
              onTap: () {
                // navigate to category screen to show all items for this specific category
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(category: categoryName),
                  ),
                );
              },
              child: Image.network(
                items[currentIndex].imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error));
                },
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: () {
            setState(() {
              onIndexChanged((currentIndex + 1) % items.length);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StyleSync'),
        backgroundColor: const Color(0xFF2E8B57),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _buildClothingRow(tops, topIndex, (i) => topIndex = i, 'Tops'),
          _buildClothingRow(
            bottoms,
            bottomIndex,
                (i) => bottomIndex = i,
            'Bottoms',
          ),
          _buildClothingRow(shoes, shoesIndex, (i) => shoesIndex = i, 'Shoe'),
        ],
      ),
    );
  }
}
