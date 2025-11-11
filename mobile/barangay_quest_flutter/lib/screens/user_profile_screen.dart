// lib/screens/user_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/star_rating.dart';
import '../theme/app_theme.dart'; // <-- IMPORTED APP THEME

class UserProfileScreen extends StatelessWidget {
  final String userId;
  UserProfileScreen({super.key, required this.userId}) {
    debugPrint('[UserProfileScreen] CONSTRUCTOR userId: $userId');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDoc() =>
      FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

  // --- RENAMED ---
  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsAsQuester() =>
      FirebaseFirestore.instance
          .collection('applications')
          .where('applicantId', isEqualTo: userId)
          .where('giverRated', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .snapshots();

  // --- NEW: Reviews as Giver ---
  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsAsGiver() =>
      FirebaseFirestore.instance
          .collection('applications')
          .where('questGiverId', isEqualTo: userId)
          .where('questerRated', isEqualTo: true)
          .orderBy('appliedAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    debugPrint('[UserProfileScreen] BUILD userId: $userId');
    final textTheme = Theme.of(context).textTheme; // <-- Get textTheme
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDoc(),
        builder: (context, userSnap) {
          debugPrint(
              '[UserProfileScreen] SNAPSHOT state: ${userSnap.connectionState} hasData: ${userSnap.hasData} hasError: ${userSnap.hasError}');
          if (userSnap.hasError) {
            debugPrint('[UserProfileScreen] ERROR: ${userSnap.error}');
          }
          if (userSnap.hasData) {
            debugPrint('[UserProfileScreen] DATA: ${userSnap.data}');
          }
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${userSnap.error}'),
              ),
            );
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            debugPrint('[UserProfileScreen] NO USER DATA for userId: $userId');
            return const Center(child: Text('User profile not found.'));
          }
          final snap = userSnap.data;
          final userData =
              (snap != null ? snap.data() : null) ?? <String, dynamic>{};
          debugPrint('[UserProfileScreen] USER DATA MAP: $userData');

          final name = (userData['name'] ?? 'User').toString();
          final photo = userData['avatarUrl'];

          final ratingsCount = (userData['numberOfRatings'] ?? 0) as int;
          final ratingsSum = (userData['totalRatingScore'] ?? 0) as num;

          final avg = ratingsCount > 0 ? (ratingsSum / ratingsCount) : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: (photo is String && photo.isNotEmpty)
                        ? NetworkImage(photo)
                        : null,
                    child: (photo is String && photo.isNotEmpty)
                        ? null
                        : Text(name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),

                        // --- START: STATS PATCH ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StarRating(
                                  value: avg.round(),
                                  readOnly: true,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ratingsCount > 0
                                      ? '${avg.toStringAsFixed(1)} ($ratingsCount Ratings)'
                                      : 'No ratings yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Quests Done: ${userData['questsCompleted'] ?? 0}',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Quests Posted: ${userData['questsPosted'] ?? 0}',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // --- END: STATS PATCH ---
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Added space before reviews
              // --- START OF NEW REVIEW SECTION ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24), // Added divider
                  Text(
                    'Reviews as Quester', // <-- New Title
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _reviewsAsQuester(), // <-- Use first stream
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator()));
                      }
                      if (snap.hasError) {
                        return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child:
                                Text('Failed to load reviews: ${snap.error}'));
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('No reviews as a quester yet.'));
                      }
                      // --- START: HORIZONTAL LIST PATCH ---
                      return SizedBox(
                        height: 160, // Give the list a fixed height
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final d = docs[index];
                            final r = d.data();
                            return SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.8, // Each card takes 80% width
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: 12.0,
                                    bottom: 4.0,
                                    top: 4.0), // Spacing
                                child: _ReviewCard(
                                  questTitle:
                                      (r['questTitle'] ?? 'Quest').toString(),
                                  review: (r['review'] ?? '')
                                      .toString(), // This is the GIVER'S review
                                  rating: (r['giverRating'] ?? 0) as int,
                                  timestamp: r['approvedAt'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                      // --- END: HORIZONTAL LIST PATCH ---
                    },
                  ),

                  const SizedBox(height: 24), // Spacer

                  Text(
                    'Reviews as Giver', // <-- New Title
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _reviewsAsGiver(), // <-- Use second stream
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator()));
                      }
                      if (snap.hasError) {
                        return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child:
                                Text('Failed to load reviews: ${snap.error}'));
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('No reviews as a giver yet.'));
                      }
                      // --- START: HORIZONTAL LIST PATCH ---
                      return SizedBox(
                        height: 160, // Give the list a fixed height
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final d = docs[index];
                            final r = d.data();
                            return SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.8, // Each card takes 80% width
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: 12.0,
                                    bottom: 4.0,
                                    top: 4.0), // Spacing
                                child: _ReviewCard(
                                  questTitle:
                                      (r['questTitle'] ?? 'Quest').toString(),
                                  review: (r['questerReview'] ?? '')
                                      .toString(), // This is the QUESTER'S review
                                  rating: (r['questerRating'] ?? 0) as int,
                                  timestamp: r['appliedAt'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                      // --- END: HORIZONTAL LIST PATCH ---
                    },
                  ),
                ],
              )
              // --- END OF NEW REVIEW SECTION ---
            ],
          );
        },
      ),
    );
  }
}

// --- ADD THIS NEW WIDGET ---
class _ReviewCard extends StatelessWidget {
  final String questTitle;
  final String review;
  final int rating;
  final Timestamp? timestamp;

  const _ReviewCard({
    required this.questTitle,
    required this.review,
    required this.rating,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    String when = '';
    if (timestamp is Timestamp) {
      final dt = timestamp!.toDate();
      when =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRating(value: rating, readOnly: true, size: 18),
                const SizedBox(width: 8),
                Text(when,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey)),
                const Spacer(),
                Expanded(
                  child: Text(
                    questTitle,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review,
                style: TextStyle(color: AppTheme.muted), // <-- USE THEME COLOR
                maxLines: 3, // <-- Limit review lines
                overflow: TextOverflow.ellipsis, // <-- Add ellipsis
              ),
            ],
          ],
        ),
      ),
    );
  }
}