import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _AuthRequired();
    final stream = FirebaseFirestore.instance
        .collection('applications')
        .where('applicantId', isEqualTo: user.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
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
            return const Center(child: Text('No applications yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final status = (d['status'] ?? 'pending').toString();
              final applicantDone = (d['applicantDone'] ?? false) == true;
              return ListTile(
                title: Text(d['questTitle'] ?? 'Quest'),
                subtitle: Text('Status: $status' +
                    (applicantDone ? ' • You marked done' : '')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'approved' && !applicantDone)
                      FilledButton(
                        onPressed: () async {
                          try {
                            await doc.reference.update({
                              'applicantDone': true,
                              'applicantDoneAt': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Marked as finished. Waiting for quest owner to confirm.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                        child: const Text("I've finished"),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.go('/quest/${d['questId']}'),
                      child: const Text('View'),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
