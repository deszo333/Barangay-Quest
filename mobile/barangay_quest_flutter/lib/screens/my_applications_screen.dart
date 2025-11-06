import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    final stream = FirebaseFirestore.instance
        .collection('applications')
        .where('applicantId', isEqualTo: user.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
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
            return const Center(child: Text('No applications yet.'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index].data();
              final id = docs[index].id;
              final title = d['questTitle'] ?? 'Quest';
              final status = (d['status'] ?? 'pending').toString();
              return ListTile(
                title: Text(title),
                subtitle: Text('Status: ${status.toUpperCase()}'),
                trailing: status == 'pending'
                    ? TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('applications')
                              .doc(id)
                              .delete();
                        },
                        child: const Text('Cancel'),
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
