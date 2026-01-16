import 'package:flutter/material.dart';
import 'mae_service.dart';

class GameTimelineWidget extends StatelessWidget {
  final List<MaeAnalysisResult> history;
  final int currentIndex;
  final Function(int) onMoveSelected;

  const GameTimelineWidget({
    super.key,
    required this.history,
    required this.currentIndex,
    required this.onMoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final move = history[index];
          final bool isSelected = index == currentIndex;
          
          // New Color Logic based on Backend Labels
          Color chipColor = Colors.grey;
          
          if (move.label.contains("Blunder")) chipColor = Colors.red;
          else if (move.label.contains("Mistake")) chipColor = Colors.orange;
          else if (move.label.contains("Inaccuracy")) chipColor = Colors.yellow[700]!;
          else if (move.label.contains("Best") || move.label.contains("Excellent")) chipColor = Colors.green;
          else if (move.label.contains("Simplification")) chipColor = Colors.blueAccent;
          
          // Highlight Risk (RVS)
          bool isRisky = move.risk > 60;

          return GestureDetector(
            onTap: () => onMoveSelected(index),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : chipColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${move.moveNumber}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Tiny dot for High Risk
                  if (isRisky)
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.orangeAccent, 
                        shape: BoxShape.circle
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}