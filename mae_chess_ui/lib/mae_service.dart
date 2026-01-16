import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// --- DATA MODELS ---

class MaeGameProfile {
  final int blunderCount;
  final int avgDifficulty; // New Metric (0-100)
  final int pushups;       // New Metric
  final String playerType; // Derived helper
  final List<MaeAnalysisResult> moves;

  MaeGameProfile({
    required this.blunderCount,
    required this.avgDifficulty,
    required this.pushups,
    required this.playerType,
    required this.moves,
  });

  factory MaeGameProfile.fromJson(Map<String, dynamic> json) {
    var list = json['moves'] as List;
    List<MaeAnalysisResult> movesList = list.map((i) => MaeAnalysisResult.fromJson(i)).toList();
    
    var stats = json['stats'];

    // Derive a "Player Type" based on the stats
    String type = "Balanced";
    int avgDiff = stats['avg_difficulty'];
    if (avgDiff > 60) type = "Grandmaster Grinder"; // High difficulty tolerance
    else if (avgDiff < 20) type = "Solid / Passive";
    else type = "Tactical Human";

    return MaeGameProfile(
      blunderCount: stats['blunders'],
      avgDifficulty: avgDiff,
      pushups: stats['pushups'],
      playerType: type,
      moves: movesList,
    );
  }
}

class MaeAnalysisResult {
  final int moveNumber;
  final String moveUci;
  final String label;          // e.g. "Pragmatic Simplification"
  final String evalDisplay;    // e.g. "+1.50" or "#3"
  final double winChance;      // 0-100
  final int difficulty;        // 0-100 (PDI)
  final int risk;              // 0-100 (RVS)
  final double delta;          // Regret
  final String? bestMove;

  MaeAnalysisResult({
    required this.moveNumber,
    required this.moveUci,
    required this.label,
    required this.evalDisplay,
    required this.winChance,
    required this.difficulty,
    required this.risk,
    required this.delta,
    this.bestMove,
  });

  factory MaeAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MaeAnalysisResult(
      moveNumber: json['move_number'],
      moveUci: json['move_uci'],
      label: json['label'],
      evalDisplay: json['eval_display'],
      winChance: (json['win_chance'] as num).toDouble(),
      difficulty: json['difficulty'],
      risk: json['risk'],
      delta: (json['delta'] as num).toDouble(),
      bestMove: json['best_move'],
    );
  }
}

// --- SERVICE ---

class MaeService {
  // Update this to your machine's IP if testing on real device
  String get _baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000"; 
    return "http://localhost:8000";
  }

  Future<MaeGameProfile?> analyzeGame(String pgn, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-game'), // Updated Endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pgn": pgn,
          "username": username
        }),
      );

      if (response.statusCode == 200) {
        return MaeGameProfile.fromJson(jsonDecode(response.body));
      } else {
        print("Backend Error: ${response.body}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
    return null;
  }
}