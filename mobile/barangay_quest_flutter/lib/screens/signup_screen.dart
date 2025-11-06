import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    // Basic required fields validation
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please fill in all required fields.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      // Mirror default user doc from web
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'status': 'pending',
        'unlockedAchievements': <String>[],
        'questsCompleted': 0,
        'questsPosted': 0,
        'questsGivenCompleted': 0,
        'totalRatingScore': 0,
        'numberOfRatings': 0,
        'avatarUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyError(e);
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email address is already registered. Please log in.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return e.message ?? 'Registration failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name *'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email *'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number *'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password *'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _signup,
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create account'),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Sign in'),
            )
          ],
        ),
      ),
    );
  }
}
