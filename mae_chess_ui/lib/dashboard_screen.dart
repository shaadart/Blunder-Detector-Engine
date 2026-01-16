import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'mae_service.dart';
import 'hero_header.dart';
import 'game_timeline.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ChessBoardController _controller = ChessBoardController();
  final MaeService _maeService = MaeService();

  MaeAnalysisResult? _currentAnalysis;
  bool _isLoading = false;
  final List<BoardArrow> _arrows = [];

  MaeGameProfile? _gameProfile;
  int _historyIndex = 0;
  bool _isGameMode = false;

  int _avgDifficulty = 0;
  int _pushups = 0;
  String _playerType = "Unknown";

  // ---------------- LOGIC ----------------

  Future<void> _uploadPgn() async {
    final pgnController = TextEditingController();
    final userController = TextEditingController();

    pgnController.text =
        '[Event "Paris Opera House"]\n'
        '[Site "Paris"]\n'
        '[Date "1858.??.??"]\n\n'
        '1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 '
        '5. Qxf3 dxe5 6. Bc4 Nf6 7. Qb3 Qe7 '
        '8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 '
        '11. Bxb5+ Nbd7 12. O-O-O Rd8 '
        '13. Rxd7 Rxd7 14. Rd1 Qe6 '
        '15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8#';

    userController.text = "Morphy";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text("Import PGN", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Username",
                labelStyle: TextStyle(color: Colors.cyan),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pgnController,
              maxLines: 6,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Courier',
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                hintText: "Paste PGN here...",
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processFullGame(pgnController.text, userController.text);
            },
            child: const Text("ANALYZE"),
          ),
        ],
      ),
    );
  }

  Future<void> _processFullGame(String pgn, String username) async {
    setState(() => _isLoading = true);

    final profile = await _maeService.analyzeGame(pgn, username);
    if (!mounted || profile == null) return;

    setState(() {
      _gameProfile = profile;
      _isGameMode = true;
      _historyIndex = 0;
      _avgDifficulty = profile.avgDifficulty;
      _pushups = profile.pushups;
      _playerType = profile.playerType;
      _isLoading = false;
    });

    _loadHistoryFrame(0);
  }

  void _loadHistoryFrame(int index) {
    if (_gameProfile == null) return;

    final safeIndex = index.clamp(0, _gameProfile!.moves.length - 1);

    final frame = _gameProfile!.moves[safeIndex];

    setState(() {
      _historyIndex = safeIndex;
      _currentAnalysis = frame;
      _updateArrows(frame);
    });
  }

  void _updateArrows(MaeAnalysisResult? result) {
    _arrows.clear();
    if (result?.bestMove == null) return;

    final best = result!.bestMove!;
    if (best.length < 4) return;

    _arrows.add(
      BoardArrow(
        from: best.substring(0, 2),
        to: best.substring(2, 4),
        color: Color(0xB300E676), // green @ 70%
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            HeroHeaderWidget(
              avgDifficulty: _avgDifficulty,
              pushups: _pushups,
              playerType: _playerType,
              onUploadPressed: _uploadPgn,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildEvalBar(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ChessBoard(
                        controller: _controller,
                        boardColor: BoardColor.brown,
                        arrows: _arrows,
                        enableUserMoves: !_isGameMode,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMentorPanel(),
                  ],
                ),
              ),
            ),
            if (_isGameMode && _gameProfile != null)
              GameTimelineWidget(
                history: _gameProfile!.moves,
                currentIndex: _historyIndex,
                onMoveSelected: _loadHistoryFrame,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalBar() {
    if (_currentAnalysis == null) return const SizedBox(height: 8);

    final percent = (_currentAnalysis!.winChance / 100).clamp(0.0, 1.0);

    final risky = _currentAnalysis!.risk > 60;

    return LinearPercentIndicator(
      lineHeight: 8,
      percent: percent,
      backgroundColor: const Color(0xFF2A2A2A),
      progressColor: risky ? Colors.orangeAccent : Colors.cyanAccent,
      barRadius: const Radius.circular(4),
      animation: true,
    );
  }

  Widget _buildMentorPanel() {
    if (_currentAnalysis == null) {
      return const Text(
        "Import a PGN to begin MAE Analysis.",
        style: TextStyle(color: Colors.white54),
      );
    }

    Color labelColor = Colors.cyanAccent;
    if (_currentAnalysis!.label.contains("Blunder")) {
      labelColor = Colors.red;
    } else if (_currentAnalysis!.label.contains("Mistake")) {
      labelColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          _statBadge(
            "DIFFICULTY",
            _currentAnalysis!.difficulty,
            Colors.redAccent,
          ),
          const SizedBox(width: 12),
          _statBadge("RISK", _currentAnalysis!.risk, Colors.orangeAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF), // 20% white
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currentAnalysis!.label.toUpperCase(),
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int value, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF), // 10% white
        border: Border.all(color: Color(0x55FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
