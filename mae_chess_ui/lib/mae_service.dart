import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// --- DATA MODELS ---

class MaeGameProfile {
  final int masteryScore;
  final String playerType;
  final double avgFragility;
  final double avgChaos;
  final List<MaeAnalysisResult> moves;

  MaeGameProfile({
    required this.masteryScore,
    required this.playerType,
    required this.avgFragility,
    required this.avgChaos,
    required this.moves,
  });

  factory MaeGameProfile.fromJson(Map<String, dynamic> json) {
    var list = json['moves_analysis'] as List;
    List<MaeAnalysisResult> movesList = list.map((i) => MaeAnalysisResult.fromJson(i)).toList();

    return MaeGameProfile(
      masteryScore: json['mastery_score'],
      playerType: json['player_type'],
      avgFragility: json['avg_fragility']?.toDouble() ?? 0.0,
      avgChaos: json['avg_chaos']?.toDouble() ?? 0.0,
      moves: movesList,
    );
  }
}

class MaeAnalysisResult {
  final String fen;
  final int moveNumber;
  final int scoreCp;
  final double winningChance;
  final bool isVolatile;
  final double fragility;
  final double chaos;
  final String bestMoveUci;
  final String bestLine;
  final String explanation;

  MaeAnalysisResult({
    required this.fen,
    required this.moveNumber,
    required this.scoreCp,
    required this.winningChance,
    required this.isVolatile,
    required this.fragility,
    required this.chaos,
    required this.bestMoveUci,
    required this.bestLine,
    required this.explanation,
  });

  factory MaeAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Handle Arrows carefully (might be empty on game over)
    String moveUci = "";
    if (json['arrows'] != null && (json['arrows'] as List).isNotEmpty) {
      moveUci = json['arrows'][0]['move_uci'];
    }

    return MaeAnalysisResult(
      fen: json['fen'],
      moveNumber: json['move_number'] ?? 0,
      scoreCp: json['eval_bar']['score_cp'],
      winningChance: json['eval_bar']['winning_chance'],
      isVolatile: json['eval_bar']['is_volatile'],
      fragility: json['telemetry']['fragility_score']?.toDouble() ?? 0.0,
      chaos: json['telemetry']['chaos_score']?.toDouble() ?? 0.0,
      bestMoveUci: moveUci,
      bestLine: json['best_line']['truncated_line'],
      explanation: json['best_line']['explanation'],
    );
  }
}

// --- SERVICE ---

class MaeService {
  String get _baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://localhost:8000";
  }

  // Analyze Single Position (Legacy support)
  Future<MaeAnalysisResult?> analyzePosition(String fen) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fen": fen}),
      );

      if (response.statusCode == 200) {
        // Wrap single response to match structure if needed, or just parse
        return MaeAnalysisResult.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }

  // Analyze Full Game (NEW)
  Future<MaeGameProfile?> analyzeGame(String pgn) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/game'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pgn": pgn}),
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