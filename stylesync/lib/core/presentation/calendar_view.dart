import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stylesync/features/closet/models/clothing_item.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({Key? key}) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late final User _user;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  CalendarFormat _calendarFormat = CalendarFormat.week;
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _selectedDay = _focusedDay;
    _loadOutfits();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  /// RE-WEAR ADDED: Save the outfit again for TODAY
  Future<void> _rewearOutfit(List<dynamic> itemIds) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('planned_outfits')
          .add({
        'date': Timestamp.fromDate(DateTime.now()),
        'itemIds': itemIds,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit re-worn and added to history!')),
      );

      await _loadOutfits(); // refresh

      setState(() {
        _selectedDay = DateTime.now();
        _focusedDay = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to re-wear outfit: $e')),
      );
    }
  }

  Future<void> _loadOutfits() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('planned_outfits')
        .get();

    final Map<DateTime, List<dynamic>> events = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dayOnly = DateTime.utc(date.year, date.month, date.day);

      if (events[dayOnly] == null) {
        events[dayOnly] = [];
      }
      events[dayOnly]!.add(data['itemIds']);
    }

    if (mounted) {
      setState(() {
        _events = events;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dayOnly = DateTime.utc(day.year, day.month, day.day);
    return _events[dayOnly] ?? [];
  }

  Future<List<ClothingItem>> _getItemsFromIds(List<dynamic> itemIds) async {
    if (itemIds.isEmpty) {
      return [];
    }
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('clothing_items')
        .where(FieldPath.documentId, whereIn: itemIds.cast<String>())
        .get();

    return querySnapshot.docs
        .map((snapshot) => ClothingItem.fromSnapshot(snapshot))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Outfit History"),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2033, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onDaySelected: (selected, focused) {
              if (mounted) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                // Guard against calling jumpToPage before PageView attaches
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                  _currentPageNotifier.value = 0;
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(0);
                      _currentPageNotifier.value = 0;
                    }
                  });
                }
              }
            },
            eventLoader: _getEventsForDay,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedDay == null) {
      return const Center(
          child: Text("Please select a day to see the outfit."));
    }

    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(child: Text("No outfit saved for this date."));
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              if (events.length > 1)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: events.length,
                  onPageChanged: (page) {
                    _currentPageNotifier.value = page;
                  },
                  itemBuilder: (context, index) {
                    final itemIds = events[index] as List<dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: FutureBuilder<List<ClothingItem>>(
                        future: _getItemsFromIds(itemIds.cast<String>()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('Outfit items not found.'));
                          }

                          final items = snapshot.data!;
                          const categoryOrder = ['Top', 'Bottom', 'Shoe'];
                          items.sort((a, b) => categoryOrder
                              .indexOf(a.category)
                              .compareTo(categoryOrder.indexOf(b.category)));

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ...items.map((item) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                                child: Icon(Icons.error_outline,
                                                    color: Colors.red)),
                                      ),
                                    ),
                                  )),

                              const SizedBox(height: 10),

                              /// RE-WEAR BUTTON (ADDED)
                              ElevatedButton(
                                onPressed: () => _rewearOutfit(itemIds),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2E8B57),
                                  side: const BorderSide(
                                      color: Color(0xFF2E8B57), width: 2),
                                ),
                                child: const Text("Re-Wear Outfit"),
                              ),

                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (events.length > 1)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
            ],
          ),
        ),
        if (events.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      events.length,
                      (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: value == index
                                  ? const Color(0xFF2E8B57)
                                  : Colors.grey,
                            ),
                          )),
                );
              },
            ),
          ),
      ],
    );
  }
}
