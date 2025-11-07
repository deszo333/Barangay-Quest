import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/star_rating.dart';

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
                    if (status == 'completed') ...[
                      const SizedBox(width: 8),
                      Builder(builder: (context) {
                        final ownerRated = (d['ownerRated'] ?? false) == true;
                        if (ownerRated) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('Rated ✓',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          );
                        }
                        return FilledButton(
                          onPressed: () => _openRatingSheet(context, doc),
                          child: const Text('Rate'),
                        );
                      })
                    ]
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

Future<void> _submitOwnerReview({
  required BuildContext context,
  required DocumentSnapshot<Map<String, dynamic>> questDoc,
  required int rating,
  required String comment,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Not signed in.')));
    return;
  }
  final q = questDoc.data()!;
  final applicantId = (q['assignedApplicantId'] ?? '').toString();
  final applicantName = (q['assignedApplicantName'] ?? 'Worker').toString();
  if (applicantId.isEmpty) {
    messenger
        .showSnackBar(const SnackBar(content: Text('No assigned worker.')));
    return;
  }
  try {
    final reviews = FirebaseFirestore.instance.collection('reviews');
    final batch = FirebaseFirestore.instance.batch();

    final newReviewRef = reviews.doc();
    batch.set(newReviewRef, {
      'questId': questDoc.id,
      'ownerId': user.uid,
      'ownerEmail': user.email,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update applicant aggregate ratings
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(applicantId);
    batch.set(
        userRef,
        {
          'ratingsCount': FieldValue.increment(1),
          'ratingsSum': FieldValue.increment(rating),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    // Mark quest as rated by owner
    batch.update(questDoc.reference, {
      'ownerRated': true,
      'ownerRatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    messenger.showSnackBar(const SnackBar(content: Text('Review submitted.')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
  }
}

void _openRatingSheet(
    BuildContext context, DocumentSnapshot<Map<String, dynamic>> questDoc) {
  final commentCtrl = TextEditingController();
  int rating = 0;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate the worker',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                StarRating(
                  value: rating,
                  onChanged: (v) => setState(() => rating = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Comments (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: rating < 1
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              await _submitOwnerReview(
                                context: context,
                                questDoc: questDoc,
                                rating: rating,
                                comment: commentCtrl.text,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      );
    },
  );
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
