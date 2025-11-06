import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuestDetailScreen extends StatefulWidget {
  final String questId;
  const QuestDetailScreen({super.key, required this.questId});

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  DocumentSnapshot<Map<String, dynamic>>? _doc;
  bool _loading = true;
  String? _error;
  bool _applyLoading = false;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await FirebaseFirestore.instance.collection('quests').doc(widget.questId).get();
      if (!d.exists) {
        setState(() { _error = 'Quest not found'; });
      }
      _doc = d;
      // Check if already applied
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && d.exists) {
        final apps = await FirebaseFirestore.instance.collection('applications')
          .where('questId', isEqualTo: d.id)
          .where('applicantId', isEqualTo: user.uid)
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() { _error = 'Please log in to apply.'; }); return; }
    final d = _doc;
    if (d == null || !d.exists) return;

    setState(() { _applyLoading = true; _error = null; });
    try {
      final data = d.data()!;
      if ((data['status'] ?? 'open') != 'open') {
        setState(() { _error = 'This quest is not open for applications.'; });
        return;
      }
      await FirebaseFirestore.instance.collection('applications').add({
        'questId': d.id,
        'questTitle': data['title'],
        'questGiverId': data['questGiverId'],
        'applicantId': user.uid,
        'applicantName': user.email, // Optionally fetch user profile for name
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });
      setState(() { _applied = true; });
    } catch (e) {
      setState(() { _error = 'Failed to apply. Please try again.'; });
    } finally {
      setState(() { _applyLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null && _doc == null) return Scaffold(body: Center(child: Text(_error!)));
    final d = _doc!; final data = d.data()!;
    String formatBudget(String type, num amount) => type == 'Hourly Rate' ? '₱$amount / hr' : '₱$amount (Fixed)';

    return Scaffold(
      appBar: AppBar(title: Text(data['title'] ?? 'Quest')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Posted by ${data['questGiverName'] ?? 'User'}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _InfoChip(label: 'Category', value: data['category']),
              _InfoChip(label: 'Status', value: data['status']?.toString().toUpperCase() ?? 'OPEN'),
              _InfoChip(label: 'Location', value: (data['location']?['address']) ?? data['workType']),
              _InfoChip(label: 'Budget', value: formatBudget(data['budgetType'] ?? 'Fixed Rate', data['budgetAmount'] ?? 0)),
            ]),
            const SizedBox(height: 16),
            if (data['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(data['imageUrl'], width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(data['description'] ?? ''),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            if ((data['status'] ?? 'open') == 'open')
              FilledButton(
                onPressed: _applied || _applyLoading ? null : _apply,
                child: _applyLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_applied ? 'Application Submitted' : 'Apply Now'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label; final String value;
  const _InfoChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
