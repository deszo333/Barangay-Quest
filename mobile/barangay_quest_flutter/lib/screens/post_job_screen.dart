import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _schedule = TextEditingController();
  final _budget = TextEditingController();
  final _description = TextEditingController();
  String _workType = 'In Person';
  String _budgetType = 'Fixed Rate';
  bool _terms = false;
  XFile? _image;
  Uint8List? _imageBytes; // for preview/web upload
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _image = img;
        _imageBytes = bytes;
      });
    }
  }

  num _parseBudget() {
    final n = num.tryParse(_budget.text.trim());
    return n ?? 0;
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }
    if (_title.text.trim().isEmpty ||
        _category.text.trim().isEmpty ||
        _description.text.trim().isEmpty) {
      setState(() {
        _error = 'Please fill in required fields.';
      });
      return;
    }
    if (!_terms) {
      setState(() {
        _error = 'You must agree to the terms.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    String? imageUrl;
    try {
      if (_imageBytes != null) {
        final fileName = _image?.name ?? 'image.jpg';
        final path =
            'quest_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final ref = FirebaseStorage.instance.ref().child(path);
        await ref.putData(
            _imageBytes!, SettableMetadata(contentType: 'image/*'));
        imageUrl = await ref.getDownloadURL();
      }

      // Create quest doc and update user counters; fetch full name for questGiverName
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Get user's full name from profile if available
        String fullName = '';
        final profileSnap = await tx.get(userRef);
        if (profileSnap.exists) {
          final p = profileSnap.data() as Map<String, dynamic>;
          final displayName =
              (p['displayName'] ?? p['name'] ?? '').toString().trim();
          final firstName = (p['firstName'] ?? '').toString().trim();
          final lastName = (p['lastName'] ?? '').toString().trim();
          if (displayName.isNotEmpty) {
            fullName = displayName;
          } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
            fullName =
                [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
          }
        }
        fullName = fullName.isNotEmpty
            ? fullName
            : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : (user.email ?? 'User'));

        tx.set(
            userRef,
            {
              'questsPosted': FieldValue.increment(1),
              'displayName': fullName,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        final newQuestRef =
            FirebaseFirestore.instance.collection('quests').doc();
        tx.set(newQuestRef, {
          'title': _title.text.trim(),
          'category': _category.text.trim(),
          'workType': _workType,
          'schedule': _schedule.text.trim(),
          'budgetType': _budgetType,
          'budgetAmount': _parseBudget(),
          'description': _description.text.trim(),
          'imageUrl': imageUrl,
          'questGiverId': user.uid,
          'questGiverName': fullName,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'location': {
            'lat': null,
            'lng': null,
            'address': _workType == 'Online' ? 'Online' : null,
          },
        });
      });

      if (!mounted) return;
      context.go('/my-quests');
    } catch (e) {
      setState(() {
        _error = 'Failed to post job. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
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
                controller: _title,
                decoration: const InputDecoration(labelText: 'Job Title *')),
            const SizedBox(height: 8),
            TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category *')),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Work Type: '),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('In Person'),
                  selected: _workType == 'In Person',
                  onSelected: (_) => setState(() => _workType = 'In Person')),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('Online'),
                  selected: _workType == 'Online',
                  onSelected: (_) => setState(() => _workType = 'Online')),
            ]),
            const SizedBox(height: 8),
            TextField(
                controller: _schedule,
                decoration: const InputDecoration(labelText: 'Schedule')),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Budget: '),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('Fixed Rate'),
                  selected: _budgetType == 'Fixed Rate',
                  onSelected: (_) =>
                      setState(() => _budgetType = 'Fixed Rate')),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('Hourly Rate'),
                  selected: _budgetType == 'Hourly Rate',
                  onSelected: (_) =>
                      setState(() => _budgetType = 'Hourly Rate')),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _budget,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0.00'))),
            ]),
            const SizedBox(height: 8),
            TextField(
                controller: _description,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description *')),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text('Select image')),
              const SizedBox(width: 12),
              if (_imageBytes != null) const Text('Image selected')
            ]),
            if (_imageBytes != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.memory(_imageBytes!, height: 160, fit: BoxFit.cover),
              )
            ],
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(
                  value: _terms,
                  onChanged: (v) => setState(() => _terms = v ?? false)),
              const Expanded(
                  child: Text(
                      'I agree to Safety & Trust policy and terms of service')),
            ]),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
