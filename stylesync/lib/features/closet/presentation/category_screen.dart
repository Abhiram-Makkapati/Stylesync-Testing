import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/closet_service.dart';
import '../../../core/services/filter_broadcast_service.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final Map<String, dynamic>? initialFilters;
  const CategoryScreen({Key? key, required this.category, this.initialFilters})
      : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ClosetService _closetService = ClosetService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedType;
  String? _selectedColor;
  String? _selectedBrand;
  String? _selectedOccasion;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // prefill from initialFilters if provided
    if (widget.initialFilters != null) {
      final f = widget.initialFilters!;
      _searchController.text = (f['search'] as String?) ?? '';
      _selectedType = f['type'] as String?;
      _selectedColor = f['color'] as String?;
      _selectedBrand = f['brand'] as String?;
      _selectedOccasion = f['occasion'] as String?;
    }
  }

  List<ClothingItem> _applyFilters(List<ClothingItem> items, String search,
      String? type, String? color, String? brand, String? occasion) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(
            color: ['Top', 'Bottom', 'Shoe'].contains(widget.category)
                ? Colors.white
                : null,
          ),
        ),
        backgroundColor: const Color(0xFF2E8B57),
        iconTheme: IconThemeData(
          color: ['Top', 'Bottom', 'Shoe'].contains(widget.category)
              ? Colors.white
              : Colors.black,
        ),
      ),
      body: StreamBuilder<List<ClothingItem>>(
        stream: _closetService.getItemsByCategory(widget.category),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading items: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          // derive filter choices from actual items
          final types = <String>{};
          final colors = <String>{};
          final brands = <String>{};
          final occasions = <String>{};
          for (final i in items) {
            if (i.itemType.isNotEmpty) types.add(i.itemType);
            if (i.colors.isNotEmpty) colors.addAll(i.colors);
            if ((i.brand ?? '').isNotEmpty) brands.add(i.brand!);
            if (i.occasions.isNotEmpty) occasions.addAll(i.occasions);
          }

          final filtered = _applyFilters(items, _searchController.text,
              _selectedType, _selectedColor, _selectedBrand, _selectedOccasion);

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search + clear
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by name, type, or color',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search & filters',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedType = null;
                          _selectedColor = null;
                          _selectedBrand = null;
                          _selectedOccasion = null;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Filters row: type, color, brand
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type dropdown
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButton<String?>(
                          value: _selectedType,
                          hint: const Text('Type'),
                          items: <DropdownMenuItem<String?>>[
                            const DropdownMenuItem(
                                value: null, child: Text('All Types')),
                            ...types.map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                          ],
                          onChanged: (v) => setState(() => _selectedType = v),
                        ),
                      ),

                      // Color dropdown
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButton<String?>(
                          value: _selectedColor,
                          hint: const Text('Color'),
                          items: <DropdownMenuItem<String?>>[
                            const DropdownMenuItem(
                                value: null, child: Text('All Colors')),
                            ...colors.map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                          ],
                          onChanged: (v) => setState(() => _selectedColor = v),
                        ),
                      ),

                      // Occasion dropdown
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButton<String?>(
                          value: _selectedOccasion,
                          hint: const Text('Occasion'),
                          items: <DropdownMenuItem<String?>>[
                            const DropdownMenuItem(
                                value: null, child: Text('All Occasions')),
                            ...occasions.map((o) =>
                                DropdownMenuItem(value: o, child: Text(o)))
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedOccasion = v),
                        ),
                      ),

                      // Brand dropdown (optional)
                      if (brands.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: DropdownButton<String?>(
                            value: _selectedBrand,
                            hint: const Text('Brand'),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem(
                                  value: null, child: Text('All Brands')),
                              ...brands.map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedBrand = v),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Result count & clear button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${filtered.length} item${filtered.length == 1 ? '' : 's'}'),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedType = null;
                              _selectedColor = null;
                              _selectedBrand = null;
                              _selectedOccasion = null;
                              debugPrint(
                                  'CategoryScreen Reset filters for ${widget.category}');
                            });
                          },
                          child: const Text('Reset filters'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // return current filters to caller (digital canvas)
                            final result = {
                              'search': _searchController.text,
                              'type': _selectedType,
                              'color': _selectedColor,
                              'brand': _selectedBrand,
                              'occasion': _selectedOccasion,
                            };
                            debugPrint(
                                'CategoryScreen ApplyToCanvas for ${widget.category}: $result');
                            // publish globally so canvases (or other callers) can react
                            try {
                              // publish the filter map directly (no extra wrapper)
                              FilterBroadcastService.instance
                                  .publish(widget.category, result);
                            } catch (_) {}
                            Navigator.of(context).pop(result);
                          },
                          child: const Text('Apply to Canvas'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Items grid or message
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                              'No ${widget.category} found with those filters.'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Card(
                              clipBehavior: Clip.hardEdge,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Optional: navigate to item detail screen if you have one
                                },
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, st) =>
                                            const Center(
                                                child: Icon(Icons.error)),
                                        loadingBuilder: (c, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name ?? '(No name)',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(item.itemType),
                                          Text(item.colors.isNotEmpty
                                              ? item.colors.join(', ')
                                              : ''),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
