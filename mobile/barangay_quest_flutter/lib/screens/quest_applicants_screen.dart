// lib/screens/quest_applicants_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart' show AuthService, UserModel;

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

  // ====================================================================
  // THE NEW ESCROW "HIRE" LOGIC
  // ====================================================================
  Future<void> _approve(BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> appDoc) async {
    
    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<AuthService>();
    final UserModel? giver = authService.firestoreUser;

    if (giver == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Error: Giver profile not found.')));
      return;
    }

    final data = appDoc.data()!;
    final applicantId = data['applicantId'];
    final applicantName = data['applicantName'];

    setState(() => _loadingIds.add(appDoc.id));

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final questRef =
            FirebaseFirestore.instance.collection('quests').doc(widget.questId);
        final appRef = appDoc.reference;
        final giverRef = 
            FirebaseFirestore.instance.collection('users').doc(giver.uid);

        // 1. --- READS FIRST ---
        final questSnap = await tx.get(questRef);
        final giverSnap = await tx.get(giverRef); // Giver snap already read by AuthService, but good to get in TX

        if (!questSnap.exists) throw Exception('Quest not found.');
        if (!giverSnap.exists) throw Exception('Your user profile not found.');


        final questData = questSnap.data()!;
        final giverData = giverSnap.data()!;
        final priceAmount = (questData['price'] ?? 0) as num;

        // 2. --- VALIDATION ---
        if ((giverData['walletBalance'] ?? 0) < priceAmount) {
          throw Exception('Insufficient funds. Please add credits to your profile.');
        }
        if (questData['status'] != 'open') {
          throw Exception('Quest is not open for hiring.');
        }

        // 3. --- WRITES LAST ---
        // Deduct from giver's wallet
        tx.update(giverRef, {
          'walletBalance': FieldValue.increment(-priceAmount),
        });

        // Update quest to 'in-progress' and store escrow amount
        tx.update(questRef, {
          'status': 'in-progress',
          'hiredApplicantId': applicantId,
          'hiredApplicantName': applicantName,
          'escrowAmount': priceAmount, // <-- CRITICAL: Store the escrow amount
          'assignedAt': FieldValue.serverTimestamp(),
        });

        // Update application to 'hired'
        tx.update(appRef, {
          'status': 'hired',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      });

      // After transaction, reject other pending applications for this quest
      final others = await FirebaseFirestore.instance
          .collection('applications')
          .where('questId', isEqualTo: widget.questId)
          .where('status', isEqualTo: 'pending')
          .get();
          
      final batch = FirebaseFirestore.instance.batch();
      for (final d in others.docs) {
        // No need to check ID, the hired one is no longer 'pending'
        batch.update(d.reference, {
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      messenger.showSnackBar(
        const SnackBar(content: Text('Applicant hired! Funds are in escrow.')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
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
          
          // Sort by status ('pending' first), then by date
          docs.sort((a, b) {
            final statusA = (a.data()['status'] ?? 'z');
            final statusB = (b.data()['status'] ?? 'z');
            if (statusA == 'pending' && statusB != 'pending') return -1;
            if (statusA != 'pending' && statusB == 'pending') return 1;

            final ta = a.data()['appliedAt'];
            final tb = b.data()['appliedAt'];
            final ma = (ta is Timestamp) ? ta.millisecondsSinceEpoch : 0;
            final mb = (tb is Timestamp) ? tb.millisecondsSinceEpoch : 0;
            return mb.compareTo(ma); // Newest first
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
              final status = (d['status'] ?? 'pending').toString();
              final applicantId = d['applicantId'] ?? '';
              final applicantName = d['applicantName'] ?? 'Applicant';
              final busy = _loadingIds.contains(doc.id);
              
              // Use the new ApplicantListTile
              return ApplicantListTile(
                applicantId: applicantId,
                applicantName: applicantName,
                status: status,
                isBusy: busy,
                onViewProfile: () => context.push('/user/$applicantId'),
                onReject: () => _reject(context, doc),
                onApprove: () => _approve(context, doc),
              );
            },
          );
        },
      ),
    );
  }
}

// ====================================================================
// NEW WIDGET: ApplicantListTile (like React's ApplicantItem)
// Fetches the applicant's profile to show their avatar and rating
// ====================================================================
class ApplicantListTile extends StatefulWidget {
  final String applicantId;
  final String applicantName;
  final String status;
  final bool isBusy;
  final VoidCallback onViewProfile;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const ApplicantListTile({
    super.key,
    required this.applicantId,
    required this.applicantName,
    required this.status,
    required this.isBusy,
    required this.onViewProfile,
    required this.onReject,
    required this.onApprove,
  });

  @override
  State<ApplicantListTile> createState() => _ApplicantListTileState();
}

class _ApplicantListTileState extends State<ApplicantListTile> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userFuture;

  @override
  void initState() {
    super.initState();
    if (widget.applicantId.isNotEmpty) {
      _userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.applicantId)
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        String avatarChar = widget.applicantName.isNotEmpty ? widget.applicantName[0] : 'A';
        String? avatarUrl;
        String ratingText = '...';

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data()!;
          avatarUrl = userData['avatarUrl'];
          avatarChar = (userData['name'] ?? 'A')[0];

          final ratingsCount = (userData['numberOfRatings'] ?? 0) as int;
          final ratingsSum = (userData['totalRatingScore'] ?? 0) as num;
          final avg = ratingsCount > 0 ? (ratingsSum / ratingsCount) : 0.0;
          ratingText = ratingsCount > 0 ? '${avg.toStringAsFixed(1)} ($ratingsCount)' : 'No ratings';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null) ? Text(avatarChar) : null,
          ),
          title: Text(widget.applicantName),
          subtitle: Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 16),
              const SizedBox(width: 4),
              Text(ratingText, style: TextStyle(fontSize: 12)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'View profile',
                onPressed: widget.isBusy ? null : widget.onViewProfile,
                icon: const Icon(Icons.person_outline),
              ),
              if (widget.status == 'pending') ...[
                TextButton(
                  onPressed: widget.isBusy ? null : widget.onReject,
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: widget.isBusy ? null : widget.onApprove,
                  child: widget.isBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Hire'), // Renamed from 'Approve'
                ),
              ] else ...[
                Text(widget.status.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        );
      },
    );
  }
}