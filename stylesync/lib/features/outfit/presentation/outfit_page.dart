import 'package:flutter/material.dart';
import '../services/outfit_service.dart';

class OutfitPage extends StatefulWidget {
  const OutfitPage({super.key});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage> {
  final OutfitService _outfitService = OutfitService();
  List<Map<String, dynamic>> _outfits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    try {
      final outfits = await _outfitService.getUserOutfits();
      setState(() {
        _outfits = outfits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading outfits: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Outfits'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _outfits.isEmpty
              ? const Center(
                  child: Text(
                    'No outfits saved yet.\nCreate your first outfit!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _outfits.length,
                  itemBuilder: (context, index) {
                    final outfit = _outfits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outfit ${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Top: ${outfit['topId']}'),
                            Text('Bottom: ${outfit['bottomId']}'),
                            Text('Shoes: ${outfit['shoeId']}'),
                            if (outfit['createdAt'] != null)
                              Text(
                                'Created: ${outfit['createdAt'].toDate().toString().split('.')[0]}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
