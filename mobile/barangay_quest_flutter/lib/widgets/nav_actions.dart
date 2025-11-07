import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavActions extends StatelessWidget {
  const NavActions({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return Row(
            children: [
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => context.go('/signup'),
                child: const Text('Sign Up'),
              ),
            ],
          );
        }

        return Row(
          children: [
            IconButton(
              onPressed: () => context.go('/find-jobs'),
              icon: const Icon(Icons.search),
              tooltip: 'Find Jobs',
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    context.push('/user/${user.uid}');
                    break;
                  case 'post':
                    context.go('/post-job');
                    break;
                  case 'apps':
                    context.go('/my-applications');
                    break;
                  case 'quests':
                    context.go('/my-quests');
                    break;
                  case 'logout':
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/login');
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'profile', child: Text('My Profile')),
                PopupMenuItem(value: 'post', child: Text('Post Job')),
                PopupMenuItem(value: 'apps', child: Text('My Applications')),
                PopupMenuItem(value: 'quests', child: Text('My Quests')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
        );
      },
    );
  }
}
