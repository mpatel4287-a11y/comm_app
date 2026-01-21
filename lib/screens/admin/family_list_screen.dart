// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/family_service.dart';
import 'add_family_screen.dart';
import 'subfamily_list_screen.dart';

class FamilyListScreen extends StatelessWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Families'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('families')
            .where('isAdmin', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No families found'));
          }

          final families = snapshot.data!.docs;
          // Client-side sort by familyId
          families.sort((a, b) {
            final idA = (a.data() as Map<String, dynamic>)['familyId'] ?? '';
            final idB = (b.data() as Map<String, dynamic>)['familyId'] ?? '';
            return idA.toString().compareTo(idB.toString());
          });

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85, // Slightly taller to prevent overflow
            ),
            itemCount: families.length,
            itemBuilder: (context, index) {
              final doc = families[index];
              final data = doc.data() as Map<String, dynamic>;

              final familyName =
                  data['familyName']?.toString() ?? 'Unnamed Family';
              final familyId = data['familyId']?.toString() ?? '------';
              final isBlocked = data['isBlocked'] == true;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubFamilyListScreen(
                        mainFamilyDocId: doc.id,
                        mainFamilyId: familyId,
                        mainFamilyName: familyName,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isBlocked ? Colors.grey.shade200 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER WITH ICON
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isBlocked
                                  ? Colors.grey
                                  : Colors.blue.shade900,
                              child: const Icon(
                                Icons.family_restroom,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            if (isBlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BLOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // FAMILY NAME
                        Text(
                          familyName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color:
                                isBlocked ? Colors.grey.shade700 : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // FAMILY ID
                        Text(
                          'ID: $familyId',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                        const Spacer(),

                        // ACTIONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // BLOCK / UNBLOCK
                            _buildCompactAction(
                              icon: isBlocked ? Icons.lock_open : Icons.block,
                              color: isBlocked ? Colors.green : Colors.orange,
                              onTap: () async {
                                await FamilyService()
                                    .toggleBlockFamily(doc.id);
                              },
                            ),

                            // DELETE
                            _buildCompactAction(
                              icon: Icons.delete,
                              color: Colors.red,
                              onTap: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Family'),
                                    content: const Text(
                                      'Are you sure? This deletes all members.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok == true) {
                                  await FamilyService().deleteFamily(doc.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFamilyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
