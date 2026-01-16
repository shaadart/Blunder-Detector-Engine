import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroHeaderWidget extends StatelessWidget {
  final int avgDifficulty; // 0-100 PDI
  final int pushups;       // Accountability
  final String playerType;
  final VoidCallback onUploadPressed;

  const HeroHeaderWidget({
    super.key,
    required this.avgDifficulty,
    required this.pushups,
    required this.playerType,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Green = High Difficulty (You played complex chess), Red = Low (Boring)
    Color scoreColor = avgDifficulty > 50 
        ? const Color(0xFF00E5FF) // Cyan/Green for High Skill
        : (avgDifficulty > 30 ? Colors.orangeAccent : Colors.grey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: Stats & Upload
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MAE ANALYSIS",
                    style: GoogleFonts.oswald(fontSize: 14, color: Colors.white54, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  // Pushup Penalty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "$pushups Pushups Due",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onUploadPressed,
                    child: Text(
                      "Import New Game >",
                      style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // RIGHT: Difficulty Meter
              CircularPercentIndicator(
                radius: 45.0,
                lineWidth: 8.0,
                animation: true,
                percent: (avgDifficulty / 100).clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$avgDifficulty",
                      style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white),
                    ),
                    const Text("DIFFICULTY", style: TextStyle(fontSize: 8, color: Colors.white54)),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.white10,
                progressColor: scoreColor,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // BOTTOM: Insight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: scoreColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Insight: You played like a $playerType. The game had ${pushups ~/ 10} major blunders in high-risk positions.",
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}