// lib/widgets/quest_card.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quest.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart'; // Import for number formatting

// --- Helper Functions (moved from inside build) ---

String _formatBudget(Quest quest) {
  final format =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  final amount = quest.price;
  if (quest.priceType == 'Hourly Rate') {
    return '${format.format(amount)} / hr';
  }
  return '${format.format(amount)} (${quest.priceType})';
}

String _formatWhen(Quest quest) {
  final ts = quest.createdAt;
  if (ts == null) {
    return 'Just now';
  }
  final dt = ts.toDate();
  final duration = DateTime.now().difference(dt);

  if (duration.inSeconds < 60) {
    return 'Just now';
  }
  if (duration.inMinutes < 60) {
    return '${duration.inMinutes}m ago';
  }
  if (duration.inHours < 24) {
    return '${duration.inHours}h ago';
  }
  final days = duration.inDays;
  return '$days day${days == 1 ? '' : 's'} ago';
}

Widget _statusPill(BuildContext context, Quest quest) {
  final status = quest.status.toLowerCase().replaceAll('_', '-');
  Color bg;
  Color fg;
  switch (status) {
    case 'open':
      bg = const Color(0x1A38BDF8);
      fg = const Color(0xFF38BDF8);
      break;
    case 'in-progress':
      bg = const Color(0x1AFACC15);
      fg = const Color(0xFFFACC15);
      break;
    case 'completed':
      bg = const Color(0x1A4ADE80);
      fg = const Color(0xFF4ADE80);
      break;
    case 'paused':
      bg = const Color(0x1A64748B);
      fg = const Color(0xFF64748B);
      break;
    case 'rejected':
      bg = const Color(0x1AF87171);
      fg = const Color(0xFFF87171);
      break;
    default:
      bg = const Color(0xFF1F2A36);
      fg = const Color(0xFFBFE7FF);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: fg.withAlpha((0.2 * 255).round())),
    ),
    child: Text(
      status,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: fg, fontWeight: FontWeight.w600),
    ),
  );
}

// --- Card is now a StatefulWidget ---
class QuestCard extends StatefulWidget {
  final Quest quest;
  final VoidCallback? onTap;

  const QuestCard({super.key, required this.quest, this.onTap});

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  String _avgRating = 'N/A';
  int _reviewCount = 0;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    // Fetch the rating data when the card is first created
    _fetchGiverData();
  }

  // --- THIS IS THE LOGIC YOU REQUESTED ---
  Future<void> _fetchGiverData() async {
    // Don't try to fetch if the ID is missing
    if (widget.quest.questGiverId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
      return;
    }

    try {
      // 1. Get the quester ID from the quest
      final giverId = widget.quest.questGiverId;

      // 2. Find its user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(giverId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;

        // 3. Get its star rating
        final num totalScore = data['totalRatingScore'] ?? 0;
        final int numRatings = data['numberOfRatings'] ?? 0;

        if (mounted) {
          // Check if the widget is still in the tree
          setState(() {
            _reviewCount = numRatings;
            if (numRatings > 0) {
              _avgRating = (totalScore / numRatings).toStringAsFixed(1);
            } else {
              _avgRating = 'New';
            }
            _isLoadingRating = false;
          });
        }
      } else {
        // User document not found
        if (mounted) {
          setState(() {
            _isLoadingRating = false;
            _avgRating = 'N/A';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching giver rating: $e');
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
          _avgRating = 'N/A';
        });
      }
    }
  }
  // --- END OF REQUESTED LOGIC ---

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quest = widget.quest; // Use 'widget.quest' to access the quest

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          // Guest view
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to see details',
                    style: textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          );
        }

        // --- Logged-in view ---
        
        // Use the state variables for rating
        final ratingText = _isLoadingRating ? '...' : _avgRating;
        final reviewCountText = _isLoadingRating ? '' : '($_reviewCount)';

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _statusPill(context, quest),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E2230),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: const Color(0xFF274A60)),
                                    ),
                                    child: Text(
                                      quest.workType == 'Online'
                                          ? 'Online'
                                          : (quest.location?['address'] ??
                                              'In Person'),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFFBFE7FF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (quest.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            quest.imageUrl!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              width: 84,
                              height: 84,
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DefaultTextStyle(
                    style: textTheme.bodySmall!
                        .copyWith(color: AppTheme.muted, height: 1.2),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFD166), size: 16),
                        const SizedBox(width: 4),
                        Text(ratingText), // <-- USE THE STATE VARIABLE
                        const SizedBox(width: 2),
                        Text(reviewCountText), // <-- USE THE STATE VARIABLE
                        const SizedBox(width: 8),
                        const Text('•'),
                        const SizedBox(width: 8),
                        Text(_formatWhen(quest)),
                        const SizedBox(width: 8),
                        const Text('•'),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'by ${quest.questGiverName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatBudget(quest),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onTap,
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}