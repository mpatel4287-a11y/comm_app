import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyListScreen extends StatelessWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Families')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('families')
            .where('isAdmin', isEqualTo: false)
            .orderBy('familyId')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No families found'));
          }

          final families = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
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
                  // 🔒 NEXT PHASE:
                  // Navigate to family members screen
                  Navigator.pushNamed(
                    context,
                    '/admin/family',
                    arguments: {
                      'familyDocId': doc.id,
                      'familyName': familyName,
                      'familyId': familyId,
                    },
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FAMILY NAME
                        Text(
                          familyName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // FAMILY ID
                        Text(
                          'ID: $familyId',
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const Spacer(),

                        // STATUS + ACTIONS
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isBlocked ? 'Blocked' : 'Active',
                                style: TextStyle(
                                  color: isBlocked ? Colors.red : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),

                            // EDIT
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/admin/editFamily',
                                  arguments: doc.id,
                                );
                              },
                            ),

                            // BLOCK / UNBLOCK
                            IconButton(
                              icon: Icon(
                                isBlocked ? Icons.lock_open : Icons.block,
                                size: 20,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('families')
                                    .doc(doc.id)
                                    .update({'isBlocked': !isBlocked});
                              },
                            ),

                            // DELETE
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Family'),
                                    content: const Text(
                                      'Are you sure you want to delete this family?',
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
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok == true) {
                                  await FirebaseFirestore.instance
                                      .collection('families')
                                      .doc(doc.id)
                                      .delete();
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
    );
  }
}
