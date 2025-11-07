import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/find_jobs_screen.dart';
import 'screens/quest_detail_screen.dart';
import 'screens/post_job_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/my_quests_screen.dart';
import 'screens/quest_applicants_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BarangayQuestApp());
}

class BarangayQuestApp extends StatelessWidget {
  const BarangayQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
            path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/', builder: (context, state) => const AuthGate()),
        GoRoute(
            path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
            path: '/signup', builder: (context, state) => const SignupScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: '/find-jobs',
            builder: (context, state) => const FindJobsScreen()),
        GoRoute(
            path: '/post-job',
            builder: (context, state) => const PostJobScreen()),
        GoRoute(
            path: '/my-applications',
            builder: (context, state) => const MyApplicationsScreen()),
        GoRoute(
            path: '/my-quests',
            builder: (context, state) => const MyQuestsScreen()),
        GoRoute(
          path: '/quest/:id',
          builder: (context, state) =>
              QuestDetailScreen(questId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/quest/:id/applicants',
          builder: (context, state) =>
              QuestApplicantsScreen(questId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/user/:id',
          builder: (context, state) =>
              UserProfileScreen(userId: state.pathParameters['id']!),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Barangay Quest',
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        // Always allow browsing Home. Home will adapt its UI for guests vs authed users.
        return const HomeScreen();
      },
    );
  }
}
