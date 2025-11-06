import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyQuestsScreen extends StatelessWidget {
  const MyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _AuthRequired();
    final stream = FirebaseFirestore.instance
        .collection('quests')
        .where('questGiverId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(child: Text('No quests posted yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final status = (d['status'] ?? 'open').toString();
              return ListTile(
                title: Text(d['title'] ?? 'Quest'),
                subtitle: Text('Status: $status'),
                onTap: () => context.go('/quest/${doc.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.go('/quest/${doc.id}/applicants'),
                      child: const Text('Applicants'),
                    ),
                    const SizedBox(width: 8),
                    if (status == 'in_progress')
                      OutlinedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            // Verify applicant marked done before owner confirmation
                            final apps = await FirebaseFirestore.instance
                                .collection('applications')
                                .where('questId', isEqualTo: doc.id)
                                .where('status', isEqualTo: 'approved')
                                .where('applicantDone', isEqualTo: true)
                                .limit(1)
                                .get();
                            if (apps.docs.isEmpty) {
                              messenger.showSnackBar(const SnackBar(
                                  content: Text(
                                      "Worker hasn't marked the job done yet.")));
                              return;
                            }

                            await FirebaseFirestore.instance
                                .collection('quests')
                                .doc(doc.id)
                                .update({
                              'status': 'completed',
                              'completedAt': FieldValue.serverTimestamp(),
                            });
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Quest marked as completed.')));
                          } catch (e) {
                            messenger.showSnackBar(
                                SnackBar(content: Text('Failed: $e')));
                          }
                        },
                        child: const Text('Mark as done'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/post-job'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AuthRequired extends StatelessWidget {
  const _AuthRequired();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sign in required'),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}
