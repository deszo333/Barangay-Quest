import 'package:cloud_firestore/cloud_firestore.dart';

class Quest {
  final String id;
  final String title;
  final String category;
  final String workType;
  final String? schedule;
  final String budgetType;
  final num budgetAmount;
  final String description;
  final String? imageUrl;
  final String questGiverId;
  final String questGiverName;
  final String status; // open, in-progress, completed
  final Timestamp? createdAt;
  final Map<String, dynamic>? location; // {lat, lng, address}

  Quest({
    required this.id,
    required this.title,
    required this.category,
    required this.workType,
    required this.schedule,
    required this.budgetType,
    required this.budgetAmount,
    required this.description,
    required this.imageUrl,
    required this.questGiverId,
    required this.questGiverName,
    required this.status,
    required this.createdAt,
    required this.location,
  });

  factory Quest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    num _parseNum(dynamic v) {
      if (v is num) return v;
      if (v is String) {
        final n = num.tryParse(v.trim());
        if (n != null) return n;
      }
      return 0;
    }

    return Quest(
      id: doc.id,
      title: d['title'] ?? '',
      category: d['category'] ?? '',
      workType: d['workType'] ?? 'In Person',
      schedule: d['schedule'],
      budgetType: d['budgetType'] ?? 'Fixed Rate',
      budgetAmount: _parseNum(d['budgetAmount']),
      description: d['description'] ?? '',
      imageUrl: d['imageUrl'],
      questGiverId: d['questGiverId'] ?? '',
      questGiverName: d['questGiverName'] ?? 'User',
      status: d['status'] ?? 'open',
      createdAt: d['createdAt'],
      location: (d['location'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
