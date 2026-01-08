import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroHeaderWidget extends StatelessWidget {
  final int score; // 0 to 100
  final String playerType; // e.g., "Risk Master", "Solid Defender"
  final VoidCallback onUploadPressed;

  const HeroHeaderWidget({
    super.key,
    required this.score,
    required this.playerType,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Color logic: Green for high score, Yellow for mid, Red for low
    Color scoreColor = score > 75 
        ? const Color(0xFF00E5FF) // Cyan
        : (score > 50 ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: Title & Upload
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PRACTICAL MASTERY",
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onUploadPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.upload_file, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Import PGN",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // RIGHT: The Glowing Score Badge
              CircularPercentIndicator(
                radius: 45.0,
                lineWidth: 8.0,
                animation: true,
                percent: score / 100,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$score",
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "SCORE",
                      style: const TextStyle(fontSize: 8, color: Colors.white54),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.white10,
                progressColor: scoreColor,
                // The Glow Effect
                widgetIndicator: Center(
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scoreColor,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // BOTTOM: The Insight Badge
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.insights, color: scoreColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "ANALYSIS: You are a $playerType. You excel at managing chaos (High RVS) but missed 2 simplifications.",
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