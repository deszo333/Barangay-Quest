import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barangay_quest_flutter/theme/app_theme.dart'; // Import theme

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- NEW CONTROLLERS to match web app ---
  final _firstName = TextEditingController();
  final _middleName = TextEditingController(); // Optional
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _agreesToVerification = false;
  // --- END NEW CONTROLLERS ---

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    // --- UPDATED VALIDATION ---
    final firstName = _firstName.text.trim();
    final middleName = _middleName.text.trim();
    final lastName = _lastName.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;
    final passwordConfirm = _passwordConfirm.text;

    // Combine names to match the single 'name' field in your UserModel
    final fullName =
        '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName';

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      setState(() {
        _error = 'Please fill in all required fields.';
      });
      return;
    }

    if (password != passwordConfirm) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }

    if (!_agreesToVerification) {
      setState(() {
        _error = 'You must agree to receive calls for verification.';
      });
      return;
    }
    // --- END UPDATED VALIDATION ---

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

      // --- UPDATED FIRESTORE DOCUMENT ---
      // This now includes all the synced fields
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
  'name': fullName, // Combined name
  'firstName': firstName,
  'middleName': middleName.isNotEmpty ? middleName : null,
  'lastName': lastName,
  'email': email,
  'phone': phone,
  'canReceiveCalls': _agreesToVerification,
  'status': 'pending', // CRITICAL: All new signups are pending
  'walletBalance': 5000, // Starting demo funds
  'totalRatingScore': 0,
  'numberOfRatings': 0,
  'questsCompleted': 0,
  'questsPosted': 0,
  'questsGivenCompleted': 0,
  'avatarUrl': null,
  'createdAt': FieldValue.serverTimestamp(),
      });
      // --- END UPDATED DOCUMENT ---

      if (!mounted) {
        return;
      }
      // Use context.go to clear the auth stack
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
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
      // Remove AppBar
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Text(
                "Let's Get Started!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to get all features',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
              const SizedBox(height: 32),

              // --- NEW FIELDS ---
              _buildTextField(
                controller: _firstName,
                label: 'First Name *',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _middleName,
                label: 'Middle Name (Optional)',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastName,
                label: 'Last Name *',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _email,
                label: 'Email *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phone,
                label: 'Phone Number *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _password,
                label: 'Password *',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordConfirm,
                label: 'Confirm Password *',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
              ),
              // --- END NEW FIELDS ---

              const SizedBox(height: 12),
              // --- NEW CHECKBOX ---
              Row(
                children: [
                  Checkbox(
                    value: _agreesToVerification,
                    onChanged: (val) {
                      setState(() {
                        _agreesToVerification = val ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'I am willing to receive calls for verification.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ),
                ],
              ),
              // --- END CHECKBOX ---

              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 12),

              // Create Account Button
              FilledButton(
                onPressed: _loading ? null : _signup,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 24),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(), // Go back to login
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        fillColor: AppTheme.bg2,
        filled: true,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
    );
  }
}