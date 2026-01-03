import 'package:flutter/material.dart';

class MemberListScreen extends StatelessWidget {
  final String familyDocId;
  final String familyName;

  const MemberListScreen(this.familyDocId, this.familyName, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(familyName)),
      body: Center(
        child: Text(
          'Members of $familyName\nFamilyDocId: $familyDocId',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
