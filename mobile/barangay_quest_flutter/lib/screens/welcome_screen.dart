// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barangay_quest_flutter/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bg,
              AppTheme.bg2,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Image.asset(
              'lib/assets/icons/2.png', // <-- This is the correct path to use in your code
              height: 96,
              width: 96,
              filterQuality: FilterQuality.high,
              // Optional: remove 'color:' if you want the original PNG colors
            ),
              const SizedBox(height: 16),
              Text(
                'Barangay Quest',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white,
                ),
              ),
              Text(
                'Find your quest. Empower your community.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () => context.push('/login'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/signup'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Up'),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}