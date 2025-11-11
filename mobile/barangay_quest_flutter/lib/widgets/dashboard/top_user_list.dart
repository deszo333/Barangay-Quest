// lib/widgets/dashboard/top_user_list.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart' show UserModel;
import '../../theme/app_theme.dart';

// Enum to define the two modes
enum TopUserMode { questers, givers }

class TopUserList extends StatefulWidget {
  const TopUserList({super.key});

  @override
  State<TopUserList> createState() => _TopUserListState();
}

class _TopUserListState extends State<TopUserList> {
  // --- NEW: State variable to track the mode ---
  TopUserMode _mode = TopUserMode.questers;

  @override
  Widget build(BuildContext context) {
    final bool isQuesters = _mode == TopUserMode.questers;

    // --- NEW: Query is now built inside the build method ---
    // This ensures it re-runs when the state changes
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'approved')
        .orderBy(
          // It dynamically orders by the correct field
          isQuesters ? 'questsCompleted' : 'questsGivenCompleted',
          descending: true,
        )
        .limit(4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- NEW: Header with toggle buttons ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- Tappable Title ---
              InkWell(
                onTap: () => setState(() {
                  _mode = isQuesters ? TopUserMode.givers : TopUserMode.questers;
                }),
                child: Text(
                  // Title changes based on state
                  isQuesters ? 'Top Questers' : 'Top Givers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              
              // --- Toggle Buttons ---
              Row(
                children: [
                  // Left Arrow
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _mode = TopUserMode.questers;
                    }),
                    color: isQuesters ? AppTheme.accent : AppTheme.muted,
                  ),
                  // Right Arrow
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _mode = TopUserMode.givers;
                    }),
                    color: !isQuesters ? AppTheme.accent : AppTheme.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // --- Horizontal List ---
        SizedBox(
          height: 120, // Height for the cards
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text(
                  isQuesters ? 'No top questers yet.' : 'No top givers yet.'
                ));
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (c, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final userDoc = snapshot.data!.docs[index];
                  final user = UserModel.fromDoc(userDoc);
                  
                  // --- Pass the correct stat to the card ---
                  final int statCount = (isQuesters
                      ? user.questsCompleted
                      : user.questsGivenCompleted);
                      
                  return _UserCard(user: user, statCount: statCount);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.statCount});
  final UserModel user;
  final int statCount; // Now accepts the stat

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/user/${user.uid}'),
      child: SizedBox(
        width: 80, // Width for each item
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  (user.avatarUrl != null) ? NetworkImage(user.avatarUrl!) : null,
              child: (user.avatarUrl == null)
                  ? Text(user.name.isNotEmpty ? user.name[0] : 'U')
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              user.name,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // --- NEW: Show the dynamic stat count ---
            Text(
              '$statCount quests',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}