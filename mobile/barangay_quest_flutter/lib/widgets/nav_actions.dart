// lib/widgets/nav_actions.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart' show AuthService, UserModel; 

class NavActions extends StatelessWidget {
  const NavActions({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final UserModel? user = authService.firestoreUser;
    final bool isLoggedIn = authService.isLoggedIn;
    final String? status = authService.status;
    
    // --- Guest View ---
    if (!isLoggedIn || user == null) {
      return Row(
        // --- FIX: Add MainAxisSize.min ---
        mainAxisSize: MainAxisSize.min, 
        children: [
          TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Login'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.push('/signup'),
            child: const Text('Sign Up'),
          ),
          const SizedBox(width: 8), 
        ],
      );
    }

    // --- Logged-In View (Pending or Approved) ---
    return Row(
      // --- FIX: Add MainAxisSize.min ---
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wrap wallet in Flexible
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '₱${user.walletBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF4ADE80), // --status-completed
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis for safety
              softWrap: false, // Don't let it wrap to a new line
            ),
          ),
        ),
        
        // Find Jobs (Visible to all logged-in users)
        IconButton(
          onPressed: () => context.push('/find-jobs'),
          icon: const Icon(Icons.search),
          tooltip: 'Find Jobs',
        ),

        // User Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          tooltip: 'My Account',
          onSelected: (value) {
            switch (value) {
              case 'post':
                context.push('/post-job');
                break;
              case 'apps':
                context.push('/my-applications');
                break;
              case 'quests':
                context.push('/my-quests');
                break;
              case 'profile':
                context.push('/profile'); 
                break;
              case 'logout':
                FirebaseAuth.instance.signOut();
                break;
            }
          },
          itemBuilder: (context) => [
            if (status == 'approved') ...[
              const PopupMenuItem(value: 'post', child: Text('Post a Job')),
              const PopupMenuItem(
                  value: 'apps', child: Text('My Applications')),
              const PopupMenuItem(value: 'quests', child: Text('My Quests')),
              const PopupMenuDivider(),
            ],
            
            const PopupMenuItem(value: 'profile', child: Text('My Profile & Wallet')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}