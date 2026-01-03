// lib/screens/user/user_explore_screen.dart

import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../../services/member_service.dart';
import 'member_detail_screen.dart';

class UserExploreScreen extends StatefulWidget {
  const UserExploreScreen({super.key});

  @override
  State<UserExploreScreen> createState() => _UserExploreScreenState();
}

class _UserExploreScreenState extends State<UserExploreScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.blue.shade900,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name or MID...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildQuickFilters(),
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Quick Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildFilterCard('All Members', Icons.people, Colors.blue),
              _buildFilterCard('Active', Icons.check_circle, Colors.green),
              _buildFilterCard(
                'New This Month',
                Icons.new_releases,
                Colors.orange,
              ),
              _buildFilterCard('Recent', Icons.schedule, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _searchQuery = title;
            _isSearching = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<MemberModel>>(
      stream: _memberService.streamAllMembers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!;

        final filteredMembers = members.where((member) {
          final searchLower = _searchQuery.toLowerCase();
          return member.fullName.toLowerCase().contains(searchLower) ||
              member.mid.toLowerCase().contains(searchLower) ||
              member.surname.toLowerCase().contains(searchLower) ||
              member.familyName.toLowerCase().contains(searchLower);
        }).toList();

        if (filteredMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No results for "$_searchQuery"'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) {
            final member = filteredMembers[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue.shade900,
                  backgroundImage: member.photoUrl.isNotEmpty
                      ? NetworkImage(member.photoUrl)
                      : null,
                  child: member.photoUrl.isEmpty
                      ? Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${member.surname} • ${member.familyName}'),
                    if (member.phone.isNotEmpty) Text(member.phone),
                  ],
                ),
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
    );
  }
}
