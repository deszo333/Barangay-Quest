// lib/models/quest.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Quest {
  final String id;
  final String title;
  final String category;
  final String workType;
  final String description;
  final String questGiverId;
  final String questGiverName;
  final String status;
  final Timestamp? createdAt;
  final num price;
  final String priceType;
  final String? imageUrl;
  final Map<String, dynamic>? location;

  // --- RATING FIELDS REMOVED ---

  Quest({
    required this.id,
    required this.title,
    required this.category,
    required this.workType,
    required this.description,
    required this.questGiverId,
    required this.questGiverName,
    required this.status,
    this.createdAt,
    required this.price,
    required this.priceType,
    this.imageUrl,
    this.location,
    
    // --- RATING FIELDS REMOVED ---
  });

  factory Quest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Quest data is null for doc ${doc.id}");
    }

    return Quest(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      category: data['category'] ?? 'Other',
      workType: data['workType'] ?? 'In Person',
      description: data['description'] ?? '',
      questGiverId: data['questGiverId'] ?? '',
      questGiverName: data['questGiverName'] ?? 'Unknown',
      status: data['status'] ?? 'open',
      createdAt: data['createdAt'] as Timestamp?,
      price: data['price'] ?? 0,
      priceType: data['priceType'] ?? 'Fixed Rate',
      imageUrl: data['imageUrl'],
      location: data['location'] as Map<String, dynamic>?,

      // --- RATING FIELDS REMOVED ---
    );
  }
}