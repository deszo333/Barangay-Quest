import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quest.dart';
import '../widgets/quest_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay Quest'),
        actions: [
          IconButton(
              onPressed: () => context.go('/find-jobs'),
              icon: const Icon(Icons.search)),
          if (user != null)
            IconButton(
                onPressed: () => context.go('/my-applications'),
                icon: const Icon(Icons.work_outline)),
          if (user != null)
            IconButton(
                onPressed: () => context.go('/my-quests'),
                icon: const Icon(Icons.list_alt)),
          if (user != null)
            IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('quests')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load quests: ${snap.error}'));
          }
          final quests =
              snap.data?.docs.map((d) => Quest.fromDoc(d)).toList() ?? [];
          if (quests.isEmpty) {
            return const Center(child: Text('No quests yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: quests.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final q = quests[index];
              return QuestCard(
                  quest: q, onTap: () => context.go('/quest/${q.id}'));
            },
          );
        },
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/post'),
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
            )
          : null,
    );
  }
}
