import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../theme/app_theme.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onTap;

  const QuestCard({super.key, required this.quest, this.onTap});

  String _formatBudget() {
    final amount = quest.budgetAmount.toString();
    if (quest.budgetType == 'Hourly Rate') return '₱$amount / hr';
    return '₱$amount (Fixed)';
  }

  String _formatWhen() {
    final ts = quest.createdAt;
    if (ts == null) return 'Just now';
    final dt = ts.toDate();
    final seconds = DateTime.now().difference(dt).inSeconds;
    if (seconds < 60) return 'Just now';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes min ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hr ago';
    final days = hours ~/ 24;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  Widget _statusPill(BuildContext context) {
    final status = quest.status.toLowerCase();
    Color bg;
    Color fg;
    switch (status) {
      case 'open':
        bg = const Color(0xFF0F2A1E);
        fg = const Color(0xFF99E2B4);
        break;
      case 'in_progress':
      case 'in-progress':
        bg = const Color(0xFF1D2433);
        fg = const Color(0xFF9DB2FF);
        break;
      case 'completed':
        bg = const Color(0xFF2A2A2A);
        fg = const Color(0xFFBDBDBD);
        break;
      case 'cancelled':
      case 'rejected':
        bg = const Color(0xFF2A1417);
        fg = const Color(0xFFFFA3A3);
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
        border: Border.all(color: bg.withOpacity(0.6)),
      ),
      child: Text(
        status.replaceAll('_', '-'),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          // Guest view: only show the title; hide meta, image, price and actions.
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
                  // Intentionally no button here to avoid redundant CTAs.
                ],
              ),
            ),
          );
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
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
                                _statusPill(context),
                                const SizedBox(width: 8),
                                Container(
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
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                        const Text('N/A'),
                        const SizedBox(width: 2),
                        const Text('(0)'),
                        const SizedBox(width: 8),
                        const Text('•'),
                        const SizedBox(width: 8),
                        Text(_formatWhen()),
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
                      Text(
                        _formatBudget(),
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: onTap,
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
