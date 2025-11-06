import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quest.dart';
import '../widgets/quest_card.dart';
import '../widgets/nav_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay Quest'),
        actions: const [NavActions()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1620), Color(0xFF0F1C28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find and post quests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user == null
                            ? 'Browse titles. Sign in to see full details.'
                            : 'Discover open jobs or post your own quest.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF9DB2C2)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (user == null)
                  FilledButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Sign Up'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => context.go('/post-job'),
                    child: const Text('Post Job'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quests')
                  // Only fetch open quests server-side to reduce data and keep lists clean
                  .where('status', isEqualTo: 'open')
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Failed to load quests: ${snap.error}'));
                }
                var quests =
                    snap.data?.docs.map((d) => Quest.fromDoc(d)).toList() ?? [];
                if (quests.isEmpty) {
                  return const Center(child: Text('No quests yet.'));
                }
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
