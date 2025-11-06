import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyQuestsScreen extends StatelessWidget {
  const MyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    final stream = FirebaseFirestore.instance
        .collection('quests')
        .where('questGiverId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Quests')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(child: Text('No posted quests yet.'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ref = snap.data!.docs[index].reference;
              final d = docs[index].data();
              final title = d['title'] ?? 'Quest';
              final status = (d['status'] ?? 'open').toString();
              return ListTile(
                title: Text(title),
                subtitle: Text('Status: ${status.toUpperCase()}'),
                trailing: status != 'completed'
                    ? TextButton(
                        onPressed: () async {
                          await ref.update({'status': 'completed'});
                        },
                        child: const Text('Mark Completed'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
