// lib/screens/admin/family_tree_screen.dart

import 'package:flutter/material.dart';
import '../user/family_tree_view.dart';

class FamilyTreeScreen extends StatelessWidget {
  final String mainFamilyDocId;
  final String familyName;

  const FamilyTreeScreen({
    super.key,
    required this.mainFamilyDocId,
    required this.familyName,
  });

  @override
  Widget build(BuildContext context) {
    // Simply reuse the redesigned FamilyTreeView
    return FamilyTreeView(
      mainFamilyDocId: mainFamilyDocId,
      familyName: familyName,
    );
  }
}
