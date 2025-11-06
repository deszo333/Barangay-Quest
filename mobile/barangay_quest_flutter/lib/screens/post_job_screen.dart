import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _schedule = TextEditingController();
  final _description = TextEditingController();
  final _budgetAmount = TextEditingController();
  final _location = TextEditingController();

  String _workType = 'In Person';
  String _budgetType = 'Fixed Rate';
  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = xfile.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Please sign in first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    String? imageUrl;
    try {
      // 1) Upload image if chosen
      if (_imageBytes != null && _imageName != null) {
        final path =
            'quest_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_imageName';
        final ref = FirebaseStorage.instance.ref().child(path);
        final task = await ref.putData(
            _imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        imageUrl = await task.ref.getDownloadURL();
      }

      // 2) Create quest document
      await FirebaseFirestore.instance.collection('quests').add({
        'title': _title.text.trim(),
        'category': _category.text.trim(),
        'workType': _workType,
        'schedule': _schedule.text.trim(),
        'budgetType': _budgetType,
        'budgetAmount': num.tryParse(_budgetAmount.text.trim()) ?? 0,
        'description': _description.text.trim(),
        'location': {
          'address': _workType == 'Online' ? 'Online' : _location.text.trim(),
        },
        'imageUrl': imageUrl,
        'questGiverId': user.uid,
        'questGiverName': user.email ?? 'User',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Failed to post job. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Work Type: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('In Person'),
                  selected: _workType == 'In Person',
                  onSelected: (_) => setState(() => _workType = 'In Person'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Online'),
                  selected: _workType == 'Online',
                  onSelected: (_) => setState(() => _workType = 'Online'),
                ),
              ]),
              if (_workType == 'In Person') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _location,
                  decoration:
                      const InputDecoration(labelText: 'Location Address *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _schedule,
                decoration: const InputDecoration(labelText: 'Schedule'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Budget: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _budgetType,
                  items: const [
                    DropdownMenuItem(
                        value: 'Fixed Rate', child: Text('Fixed Rate')),
                    DropdownMenuItem(
                        value: 'Hourly Rate', child: Text('Hourly Rate')),
                  ],
                  onChanged: (v) =>
                      setState(() => _budgetType = v ?? 'Fixed Rate'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _budgetAmount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                )
              ]),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Choose image'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _imageName ?? 'No image selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
