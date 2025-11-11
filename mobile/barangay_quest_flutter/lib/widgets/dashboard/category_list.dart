// lib/widgets/dashboard/category_list.dart

import 'package:flutter/material.dart'; // <-- FIX: Was 'package.flutter'
import '../../theme/app_theme.dart';

// Helper for section headers
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// --- NEW: CategoryList widget ---
class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  // Data from Home.jsx
  static const Map<String, IconData> _categories = {
    "Tutoring": Icons.book_outlined,
    "Home Repair": Icons.build_outlined,
    "Gardening": Icons.local_florist_outlined,
    "Photography": Icons.camera_alt_outlined,
    "Errands": Icons.directions_run_outlined,
    "Child Care": Icons.child_care_outlined,
    "Elder Care": Icons.elderly_outlined,
    "Cleaning": Icons.cleaning_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final items = _categories.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Categories'),
        // --- NEW: Horizontal ListView ---
        SizedBox(
          height: 90, // Give the horizontal list a fixed height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Add padding to the list
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _CategoryCard(
                icon: item.value,
                label: item.key,
                onTap: () {
                  // TODO: Navigate to find-jobs with category filter
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- NEW: A card optimized for a horizontal list ---
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.bg2, // Use bg2 for a nice contrast
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 120, // Give the card a fixed width
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.accent, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}