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
<<<<<<< HEAD
                // Schedule navigation after the popup has closed to avoid
                // ancestor lookups on a deactivated element (race condition).
                // This ensures any Theme/PopupMenu lookup inside the popup
                // finishes before we trigger route changes.
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  switch (value) {
                    case 'post':
                      if (context.mounted) {
                        context.go('/post-job');
                      }
                      break;
                    case 'apps':
                      if (context.mounted) {
                        context.go('/my-applications');
                      }
                      break;
                    case 'quests':
                      if (context.mounted) {
                        context.go('/my-quests');
                      }
                      break;
                    case 'logout':
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                      break;
                  }
                });
=======
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
>>>>>>> 7231058dfd1423c83baefd468243f6648978788e
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
