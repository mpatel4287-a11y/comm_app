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
        );
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

    // Build generations starting from head
    final generations = <List<Person>>[];
    final processed = <String>{};

    // Generation 0: Head of family and spouse
    if (headMember != null && headMember.mid.isNotEmpty && personMap.containsKey(headMember.mid)) {
      final headPerson = personMap[headMember.mid]!;
      final generation0 = [headPerson];
      processed.add(headMember.mid);

      // Add spouse if exists (relationToHead == 'wife' or 'husband')
      try {
        final spouse = members.firstWhere(
          (m) =>
              m.relationToHead == 'wife' ||
              (m.relationToHead == 'husband' && m.gender.toLowerCase() == 'male'),
        );

        if (spouse.mid.isNotEmpty &&
            personMap.containsKey(spouse.mid) &&
            !processed.contains(spouse.mid)) {
          generation0.add(personMap[spouse.mid]!);
          processed.add(spouse.mid);
        }
      } catch (e) {
        // No spouse found, continue without spouse
      }

      generations.add(generation0);
    }

    // Build subsequent generations
    int currentGenIndex = 0;
    while (currentGenIndex < generations.length) {
      final currentGeneration = generations[currentGenIndex];
      final nextGeneration = <Person>[];

      for (final person in currentGeneration) {
        if (person.childrenIds.isNotEmpty) {
          for (final childMid in person.childrenIds) {
            if (personMap.containsKey(childMid) &&
                !processed.contains(childMid)) {
              nextGeneration.add(personMap[childMid]!);
              processed.add(childMid);
            }
          }
        }
      }

      if (nextGeneration.isNotEmpty) {
        generations.add(nextGeneration);
        currentGenIndex++;
      } else {
        break;
      }
    }

    // Add any remaining members (orphans or those without proper parent links) to the last generation
    final remainingMembers = personMap.values
        .where((p) => !processed.contains(p.mid))
        .toList();
    if (remainingMembers.isNotEmpty) {
      if (generations.isEmpty) {
        generations.add(remainingMembers);
      } else if (generations.isNotEmpty) {
        generations.last.addAll(remainingMembers);
      }
    }

    return generations;
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


