// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- Import permission_handler

import '../main.dart' show AuthService, UserModel; 
import '../theme/app_theme.dart';
import '../models/quest.dart'; 

// --- IMPORT THE DASHBOARD WIDGETS ---
import '../widgets/dashboard/category_chips.dart';
import '../widgets/dashboard/top_user_list.dart';
import '../widgets/dashboard/home_map.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // --- ADDED: Request permission when the home screen loads ---
    _requestLocationPermission();
  }

  // --- NEW: Function to request location permission ---
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is needed to show nearby quests.')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // User permanently denied. Open app settings.
      openAppSettings();
    }
    // If status.isGranted, the map's "myLocationEnabled" will now work.
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.firestoreUser;
  // final bool canPost = authService.status == 'approved'; // Unused variable removed

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${user?.name.split(' ')[0] ?? 'User'}!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              // TODO: Open notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.mic_none),
                fillColor: AppTheme.bg2,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onTap: () => context.push('/find-jobs'),
              readOnly: true,
            ),
          ),
          const SizedBox(height: 24),
          
          // --- Category Chips ---
          const CategoryChips(),
          
          const SizedBox(height: 24),
          
          // --- HomeMap ---
          const HomeMap(),

          const SizedBox(height: 24),
          
          // --- Top Questers (remains at the bottom) ---
          const TopUserList(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}