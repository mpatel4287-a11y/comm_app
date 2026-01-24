import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/member_model.dart';
import 'advanced_search_screen.dart';

class UserSearchTab extends StatelessWidget {
  const UserSearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('members').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No members found'));
        }

        final members = snapshot.data!.docs.map((doc) {
          return MemberModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();

        return AdvancedSearchScreen(allMembers: members);
      },
    );
  }
}
