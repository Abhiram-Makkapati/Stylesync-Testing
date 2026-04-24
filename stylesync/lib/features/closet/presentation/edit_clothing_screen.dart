import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/closet_service.dart';

class EditClothingScreen extends StatefulWidget {
  final ClothingItem item;
  const EditClothingScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<EditClothingScreen> createState() => _EditClothingScreenState();
}

class _EditClothingScreenState extends State<EditClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _typeController;
  late TextEditingController _styleController;
  late TextEditingController _colorsController; // comma-separated
  final ClosetService _closetService = ClosetService();
  late TextEditingController _brandController;
  late TextEditingController _sizeController;
  late Set<String> _selectedOccasions;
  List<String> _occasionOptions = ['Casual', 'Formal', 'Night Out', 'Work', 'Active Wear'];
  late TextEditingController _newOccasionController;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _typeController = TextEditingController(text: item.itemType);
    _styleController = TextEditingController(text: item.style);
    _colorsController = TextEditingController(text: item.colors.join(', '));
    _brandController = TextEditingController(text: item.brand ?? '');
    _sizeController = TextEditingController(text: item.size ?? '');
    _selectedOccasions = item.occasions.toSet();
    for (final o in item.occasions) {
      if (o.isNotEmpty && !_occasionOptions.contains(o)) _occasionOptions.add(o);
    }
    _newOccasionController = TextEditingController();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _styleController.dispose();
    _colorsController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _newOccasionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = ClothingItem(
      id: widget.item.id,
      name: widget.item.name,
      category: widget.item.category,
      itemType: _typeController.text.trim(),
      style: _styleController.text.trim(),
      specificStyles: widget.item.specificStyles,
      colors: _colorsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      occasions: _selectedOccasions.toList(),
      imageUrl: widget.item.imageUrl,
      brand: _brandController.text.isEmpty ? null : _brandController.text.trim(),
      size: _sizeController.text.isEmpty ? null : _sizeController.text.trim(),
      notes: null,
      createdAt: widget.item.createdAt,
      tags: widget.item.tags,
    );

    try {
      await _closetService.updateClothingItem(widget.item.id, updated);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _styleController, decoration: const InputDecoration(labelText: 'Style (optional)')),
              const SizedBox(height: 8),
              TextFormField(controller: _colorsController, decoration: const InputDecoration(labelText: 'Colors (comma separated)')),
              const SizedBox(height: 8),
              TextFormField(controller: _brandController, decoration: const InputDecoration(labelText: 'Brand (optional)')),
              const SizedBox(height: 8),
              TextFormField(controller: _sizeController, decoration: const InputDecoration(labelText: 'Size (optional)')),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              const Text('Occasion(s)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _occasionOptions.map((o) {
                  final selected = _selectedOccasions.contains(o);
                  return ChoiceChip(
                    label: Text(o),
                    selected: selected,
                    onSelected: (sel) {
                      setState(() {
                        if (sel) _selectedOccasions.add(o);
                        else _selectedOccasions.remove(o);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newOccasionController,
                      decoration: const InputDecoration(hintText: 'Add occasion (e.g., Brunch)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final v = _newOccasionController.text.trim();
                      if (v.isEmpty) return;
                      setState(() {
                        if (!_occasionOptions.contains(v)) _occasionOptions.add(v);
                        _selectedOccasions.add(v);
                        _newOccasionController.clear();
                      });
                    },
                    child: const Text('Add'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
