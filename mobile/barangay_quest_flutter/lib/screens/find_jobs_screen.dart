// lib/screens/find_jobs_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quest.dart';
import '../widgets/quest_card.dart';
// import '../widgets/nav_actions.dart'; // No longer needed in AppBar
import '../theme/app_theme.dart'; 

class FindJobsScreen extends StatefulWidget {
  const FindJobsScreen({super.key});

  @override
  State<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends State<FindJobsScreen> {
  static const double _maxPrice = 10000;
  static const String _defaultSort = 'createdAt-desc';

  String _search = '';
  String _jobType = 'All'; 
  double _selectedMaxPrice = _maxPrice;
  // --- ADD THIS ---
  double _sliderValue = _maxPrice;
  // --- END ADD ---
  String _sortBy = _defaultSort;

  Stream<QuerySnapshot<Map<String, dynamic>>> _queryStream() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('quests')
        .where('status', isEqualTo: 'open') 
        .orderBy('createdAt', descending: true);
    return q.snapshots();
  }

  void _resetFilters() {
    setState(() {
      _search = '';
      _jobType = 'All';
  _selectedMaxPrice = _maxPrice;
      _sortBy = _defaultSort;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- FIX: This is a main tab, so it should not have a back button ---
        title: const Text('Find Jobs'),
        // actions: const [NavActions()], // Removed, nav actions are on home
        automaticallyImplyLeading: false, // Don't show a back arrow
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search title or category'),
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Job Type', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    _StatusChip(
                      label: 'All',
                      selected: _jobType == 'All',
                      onSelected: () => setState(() => _jobType = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'In Person',
                      selected: _jobType == 'In Person',
                      onSelected: () => setState(() => _jobType = 'In Person'),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Online',
                      selected: _jobType == 'Online',
                      onSelected: () => setState(() => _jobType = 'Online'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Max Budget', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _selectedMaxPrice == _maxPrice ? '₱${_selectedMaxPrice.toInt()}+' : '₱${_selectedMaxPrice.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
                Slider(
                  value: _sliderValue, // <-- USE _sliderValue
                  min: 0,
                  max: _maxPrice,
                  divisions: 100, 
                  label: '₱${_sliderValue.toInt()}', // <-- USE _sliderValue
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value; // Update the UI
                    });
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      _selectedMaxPrice = value; // Update the actual query filter
                    });
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bg2, // Updated color
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    underline: Container(),
                    style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(
                        value: 'createdAt-desc',
                        child: Text('Sort by: Newest'),
                      ),
                      DropdownMenuItem(
                        value: 'price-desc',
                        child: Text('Sort by: Price (High-Low)'),
                      ),
                      DropdownMenuItem(
                        value: 'price-asc',
                        child: Text('Sort by: Price (Low-High)'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _sortBy = value ?? _defaultSort),
                  ),
                ),
                
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _queryStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Failed to load: ${snap.error}'));
                }
                
                var quests =
                    snap.data?.docs.map((d) => Quest.fromDoc(d)).toList() ?? [];
                
                if (_search.isNotEmpty) {
                  quests = quests
                      .where((q) =>
                          q.title.toLowerCase().contains(_search) ||
                          q.category.toLowerCase().contains(_search))
                      .toList();
                }

                if (_jobType != 'All') {
                  quests = quests.where((q) => q.workType == _jobType).toList();
                }

                if (_selectedMaxPrice < _maxPrice) {
                  quests = quests.where((q) => q.price <= _selectedMaxPrice).toList();
                }

                quests.sort((a, b) {
                  switch (_sortBy) {
                    case 'price-asc':
                      return a.price.compareTo(b.price);
                    case 'price-desc':
                      return b.price.compareTo(a.price);
                    default: 
                      final tsA = a.createdAt?.millisecondsSinceEpoch ?? 0;
                      final tsB = b.createdAt?.millisecondsSinceEpoch ?? 0;
                      return tsB.compareTo(tsA);
                  }
                });

                if (quests.isEmpty) {
                  return const Center(child: Text('No results match your filters.'));
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: quests.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = quests[index];
                    return QuestCard(
                        quest: q, onTap: () => context.push('/quest/${q.id}'));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _StatusChip(
      {required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? AppTheme.bg : AppTheme.white,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppTheme.accent,
      backgroundColor: AppTheme.bg2,
    );
  }
}