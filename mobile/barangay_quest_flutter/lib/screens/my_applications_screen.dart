// lib/screens/my_applications_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/star_rating.dart'; // Import StarRating
import '../widgets/ui/status_chip.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _loadingIds = {};
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Pending'),
    Tab(text: 'Hired'),
    Tab(text: 'Completed'),
    Tab(text: 'Rejected'),
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

  Future<void> _submitGiverReview({
    required BuildContext context,
    required DocumentSnapshot<Map<String, dynamic>> appDoc,
    required int rating,
    required String review, // --- ADD THIS ---
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final appData = appDoc.data();
    if (appData == null) return;

    final String giverId = appData['questGiverId'] ?? '';
    if (giverId.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Error: Giver ID not found.')));
      return;
    }

    setState(() => _loadingIds.add(appDoc.id));

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final giverRef = FirebaseFirestore.instance.collection('users').doc(giverId);
        final applicationRef = appDoc.reference;

        tx.update(giverRef, {
          'totalRatingScore': FieldValue.increment(rating),
          'numberOfRatings': FieldValue.increment(1),
        });

        // --- UPDATE THIS ---
        tx.update(applicationRef, {
          'questerRating': rating,
          'questerRated': true,
          'questerReview': review, // Save the review text
        });
        // --- END UPDATE ---
      });
      messenger.showSnackBar(const SnackBar(content: Text('Review submitted!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loadingIds.remove(appDoc.id));
    }
  }

  void _openGiverRatingSheet(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> appDoc) {
    int rating = 0;
    // --- ADD THIS ---
    final reviewController = TextEditingController();
    // --- END ADD ---

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
                  const Text('Rate the Quest Giver',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  StarRating(
                    value: rating,
                    onChanged: (v) => setState(() => rating = v),
                  ),
                  const SizedBox(height: 16), // --- ADDED SIZEDBOX ---

                  // --- ADD THIS TEXTFIELD ---
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Write a review (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  // --- END ADD ---

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
                                await _submitGiverReview(
                                  context: context,
                                  appDoc: appDoc,
                                  rating: rating,
                                  // --- ADD THIS ---
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


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _AuthRequired();
    }
    
    final stream = FirebaseFirestore.instance
        .collection('applications')
        .where('applicantId', isEqualTo: user.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        // --- FIX: Remove back button from a main tab ---
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
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
            return const Center(child: Text('No applications yet.'));
          }

          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final String currentTab = _tabs[_tabController.index].text!.toLowerCase();
              
              final List<DocumentSnapshot<Map<String, dynamic>>> filteredDocs;
              if (currentTab == 'all') {
                filteredDocs = allDocs;
              } else {
                filteredDocs = allDocs.where((doc) {
                  final status = (doc.data()['status'] ?? 'pending').toString();
                  return status == currentTab;
                }).toList();
              }

              if (filteredDocs.isEmpty) {
                return Center(child: Text('No applications found for "$currentTab".'));
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, i) {
                  final doc = filteredDocs[i];
                  final d = doc.data()!;
                  final status = (d['status'] ?? 'pending').toString();
                  final bool questerRated = d['questerRated'] ?? false;
                  final bool isLoading = _loadingIds.contains(doc.id);

                  List<Widget> trailingWidgets = [];
                  if (status == 'completed' && !questerRated) {
                    trailingWidgets.add(FilledButton(
                      onPressed: isLoading ? null : () => _openGiverRatingSheet(context, doc),
                      child: isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Rate Giver'),
                    ));
                  }
                  if (status == 'completed' && questerRated) {
                    trailingWidgets.add(const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('Rated ✓', style: TextStyle(fontWeight: FontWeight.w600)),
                    ));
                  }
                  trailingWidgets.add(const SizedBox(width: 8));
                  trailingWidgets.add(TextButton(
                    onPressed: () => context.push('/quest/${d['questId']}'),
                    child: const Text('View'),
                  ));

                  return ListTile(
                    title: Text(d['questTitle'] ?? 'Quest'),
                    subtitle: StatusChip(status: status),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: trailingWidgets,
                    ),
                  );
                },
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
                onPressed: () => context.push('/login'),
                child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}