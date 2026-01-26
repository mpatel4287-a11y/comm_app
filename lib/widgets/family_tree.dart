import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/person.dart';
import 'person_card.dart';
import 'person_detail_dialog.dart';
import 'animation_utils.dart';

class FamilyTree extends StatefulWidget {
  final List<List<Person>> generations;
  final double cardWidth;
  final double cardHeight;
  final double generationSpacing;
  final double siblingSpacing;

  const FamilyTree({
    super.key,
    required this.generations,
    this.cardWidth = 120,
    this.cardHeight = 140,
    this.generationSpacing = 60,
    this.siblingSpacing = 15,
  });

  @override
  State<FamilyTree> createState() => _FamilyTreeState();
}

class _FamilyTreeState extends State<FamilyTree> {
  final Map<String, GlobalKey> _cardKeys = {};
  final Map<String, Offset> _cardPositions = {};

  @override
  void initState() {
    super.initState();
    // Initialize card keys for all persons
    for (final generation in widget.generations) {
      for (final person in generation) {
        _cardKeys[person.id] = GlobalKey();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: _FamilyTreePainter(
                    generations: widget.generations,
                    cardPositions: _cardPositions,
                    cardWidth: widget.cardWidth,
                    cardHeight: widget.cardHeight,
                    generationSpacing: widget.generationSpacing,
                    siblingSpacing: widget.siblingSpacing,
                  ),
                  child: Column(
                    children: _buildGenerations(context),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGenerations(BuildContext context) {
    List<Widget> generationWidgets = [];
    
    for (int i = 0; i < widget.generations.length; i++) {
      generationWidgets.add(_buildGeneration(context, widget.generations[i], i));
      
      if (i < widget.generations.length - 1) {
        generationWidgets.add(SizedBox(height: widget.generationSpacing));
      }
    }
    
    // Update positions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCardPositions();
    });
    
    return generationWidgets;
  }

  void _updateCardPositions() {
    final RenderBox? treeBox = context.findRenderObject() as RenderBox?;
    if (treeBox == null) return;

    final Map<String, Offset> newPositions = {};
    for (final entry in _cardKeys.entries) {
      final RenderBox? cardBox = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (cardBox != null) {
        final position = cardBox.localToGlobal(Offset.zero, ancestor: treeBox);
        newPositions[entry.key] = position;
      }
    }
    
    if (mounted) {
      setState(() {
        _cardPositions.clear();
        _cardPositions.addAll(newPositions);
      });
    }
  }

  Widget _buildGeneration(BuildContext context, List<Person> people, int generationIndex) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: widget.siblingSpacing,
      runSpacing: 10,
      children: people.asMap().entries.map((entry) {
        final index = entry.key;
        final person = entry.value;
        return SlideInAnimation(
          delay: Duration(milliseconds: 100 + (generationIndex * 50) + (index * 30)),
          beginOffset: const Offset(0, 0.2),
          child: _buildPersonCard(context, person),
        );
      }).toList(),
    );
  }

  Widget _buildPersonCard(BuildContext context, Person person) {
    return Container(
      key: _cardKeys[person.id],
      child: PersonCard(
        person: person,
        width: widget.cardWidth,
        height: widget.cardHeight,
        onTap: () => _showPersonDetails(context, person),
      ),
    );
  }

  void _showPersonDetails(BuildContext context, Person person) {
    showDialog(
      context: context,
      builder: (context) => PersonDetailDialog(person: person),
    );
  }
}

/// Custom painter to draw connecting lines between family members
class _FamilyTreePainter extends CustomPainter {
  final List<List<Person>> generations;
  final Map<String, Offset> cardPositions;
  final double cardWidth;
  final double cardHeight;
  final double generationSpacing;
  final double siblingSpacing;

  _FamilyTreePainter({
    required this.generations,
    required this.cardPositions,
    required this.cardWidth,
    required this.cardHeight,
    required this.generationSpacing,
    required this.siblingSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cardPositions.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw lines from parents to children
    for (int genIndex = 0; genIndex < generations.length - 1; genIndex++) {
      final currentGen = generations[genIndex];
      final nextGen = generations[genIndex + 1];

      for (final parent in currentGen) {
        final parentPos = cardPositions[parent.id];
        if (parentPos == null) continue;

        final parentCenter = Offset(
          parentPos.dx + cardWidth / 2,
          parentPos.dy + cardHeight,
        );

        // Find children of this parent
        final children = nextGen.where((child) => 
          child.parentIds.contains(parent.id)
        ).toList();

        if (children.isEmpty) continue;

        // Draw line from parent to midpoint
        final childPositions = children
            .map((child) => cardPositions[child.id])
            .where((pos) => pos != null)
            .map((pos) => Offset(pos!.dx + cardWidth / 2, pos.dy))
            .toList();

        if (childPositions.isEmpty) continue;

        // Calculate midpoint of children
        final midY = childPositions.first.dy;

        // Draw vertical line from parent down
        canvas.drawLine(
          parentCenter,
          Offset(parentCenter.dx, midY - generationSpacing / 2),
          paint,
        );

        // Draw horizontal line connecting children
        if (childPositions.length > 1) {
          final minX = childPositions.map((p) => p.dx).reduce(math.min);
          final maxX = childPositions.map((p) => p.dx).reduce(math.max);
          canvas.drawLine(
            Offset(minX, midY - generationSpacing / 2),
            Offset(maxX, midY - generationSpacing / 2),
            paint,
          );
        }

        // Draw lines from horizontal line to each child
        for (final childPos in childPositions) {
          canvas.drawLine(
            Offset(childPos.dx, midY - generationSpacing / 2),
            childPos,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FamilyTreePainter oldDelegate) {
    return cardPositions != oldDelegate.cardPositions ||
        generations != oldDelegate.generations;
  }
}
