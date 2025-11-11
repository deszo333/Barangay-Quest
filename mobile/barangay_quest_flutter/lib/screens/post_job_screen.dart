// lib/screens/post_job_screen.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart'; // <-- FIXED
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // <-- FIXED
// Note: 'location' package is no longer needed here,
// it is handled by the interactive_quest_map widget.

import '../theme/app_theme.dart';
import '../main.dart' show AuthService, UserModel;
import '../widgets/dashboard/interactive_quest_map.dart';

const List<String> kCategories = [
  "Tutoring", "Home Repair", "Gardening", "Photography", "Errands",
  "Child Care", "Elder Care", "Cleaning", "Pet Care", "Transport",
  "Test Prep", "Bookkeeping", "Catering", "PC Help", "Design",
  "Events", "Other"
];

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  String? _category = kCategories.first;
  String _workType = 'In Person';
  DateTime? _specificDate;
  bool _terms = false;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;

  final Completer<GoogleMapController> _mapController = Completer();
  Marker? _marker;
  String? _locationAddress;
  static const CameraPosition _manilaPosition = CameraPosition(
    target: LatLng(14.5995, 120.9842),
    zoom: 11,
  );

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && picked != _specificDate) {
      setState(() {
        _specificDate = picked;
      });
    }
  }

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

  num _parsePrice() {
    final n = num.tryParse(_price.text.trim());
    return n ?? 0;
  }

  Future<void> _onMapTap(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _locationAddress =
              "${p.name}, ${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.postalCode}";
        });
      }
    } catch (e) {
      setState(() {
        _locationAddress = "Could not get address. Tap again.";
      });
    }

    setState(() {
      _marker = Marker(
        markerId: const MarkerId('quest-location'),
        position: position,
        infoWindow: InfoWindow(
          title: 'Quest Location',
          snippet: _locationAddress ?? 'Selected point',
        ),
      );
    });

    // Animate the map (the controller is shared from the child widget)
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  Future<void> _submit() async {
    final authService = context.read<AuthService>();
    final UserModel? user = authService.firestoreUser;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_terms) {
      setState(() => _error = 'You must agree to the terms.');
      return;
    }

    if (_workType == 'In Person' && _marker == null) {
      setState(() => _error = 'Please pin the job location on the map.');
      return;
    }

    final num priceAmount = _parsePrice();
    final num walletBalance = user.walletBalance;

    if (walletBalance < priceAmount) {
      setState(() {
        _error =
            'Your ₱${walletBalance.toStringAsFixed(2)} balance is too low to post this ₱${priceAmount.toStringAsFixed(2)} job.';
      });
      return;
    }

    // --- ADD THIS CALCULATION ---
    // Get the user's current rating data
    final int reviewCount = user.numberOfRatings;
    final num totalScore = user.totalRatingScore;
    final double avgRating = (reviewCount > 0) ? (totalScore / reviewCount) : 0.0;
    // --- END OF ADDITION ---

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

        final bytes = await _image!.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(
              contentType:
                  'image/${fileName.split('.').last.replaceAll('jpg', 'jpeg')}'),
        );

        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        tx.update(userRef, {
          'questsPosted': FieldValue.increment(1),
        });

        final newQuestRef =
            FirebaseFirestore.instance.collection('quests').doc();

        tx.set(newQuestRef, {
          'title': _title.text.trim(),
          'category': _category,
          'workType': _workType,
          'description': _description.text.trim(),
          'price': priceAmount,
          'priceType': 'Fixed Rate',
          'schedule': 'Specific Date',
          'specificDate': _specificDate != null
              ? Timestamp.fromDate(_specificDate!)
              : null,
          'engagement': 'One-Time',
          'imageUrl': imageUrl,
          'location': {
            'lat': _workType == 'In Person' ? _marker?.position.latitude : null,
            'lng': _workType == 'In Person' ? _marker?.position.longitude : null,
            'address': _workType == 'Online' ? 'Online' : _locationAddress,
          },
          'lat': _workType == 'In Person' ? _marker?.position.latitude : null,
          'lng': _workType == 'In Person' ? _marker?.position.longitude : null,
          'locationAddress': _workType == 'Online' ? 'Online' : _locationAddress,
          'questGiverId': user.uid,
          'questGiverName': user.name,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          
          // --- ADD THESE TWO LINES ---
          'questGiverAvgRating': avgRating,
          'questGiverReviewCount': reviewCount,
          // --- END OF ADDITION ---
        });
      });

      if (!mounted) return;
      context.go('/my-quests');
    } catch (e) {
      setState(() {
        _error = 'Failed to post job: ${e.toString()}';
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
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Job Title *'),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: kCategories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Category is required' : null,
              ),
              const SizedBox(height: 12),
              const Text('Work Type', style: TextStyle(fontSize: 12)),
              Row(children: [
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
              const SizedBox(height: 12),
              if (_workType == 'In Person')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pin Job Location *',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // --- START: INTEGRATION POINT ---
                    Container(
                      height: 300,
                      child: InteractiveQuestMap(
                        initialCenter: _manilaPosition.target,
                        initialZoom: _manilaPosition.zoom,
                        // This passes the screen's controller completer to the map
                        onMapCreated: (controller) {
                          if (!_mapController.isCompleted) {
                            _mapController.complete(controller);
                          }
                        },
                        onMapTap: _onMapTap,
                        markers: _marker == null ? {} : {_marker!},
                      ),
                    ),
                    // --- END: INTEGRATION POINT ---
                    if (_locationAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_locationAddress!),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _specificDate == null
                      ? ''
                      : DateFormat.yMMMd().format(_specificDate!),
                ),
                decoration: InputDecoration(
                  labelText: 'Date of Job *',
                  hintText: 'Select a date',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                onTap: () => _selectDate(context),
                validator: (value) =>
                    _specificDate == null ? 'Date is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (Fixed Rate) *',
                  prefixText: '₱',
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Budget is required';
                  }
                  final n = num.tryParse(value!);
                  if (n == null || n <= 0) {
                    return 'Must be a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Select image (Optional)')),
                const SizedBox(width: 12),
                if (_imageBytes != null)
                  const Icon(Icons.check, color: Colors.green),
              ]),
              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_imageBytes!,
                        height: 160, fit: BoxFit.cover),
                  ),
                ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}