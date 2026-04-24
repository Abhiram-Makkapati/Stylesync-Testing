import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  _AddClothingScreenState createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  File? _selectedImage;
  final UploadService _uploadService = UploadService();
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();

  // form controllers - REMOVE _nameController
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _typeController = TextEditingController();
  final _colorController = TextEditingController();
  final _styleController = TextEditingController();
  final _newOccasionController = TextEditingController();

  // dropdown values
  String? _selectedCategory; // Make nullable for validation

  // dropdown options
  final List<String> _categories = ['Top', 'Bottom', 'Shoe'];
  // occasion options for multi-select
  final List<String> _occasionOptions = [
    'Casual',
    'Work',
    'Night Out',
    'Formal',
    'Sport'
  ];
  final Set<String> _selectedOccasions = <String>{};

  @override
  void dispose() {
    _brandController.dispose();
    _sizeController.dispose();
    _typeController.dispose();
    _colorController.dispose();
    _styleController.dispose();
    _newOccasionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveClothingItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    // UPDATED VALIDATION - no name field, check dropdown
    if (_selectedImage == null ||
        _selectedCategory == null ||
        _typeController.text.isEmpty ||
        _colorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill in all required fields and select an image'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _uploadService.addClothingItemWithImage(
        imageFile: _selectedImage!,
        name: null, // optional name not collected in this screen
        category: _selectedCategory!,
        itemType: _typeController.text,
        style: _styleController.text.isEmpty ? '' : _styleController.text,
        colors: [_colorController.text],
        occasions: _selectedOccasions.toList(),
        specificStyles: null,
        brand: _brandController.text.isEmpty ? null : _brandController.text,
        size: _sizeController.text.isEmpty ? null : _sizeController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clothing item added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Clothing Item'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B57),
              Color(0xFF20B2AA),
              Color(0xFFE0F2F1),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Image picker section
                  GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF2E8B57), width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_selectedImage!,
                                  fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: Color(0xFF2E8B57),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to select image from gallery or camera',
                                  style: TextStyle(
                                    color: Color(0xFF2E8B57),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CATEGORY DROPDOWN (REQUIRED)
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 16),

                  // TYPE FIELD (REQUIRED) - This becomes the main display name
                  TextFormField(
                    controller: _typeController,
                    decoration: InputDecoration(
                      labelText: 'Type * (e.g., cardigan, jeans, sneakers)',
                      labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a type' : null,
                  ),
                  const SizedBox(height: 16),

                  // STYLE FIELD (optional)
                  TextFormField(
                    controller: _styleController,
                    decoration: InputDecoration(
                      labelText: 'Style (optional, e.g., T-shirt, Straight)',
                      labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _colorController,
                    decoration: InputDecoration(
                      labelText: 'Color *',
                      labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a color' : null,
                  ),
                  const SizedBox(height: 16),

                  // OCCASIONS multi-select chips
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Occasion(s)',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _occasionOptions
                              .map((o) => ChoiceChip(
                                    label: Text(o),
                                    selected: _selectedOccasions.contains(o),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected)
                                          _selectedOccasions.add(o);
                                        else
                                          _selectedOccasions.remove(o);
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newOccasionController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Add custom occasion (e.g., Brunch)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final newVal =
                                    _newOccasionController.text.trim();
                                if (newVal.isEmpty) return;
                                setState(() {
                                  if (!_occasionOptions.contains(newVal))
                                    _occasionOptions.add(newVal);
                                  _selectedOccasions.add(newVal);
                                  _newOccasionController.clear();
                                });
                              },
                              child: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E8B57)),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: 'Brand (Optional)',
                      labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _sizeController,
                    decoration: InputDecoration(
                      labelText: 'Size (Optional)',
                      labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  ElevatedButton(
                    onPressed: _isUploading ? null : _saveClothingItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Clothing Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
