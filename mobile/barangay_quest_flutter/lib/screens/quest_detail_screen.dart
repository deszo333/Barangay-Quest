// lib/screens/quest_detail_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';

import '../main.dart' show AuthService, UserModel;
import '../theme/app_theme.dart';
import '../widgets/ui/info_chip.dart'; 

class QuestDetailScreen extends StatefulWidget {
  final String questId;
  const QuestDetailScreen({super.key, required this.questId});

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  final String _defaultImageUrl =
      'https://images.unsplash.com/photo-1599050751792-352e7c445aee?q=80&w=1200&auto=format&fit=crop';

  DocumentSnapshot<Map<String, dynamic>>? _doc;
  UserModel? _questGiver;
  bool _loading = true;
  String? _error;
  bool _applyLoading = false;
  bool _applied = false;
  UserModel? _loggedInUser; 

  @override
  void initState() {
    super.initState();
    _loggedInUser = context.read<AuthService>().firestoreUser;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await FirebaseFirestore.instance
          .collection('quests')
          .doc(widget.questId)
          .get();

      if (!d.exists) {
        throw Exception('Quest not found');
      }
      
      final questData = d.data()!;
      setState(() => _doc = d); 

      if (questData['questGiverId'] != null) {
        final giverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(questData['questGiverId'])
            .get();
        if (giverDoc.exists) {
          setState(() => _questGiver = UserModel.fromDoc(giverDoc));
        }
      }

      if (_loggedInUser != null) {
        final apps = await FirebaseFirestore.instance
            .collection('applications')
            .where('questId', isEqualTo: d.id)
            .where('applicantId', isEqualTo: _loggedInUser!.uid)
            .limit(1)
            .get();
        _applied = apps.docs.isNotEmpty;
      }
    } catch (e) {
      setState(() { _error = 'Failed to load quest.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _apply() async {
    if (_loggedInUser == null || _doc == null) {
      setState(() { _error = 'Please log in to apply.'; });
      return;
    }
    final questData = _doc!.data()!;
    setState(() { _applyLoading = true; _error = null; });
    try {
      if (questData['questGiverId'] == _loggedInUser!.uid) {
        throw Exception("You can't apply to your own job.");
      }
      if (questData['status'] != 'open') {
        throw Exception('This quest is not open for applications.');
      }
      // --- START OF PATCH ---
      // Use a transaction to ensure both writes succeed
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // 1. Get the reference to the quest
        final questRef = FirebaseFirestore.instance.collection('quests').doc(_doc!.id);
        // 2. Create the new application document
        final newAppRef = FirebaseFirestore.instance.collection('applications').doc();
        tx.set(newAppRef, {
          'questId': _doc!.id,
          'questTitle': questData['title'],
          'questGiverId': questData['questGiverId'],
          'applicantId': _loggedInUser!.uid,
          'applicantName': _loggedInUser!.name,
          'status': 'pending',
          'appliedAt': FieldValue.serverTimestamp(),
        });
        // 3. Update the applicantCount on the quest
        tx.update(questRef, {
          'applicantCount': FieldValue.increment(1),
        });
      });
      // --- END OF PATCH ---
      setState(() { _applied = true; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _applyLoading = false; });
    }
  }

  String _formatQuestDate(dynamic dateValue) {
    if (dateValue == null) return "Flexible";
    if (dateValue is Timestamp) {
      return DateFormat.yMMMd().format(dateValue.toDate());
    }
    if (dateValue is String) {
      try {
        final dt = DateTime.parse(dateValue);
        return DateFormat.yMMMd().format(dt);
      } catch (e) {
        return dateValue;
      }
    }
    return "Invalid Date";
  }

  String _formatPrice(Map<String, dynamic> questData) {
    final num amount = _parseNum(questData['price']);
    final String priceType = questData['priceType'] ?? 'Fixed Rate';
    final format = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    return '${format.format(amount)} ($priceType)';
  }

  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator())
      );
    }
    if (_error != null || _doc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Quest not found.'))
      );
    }

    final questData = _doc!.data()!;
    final isOwner = _loggedInUser?.uid == questData['questGiverId'];
    final bool canApply = _loggedInUser != null && !isOwner && questData['status'] == 'open';

    final lat = _parseNum(questData['location']?['lat']).toDouble();
    final lng = _parseNum(questData['location']?['lng']).toDouble();
    final LatLng? questLocation = (lat != 0.0 && lng != 0.0) ? LatLng(lat, lng) : null;
    
    final Set<Marker> markers = questLocation != null ? {
      Marker(markerId: MarkerId(_doc!.id), position: questLocation)
    } : {};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                questData['title'] ?? 'Quest',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              background: Image.network(
                questData['imageUrl'] ?? _defaultImageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withAlpha((255 * 0.4).round()),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    _defaultImageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withAlpha((255 * 0.4).round()),
                    colorBlendMode: BlendMode.darken,
                  );
                },
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      _buildGiverInfo(context),
                      
                      const SizedBox(height: 24),
                      
                      _buildActionButton(context, isOwner, canApply, questData),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),

                      const SizedBox(height: 24),
                      
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          InfoChip(
                            icon: Icons.paid_outlined, 
                            label: _formatPrice(questData)
                          ),
                          InfoChip(
                            icon: questData['workType'] == 'Online' ? Icons.laptop_mac : Icons.people_outline, 
                            label: questData['workType'] ?? 'In Person'
                          ),
                          InfoChip(
                            icon: Icons.calendar_today_outlined, 
                            label: _formatQuestDate(questData['specificDate'])
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader(context, 'Description'),
                      Text(questData['description'] ?? '', style: TextStyle(color: AppTheme.muted)),

                      const SizedBox(height: 24),
                      
                      if (questLocation != null)
                        _buildLocationMap(context, questLocation, markers),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiverInfo(BuildContext context) {
    if (_questGiver == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () => context.push('/user/${_questGiver!.uid}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: (_questGiver!.avatarUrl != null) 
              ? NetworkImage(_questGiver!.avatarUrl!) 
              : null,
            child: (_questGiver!.avatarUrl == null) 
              ? Text(_questGiver!.name.isNotEmpty ? _questGiver!.name[0] : 'U') 
              : null,
          ),
          const SizedBox(width: 12),
          Text(
            _questGiver!.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isOwner, bool canApply, Map<String, dynamic> questData) {
    if (isOwner) {
      return FilledButton.tonal(
        onPressed: () => context.go('/quest/${_doc!.id}/applicants'),
        child: const Text('View Applicants'),
      );
    }
    
    return FilledButton(
      onPressed: (_applied || _applyLoading || !canApply) ? null : _apply,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _applyLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(
              _applied ? 'Application Submitted' 
              : (questData['status'] != 'open' ? 'Quest is closed' : 'Apply Now')
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLocationMap(BuildContext context, LatLng location, Set<Marker> markers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Location'),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            // --- FIX: The parameter has been removed ---
            initialCameraPosition: CameraPosition(
              target: location,
              zoom: 15,
            ),
            markers: markers,
            zoomControlsEnabled: true,
          ),
        ),
      ],
    );
  }
}