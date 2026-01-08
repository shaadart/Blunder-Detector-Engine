import 'package:flutter/material.dart';
import 'mae_service.dart'; // To access data models

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
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final move = history[index];
          final bool isSelected = index == currentIndex;
          
          // Color Logic:
          // Green = Low Chaos
          // Orange = High Chaos/Fragility
          // Red = Blunder (Huge CP swing, logic approximated here)
          Color chipColor = Colors.greenAccent;
          if (move.isVolatile) chipColor = Colors.orangeAccent;
          if (move.fragility > 0.8) chipColor = Colors.redAccent;

          return GestureDetector(
            onTap: () => onMoveSelected(index),
            child: Container(
              width: 45,
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
                    "${index + 1}",
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  // Tiny dot for chaos
                  if (move.chaos > 0.5)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4, height: 4,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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