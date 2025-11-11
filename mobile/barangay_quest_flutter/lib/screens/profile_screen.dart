// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart' show AuthService, UserModel;
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  bool _isAddingFunds = false;
  String? _uploadError;

  final ImagePicker _picker = ImagePicker();

  final currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  Future<void> _addDemoFunds(UserModel user) async {
    setState(() => _isAddingFunds = true);
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'walletBalance': FieldValue.increment(10000),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding funds: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingFunds = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar(UserModel user) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (image == null) {
        setState(() => _isUploading = false);
        return; 
      }

      final String fileExtension = image.name.split('.').last;
      final String filePath = 'profile_pictures/${user.uid}.$fileExtension';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);

      final bytes = await image.readAsBytes();
      final UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/${fileExtension.replaceAll('jpg', 'jpeg')}'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDocRef.update({
        'avatarUrl': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      setState(() => _uploadError = 'Upload failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // --- NEW: Logout Function ---
  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut();
    // The router's redirect logic in main.dart will handle the navigation
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final UserModel? userModel = authService.firestoreUser;

    if (userModel == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in.')),
      );
    }

    final String? avatarUrl = userModel.avatarUrl;

    return Scaffold(
      // --- NEW: Add an AppBar ---
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Wallet Section ---
            _buildSectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Wallet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Balance',
                    style: TextStyle(color: AppTheme.muted, fontSize: 16),
                  ),
                  Text(
                    currencyFormat.format(userModel.walletBalance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF4ADE80), // --status-completed
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: _isAddingFunds ? null : () => _addDemoFunds(userModel),
                    child: _isAddingFunds
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add ₱10,000 (Demo)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Profile Picture Section ---
            _buildSectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.card,
                        backgroundImage: (avatarUrl != null)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null)
                            ? Text(
                                userModel.name.isNotEmpty ? userModel.name[0] : 'U',
                                style: Theme.of(context).textTheme.headlineSmall,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () => _pickAndUploadAvatar(userModel),
                          icon: _isUploading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.upload_file),
                          label: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Upload Picture'),
                        ),
                      ),
                    ],
                  ),
                  if (_uploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _uploadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

            // --- NEW: Logout Button ---
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _logOut,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[300],
                side: BorderSide(color: Colors.red[300]!.withOpacity(0.5)),
              ),
            ),
            // --- END NEW ---
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required BuildContext context, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}