// lib/screens/user/user_home_screen.dart

// ignore_for_file: unused_field, unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import 'member_detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final MemberService _memberService = MemberService();
  String _searchQuery = '';
  String? _selectedFamilyFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community App'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: MemberSearchDelegate());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsSection(),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search members...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Member List
          Expanded(
            child: StreamBuilder<List<MemberModel>>(
              stream: _memberService.streamAllMembers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data!;

                // Filter by search query
                final filteredMembers = members.where((member) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      member.fullName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      member.mid.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                  return matchesSearch;
                }).toList();

                if (filteredMembers.isEmpty) {
                  return const Center(child: Text('No members found'));
                }

                return ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade900,
                          backgroundImage: member.photoUrl.isNotEmpty
                              ? NetworkImage(member.photoUrl)
                              : null,
                          child: member.photoUrl.isEmpty
                              ? Text(
                                  member.fullName.isNotEmpty
                                      ? member.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(member.fullName),
                        subtitle: Text('${member.familyName} • ${member.mid}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MemberDetailScreen(memberId: member.id),
                            ),
                          );
                        },
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

  Widget _buildStatsSection() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _memberService.getMemberCount(),
        _memberService.getActiveMemberCount(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final totalMembers = snapshot.data![0];
        final activeMembers = snapshot.data![1];

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Members',
                  totalMembers.toString(),
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  activeMembers.toString(),
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue.shade900),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MemberSearchDelegate extends SearchDelegate {
  final MemberService _memberService = MemberService();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<MemberModel>>(
      stream: _memberService.searchMembers(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!;
        if (members.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade900,
                child: Text(
                  member.fullName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(member.fullName),
              subtitle: Text('${member.mid} • ${member.familyName}'),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MemberDetailScreen(memberId: member.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search for members by name or ID'));
  }
}
