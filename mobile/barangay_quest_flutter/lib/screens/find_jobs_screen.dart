import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quest.dart';
import '../widgets/quest_card.dart';

class FindJobsScreen extends StatefulWidget {
  const FindJobsScreen({super.key});

  @override
  State<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends State<FindJobsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Jobs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search title or category'),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Failed to load: ${snap.error}'));
                }
                var quests = snap.data?.docs.map((d) => Quest.fromDoc(d)).toList() ?? [];
                if (_search.isNotEmpty) {
                  quests = quests.where((q) =>
                    q.title.toLowerCase().contains(_search) ||
                    q.category.toLowerCase().contains(_search)
                  ).toList();
                }
                if (quests.isEmpty) return const Center(child: Text('No results'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: quests.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final q = quests[index];
                    return QuestCard(
                      quest: q,
                      onTap: () => context.go('/quest/${q.id}')
                    );
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
