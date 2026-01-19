import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// --- DATA MODELS ---
// Updated to match the actual API response from /analyze-pgn

class MaeGameProfile {
  final int blunderCount;
  final int mistakeCount;
  final int inaccuracyCount;
  final int totalProblems;
  final int pushups;
  final String player;
  final String opponent;
  final String playerColor;
  final String gameMode;
  final String? gameLink;
  final List<MaeAnalysisResult> moves;

  MaeGameProfile({
    required this.blunderCount,
    required this.mistakeCount,
    required this.inaccuracyCount,
    required this.totalProblems,
    required this.pushups,
    required this.player,
    required this.opponent,
    required this.playerColor,
    required this.gameMode,
    this.gameLink,
    required this.moves,
  });

  factory MaeGameProfile.fromJson(Map<String, dynamic> json) {
    // Parse problems list from API response
    var problemsList = json['problems'] as List? ?? [];
    List<MaeAnalysisResult> movesList = problemsList
        .map((i) => MaeAnalysisResult.fromJson(i))
        .toList();

    return MaeGameProfile(
      blunderCount: json['blunders'] ?? 0,
      mistakeCount: json['mistakes'] ?? 0,
      inaccuracyCount: json['inaccuracies'] ?? 0,
      totalProblems: json['total_problems'] ?? 0,
      pushups: json['pushups'] ?? 0,
      player: json['player'] ?? 'Unknown',
      opponent: json['opponent'] ?? 'Unknown',
      playerColor: json['player_color'] ?? 'white',
      gameMode: json['game_mode'] ?? 'unknown',
      gameLink: json['game_link'],
      moves: movesList,
    );
  }

  /// Derive a "Player Type" based on the stats
  String get playerType {
    if (blunderCount == 0 && mistakeCount == 0) {
      return "Solid Player";
    } else if (blunderCount >= 3) {
      return "Tactical Gambler";
    } else if (blunderCount == 0 && mistakeCount <= 2) {
      return "Careful Calculator";
    }
    return "Tactical Human";
  }
}

class MaeAnalysisResult {
  final int moveNumber;
  final String played; // The move played (SAN notation)
  final String bestMove; // Best move (SAN notation)
  final String severity; // "blunder", "mistake", "inaccuracy"
  final double regret; // Win probability lost (0-100)
  final String evalBefore; // Eval before move e.g. "+1.50"
  final String evalAfter; // Eval after move e.g. "+0.19"
  final bool hangingPiece; // Did move hang a piece?
  final int? mateThreat; // Mate threat (mate in N)
  final bool forcedLoss; // Forced material loss?
  final String? punishmentLine; // Opponent's best response
  final String gamePhase; // "opening", "middlegame", "endgame"

  MaeAnalysisResult({
    required this.moveNumber,
    required this.played,
    required this.bestMove,
    required this.severity,
    required this.regret,
    required this.evalBefore,
    required this.evalAfter,
    required this.hangingPiece,
    this.mateThreat,
    required this.forcedLoss,
    this.punishmentLine,
    required this.gamePhase,
  });

  factory MaeAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MaeAnalysisResult(
      moveNumber: json['move_number'] ?? 0,
      played: json['played'] ?? '?',
      bestMove: json['best_move'] ?? '?',
      severity: json['severity'] ?? 'inaccuracy',
      regret: (json['regret'] as num?)?.toDouble() ?? 0.0,
      evalBefore: json['eval_before'] ?? '0.00',
      evalAfter: json['eval_after'] ?? '0.00',
      hangingPiece: json['hanging_piece'] ?? false,
      mateThreat: json['mate_threat'],
      forcedLoss: json['forced_loss'] ?? false,
      punishmentLine: json['punishment_line'],
      gamePhase: json['game_phase'] ?? 'middlegame',
    );
  }

  /// User-friendly label for display
  String get label {
    switch (severity) {
      case 'blunder':
        return 'BLUNDER';
      case 'mistake':
        return 'Mistake';
      case 'inaccuracy':
        return 'Inaccuracy';
      default:
        return severity;
    }
  }

  /// Formatted eval for display (use evalAfter as current position)
  String get evalDisplay => evalAfter;

  /// Alias for compatibility
  String get moveUci => played;

  /// Regret as delta (compatibility alias)
  double get delta => regret;
}

// --- SERVICE ---

class MaeService {
  String get _baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://localhost:8000";
  }

  Future<Map<String, dynamic>?> analyzeGame({
    required String pgn,
    required String username,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/analyze-pgn?player=${Uri.encodeQueryComponent(username)}',
      );

      final response = await http.post(
        uri,
        headers: {"Content-Type": "text/plain"},
        body: pgn,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Backend Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
    }
    return null;
  }
}
