import 'package:flutter/material.dart';
import '../widgets/family_tree.dart';
import '../data/sample_family_data.dart';

class FamilyTreeScreen extends StatelessWidget {
  const FamilyTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Family Tree',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
      ),
      body: FamilyTree(
        generations: SampleFamilyData.getSampleGenerations(),
      ),
    );
  }
}
