// lib/screens/main_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is the page (Home, Find Jobs, etc.)
      body: navigationShell,
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // Go to the selected tab
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        // --- Styling to match the image ---
        type: BottomNavigationBarType.fixed, // Shows all labels
        backgroundColor: AppTheme.bg, // Dark background
        selectedItemColor: AppTheme.accent, // Blue for active icon
        unselectedItemColor: AppTheme.muted, // Grey for inactive
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        
        // --- UPDATED: Now 5 items ---
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          // --- NEW: "Find Jobs" Tab ---
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Jobs',
          ),
          // --- END NEW ---
          BottomNavigationBarItem(
            icon: Icon(Icons.work_history_outlined),
            label: 'My Quests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'My Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}