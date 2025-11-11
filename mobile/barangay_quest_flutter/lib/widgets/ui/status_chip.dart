// lib/widgets/ui/status_chip.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cleanStatus = status.toLowerCase().replaceAll(' ', '-');
    Color bg;
    Color fg;
    String text = status[0].toUpperCase() + status.substring(1);

    switch (cleanStatus) {
      case 'pending':
        bg = const Color(0x1AFBBF24); fg = const Color(0xFFFBBF24); break;
      case 'hired':
        bg = const Color(0x1A4ADE80); fg = const Color(0xFF4ADE80); break;
      case 'completed':
        bg = const Color(0x1A4ADE80); fg = const Color(0xFF4ADE80); break;
      case 'awaiting-confirmation':
        bg = const Color(0x1A60A5FA); fg = const Color(0xFF60A5FA); text = 'Awaiting Confirmation'; break;
      case 'rejected':
        bg = const Color(0x1AF87171); fg = const Color(0xFFF87171); break;
      case 'paused':
        bg = const Color(0x1A64748B); fg = const Color(0xFF64748B); break;
      case 'in-progress':
        bg = const Color(0x1AFACC15); fg = const Color(0xFFFACC15); text = 'In Progress'; break;
      case 'open':
        bg = const Color(0x1A38BDF8); fg = const Color(0xFF38BDF8); break;
      default:
        bg = AppTheme.card; fg = AppTheme.muted; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withAlpha((0.2 * 255).round())),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
