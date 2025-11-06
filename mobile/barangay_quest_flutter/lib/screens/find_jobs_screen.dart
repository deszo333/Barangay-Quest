import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quest.dart';
import '../widgets/quest_card.dart';
import '../widgets/nav_actions.dart';

class FindJobsScreen extends StatefulWidget {
  const FindJobsScreen({super.key});

  @override
  State<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends State<FindJobsScreen> {
  String _search = '';
  String _status = 'open'; // open | in_progress | completed | all

  Stream<QuerySnapshot<Map<String, dynamic>>> _queryStream() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('quests')
        .orderBy('createdAt', descending: true);
    if (_status != 'all') {
      q = q.where('status', isEqualTo: _status);
    }
    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Jobs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: const [NavActions()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search title or category'),
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          // Status filter chips (3rd suggested option)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _StatusChip(
                  label: 'Open',
                  selected: _status == 'open',
                  onSelected: () => setState(() => _status = 'open'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'In Progress',
                  selected: _status == 'in_progress',
                  onSelected: () => setState(() => _status = 'in_progress'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Completed',
                  selected: _status == 'completed',
                  onSelected: () => setState(() => _status = 'completed'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'All',
                  selected: _status == 'all',
                  onSelected: () => setState(() => _status = 'all'),
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
                if (quests.isEmpty)
                  return const Center(child: Text('No results'));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: quests.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = quests[index];
                    return QuestCard(
                        quest: q, onTap: () => context.go('/quest/${q.id}'));
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
    );
  }
}
