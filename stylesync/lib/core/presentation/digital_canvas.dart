import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../features/closet/models/clothing_item.dart';
import '../../features/closet/services/closet_service.dart';
import '../../features/closet/presentation/category_screen.dart';
import '../services/filter_broadcast_service.dart';

// digital canvas

class NewHome extends StatefulWidget {
  const NewHome({super.key});

  @override
  _NewHomeState createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> {
  final ClosetService _closetService = ClosetService();
  // raw lists (from service)
  List<ClothingItem> _allTops = [];
  List<ClothingItem> _allBottoms = [];
  List<ClothingItem> _allShoes = [];

  // filtered lists shown on canvas
  List<ClothingItem> tops = [];
  List<ClothingItem> bottoms = [];
  List<ClothingItem> shoes = [];

  int topIndex = 0;
  int bottomIndex = 0;
  int shoesIndex = 0;

  bool _isLoading = true;
  String? _error;

  // per-category filters returned from CategoryScreen
  final Map<String, Map<String, dynamic>?> _categoryFilters = {
    'Top': null,
    'Bottom': null,
    'Shoe': null,
  };

  // track which category screen was last opened from this canvas instance
  String? _currentCategory;

  // active filters for the currently-focused category (used when a broadcast targets visible category)
  Map<String, dynamic> _activeFilters = {
    'search': '',
    'type': null,
    'color': null,
    'brand': null,
    'occasion': null,
  };

  StreamSubscription<Map<String, dynamic>>? _filterBroadcastSub;

  String? get selectedTopId => tops.isEmpty ? null : tops[topIndex].id;
  String? get selectedBottomId =>
      bottoms.isEmpty ? null : bottoms[bottomIndex].id;
  String? get selectedShoeId => shoes.isEmpty ? null : shoes[shoesIndex].id;

  StreamSubscription<List<ClothingItem>>? _topsSub;
  StreamSubscription<List<ClothingItem>>? _bottomsSub;
  StreamSubscription<List<ClothingItem>>? _shoesSub;

  void _subscribeToClothing() {
    setState(() => _isLoading = true);

    _topsSub = _closetService.getItemsByCategory('Top').listen((items) {
      if (mounted) {
        setState(() {
          _allTops = items;
          topIndex = items.isEmpty ? 0 : math.min(topIndex, items.length - 1);
          tops = _applyFiltersForCategory('Top', _allTops);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });

    _bottomsSub = _closetService.getItemsByCategory('Bottom').listen((items) {
      if (mounted) {
        setState(() {
          _allBottoms = items;
          bottomIndex =
              items.isEmpty ? 0 : math.min(bottomIndex, items.length - 1);
          bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });

    _shoesSub = _closetService.getItemsByCategory('Shoe').listen((items) {
      if (mounted) {
        setState(() {
          _allShoes = items;
          shoesIndex =
              items.isEmpty ? 0 : math.min(shoesIndex, items.length - 1);
          shoes = _applyFiltersForCategory('Shoe', _allShoes);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _subscribeToClothing();
    // listen for global filter broadcasts from CategoryScreen
    _filterBroadcastSub =
        FilterBroadcastService.instance.stream.listen((event) {
      try {
        final rawCategory = (event['category'] as String?) ?? '';
        final filters = (event['filters'] as Map<String, dynamic>?) ?? {};
        var key = rawCategory;
        if (key.endsWith('s')) key = key.substring(0, key.length - 1);
        if (key.isEmpty) return;
        final normalized =
            key[0].toUpperCase() + key.substring(1).toLowerCase();
        debugPrint(
            'Canvas received broadcast filters for $rawCategory -> $normalized: $filters');

        // store into the general category filters map (keeps previous behavior)
        _categoryFilters[normalized] = filters;

        // If the broadcast targets the category currently being edited/viewed from this canvas,
        // update the focused active filters and apply only to that category's visible list.
        if (_currentCategory != null && _currentCategory == normalized) {
          _activeFilters = Map<String, dynamic>.from(filters);
          _applyFiltersToCanvas();
        } else {
          // otherwise, reapply all category filters (keep existing behavior)
          setState(() {
            tops = _applyFiltersForCategory('Top', _allTops);
            bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
            shoes = _applyFiltersForCategory('Shoe', _allShoes);
          });
        }
      } catch (e) {
        debugPrint('Error applying broadcasted filters (canvas): $e');
      }
    });
  }

  // Apply the currently-active focused filters (_activeFilters) to the canvas row
  void _applyFiltersToCanvas() {
    setState(() {
      final s = (_activeFilters['search'] as String?)?.toLowerCase() ?? '';

      bool matchesFilter(ClothingItem item) {
        if (s.isNotEmpty) {
          final nameMatches = (item.name ?? '').toLowerCase().contains(s);
          final typeMatches = item.itemType.toLowerCase().contains(s);
          final colorMatches =
              item.colors.any((c) => c.toLowerCase().contains(s));
          if (!(nameMatches || typeMatches || colorMatches)) return false;
        }
        final type = _activeFilters['type'] as String?;
        final color = _activeFilters['color'] as String?;
        final brand = _activeFilters['brand'] as String?;
        final occasion = _activeFilters['occasion'] as String?;

        if (type != null &&
            type.isNotEmpty &&
            item.itemType.toLowerCase() != type.toLowerCase()) return false;
        if (color != null &&
            color.isNotEmpty &&
            !item.colors
                .map((c) => c.toLowerCase())
                .contains(color.toLowerCase())) return false;
        if (brand != null &&
            brand.isNotEmpty &&
            (item.brand ?? '').toLowerCase() != brand.toLowerCase())
          return false;
        if (occasion != null &&
            occasion.isNotEmpty &&
            !item.occasions
                .map((o) => o.toLowerCase())
                .contains(occasion.toLowerCase())) return false;
        return true;
      }

      if (_currentCategory == 'Top') {
        tops = _allTops.where(matchesFilter).toList();
      } else if (_currentCategory == 'Bottom') {
        bottoms = _allBottoms.where(matchesFilter).toList();
      } else if (_currentCategory == 'Shoe') {
        shoes = _allShoes.where(matchesFilter).toList();
      }
    });
  }

  // Apply a filter map (from CategoryScreen) to a list of items
  List<ClothingItem> _applyFiltersForCategory(
      String category, List<ClothingItem> items) {
    final f = _categoryFilters[category];
    if (f == null) return items;
    final search = (f['search'] as String?) ?? '';
    final type = f['type'] as String?;
    final color = f['color'] as String?;
    final brand = f['brand'] as String?;
    final occasion = f['occasion'] as String?;

    final lower = search.toLowerCase().trim();
    return items.where((item) {
      if (lower.isNotEmpty) {
        final nameMatches = (item.name ?? '').toLowerCase().contains(lower);
        final typeMatches = item.itemType.toLowerCase().contains(lower);
        final colorMatches =
            item.colors.any((c) => c.toLowerCase().contains(lower));
        if (!(nameMatches || typeMatches || colorMatches)) return false;
      }
      if (type != null &&
          type.isNotEmpty &&
          item.itemType.toLowerCase() != type.toLowerCase()) return false;
      if (color != null &&
          color.isNotEmpty &&
          !item.colors
              .map((c) => c.toLowerCase())
              .contains(color.toLowerCase())) return false;
      if (brand != null &&
          brand.isNotEmpty &&
          (item.brand ?? '').toLowerCase() != brand.toLowerCase()) return false;
      if (occasion != null &&
          occasion.isNotEmpty &&
          !item.occasions
              .map((o) => o.toLowerCase())
              .contains(occasion.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _topsSub?.cancel();
    _bottomsSub?.cancel();
    _shoesSub?.cancel();
    _filterBroadcastSub?.cancel();
    super.dispose();
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
        // per-category reset filter button
        IconButton(
          icon: const Icon(Icons.filter_alt_off, size: 20),
          tooltip: 'Reset filters for $categoryName',
          onPressed: () {
            setState(() {
              final key = categoryName.endsWith('s')
                  ? categoryName.substring(0, categoryName.length - 1)
                  : categoryName;
              final normalized =
                  key[0].toUpperCase() + key.substring(1).toLowerCase();
              _categoryFilters[normalized] = null;
              tops = _applyFiltersForCategory('Top', _allTops);
              bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
              shoes = _applyFiltersForCategory('Shoe', _allShoes);
            });
          },
        ),
        Expanded(
          child: SizedBox(
            height: 250,
            child: InkWell(
              onTap: () async {
                // navigate to category screen to show all items for this specific category
                final key = categoryName.endsWith('s')
                    ? categoryName.substring(0, categoryName.length - 1)
                    : categoryName;
                final normalized =
                    key[0].toUpperCase() + key.substring(1).toLowerCase();
                setState(() => _currentCategory = normalized);
                final result =
                    await Navigator.of(context).push<Map<String, dynamic>?>(
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                        category: categoryName,
                        initialFilters: _categoryFilters[normalized]),
                  ),
                );
                // If the user applied filters, store them and re-apply
                if (result != null) {
                  debugPrint(
                      'Canvas received filters for $categoryName: $result');
                  setState(() {
                    // result corresponds to normalized key we passed initialFilters for
                    final key2 = categoryName.endsWith('s')
                        ? categoryName.substring(0, categoryName.length - 1)
                        : categoryName;
                    final normalized2 =
                        key2[0].toUpperCase() + key2.substring(1).toLowerCase();
                    _categoryFilters[normalized2] = result;
                    debugPrint(
                        'Stored in _categoryFilters[$normalized2] = ${_categoryFilters[normalized2]}');
                    // reapply filters immediately
                    tops = _applyFiltersForCategory('Top', _allTops);
                    bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
                    shoes = _applyFiltersForCategory('Shoe', _allShoes);
                  });
                }
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
        actions: [
          IconButton(
            tooltip: 'Reset all canvas filters',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              setState(() {
                _categoryFilters['Top'] = null;
                _categoryFilters['Bottom'] = null;
                _categoryFilters['Shoe'] = null;
                tops = _applyFiltersForCategory('Top', _allTops);
                bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
                shoes = _applyFiltersForCategory('Shoe', _allShoes);
              });
            },
          ),
        ],
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
          _buildClothingRow(
              tops, topIndex, (i) => setState(() => topIndex = i), 'Tops'),
          _buildClothingRow(
            bottoms,
            bottomIndex,
            (i) => setState(() => bottomIndex = i),
            'Bottoms',
          ),
          _buildClothingRow(shoes, shoesIndex,
              (i) => setState(() => shoesIndex = i), 'Shoes'),
        ],
      ),
    );
  }
}

// display the canvas in home screen
class NewHomeCanvas extends StatefulWidget {
  const NewHomeCanvas({Key? key}) : super(key: key);

  @override
  State<NewHomeCanvas> createState() => NewHomeCanvasState();
}

class NewHomeCanvasState extends State<NewHomeCanvas> {
  final ClosetService _closetService = ClosetService();
  // raw lists (from service)
  List<ClothingItem> _allTops = [];
  List<ClothingItem> _allBottoms = [];
  List<ClothingItem> _allShoes = [];

  // filtered lists shown on canvas
  List<ClothingItem> tops = [];
  List<ClothingItem> bottoms = [];
  List<ClothingItem> shoes = [];

  int topIndex = 0;
  int bottomIndex = 0;
  int shoesIndex = 0;

  bool _isLoading = true;
  String? _error;

  // per-category filters returned from CategoryScreen
  final Map<String, Map<String, dynamic>?> _categoryFilters = {
    'Top': null,
    'Bottom': null,
    'Shoe': null,
  };

  // track which category screen was last opened from this canvas instance
  String? _currentCategory;

  // active filters for the currently-focused category (used when a broadcast targets visible category)
  Map<String, dynamic> _activeFilters = {
    'search': '',
    'type': null,
    'color': null,
    'brand': null,
    'occasion': null,
  };

  StreamSubscription<Map<String, dynamic>>? _filterBroadcastSub;

  String? get selectedTopId => tops.isEmpty ? null : tops[topIndex].id;
  String? get selectedBottomId =>
      bottoms.isEmpty ? null : bottoms[bottomIndex].id;
  String? get selectedShoeId => shoes.isEmpty ? null : shoes[shoesIndex].id;

  StreamSubscription<List<ClothingItem>>? _topsSub;
  StreamSubscription<List<ClothingItem>>? _bottomsSub;
  StreamSubscription<List<ClothingItem>>? _shoesSub;

  // Apply the currently-active focused filters (_activeFilters) to the canvas row
  void _applyFiltersToCanvas() {
    setState(() {
      final s = (_activeFilters['search'] as String?)?.toLowerCase() ?? '';

      bool matchesFilter(ClothingItem item) {
        if (s.isNotEmpty) {
          final nameMatches = (item.name ?? '').toLowerCase().contains(s);
          final typeMatches = item.itemType.toLowerCase().contains(s);
          final colorMatches =
              item.colors.any((c) => c.toLowerCase().contains(s));
          if (!(nameMatches || typeMatches || colorMatches)) return false;
        }
        final type = _activeFilters['type'] as String?;
        final color = _activeFilters['color'] as String?;
        final brand = _activeFilters['brand'] as String?;
        final occasion = _activeFilters['occasion'] as String?;

        if (type != null &&
            type.isNotEmpty &&
            item.itemType.toLowerCase() != type.toLowerCase()) return false;
        if (color != null &&
            color.isNotEmpty &&
            !item.colors
                .map((c) => c.toLowerCase())
                .contains(color.toLowerCase())) return false;
        if (brand != null &&
            brand.isNotEmpty &&
            (item.brand ?? '').toLowerCase() != brand.toLowerCase())
          return false;
        if (occasion != null &&
            occasion.isNotEmpty &&
            !item.occasions
                .map((o) => o.toLowerCase())
                .contains(occasion.toLowerCase())) return false;
        return true;
      }

      if (_currentCategory == 'Top') {
        tops = _allTops.where(matchesFilter).toList();
      } else if (_currentCategory == 'Bottom') {
        bottoms = _allBottoms.where(matchesFilter).toList();
      } else if (_currentCategory == 'Shoe') {
        shoes = _allShoes.where(matchesFilter).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _subscribeToClothing();
    // listen for broadcasts as well
    debugPrint('NewHomeCanvasState: subscribing to FilterBroadcastService');
    _filterBroadcastSub =
        FilterBroadcastService.instance.stream.listen((event) {
      try {
        debugPrint('NewHomeCanvasState: received raw event -> $event');
        final rawCategory = (event['category'] as String?) ?? '';
        final filters = (event['filters'] as Map<String, dynamic>?) ?? {};
        var key = rawCategory;
        if (key.endsWith('s')) key = key.substring(0, key.length - 1);
        if (key.isEmpty) return;
        final normalized =
            key[0].toUpperCase() + key.substring(1).toLowerCase();
        debugPrint(
            'NewHomeCanvasState: parsed rawCategory="$rawCategory" normalized="$normalized" filters=$filters');
        _categoryFilters[normalized] = filters;
        if (_currentCategory != null && _currentCategory == normalized) {
          _activeFilters = Map<String, dynamic>.from(filters);
          debugPrint(
              'NewHomeCanvasState: applying focused filters for $_currentCategory -> $_activeFilters');
          _applyFiltersToCanvas();
        } else {
          debugPrint(
              'NewHomeCanvasState: applying filters globally (not focused)');
          setState(() {
            tops = _applyFiltersForCategory('Top', _allTops);
            bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
            shoes = _applyFiltersForCategory('Shoe', _allShoes);
          });
        }
      } catch (e) {
        debugPrint('Canvas(Home) broadcast error: $e');
      }
    });
  }

  void _subscribeToClothing() {
    setState(() => _isLoading = true);

    _topsSub = _closetService.getItemsByCategory('Top').listen((items) {
      if (mounted) {
        setState(() {
          _allTops = items;
          tops = _applyFiltersForCategory('Top', _allTops);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });

    _bottomsSub = _closetService.getItemsByCategory('Bottom').listen((items) {
      if (mounted) {
        setState(() {
          _allBottoms = items;
          bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });

    _shoesSub = _closetService.getItemsByCategory('Shoe').listen((items) {
      if (mounted) {
        setState(() {
          _allShoes = items;
          shoes = _applyFiltersForCategory('Shoe', _allShoes);
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  List<ClothingItem> _applyFiltersForCategory(
      String category, List<ClothingItem> items) {
    final f = _categoryFilters[category];
    if (f == null) return items;
    final search = (f['search'] as String?) ?? '';
    final type = f['type'] as String?;
    final color = f['color'] as String?;
    final brand = f['brand'] as String?;
    final occasion = f['occasion'] as String?;

    final lower = search.toLowerCase().trim();
    return items.where((item) {
      if (lower.isNotEmpty) {
        final nameMatches = (item.name ?? '').toLowerCase().contains(lower);
        final typeMatches = item.itemType.toLowerCase().contains(lower);
        final colorMatches =
            item.colors.any((c) => c.toLowerCase().contains(lower));
        if (!(nameMatches || typeMatches || colorMatches)) return false;
      }
      if (type != null &&
          type.isNotEmpty &&
          item.itemType.toLowerCase() != type.toLowerCase()) return false;
      if (color != null &&
          color.isNotEmpty &&
          !item.colors
              .map((c) => c.toLowerCase())
              .contains(color.toLowerCase())) return false;
      if (brand != null &&
          brand.isNotEmpty &&
          (item.brand ?? '').toLowerCase() != brand.toLowerCase()) return false;
      if (occasion != null &&
          occasion.isNotEmpty &&
          !item.occasions
              .map((o) => o.toLowerCase())
              .contains(occasion.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _topsSub?.cancel();
    _bottomsSub?.cancel();
    _shoesSub?.cancel();
    _filterBroadcastSub?.cancel();
    super.dispose();
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
              onTap: () async {
                final key = categoryName.endsWith('s')
                    ? categoryName.substring(0, categoryName.length - 1)
                    : categoryName;
                final normalized =
                    key[0].toUpperCase() + key.substring(1).toLowerCase();
                setState(() => _currentCategory = normalized);
                final result =
                    await Navigator.of(context).push<Map<String, dynamic>?>(
                  MaterialPageRoute(
                      builder: (_) => CategoryScreen(
                          category: categoryName,
                          initialFilters: _categoryFilters[normalized])),
                );
                if (result != null) {
                  debugPrint(
                      'Canvas received filters for $categoryName: $result');
                  setState(() {
                    final key = categoryName.endsWith('s')
                        ? categoryName.substring(0, categoryName.length - 1)
                        : categoryName;
                    final normalized =
                        key[0].toUpperCase() + key.substring(1).toLowerCase();
                    _categoryFilters[normalized] = result;
                    debugPrint(
                        'Stored in _categoryFilters[$normalized] = ${_categoryFilters[normalized]}');
                    tops = _applyFiltersForCategory('Top', _allTops);
                    bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
                    shoes = _applyFiltersForCategory('Shoe', _allShoes);
                  });
                }
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // top-right reset button for convenience
        Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Reset canvas filters',
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () {
                  setState(() {
                    _categoryFilters['Top'] = null;
                    _categoryFilters['Bottom'] = null;
                    _categoryFilters['Shoe'] = null;
                    _activeFilters = {
                      'search': '',
                      'type': null,
                      'color': null,
                      'brand': null,
                      'occasion': null,
                    };
                    _currentCategory = null;
                    tops = _applyFiltersForCategory('Top', _allTops);
                    bottoms = _applyFiltersForCategory('Bottom', _allBottoms);
                    shoes = _applyFiltersForCategory('Shoe', _allShoes);
                  });
                },
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildClothingRow(
                tops,
                topIndex,
                (i) => setState(() => topIndex = i),
                'Tops',
              ),
              const SizedBox(height: 12),
              _buildClothingRow(
                bottoms,
                bottomIndex,
                (i) => setState(() => bottomIndex = i),
                'Bottoms',
              ),
              const SizedBox(height: 12),
              _buildClothingRow(
                shoes,
                shoesIndex,
                (i) => setState(() => shoesIndex = i),
                'Shoes',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }
}
