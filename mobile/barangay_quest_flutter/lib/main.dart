// lib/main.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import 'screens/profile_screen.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'widgets/network_aware.dart';

// ====================================================================
// User Model (Updated)
// ====================================================================
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String phone;
  final bool canReceiveCalls;
  final String status;
  final num walletBalance;
  final String? avatarUrl;
  final int questsCompleted;
  final int questsGivenCompleted;
  final num totalRatingScore;
  final int numberOfRatings;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.firstName,
    this.middleName,
    this.lastName,
    required this.phone,
    required this.canReceiveCalls,
    required this.status,
    required this.walletBalance,
    this.avatarUrl,
    required this.questsCompleted,
    required this.questsGivenCompleted,
    required this.totalRatingScore,
    required this.numberOfRatings,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'No Name',
      firstName: data['firstName'],
      middleName: data['middleName'],
      lastName: data['lastName'],
      phone: data['phone'] ?? 'No Phone',
      canReceiveCalls: data['canReceiveCalls'] ?? false,
      status: data['status'] ?? 'pending',
      walletBalance: data['walletBalance'] ?? 0,
      avatarUrl: data['avatarUrl'],
      questsCompleted: data['questsCompleted'] ?? 0,
      questsGivenCompleted: data['questsGivenCompleted'] ?? 0,
      totalRatingScore: data['totalRatingScore'] ?? 0,
      numberOfRatings: data['numberOfRatings'] ?? 0,
    );
  }
}

// ====================================================================
// Authentication Service
// ====================================================================
class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _authStateSub;
  StreamSubscription? _userDocSub;

  bool _isLoading = true;
  User? _firebaseUser;
  UserModel? _firestoreUser;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  String? get status => _firestoreUser?.status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get firestoreUser => _firestoreUser;

  AuthService() {
    _isLoading = true;
    _authStateSub = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _firebaseUser = null;
      _firestoreUser = null;
      _userDocSub?.cancel();
      _isLoading = false;
      notifyListeners();
    } else {
      _firebaseUser = user;
      _isLoading = true;
      notifyListeners();

      _userDocSub?.cancel();
      _userDocSub =
          _db.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          _firestoreUser = UserModel.fromDoc(doc);
        } else {
          _firestoreUser = null;
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint("Error listening to user doc: $e");
        _firestoreUser = null;
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}

// ====================================================================
// Pending Approval Screen
// ====================================================================
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).firestoreUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, ${user?.firstName ?? user?.name ?? 'User'}!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account has been created but must be approved by a barangay administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card.withAlpha((255 * 0.5).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.card),
                ),
                child: Text(
                  'Please expect a call or text at ${user?.phone ?? 'your number'} for verification.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// Navigator Keys
// ====================================================================
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ====================================================================
// Main App Entry Point
// ====================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const BarangayQuestApp(),
    ),
  );
}

class BarangayQuestApp extends StatelessWidget {
  const BarangayQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authService,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isLoading = authService.isLoading;
        final bool isLoggedIn = authService.isLoggedIn;
        final String? status = authService.status?.trim().toLowerCase();
        final String location = state.matchedLocation;

        final isAuthRoute =
            (location == '/login' || location == '/signup' || location == '/welcome');
        final isSplashing = location == '/splash';

        // 1. If loading, stay on splash
        if (isLoading) {
          return isSplashing ? null : '/splash';
        }

        // 2. If loaded from splash, decide where to go
        if (isSplashing) {
          return isLoggedIn ? '/home' : '/welcome';
        }

        // 3. Handle 'pending' status
        if (isLoggedIn && status == 'pending') {
          if (location == '/pending-approval') return null;
          return '/pending-approval';
        }

        // 4. Handle logged in user trying to see auth pages
        if (isLoggedIn && status == 'approved' && isAuthRoute) {
          return '/home';
        }

        // 5. Handle logged in 'approved' user trying to see pending page
        if (isLoggedIn && status == 'approved' && location == '/pending-approval') {
          return '/home';
        }

        // 6. Handle logged OUT user trying to see app
        if (!isLoggedIn && !isAuthRoute && !isSplashing) {
          return '/welcome';
        }

        // 7. No redirect needed
        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Welcome
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),

        // Auth
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),

        // Pending
        GoRoute(
          path: '/pending-approval',
          builder: (context, state) => const PendingApprovalScreen(),
        ),

        // ======================================================
        // Main shell with the 5 tabs just like you had
        // ======================================================
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            // Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            // Find Jobs
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/find-jobs',
                  builder: (context, state) => const FindJobsScreen(),
                ),
              ],
            ),
            // My Quests
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-quests',
                  builder: (context, state) => const MyQuestsScreen(),
                ),
              ],
            ),
            // My Applications
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-applications',
                  builder: (context, state) => const MyApplicationsScreen(),
                ),
              ],
            ),
            // Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // ======================================================
        // Top-level detail routes (stable, root navigator)
        // ======================================================
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/quest/:id',
          builder: (context, state) => QuestDetailScreen(
            questId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              parentNavigatorKey: _rootNavigatorKey,
              path: 'applicants',
              builder: (context, state) => QuestApplicantsScreen(
                questId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),

        // Post job
        GoRoute(
          path: '/post-job',
          builder: (context, state) => const PostJobScreen(),
        ),

        // User profile
        GoRoute(
          path: '/user/:id',
          builder: (context, state) =>
              UserProfileScreen(userId: state.pathParameters['id']!),
        ),

        // Root redirect
        GoRoute(
          path: '/',
          redirect: (_, __) => '/home',
        ),
      ],
    );

    return NetworkAware(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Barangay Quest',
        theme: AppTheme.dark(),
        routerConfig: router,
      ),
    );
  }
}
