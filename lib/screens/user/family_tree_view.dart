import 'package:flutter/material.dart';
import '../../widgets/family_tree.dart';
import '../../models/member_model.dart';
import '../../models/person.dart';
import '../../services/member_service.dart';

class FamilyTreeView extends StatefulWidget {
  final String mainFamilyDocId;
  final String familyName;
  final String? subFamilyDocId;

  const FamilyTreeView({
    super.key,
    required this.mainFamilyDocId,
    required this.familyName,
    this.subFamilyDocId,
  });

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  final MemberService _memberService = MemberService();
  bool _loading = true;
  List<List<Person>> _generations = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyTree();
  }

  Future<void> _loadFamilyTree() async {
    setState(() => _loading = true);

    try {
      // Get all members for this family
      final allMembers = await _memberService.getAllMembers();
      
      // Filter members for this specific family
      final familyMembers = allMembers.where((member) {
        return member.familyDocId == widget.mainFamilyDocId &&
            (widget.subFamilyDocId == null ||
                member.subFamilyDocId == widget.subFamilyDocId) &&
            member.isActive;
      }).toList();

      if (familyMembers.isEmpty) {
        setState(() {
          _generations = [];
          _loading = false;
        });
        return;
      }

      // Convert MemberModel to Person and build tree structure
      final generations = _buildFamilyTree(familyMembers);

      setState(() {
        _generations = generations;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading family tree: $e');
      setState(() {
        _generations = [];
        _loading = false;
      });
    }
  }

  List<List<Person>> _buildFamilyTree(List<MemberModel> members) {
    if (members.isEmpty) return [];

    // Create maps for quick lookup
    final Map<String, Person> personMap = {}; // MID -> Person
    final Map<String, List<String>> childrenMap = {}; // Parent MID -> List of child MIDs

    // Convert all members to Person objects
    for (final member in members) {
      final nameParts = member.fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : member.fullName;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : member.surname.isNotEmpty
              ? member.surname
              : '';

      // Extract birth year from birthDate
      int birthYear = DateTime.now().year - member.age;
      if (member.birthDate.isNotEmpty) {
        try {
          final parts = member.birthDate.split('/');
          if (parts.length == 3) {
            birthYear = int.parse(parts[2]);
          }
        } catch (e) {
          // Use calculated year if parsing fails
        }
      }

      final person = Person(
        id: member.id,
        firstName: firstName,
        lastName: lastName,
        birthYear: birthYear,
        gender: member.gender.toLowerCase() == 'female'
            ? Gender.female
            : Gender.male,
        photoUrl: member.photoUrl.isNotEmpty ? member.photoUrl : null,
        details: member.nativeHome.isNotEmpty
            ? 'Native: ${member.nativeHome}'
            : null,
        age: member.age,
        mid: member.mid,
        relationToHead: member.relationToHead,
        parentIds: member.parentMid.isNotEmpty ? [member.parentMid] : [],
      );

      personMap[member.mid] = person;

      // Build children map (parent MID -> children MIDs)
      if (member.parentMid.isNotEmpty && member.parentMid != member.mid) {
        if (!childrenMap.containsKey(member.parentMid)) {
          childrenMap[member.parentMid] = [];
        }
        childrenMap[member.parentMid]!.add(member.mid);
      }
    }

    // Update childrenIds for each person
    for (final entry in childrenMap.entries) {
      final parentMid = entry.key;
      if (personMap.containsKey(parentMid)) {
        final parent = personMap[parentMid]!;
        personMap[parentMid] = Person(
          id: parent.id,
          firstName: parent.firstName,
          lastName: parent.lastName,
          birthYear: parent.birthYear,
          gender: parent.gender,
          photoUrl: parent.photoUrl,
          details: parent.details,
          age: parent.age,
          mid: parent.mid,
          relationToHead: parent.relationToHead,
          parentIds: parent.parentIds,
          childrenIds: entry.value,
          spouseId: parent.spouseId,
        );
      }
    }

    // Match spouses
    final List<Person> allPeople = personMap.values.toList();
    for (final person in allPeople) {
      if (person.spouseId != null) continue;

      if (person.relationToHead?.toLowerCase() == 'head') {
        final wife = allPeople.firstWhere(
          (p) => p.relationToHead?.toLowerCase() == 'wife' && p.spouseId == null,
          orElse: () => allPeople.firstWhere(
            (p) => p.relationToHead?.toLowerCase() == 'husband' && p.spouseId == null && p.mid != person.mid,
            orElse: () => person,
          ),
        );
        if (wife != person) {
          personMap[person.mid!] = _linkSpouses(person, wife);
          personMap[wife.mid!] = _linkSpouses(wife, person);
        }
      } else if (person.relationToHead?.toLowerCase() == 'son') {
        // Try to find a daughter-in-law that hasn't been matched
        // In a more complex system, we'd check if they have common children.
        // For now, we'll match by order if there are multiple.
        try {
          final dil = allPeople.firstWhere(
            (p) => p.relationToHead?.toLowerCase() == 'daughter_in_law' && p.spouseId == null,
          );
          personMap[person.mid!] = _linkSpouses(person, dil);
          personMap[dil.mid!] = _linkSpouses(dil, person);
        } catch (e) {
          // No unmatched daughter-in-law found
        }
      }
    }

    // Find head of family (relationToHead == 'head')
    MemberModel? headMember;
    try {
      headMember = members.firstWhere(
        (m) => m.relationToHead == 'head' && m.isActive,
      );
    } catch (e) {
      // If no head found, use the member with no parent
      try {
        headMember = members.firstWhere(
          (m) => m.parentMid.isEmpty && m.isActive,
        );
      } catch (e2) {
        // If still not found, use first active member
        if (members.isNotEmpty) {
          headMember = members.first;
        }
      }
    }

    final generations = <List<Person>>[];
    final processed = <String>{};

    // Build generations starting from head
    if (headMember != null && headMember.mid.isNotEmpty && personMap.containsKey(headMember.mid)) {
      final headPerson = personMap[headMember.mid]!;
      final generation0 = [headPerson];
      processed.add(headPerson.mid!);

      if (headPerson.spouseId != null && personMap.containsKey(headPerson.spouseId)) {
        generation0.add(personMap[headPerson.spouseId!]!);
        processed.add(headPerson.spouseId!);
      }

      generations.add(generation0);
    }

    // Build subsequent generations
    int currentGenIndex = 0;
    while (currentGenIndex < generations.length) {
      final currentLevel = generations[currentGenIndex];
      final nextLevel = <Person>[];

      // Add children of each person in the current level
      for (final person in currentLevel) {
        if (person.childrenIds.isNotEmpty) {
          for (final childMid in person.childrenIds) {
            if (personMap.containsKey(childMid) && !processed.contains(childMid)) {
              final child = personMap[childMid]!;
              nextLevel.add(child);
              processed.add(child.mid!);

              // Also add child's spouse if exists and in the same generation
              if (child.spouseId != null && 
                  personMap.containsKey(child.spouseId) && 
                  !processed.contains(child.spouseId)) {
                nextLevel.add(personMap[child.spouseId!]!);
                processed.add(child.spouseId!);
              }
            }
          }
        }
      }

      if (nextLevel.isNotEmpty) {
        generations.add(nextLevel);
        currentGenIndex++;
      } else {
        break;
      }
    }

    // Add any remaining members
    final remaining = personMap.values.where((p) => !processed.contains(p.mid)).toList();
    if (remaining.isNotEmpty) {
      if (generations.isEmpty) {
        generations.add(remaining);
      } else {
        generations.last.addAll(remaining);
      }
    }

    return generations;
  }

  Person _linkSpouses(Person p1, Person p2) {
    return Person(
      id: p1.id,
      firstName: p1.firstName,
      lastName: p1.lastName,
      birthYear: p1.birthYear,
      gender: p1.gender,
      photoUrl: p1.photoUrl,
      details: p1.details,
      age: p1.age,
      mid: p1.mid,
      relationToHead: p1.relationToHead,
      parentIds: p1.parentIds,
      childrenIds: p1.childrenIds,
      spouseId: p2.mid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.familyName} - Family Tree',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE8E8E8),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _generations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_tree,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No family members found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : FamilyTree(
                  generations: _generations,
                ),
    );
  }
}


