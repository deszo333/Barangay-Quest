// lib/widgets/dashboard/category_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Make sure you added this package
import '../../theme/app_theme.dart';

// --- Placeholder Icon SVGs ---
// You should replace these with your own .svg files in an 'assets' folder
const String _devIcon = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"></polyline><polyline points="8 6 2 12 8 18"></polyline></svg>
''';

const String _designIcon = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"></path><path d="M4 14H.75"></path><path d="M12 4H.75"></path><path d="M22 12c-3 0-8 0-14 0"></path><path d="M6 18c-2 0-3-1-3-3v-6c0-2 1-3 3-3"></path><path d="M18 6c2 0 3 1 3 3v6c0 2-1 3-3 3"></path></svg>
''';

// --- End Placeholder Icons ---


class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    // You can make this list dynamic from Firestore later
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'Development',
            svgIcon: _devIcon,
            color: Colors.redAccent,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _CategoryChip(
            label: 'Design',
            svgIcon: _designIcon,
            color: Colors.blueAccent,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _CategoryChip(
            label: 'Marketing',
            svgIcon: _devIcon, // Placeholder
            color: Colors.greenAccent,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _CategoryChip(
            label: 'Business',
            svgIcon: _designIcon, // Placeholder
            color: Colors.purpleAccent,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String svgIcon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.svgIcon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.string(
                svgIcon,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}