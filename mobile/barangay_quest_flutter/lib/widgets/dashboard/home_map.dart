// lib/widgets/dashboard/home_map.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../models/quest.dart';
import '../../theme/app_theme.dart';
import 'interactive_quest_map.dart';

class HomeMap extends StatefulWidget {
  const HomeMap({super.key});

  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  // Manila
  static const LatLng _initialCenter = LatLng(14.5995, 120.9842);
  static const double _initialZoom = 12.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quests Near You',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // This StreamBuilder fetches the quests
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('quests')
                .where('status', isEqualTo: 'open')
                .where('location.lat',
                    isNotEqualTo: null) // Only get quests with a lat
                .snapshots(),
            builder: (context, snapshot) {
              Set<Marker> markers = {};
              if (snapshot.hasData) {
                // When data comes in, build the markers
                for (var doc in snapshot.data!.docs) {
                  final quest = Quest.fromDoc(doc);

                  final lat = quest.location?['lat'];
                  final lng = quest.location?['lng'];

                  if (lat != null && lng != null) {
                    markers.add(
                      Marker(
                        markerId: MarkerId(quest.id),
                        position: LatLng(lat, lng),
                        infoWindow: InfoWindow(
                          title: quest.title,
                          snippet:
                              '₱${quest.price.toStringAsFixed(0)} (${quest.priceType})',
                          onTap: () {
                            // GoRouter is available in the context
                            context.push('/quest/${quest.id}');
                          },
                        ),
                      ),
                    );
                  }
                }
              }

              // --- INTEGRATION POINT ---
              // Use the InteractiveQuestMap widget
              return Container(
                height: 300,
                child: InteractiveQuestMap(
                  markers: markers,
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}