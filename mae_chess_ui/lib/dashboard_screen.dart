import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'mae_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ChessBoardController _controller = ChessBoardController();
  final MaeService _maeService = MaeService();
  
  // State variables for our "Telemetry"
  MaeAnalysisResult? _currentAnalysis;
  bool _isLoading = false;
  List<BoardArrow> _arrows = [];

  @override
  void initState() {
    super.initState();
    // Analyze the starting position immediately
    _analyzePosition();
  }

  /// The Brain: Sends current FEN to Docker Backend
  Future<void> _analyzePosition() async {
    setState(() => _isLoading = true);

    // Get the FEN from the board controller
    String fen = _controller.getFen();
    
    final result = await _maeService.analyzePosition(fen);

    if (mounted) {
      setState(() {
        _currentAnalysis = result;
        _isLoading = false;
        
        // Draw the arrow if we have a best move
        _arrows.clear();
        if (result != null && result.bestMoveUci.isNotEmpty) {
          _arrows.add(_parseArrow(result.bestMoveUci));
        }
      });
    }
  }

  /// Helper: Converts "e2e4" string to a BoardArrow object
  BoardArrow _parseArrow(String uci) {
    // UCI is always 4 or 5 chars (e2e4 or e7e8q)
    String from = uci.substring(0, 2);
    String to = uci.substring(2, 4);
    
    return BoardArrow(
      from: from,
      to: to,
      color: Colors.cyanAccent.withOpacity(0.8), // The "Engine" Arrow
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout: Use Column for Mobile, Row for Web could be added later.
    // We stick to a clean vertical stack for the MVP.
    return Scaffold(
      appBar: AppBar(
        title: const Text("MAE // COCKPIT"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.resetBoard();
              _analyzePosition();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. THE EVALUATION BAR (With Glow Logic)
            _buildEvalBar(),
            
            const SizedBox(height: 20),

            // 2. THE CHESS BOARD
            Expanded(
              flex: 3,
              child: Center(
                child: ChessBoard(
                  controller: _controller,
                  boardColor: BoardColor.brown, // Classic look, high contrast
                  boardOrientation: PlayerColor.white,
                  arrows: _arrows,
                  onMove: () {
                    // Auto-analyze when user makes a move
                    _analyzePosition();
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. NAVIGATION CONTROLS
            _buildControlPanel(),

            const SizedBox(height: 20),

            // 4. THE MENTOR PANEL (Best Move & Explanation)
            Expanded(
              flex: 1,
              child: _buildMentorPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalBar() {
    // Default to 50% if loading
    double percent = _currentAnalysis?.winningChance ?? 0.5;
    bool isVolatile = _currentAnalysis?.isVolatile ?? false;

    // The Logic: If volatile (risky), glow Pink. If stable, glow Cyan.
    final barColor = isVolatile ? Colors.pink : Colors.cyan;
    List<BoxShadow>? glow = isVolatile 
        ? [BoxShadow(color: barColor.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 2)] 
        : null;

    return Container(
      decoration: BoxDecoration(boxShadow: glow),
      child: LinearPercentIndicator(
        lineHeight: 12.0,
        percent: percent,
        backgroundColor: Colors.grey[800],
        progressColor: barColor,
        barRadius: const Radius.circular(6),
        animation: true,
        animateFromLastPercent: true,
        center: Text(
          _currentAnalysis == null 
              ? "Initializing..." 
              : "${(_currentAnalysis!.scoreCp / 100).toStringAsFixed(1)}",
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navButton(Icons.first_page, () {
          // Note: resetBoard clears history in some versions, 
          // usually we'd implement full history navigation here.
          // For MVP, reset is "First".
          _controller.resetBoard();
          _analyzePosition();
        }),
        _navButton(Icons.chevron_left, () {
          _controller.undoMove();
          _analyzePosition();
        }),
        // Analyze button for manual trigger
        FloatingActionButton(
          backgroundColor: Colors.cyan[300],
          onPressed: _analyzePosition,
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.black) 
            : const Icon(Icons.psychology, color: Colors.black),
        ),
        // Forward button (Note: chess_board controller often doesn't support 'redo' easily 
        // without custom history management. We keep it visual for now or for future PGN loading).
        _navButton(Icons.chevron_right, () {
           // Placeholder for Redo logic
        }),
        _navButton(Icons.last_page, () {}),
      ],
    );
  }

  Widget _navButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70),
      iconSize: 32,
      onPressed: onPressed,
    );
  }

  Widget _buildMentorPanel() {
    if (_currentAnalysis == null) {
      return const Center(child: Text("Waiting for telemetry..."));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "RECOMMENDATION: ",
                style: TextStyle(
                  color: Colors.grey[400], 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12
                ),
              ),
              Text(
                _currentAnalysis!.bestMoveUci.toUpperCase(),
                style: const TextStyle(
                  color: Colors.cyan, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  fontFamily: 'Courier' // Monospace for moves
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _currentAnalysis!.explanation,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  height: 1.4
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Line: ${_currentAnalysis!.bestLine}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}