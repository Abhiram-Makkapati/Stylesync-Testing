import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

// Core Models & Presentation
import 'package:stylesync/core/models/user_data.dart';
import 'suggestion_popup.dart';
import 'calendar_view.dart';
import '../services/filter_broadcast_service.dart';

// Features
import '../../features/closet/models/clothing_item.dart';
import '../../features/closet/services/closet_service.dart';
import '../../features/upload/presentation/add_clothing_screen.dart';
import '../../features/closet/presentation/closet_screen.dart';
import '../../features/closet/presentation/category_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? username;

  const HomeScreen({super.key, this.firstName, this.lastName, this.username});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ClosetService _closetService = ClosetService();
  final User? _user = FirebaseAuth.instance.currentUser;
  String _displayName = '';
  StreamSubscription<Map<String, dynamic>>? _filterBroadcastSub;

  List<ClothingItem> tops = [];
  List<ClothingItem> bottoms = [];
  List<ClothingItem> shoes = [];

  int topsIndex = 0;
  int bottomsIndex = 0;
  int shoeIndex = 0;

  bool isLoading = true;

  final GlobalKey _shuffleKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  final GlobalKey _suggestionKey = GlobalKey();
  final GlobalKey _filteredViewKey = GlobalKey();
  final GlobalKey _addClothesKey = GlobalKey();
  final GlobalKey _viewClosetKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _logoutKey = GlobalKey();
  final GlobalKey _tutorialKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _determineDisplayName();
    _fetchAndSetClothing();
    // Listen for filter broadcasts so HomeScreen rows update when 'Apply to Canvas' is used
    _filterBroadcastSub = FilterBroadcastService.instance.stream.listen((event) {
      try {
        final rawCategory = (event['category'] as String?) ?? '';
        final filters = (event['filters'] as Map<String, dynamic>?) ?? {};
        var key = rawCategory;
        if (key.endsWith('s')) key = key.substring(0, key.length - 1);
        if (key.isEmpty) return;
        final normalized = key[0].toUpperCase() + key.substring(1).toLowerCase();
        debugPrint('HomeScreen received broadcast for $rawCategory -> $normalized: $filters');
        setState(() {
          if (normalized == 'Top') {
            tops = _filterItems(tops, filters);
            topsIndex = tops.isEmpty ? 0 : math.min(topsIndex, tops.length - 1);
          } else if (normalized == 'Bottom') {
            bottoms = _filterItems(bottoms, filters);
            bottomsIndex = bottoms.isEmpty ? 0 : math.min(bottomsIndex, bottoms.length - 1);
          } else if (normalized == 'Shoe') {
            shoes = _filterItems(shoes, filters);
            shoeIndex = shoes.isEmpty ? 0 : math.min(shoeIndex, shoes.length - 1);
          }
        });
      } catch (e) {
        debugPrint('HomeScreen broadcast handling error: $e');
      }
    });
  }

  @override
  void dispose() {
    _filterBroadcastSub?.cancel();
    super.dispose();
  }

  Future<void> _determineDisplayName() async {
    // Prefer explicit props passed in (e.g., from registration screen)
    if (widget.firstName != null && widget.firstName!.trim().isNotEmpty) {
      setState(() => _displayName = widget.firstName!.trim());
      return;
    }

    // Next prefer FirebaseAuth displayName
    final authName = FirebaseAuth.instance.currentUser?.displayName;
    if (authName != null && authName.trim().isNotEmpty) {
      setState(() => _displayName = authName.trim());
      return;
    }

    // Fallback: try to read Firestore user doc for first/last name
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final fn = (data['firstName'] as String?)?.trim() ?? '';
      final ln = (data['lastName'] as String?)?.trim() ?? '';
      final name = ('$fn ${ln}').trim();
      if (name.isNotEmpty) setState(() => _displayName = name);
    } catch (_) {
      // ignore errors silently — leave displayName blank
    }
  }

  void _startTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([
        _shuffleKey,
        _saveKey,
        _suggestionKey,
        _filteredViewKey,
        _addClothesKey,
        _viewClosetKey,
        _historyKey,
        _logoutKey,
        _tutorialKey,
      ]);
    });
  }

  Future<void> _fetchAndSetClothing() async {
    try {
      const timeoutDuration = Duration(seconds: 10);
      final results = await Future.wait([
        _closetService.getItemsByCategory('Top').first.timeout(timeoutDuration, onTimeout: () => []),
        _closetService.getItemsByCategory('Bottom').first.timeout(timeoutDuration, onTimeout: () => []),
        _closetService.getItemsByCategory('Shoe').first.timeout(timeoutDuration, onTimeout: () => []),
      ]);
      if (!mounted) return;
      setState(() {
        tops = results[0];
        bottoms = results[1];
        shoes = results[2];
        // ensure indices are within bounds after initial load
        topsIndex = tops.isEmpty ? 0 : math.min(topsIndex, tops.length - 1);
        bottomsIndex = bottoms.isEmpty ? 0 : math.min(bottomsIndex, bottoms.length - 1);
        shoeIndex = shoes.isEmpty ? 0 : math.min(shoeIndex, shoes.length - 1);
        isLoading = false;
      });
      _checkAndShowTutorial();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
    }
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool tutorialShown = prefs.getBool('homeScreenTutorialShown') ?? false;
    if (!tutorialShown && mounted) {
      _startTutorial();
      await prefs.setBool('homeScreenTutorialShown', true);
    }
  }

  void _updateOutfit(ClothingItem selectedSuggestion) {
    int? newIndex;
    switch (selectedSuggestion.category) {
      case 'Top':
        newIndex = tops.indexWhere((item) => item.id == selectedSuggestion.id);
        if (newIndex != -1) setState(() => topsIndex = newIndex!);
        break;
      case 'Bottom':
        newIndex = bottoms.indexWhere((item) => item.id == selectedSuggestion.id);
        if (newIndex != -1) setState(() => bottomsIndex = newIndex!);
        break;
      case 'Shoe':
        newIndex = shoes.indexWhere((item) => item.id == selectedSuggestion.id);
        if (newIndex != -1) setState(() => shoeIndex = newIndex!);
        break;
    }
    if (newIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find the selected item.')));
    }
  }

  Future<void> _saveOutfitForToday() async {
    if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select one item in each category.')));
      return;
    }
    final itemIds = [tops[topsIndex].id, bottoms[bottomsIndex].id, shoes[shoeIndex].id];
    try {
      await Provider.of<UserData>(context, listen: false).saveOutfit(DateTime.now(), itemIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outfit saved for today!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save outfit: $e')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('homeScreenTutorialShown', false);
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) {
        return Builder(
          builder: (scaffoldContext) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('StyleSync'),
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                actions: [
                  Showcase(
                    key: _tutorialKey,
                    title: 'Get Help',
                    description: 'Click here anytime to see this tutorial again.',
                    child: IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: 'Show Tutorial',
                      onPressed: () {
                        print("Help tapped!");
                        ShowCaseWidget.of(scaffoldContext).startShowCase([
                          _shuffleKey,
                          _saveKey,
                          _suggestionKey,
                          _filteredViewKey,
                          _addClothesKey,
                          _viewClosetKey,
                          _historyKey,
                          _logoutKey,
                          _tutorialKey,
                        ]);
                      },
                    ),
                  ),
                  Showcase(
                    key: _logoutKey,
                    title: 'Logout',
                    description: 'Click here to sign out of your account.',
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                      tooltip: 'Logout',
                    ),
                  ),
                ],
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome${_displayName.isNotEmpty ? ' ${_displayName}' : ''}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E8B57),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Showcase(
                          key: _saveKey,
                          title: 'Save Your Outfit',
                          description: 'Click here to save this outfit and add it to your history.',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // small reset filters button above Save
                              IconButton(
                                tooltip: 'Reset canvas filters',
                                icon: const Icon(Icons.filter_alt_off, size: 20),
                                onPressed: () {
                                  final empty = {
                                    'search': '',
                                    'type': null,
                                    'color': null,
                                    'brand': null,
                                    'occasion': null,
                                  };
                                  try {
                                    FilterBroadcastService.instance.publish('Top', empty);
                                    FilterBroadcastService.instance.publish('Bottom', empty);
                                    FilterBroadcastService.instance.publish('Shoe', empty);
                                  } catch (e) {
                                    debugPrint('Error publishing reset filters: $e');
                                  }
                                  _fetchAndSetClothing();
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canvas filters reset')));
                                },
                              ),
                              // smaller Save button to fit the reset above
                              ElevatedButton.icon(
                                onPressed: _saveOutfitForToday,
                                icon: const Icon(Icons.save, color: Color(0xFF2E8B57), size: 18),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(70, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2E8B57),
                                  textStyle: const TextStyle(fontSize: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: Color(0xFF2E8B57), width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildClothingRow(tops, topsIndex, (i) => setState(() => topsIndex = i), 'Top', flex: 3, arrowKey: _shuffleKey, imageKey: _suggestionKey),
                        _buildClothingRow(bottoms, bottomsIndex, (i) => setState(() => bottomsIndex = i), 'Bottom', flex: 5, imageKey: _filteredViewKey),
                        _buildClothingRow(shoes, shoeIndex, (i) => setState(() => shoeIndex = i), 'Shoe', flex: 2),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomNavBar(),
            );
          },
        );
      },
    );
  }

  List<ClothingItem> _filterItems(List<ClothingItem> items, Map<String, dynamic> f) {
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
        final colorMatches = item.colors.any((c) => c.toLowerCase().contains(lower));
        if (!(nameMatches || typeMatches || colorMatches)) return false;
      }
      if (type != null && type.isNotEmpty && item.itemType.toLowerCase() != type.toLowerCase()) return false;
      if (color != null && color.isNotEmpty && !item.colors.map((c) => c.toLowerCase()).contains(color.toLowerCase())) return false;
      if (brand != null && brand.isNotEmpty && (item.brand ?? '').toLowerCase() != brand.toLowerCase()) return false;
      if (occasion != null && occasion.isNotEmpty && !item.occasions.map((o) => o.toLowerCase()).contains(occasion.toLowerCase())) return false;
      return true;
    }).toList();
  }

  Widget _buildClothingRow(List<ClothingItem> items, int currentIndex, ValueChanged<int> onIndexChanged, String categoryName, {required int flex, GlobalKey? arrowKey, GlobalKey? imageKey}) {
    bool hasItems = items.isNotEmpty;
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Showcase(
            key: arrowKey ?? GlobalKey(),
            title: 'Scroll Through Clothes',
            description: 'Click on the arrows to scroll through your clothes.',
            targetShapeBorder: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black54),
              onPressed: !hasItems ? null : () => onIndexChanged((currentIndex - 1 + items.length) % items.length),
            ),
          ),
          Expanded(
            child: Showcase(
              key: imageKey ?? GlobalKey(),
              title: imageKey == _suggestionKey ? 'Get Outfit Suggestions' : 'Filtered View',
              description: imageKey == _suggestionKey ? 'Double-tap on the clothing to get outfit suggestions based on color.' : 'Tap here once to see a filtered view of all items in this category.',
              child: GestureDetector(
                onTap: hasItems ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(category: categoryName))) : null,
                onDoubleTap: hasItems
                    ? () {
                  final tappedItem = items[currentIndex];
                  List<ClothingItem> suggestionPool;
                  if (categoryName == 'Top') {
                    suggestionPool = [...bottoms, ...shoes];
                  } else if (categoryName == 'Bottom') {
                    suggestionPool = [...tops, ...shoes];
                  } else {
                    suggestionPool = [...tops, ...bottoms];
                  }
                  final tappedColors = tappedItem.colors.map((c) => c.toLowerCase()).toSet();
                  final finalSuggestions = suggestionPool.where((item) {
                    // Check if any color in this item's list exists in the tapped item's color set.
                    return item.colors.any((color) => tappedColors.contains(color.toLowerCase()));
                  }).toList();

                  if (finalSuggestions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No matching color items found.')));
                    return;
                  }
                  showColorSuggestionDialog(context, finalSuggestions, _updateOutfit);
                }
                    : null,
                child: hasItems
                    ? Image.network(
                  items[currentIndex].imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
                )
                    : Center(child: Text('No items in $categoryName')),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
            onPressed: !hasItems ? null : () => onIndexChanged((currentIndex + 1) % items.length),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2E8B57),
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Showcase(
            key: _addClothesKey,
            title: 'Add Clothes',
            description: 'Click here to add new clothing items to your closet.',
            child: const Icon(Icons.add),
          ),
          label: 'Add Clothes',
        ),
        BottomNavigationBarItem(
          icon: Showcase(
            key: _viewClosetKey,
            title: 'View Your Closet',
            description: 'Click here to view your collection of clothes.',
            child: const Icon(Icons.checkroom),
          ),
          label: 'View Closet',
        ),
        BottomNavigationBarItem(
          icon: Showcase(
            key: _historyKey,
            title: 'View Outfit History',
            description: 'Click here to view your past outfits on the calendar.',
            child: const Icon(Icons.history),
          ),
          label: 'History',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddClothingScreen()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClosetScreen()));
            break;
          case 3:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarView()));
            break;
        }
      },
    );
  }

}
