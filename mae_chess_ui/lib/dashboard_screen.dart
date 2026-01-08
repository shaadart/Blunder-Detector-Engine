import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:mae_chess_ui/game_timeline.dart';
import 'package:mae_chess_ui/hero_header.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'mae_service.dart';
import 'radar_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ChessBoardController _controller = ChessBoardController();
  final MaeService _maeService = MaeService();

  // Single Move Analysis
  MaeAnalysisResult? _currentAnalysis;
  bool _isLoading = false;
  List<BoardArrow> _arrows = [];

  // Full Game Mode Data
  MaeGameProfile? _gameProfile;
  int _historyIndex = 0;
  bool _isGameMode = false;

  // Header Data
  int _masteryScore = 0;
  String _playerType = "Unknown";

  @override
  void initState() {
    super.initState();
    _analyzePosition(); // Analyze starting position
  }

  // --- LOGIC ---

  Future<void> _analyzePosition() async {
    // If we are in Game Mode, do NOT re-analyze with backend. 
    // Just show the cached data from the profile.
    if (_isGameMode && _gameProfile != null) {
      _loadHistoryFrame(_historyIndex);
      return;
    }

    setState(() => _isLoading = true);
    String fen = _controller.getFen();
    final result = await _maeService.analyzePosition(fen);

    if (mounted) {
      setState(() {
        _currentAnalysis = result;
        _isLoading = false;
        _updateArrows(result);
      });
    }
  }

  Future<void> _uploadPgn() async {
    // Show Dialog to paste PGN
    TextEditingController pgnController = TextEditingController();
    
    // Default PGN for testing (The Opera Game)
    pgnController.text = '[Event "Paris Opera House"]\n[Site "Paris"]\n[Date "1858.??.??"]\n[Round "?"]\n[White "Paul Morphy"]\n[Black "Duke Karl / Count Isouard"]\n[Result "1-0"]\n\n1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5 6. Bc4 Nf6 7. Qb3 Qe7 8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7 12. O-O-O Rd8 13. Rxd7 Rxd7 14. Rd1 Qe6 15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8# 1-0';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Import PGN", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pgnController,
          maxLines: 8,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Courier', fontSize: 12),
          decoration: const InputDecoration(
            hintText: "Paste PGN here...",
            hintStyle: TextStyle(color: Colors.white24),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processFullGame(pgnController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            child: const Text("ANALYZE GAME", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _processFullGame(String pgn) async {
    setState(() => _isLoading = true);
    
    final profile = await _maeService.analyzeGame(pgn);

    if (mounted && profile != null) {
      setState(() {
        _gameProfile = profile;
        _isGameMode = true;
        _historyIndex = 0;
        _masteryScore = profile.masteryScore;
        _playerType = profile.playerType;
        _isLoading = false;
      });
      // Load the first move
      _loadHistoryFrame(0);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _loadHistoryFrame(int index) {
    if (_gameProfile == null) return;
    
    // Ensure index bounds
    if (index < 0) index = 0;
    if (index >= _gameProfile!.moves.length) index = _gameProfile!.moves.length - 1;

    final frame = _gameProfile!.moves[index];

    setState(() {
      _historyIndex = index;
      _currentAnalysis = frame;
      _controller.loadFen(frame.fen); // Update the board visually
      _updateArrows(frame);
    });
  }

  void _updateArrows(MaeAnalysisResult? result) {
    _arrows.clear();
    if (result != null && result.bestMoveUci.isNotEmpty) {
      if (result.bestMoveUci.length >= 4) {
        _arrows.add(BoardArrow(
          from: result.bestMoveUci.substring(0, 2),
          to: result.bestMoveUci.substring(2, 4),
          color: Colors.cyanAccent.withOpacity(0.8),
        ));
      }
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // 1. HERO HEADER
            HeroHeaderWidget(
              score: _masteryScore,
              playerType: _playerType,
              onUploadPressed: _uploadPgn,
            ),

            // 2. MAIN CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildEvalBar(),
                    const SizedBox(height: 10),
                    
                    // Board
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: ChessBoard(
                          controller: _controller,
                          boardColor: BoardColor.brown,
                          boardOrientation: PlayerColor.white,
                          arrows: _arrows,
                          enableUserMoves: !_isGameMode, // Disable manual moves in review mode
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildControlPanel(),
                    const SizedBox(height: 10),
                    
                    // Mentor Panel
                    SizedBox(
                      height: 150,
                      child: _buildMentorPanel(),
                    ),
                  ],
                ),
              ),
            ),
            
            // 3. TIMELINE (Only visible in Game Mode)
            if (_isGameMode && _gameProfile != null)
              GameTimelineWidget(
                history: _gameProfile!.moves,
                currentIndex: _historyIndex,
                onMoveSelected: (index) => _loadHistoryFrame(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalBar() {
    double percent = _currentAnalysis?.winningChance ?? 0.5;
    bool isVolatile = _currentAnalysis?.isVolatile ?? false;
    final barColor = isVolatile ? Colors.pinkAccent : Colors.cyanAccent;
    List<BoxShadow>? glow = isVolatile
        ? [BoxShadow(color: barColor.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)]
        : null;

    return Container(
      decoration: BoxDecoration(boxShadow: glow),
      child: LinearPercentIndicator(
        lineHeight: 8.0,
        percent: percent,
        backgroundColor: Colors.grey[800],
        progressColor: barColor,
        barRadius: const Radius.circular(4),
        animation: true,
        animateFromLastPercent: true,
      ),
    );
  }

  Widget _buildControlPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navButton(Icons.first_page, () {
          if (_isGameMode) _loadHistoryFrame(0);
          else { _controller.resetBoard(); _analyzePosition(); }
        }),
        _navButton(Icons.chevron_left, () {
          if (_isGameMode) _loadHistoryFrame(_historyIndex - 1);
          else { _controller.undoMove(); _analyzePosition(); }
        }),
        FloatingActionButton(
          mini: true,
          backgroundColor: Colors.cyanAccent,
          onPressed: _isGameMode ? null : _analyzePosition, // Disable manual analyze in review
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Icon(Icons.psychology, color: Colors.black, size: 20),
        ),
        _navButton(Icons.chevron_right, () {
          if (_isGameMode) _loadHistoryFrame(_historyIndex + 1);
        }),
        _navButton(Icons.last_page, () {
           if (_isGameMode && _gameProfile != null) _loadHistoryFrame(_gameProfile!.moves.length - 1);
        }),
      ],
    );
  }

  Widget _navButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70),
      iconSize: 28,
      onPressed: onPressed,
    );
  }

  Widget _buildMentorPanel() {
    if (_currentAnalysis == null) {
      return const Center(child: Text("Waiting for telemetry...", style: TextStyle(color: Colors.white54)));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          MaeRadarChart(
            objective: _currentAnalysis!.winningChance,
            fragility: _currentAnalysis!.fragility,
            chaos: _currentAnalysis!.chaos,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text("RECOMMENDATION: ", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 10)),
                    Text(
                      _currentAnalysis!.bestMoveUci.toUpperCase(),
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Courier'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _currentAnalysis!.explanation,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Fragility: ${(_currentAnalysis!.fragility * 100).toInt()}% | Chaos: ${(_currentAnalysis!.chaos * 100).toInt()}%",
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}