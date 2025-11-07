import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/star_rating.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDoc() =>
      FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviews() =>
      FirebaseFirestore.instance
          .collection('reviews')
          .where('applicantId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
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
          final snap = userSnap.data;
          final userData =
              (snap != null ? snap.data() : null) ?? <String, dynamic>{};
          final name = (userData['displayName'] ?? userData['name'] ?? 'User')
              .toString();
          final photo = userData['photoURL'];
          final ratingsCount = (userData['ratingsCount'] ?? 0) as int;
          final ratingsSum = (userData['ratingsSum'] ?? 0) as int;
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
                                  ? '${avg.toStringAsFixed(1)} (${ratingsCount})'
                                  : 'No ratings yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Reviews',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _reviews(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('Failed to load reviews: ${snap.error}'),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('No reviews yet.'),
                    );
                  }
                  return Column(
                    children: docs.map((d) {
                      final r = d.data();
                      final rating = (r['rating'] ?? 0) as int;
                      final comment = (r['comment'] ?? '').toString();
                      final owner = (r['ownerEmail'] ?? 'Client').toString();
                      final createdAt = r['createdAt'];
                      String when = '';
                      if (createdAt is Timestamp) {
                        final dt = createdAt.toDate();
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
                                  StarRating(
                                      value: rating, readOnly: true, size: 18),
                                  const SizedBox(width: 8),
                                  Text(when,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey)),
                                  const Spacer(),
                                  Text(owner,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(comment),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }
}
