// lib/screens/admin/firms_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import '../../services/language_service.dart';
import '../../widgets/animation_utils.dart';
import '../user/member_detail_screen.dart';

class FirmsListScreen extends StatefulWidget {
  const FirmsListScreen({super.key});

  @override
  State<FirmsListScreen> createState() => _FirmsListScreenState();
}

class _FirmsListScreenState extends State<FirmsListScreen> {
  final MemberService _memberService = MemberService();
  String _searchQuery = '';

  // Extract unique firms from members
  Map<String, List<MemberModel>> _getFirmsMap(List<MemberModel> members) {
    final Map<String, List<MemberModel>> firmsMap = {};
    
    for (final member in members) {
      for (final firm in member.firms) {
        final firmName = firm['name'] ?? '';
        if (firmName.isNotEmpty) {
          if (!firmsMap.containsKey(firmName)) {
            firmsMap[firmName] = [];
          }
          firmsMap[firmName]!.add(member);
        }
      }
    }
    
    return firmsMap;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('firms')),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search firms...',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Firms List
          Expanded(
            child: StreamBuilder<List<MemberModel>>(
              stream: _memberService.streamAllMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PulseAnimation(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade700,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading firms...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No firms found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final firmsMap = _getFirmsMap(snapshot.data!);
                final filteredFirms = firmsMap.entries.where((entry) {
                  if (_searchQuery.isEmpty) return true;
                  return entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

                if (filteredFirms.isEmpty) {
                  return Center(
                    child: Text(
                      'No firms match your search',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredFirms.length,
                  itemBuilder: (context, index) {
                    final firmEntry = filteredFirms[index];
                    final firmName = firmEntry.key;
                    final members = firmEntry.value;
                    
                    return SlideInAnimation(
                      delay: Duration(milliseconds: 50 * index),
                      beginOffset: const Offset(0, 0.2),
                      child: AnimatedCard(
                        borderRadius: 16,
                        margin: const EdgeInsets.only(bottom: 12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FirmDetailScreen(
                                firmName: firmName,
                                members: members,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange.shade50,
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Firm Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: Colors.orange.shade700,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Firm Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      firmName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.groups_2,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Arrow
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey.shade400,
                                size: 16,
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
          ),
        ],
      ),
    );
  }
}

// Firm Detail Screen
class FirmDetailScreen extends StatelessWidget {
  final String firmName;
  final List<MemberModel> members;

  const FirmDetailScreen({
    super.key,
    required this.firmName,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(firmName),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Column(
        children: [
          // Header with total count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade600,
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.store,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Members',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '${members.length}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Members List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                
                return SlideInAnimation(
                  delay: Duration(milliseconds: 30 * index),
                  beginOffset: const Offset(0, 0.1),
                  child: AnimatedCard(
                    borderRadius: 12,
                    margin: const EdgeInsets.only(bottom: 8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberDetailScreen(
                            memberId: member.id,
                            familyDocId: member.familyDocId,
                            subFamilyDocId: member.subFamilyDocId,
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        backgroundImage: member.photoUrl.isNotEmpty && member.photoUrl.startsWith('http')
                            ? NetworkImage(member.photoUrl)
                            : null,
                        child: member.photoUrl.isEmpty || !member.photoUrl.startsWith('http')
                            ? Text(
                                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${member.mid} • ${member.familyName}'),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
