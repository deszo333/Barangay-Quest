import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestApplicantsScreen extends StatefulWidget {
  final String questId;
  const QuestApplicantsScreen({super.key, required this.questId});

  @override
  State<QuestApplicantsScreen> createState() => _QuestApplicantsScreenState();
}

class _QuestApplicantsScreenState extends State<QuestApplicantsScreen> {
  final Set<String> _loadingIds = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _appsStream() {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('questId', isEqualTo: widget.questId)
        .snapshots();
  }

  Future<void> _approve(BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> appDoc) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = appDoc.data()!;
    final applicantId = data['applicantId'];
    final applicantName = data['applicantName'];
    setState(() => _loadingIds.add(appDoc.id));
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final questRef =
            FirebaseFirestore.instance.collection('quests').doc(widget.questId);
        final appRef = appDoc.reference;
        final questSnap = await tx.get(questRef);
        if (!questSnap.exists) {
          throw Exception('Quest not found.');
        }
        final q = questSnap.data() as Map<String, dynamic>;
        final status = (q['status'] ?? 'open').toString();
        final alreadyAssigned =
            (q['assignedApplicantId'] ?? '').toString().isNotEmpty;
        if (status != 'open' || alreadyAssigned) {
          throw Exception('Quest already assigned or not open.');
        }
        tx.update(appRef, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
        tx.update(questRef, {
          'status': 'in_progress',
          'assignedApplicantId': applicantId,
          'assignedApplicantName': applicantName,
          'assignedAt': FieldValue.serverTimestamp(),
        });
      });

      // Reject other pending applications for this quest
      final others = await FirebaseFirestore.instance
          .collection('applications')
          .where('questId', isEqualTo: widget.questId)
          .where('status', isEqualTo: 'pending')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in others.docs) {
        if (d.id == appDoc.id) continue;
        batch.update(d.reference, {
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      messenger.showSnackBar(
        const SnackBar(content: Text('Applicant approved and quest assigned.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loadingIds.remove(appDoc.id));
    }
  }

  Future<void> _reject(BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> appDoc) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingIds.add(appDoc.id));
    try {
      await appDoc.reference.update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Applicant rejected.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to reject: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingIds.remove(appDoc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _AuthRequired();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _appsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          var docs = snap.data?.docs ?? [];
          // Sort by appliedAt desc if available
          docs.sort((a, b) {
            final ta = a.data()['appliedAt'];
            final tb = b.data()['appliedAt'];
            final ma = (ta is Timestamp) ? ta.millisecondsSinceEpoch : 0;
            final mb = (tb is Timestamp) ? tb.millisecondsSinceEpoch : 0;
            return mb.compareTo(ma);
          });
          if (docs.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final applicantName = d['applicantName'] ?? 'Applicant';
              final status = (d['status'] ?? 'pending').toString();
              final ts = d['appliedAt'];
              String when = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                when =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              }
              final busy = _loadingIds.contains(doc.id);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(applicantName),
                subtitle: Text(when.isEmpty
                    ? 'Status: ${status.toUpperCase()}'
                    : 'Applied: $when • Status: ${status.toUpperCase()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View profile',
                      onPressed: () =>
                          context.push('/user/${d['applicantId']}'),
                      icon: const Icon(Icons.person_outline),
                    ),
                    if (status == 'pending') ...[
                      TextButton(
                        onPressed: busy ? null : () => _reject(context, doc),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: busy ? null : () => _approve(context, doc),
                        child: busy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Approve'),
                      ),
                    ] else ...[
                      Text(status.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                onTap: () => context.go('/quest/${d['questId']}'),
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
