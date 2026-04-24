import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/closet_service.dart';
import '../models/clothing_item.dart';
import '../presentation/edit_clothing_screen.dart';
import '../../../core/presentation/history_list.dart';
import '../../upload/services/upload_service.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final ClosetService _closetService = ClosetService();
  final UploadService _uploadService = UploadService();

  List<ClothingItem> _clothingItems = [];
  // Keep full unfiltered list so we can apply filters synchronously
  List<ClothingItem> _allClothingItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  // filters
  String? _selectedColor;
  String? _selectedBrand;
  String? _selectedOccasion;
  String? _selectedType;

  final List<String> _categories = [
    'all',
    'Top',
    'Bottom',
    'Shoe',
  ];

  @override
  void initState() {
    super.initState();
    _loadClothingItems();
  }

  void _loadClothingItems() {
    setState(() => _isLoading = true);

    try {
      Stream<List<ClothingItem>> stream;
      if (_selectedCategory == 'all') {
        stream = _closetService.getUserClothingItems();
      } else {
        stream = _closetService.getItemsByCategory(_selectedCategory);
      }

      stream.listen((items) {
        // store full list, then apply client-side filters synchronously
        _allClothingItems = items;
        final filtered = _applyClientFilters(items);

        setState(() {
          _clothingItems = filtered;
          _isLoading = false;
        });
      }).onError((error) {
        debugPrint('Error loading items: $error');
        setState(() => _isLoading = false);
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
      setState(() => _isLoading = false);
    }
  }

  // Apply the currently selected filters to the provided list and return the result
  List<ClothingItem> _applyClientFilters(List<ClothingItem> items) {
    return items.where((item) {
      if (_selectedType != null && _selectedType!.isNotEmpty) {
        if (item.itemType.toLowerCase() != _selectedType!.toLowerCase())
          return false;
      }
      if (_selectedColor != null && _selectedColor!.isNotEmpty) {
        if (!item.colors
            .map((c) => c.toLowerCase())
            .contains(_selectedColor!.toLowerCase())) return false;
      }
      if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
        if ((item.brand ?? '').toLowerCase() != _selectedBrand!.toLowerCase())
          return false;
      }
      if (_selectedOccasion != null && _selectedOccasion!.isNotEmpty) {
        if (!item.occasions
            .map((o) => o.toLowerCase())
            .contains(_selectedOccasion!.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _deleteClothingItem(ClothingItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item'),
        content: Text(
            'Delete "${item.name ?? item.itemType}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // If there is an imageUrl, try deleting via UploadService (which deletes storage then Firestore doc)
      if (item.imageUrl.isNotEmpty) {
        try {
          await _uploadService.deleteClothingItem(item.id, item.imageUrl);

          // success: remove locally
          if (mounted) {
            setState(() {
              _clothingItems.removeWhere((i) => i.id == item.id);
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Deleted "${item.name ?? item.itemType}" successfully')),
            );
          }
          return;
        } on FirebaseException catch (e) {
          // Storage deletion failed (permissions/App Check). Attempt to at least delete the Firestore doc so UI stays consistent.
          debugPrint('Storage delete failed: ${e.code} ${e.message}');
          try {
            await _closetService.deleteClothingItem(item.id);
            if (mounted) {
              setState(() {
                _clothingItems.removeWhere((i) => i.id == item.id);
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Item removed from closet, but storage deletion failed (permission).'),
                backgroundColor: Colors.orange,
              ));
            }
            return;
          } catch (e2) {
            // both storage and firestore delete failed
            debugPrint(
                'Firestore delete after storage failure also failed: $e2');
            rethrow;
          }
        }
      }

      // No imageUrl: just delete Firestore doc
      await _closetService.deleteClothingItem(item.id);
      if (mounted) {
        setState(() {
          _clothingItems.removeWhere((i) => i.id == item.id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Deleted "${item.name ?? item.itemType}" successfully')),
        );
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to delete "${item.name ?? item.itemType}": $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? tempColor = _selectedColor;
        String? tempBrand = _selectedBrand;
        String? tempOccasion = _selectedOccasion;
        String? tempType = _selectedType;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E8B57),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TYPE
                  ExpansionTile(
                    title: const Text('Type'),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allClothingItems
                            .map((i) => i.itemType)
                            .where((t) => t.isNotEmpty)
                            .toSet()
                            .map((type) => FilterChip(
                                  label: Text(type),
                                  selected: tempType == type,
                                  selectedColor:
                                      const Color(0xFF2E8B57).withOpacity(0.2),
                                  onSelected: (selected) {
                                    setModalState(() =>
                                        tempType = selected ? type : null);
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),

                  // COLOR
                  ExpansionTile(
                    title: const Text('Color'),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Black',
                          'White',
                          'Blue',
                          'Dark Blue',
                          'Red',
                          'Green',
                          'Brown',
                          'Beige'
                        ]
                            .map((color) => FilterChip(
                                  label: Text(color),
                                  selected: tempColor == color,
                                  selectedColor:
                                      const Color(0xFF2E8B57).withOpacity(0.2),
                                  onSelected: (selected) {
                                    setModalState(() =>
                                        tempColor = selected ? color : null);
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),

                  // BRAND
                  ExpansionTile(
                    title: const Text('Brand'),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Brand',
                          border: OutlineInputBorder(),
                        ),
                        value: tempBrand,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ..._allClothingItems
                              .map((item) => item.brand ?? '')
                              .where((b) => b.isNotEmpty)
                              .toSet()
                              .map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                        ],
                        onChanged: (v) => setModalState(() => tempBrand = v),
                      ),
                    ],
                  ),

                  // OCCASION (derived from items)
                  ExpansionTile(
                    title: const Text('Occasion'),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    children: [
                      Builder(builder: (ctx) {
                        final occasions = _allClothingItems
                            .expand((i) => i.occasions)
                            .where((o) => o.isNotEmpty)
                            .toSet()
                            .toList();
                        if (occasions.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No occasions available'),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: occasions
                              .map((occasion) => FilterChip(
                                    label: Text(occasion),
                                    selected: tempOccasion == occasion,
                                    selectedColor: const Color(0xFF2E8B57)
                                        .withOpacity(0.2),
                                    onSelected: (selected) {
                                      setModalState(() => tempOccasion =
                                          selected ? occasion : null);
                                    },
                                  ))
                              .toList(),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedColor = null;
                            _selectedBrand = null;
                            _selectedOccasion = null;
                            _selectedType = null;
                            _clothingItems =
                                _applyClientFilters(_allClothingItems);
                          });
                        },
                        child: const Text('Reset',
                            style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E8B57)),
                        icon: const Icon(Icons.check),
                        label: const Text('Apply'),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedColor = tempColor;
                            _selectedBrand = tempBrand;
                            _selectedOccasion = tempOccasion;
                            _selectedType = tempType;
                            _clothingItems =
                                _applyClientFilters(_allClothingItems);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Top':
        return Colors.blue;
      case 'Bottom':
        return Colors.green;
      case 'Shoe':
        return Colors.brown;
      case 'Accessory':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Top':
        return Icons.checkroom;
      case 'Bottom':
        return Icons.checkroom;
      case 'Shoe':
        return Icons.directions_run;
      case 'Accessory':
        return Icons.watch;
      default:
        return Icons.checkroom;
    }
  }

  Widget _buildClothingCard(ClothingItem item) {
    return Stack(
      children: [
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryList(item: item)));
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stack) {
                              return Center(
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  color: _getCategoryColor(item.category),
                                  size: 40,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: _getCategoryColor(item.category),
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.itemType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (item.style.isNotEmpty)
                        Text(item.style,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      Text(
                        item.colors.isNotEmpty ? item.colors.join(', ') : '',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (item.brand != null)
                        Text(item.brand!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),

        // Action menu (positioned above the card at top-right)
        Positioned(
          right: 6,
          top: 6,
          child: Material(
            color: Colors.transparent,
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  // open edit screen and reload items on return
                  final updated =
                      await Navigator.of(context).push<ClothingItem?>(
                    MaterialPageRoute(
                        builder: (_) => EditClothingScreen(item: item)),
                  );
                  if (updated != null) _loadClothingItems();
                } else if (value == 'delete') {
                  // call your delete method
                  await _deleteClothingItem(item);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Closet (${_clothingItems.length} items)'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category Chips + Filter Button Row
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        String category = _categories[index];
                        bool isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(category.toUpperCase(),
                                style: const TextStyle(color: Colors.black)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = category);
                              _loadClothingItems();
                            },
                            selectedColor: Colors.teal.withOpacity(0.3),
                            backgroundColor: Colors.grey[200],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openFilterSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  label: const Text(
                    'Filter',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Closet grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clothingItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checkroom,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory == 'all'
                                  ? 'No clothing items yet'
                                  : 'No ${_selectedCategory}s available',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text('Add some items to your closet!',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          // Slightly taller cards to avoid tiny bottom overflow on some devices
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _clothingItems.length,
                        itemBuilder: (context, index) {
                          return _buildClothingCard(_clothingItems[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
