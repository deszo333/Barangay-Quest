// lib/screens/my_quests_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart' show AuthService;
import '../widgets/star_rating.dart';
// import '../theme/app_theme.dart';
import '../widgets/ui/status_chip.dart';

class MyQuestsScreen extends StatefulWidget {
  const MyQuestsScreen({super.key});

  @override
  State<MyQuestsScreen> createState() => _MyQuestsScreenState();
}

class _MyQuestsScreenState extends State<MyQuestsScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _loadingIds = {};
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'Active'),
    Tab(text: 'Completed'),
    Tab(text: 'Archived'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markCompleteAndPay(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> questDoc) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AuthService>().firebaseUser;
    if (user == null) return;

    final questId = questDoc.id;
    final questData = questDoc.data();
    if (questData == null) return;

    final String hiredApplicantId = questData['hiredApplicantId'] ?? '';
    final num escrowAmount = (questData['escrowAmount'] ?? 0) as num;

    if (hiredApplicantId.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Error: No quester was hired.')));
      return;
    }

    setState(() => _loadingIds.add(questId));

    try {
      final appQuery = await FirebaseFirestore.instance
          .collection('applications')
          .where('questId', isEqualTo: questId)
          .where('applicantId', isEqualTo: hiredApplicantId)
          .where('status', isEqualTo: 'hired')
          .limit(1)
          .get();

      final DocumentReference? appRef =
          appQuery.docs.isNotEmpty ? appQuery.docs.first.reference : null;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final questRef = FirebaseFirestore.instance.collection('quests').doc(questId);
        final giverRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final questerRef =
            FirebaseFirestore.instance.collection('users').doc(hiredApplicantId);

        final questSnap = await tx.get(questRef);
        final questerSnap = await tx.get(questerRef);

        if (!questSnap.exists || questSnap.data()?['status'] != 'in-progress') {
          throw Exception('Quest is not in progress or does not exist.');
        }
        if (!questerSnap.exists) {
          throw Exception('Quester profile not found!');
        }

        tx.update(questerRef, {
          'walletBalance': FieldValue.increment(escrowAmount),
          'questsCompleted': FieldValue.increment(1),
        });
        tx.update(giverRef, {
          'questsGivenCompleted': FieldValue.increment(1),
        });
        tx.update(questRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'escrowAmount': 0,
          'hiredApplicationId': appRef?.id, 
        });
        if (appRef != null) {
          tx.update(appRef, {'status': 'completed'});
        }
      });

      messenger.showSnackBar(const SnackBar(
        content: Text('Quest marked complete and Quester has been paid!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loadingIds.remove(questId));
    }
  }

  Future<void> _cancelAndRefund(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> questDoc) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AuthService>().firebaseUser;
    if (user == null) return;

    final bool didConfirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel & Refund Quest?'),
            content: const Text(
                'This will cancel the hire, return the escrowed funds to your wallet, and set the quest back to "open". The quester will be notified.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Nevermind'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red[800]),
                child: const Text('Cancel & Refund'),
              ),
            ],
          ),
        ) ?? false;

    if (!didConfirm || !mounted) return;

    final questId = questDoc.id;
    final questData = questDoc.data();
    if (questData == null) return;

    final String hiredApplicantId = questData['hiredApplicantId'] ?? '';
    final num escrowAmount = (questData['escrowAmount'] ?? 0) as num;

    setState(() => _loadingIds.add(questId));

    try {
      final appQuery = await FirebaseFirestore.instance
          .collection('applications')
          .where('questId', isEqualTo: questId)
          .where('applicantId', isEqualTo: hiredApplicantId)
          .where('status', isEqualTo: 'hired')
          .limit(1)
          .get();

      final DocumentReference? appRef =
          appQuery.docs.isNotEmpty ? appQuery.docs.first.reference : null;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final questRef = FirebaseFirestore.instance.collection('quests').doc(questId);
        final giverRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final questSnap = await tx.get(questRef);
        if (!questSnap.exists || questSnap.data()?['status'] != 'in-progress') {
          throw Exception('Quest is not in progress.');
        }

        tx.update(giverRef, {
          'walletBalance': FieldValue.increment(escrowAmount),
        });
        tx.update(questRef, {
          'status': 'open', 
          'hiredApplicantId': null,
          'hiredApplicantName': null,
          'escrowAmount': 0,
          'assignedAt': null,
        });
        if (appRef != null) {
          tx.update(appRef, {'status': 'rejected'});
        }
      });

      messenger.showSnackBar(const SnackBar(
        content: Text('Quest cancelled and funds refunded.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loadingIds.remove(questId));
    }
  }

  Future<void> _togglePause(String questId, String currentStatus) async {
    final newStatus = currentStatus == 'open' ? 'paused' : 'open';
    setState(() => _loadingIds.add(questId));
    try {
      await FirebaseFirestore.instance
          .collection('quests')
          .doc(questId)
          .update({'status': newStatus});
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _loadingIds.remove(questId));
    }
  }

  Future<void> _deleteQuest(String questId) async {
    final bool didConfirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Quest?'),
            content: const Text('Are you sure you want to permanently delete this quest? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red[800]),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
    
    if (!didConfirm || !mounted) return;

    setState(() => _loadingIds.add(questId));
    try {
      await FirebaseFirestore.instance.collection('quests').doc(questId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quest deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loadingIds.remove(questId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().firebaseUser;
    if (user == null) {
      return const _AuthRequired();
    }
    final stream = FirebaseFirestore.instance
        .collection('quests')
        .where('questGiverId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quests'),
        // --- FIX: Remove back button from a main tab ---
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final allDocs = snap.data?.docs ?? [];
          if (allDocs.isEmpty) {
            return const Center(child: Text('No quests posted yet.'));
          }
          
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final String currentTab = _tabs[_tabController.index].text!.toLowerCase();
              
              final List<DocumentSnapshot<Map<String, dynamic>>> filteredDocs;
              
              if (currentTab == 'active') {
                filteredDocs = allDocs.where((doc) {
                  final status = (doc.data()['status'] ?? 'open').toString();
                  // --- FIX: "Paused" should not be in "Active" ---
                  return status == 'open' || status == 'in-progress';
                }).toList();
              } else if (currentTab == 'completed') {
                 filteredDocs = allDocs.where((doc) {
                  final status = (doc.data()['status'] ?? 'open').toString();
                  return status == 'completed';
                }).toList();
              } else { // Archived
                 filteredDocs = allDocs.where((doc) {
                  final status = (doc.data()['status'] ?? 'open').toString();
                  // --- FIX: Show 'paused' quests in 'Archived' tab ---
                  return status == 'archived' || status == 'paused';
                }).toList();
              }
              
              if (filteredDocs.isEmpty) {
                return Center(child: Text('No quests found for "$currentTab".'));
              }
              
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filteredDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = filteredDocs[i];
                  final d = doc.data()!;
                  final status = (d['status'] ?? 'open').toString();
                  final bool isLoading = _loadingIds.contains(doc.id);
                  final String? hiredApplicationId = d['hiredApplicationId'];
                  // --- FIX: Get the applicant count ---
                  final int appCount = (d['applicantCount'] ?? 0) as int;
                  final String buttonText = '$appCount Applicant${appCount == 1 ? '' : 's'}';
                  // --- END FIX ---

                  return ListTile(
                    title: Text(d['title'] ?? 'Quest'),
                    subtitle: StatusChip(status: status), 
                    onTap: () => context.push('/quest/${doc.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == 'open')
                          TextButton(
                            onPressed: () => context.push('/quest/${doc.id}/applicants'),
                            // --- FIX: Use the dynamic button text ---
                            child: Text(buttonText),
                          ),
                        if (status == 'in-progress')
                          FilledButton(
                            onPressed: isLoading ? null : () => _markCompleteAndPay(context, doc),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4ADE80), foregroundColor: Colors.black),
                            child: isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Confirm & Pay'),
                          ),

                        if (status == 'completed')
                          Builder(builder: (context) {
                            final bool giverRated = d['giverRated'] ?? false; 
                            if (giverRated) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text('Rated ✓',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }
                            return FilledButton(
                              onPressed: () => _openRatingSheet(context, doc, hiredApplicationId),
                              child: const Text('Rate'),
                            );
                          }),
                        
                        if (status == 'open' || status == 'paused' || status == 'in-progress')
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'pause') {
                              _togglePause(doc.id, status);
                            } else if (value == 'delete') {
                              _deleteQuest(doc.id);
                            } else if (value == 'cancel') {
                              _cancelAndRefund(context, doc);
                            }
                          },
                          itemBuilder: (context) => [
                            if (status == 'open' || status == 'paused')
                              PopupMenuItem(
                                value: 'pause',
                                child: Text(status == 'open' ? 'Pause Quest' : 'Unpause Quest'),
                              ),
                            
                            if (status == 'open' || status == 'paused')
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Quest', style: TextStyle(color: Colors.red)),
                              ),
                            
                            if (status == 'in-progress')
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancel & Refund', style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),

                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // --- FIX: Add FAB to a tabbed screen ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post-job'), // Use push
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ... (rest of _submitOwnerReview, _openRatingSheet, _StatusChip, _AuthRequired) ...
// (These helpers are unchanged from the previous step)
// ...

// --- Standardized Rating Logic (from previous step) ---
Future<void> _submitOwnerReview({
  required BuildContext context,
  required DocumentSnapshot<Map<String, dynamic>> questDoc,
  required String? hiredApplicationId, 
  required int rating,
  required String review,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Not signed in.')));
    return;
  }
  
  final q = questDoc.data()!;
  final applicantId = (q['hiredApplicantId'] ?? '').toString();
  
  if (applicantId.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Error: No applicant ID found.')));
    return;
  }
  if (hiredApplicationId == null || hiredApplicationId.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Error: No application ID found.')));
    return;
  }

  try {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final applicantRef = FirebaseFirestore.instance.collection('users').doc(applicantId);
      final applicationRef = FirebaseFirestore.instance.collection('applications').doc(hiredApplicationId);
      
      tx.update(applicantRef, {
        'totalRatingScore': FieldValue.increment(rating),
        'numberOfRatings': FieldValue.increment(1),
      });
      tx.update(applicationRef, {
        'giverRating': rating,
        'giverRated': true,
        'review': review,
      });
      tx.update(questDoc.reference, {
        'giverRated': true, 
      });
    });
    messenger.showSnackBar(const SnackBar(content: Text('Review submitted!')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
  }
}

void _openRatingSheet(
    BuildContext context, DocumentSnapshot<Map<String, dynamic>> questDoc, String? hiredApplicationId) {
  
  if (hiredApplicationId == null) {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Cannot find application to rate.')));
     return;
  }

  int rating = 0;
  final reviewController = TextEditingController();
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
                const SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Write a review (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
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
                                hiredApplicationId: hiredApplicationId, 
                                rating: rating,
                                review: reviewController.text.trim(),
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
                onPressed: () => context.push('/login'),
                child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}