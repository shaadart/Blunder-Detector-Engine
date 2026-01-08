import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;

class MaeAnalysisResult {
  final int scoreCp;
  final double winningChance;
  final bool isVolatile;
  // NEW FIELDS
  final double fragility; 
  final double chaos;

  final String bestMoveUci;
  final String bestLine;
  final String explanation;

  MaeAnalysisResult({
    required this.scoreCp,
    required this.winningChance,
    required this.isVolatile,
    required this.fragility, // New
    required this.chaos,     // New
    required this.bestMoveUci,
    required this.bestLine,
    required this.explanation,
  });

  factory MaeAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MaeAnalysisResult(
      scoreCp: json['eval_bar']['score_cp'],
      winningChance: json['eval_bar']['winning_chance'],
      isVolatile: json['eval_bar']['is_volatile'],
      // Parse new Telemetry block
      fragility: json['telemetry']['fragility_score']?.toDouble() ?? 0.0,
      chaos: json['telemetry']['chaos_score']?.toDouble() ?? 0.0,
      
      bestMoveUci: json['arrows'][0]['move_uci'],
      bestLine: json['best_line']['truncated_line'],
      explanation: json['best_line']['explanation'],
    );
  }
}

class MaeService {
  // Android Emulator uses 10.0.2.2 to access localhost
  // Web/iOS uses localhost
  String get _baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://localhost:8000";
  }

  Future<MaeAnalysisResult?> analyzePosition(String fen) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fen": fen}),
      );

      if (response.statusCode == 200) {
        return MaeAnalysisResult.fromJson(jsonDecode(response.body));
      } else {
        print("Backend Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Connection Error: $e");
      return null;
    }
  }
}