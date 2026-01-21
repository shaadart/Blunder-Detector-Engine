import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';
import 'chess_board_panel.dart';
import 'tutor_console.dart';
import 'move_table.dart';
import 'pgn_dialog.dart';
import 'mae_service.dart';

void main() {
  runApp(const MaeChessApp());
}

/// Main application - Uses WidgetsApp instead of MaterialApp
/// to avoid Material Design defaults
class MaeChessApp extends StatelessWidget {
  const MaeChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Chess Analysis Tool v1.0',
      debugShowCheckedModeBanner: false,
      color: RetroColors.titleBarActive,
      builder: (context, _) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: RetroTextStyles.uiText,
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) => const RetroChessAnalyzer()),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Main chess analyzer screen with Windows 95 style
class RetroChessAnalyzer extends StatefulWidget {
  const RetroChessAnalyzer({super.key});

  @override
  State<RetroChessAnalyzer> createState() => _RetroChessAnalyzerState();
}

class _RetroChessAnalyzerState extends State<RetroChessAnalyzer> {
  final MaeService _maeService = MaeService();
  final ChessGameController _boardController = ChessGameController();
  final FocusNode _keyboardFocusNode = FocusNode();

  // State
  MaeGameProfile? _gameProfile;
  bool _isLoading = false;
  bool _showPgnDialog = false;
  String? _errorMessage;
  String _statusText = 'Ready. Use File > Load PGN to analyze a game.';

  int get _currentMoveIndex => _boardController.currentMoveIndex;

  /// Get analysis result for the current board position (if any)
  MaeAnalysisResult? get _currentAnalysis {
    if (_gameProfile == null || _currentMoveIndex < 0) return null;

    // Find if there's a problem at this half-move index
    // Problems are stored by move number - need to map half-move to move number
    final isWhiteMove = _currentMoveIndex % 2 == 0;
    final moveNumber = (_currentMoveIndex ~/ 2) + 1;
    final playerIsWhite = _gameProfile!.playerColor.toLowerCase() == 'white';

    // Only show analysis if this move belongs to the analyzed player
    if (isWhiteMove != playerIsWhite) return null;

    // Find problem for this move number
    for (final problem in _gameProfile!.moves) {
      if (problem.moveNumber == moveNumber) {
        return problem;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: const Color.fromARGB(255, 0, 136, 247), // Classic teal desktop
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main window - always centered, wrapped to prevent text selection
            MouseRegion(
              cursor: SystemMouseCursors.basic,
              child: _buildMainWindow(),
            ),
            // Overlays - positioned to fill the entire screen and centered
            if (_showPgnDialog) _buildFullScreenOverlay(_buildDialogContent()),
            if (_isLoading) _buildFullScreenOverlay(_buildLoadingContent()),
            if (_errorMessage != null)
              _buildFullScreenOverlay(_buildErrorContent()),
          ],
        ),
      ),
    );
  }

  /// Full screen overlay that won't shift the main content
  Widget _buildFullScreenOverlay(Widget child) {
    return Positioned.fill(
      child: Container(
        color: const Color(0x80000000),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildDialogContent() {
    return PgnLoadDialog(
      onLoad: _loadPgn,
      onCancel: () => setState(() => _showPgnDialog = false),
    );
  }

  Widget _buildLoadingContent() {
    return const RetroLoadingDialog(
      message: 'Analyzing game with MAE Engine...',
    );
  }

  Widget _buildErrorContent() {
    return RetroMessageDialog(
      title: 'Error',
      message: _errorMessage!,
      onOk: () => setState(() => _errorMessage = null),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goToPrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _goToNext();
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        _goToStart();
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        _goToEnd();
      }
    }
  }

  Widget _buildMainWindow() {
    return RetroWindowFrame(
      title: 'Chess Analysis Tool v1.0 - MAE Engine',
      width: 900,
      height: 650,
      statusText: _statusText,
      menuItems: [
        RetroMenuItem(
          label: 'File',
          onTap: () => setState(() => _showPgnDialog = true),
        ),
        RetroMenuItem(label: 'Edit', onTap: () {}),
        RetroMenuItem(label: 'View', onTap: () {}),
        RetroMenuItem(label: 'Help', onTap: () => _showAbout()),
      ],
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel - Chess board
        Container(
          width: 370,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Interactive board - Expanded to take available space
              Expanded(
                child: RetroPanel(
                  child: InteractiveChessBoardPanel(
                    controller: _boardController,
                    boardSize: 300,
                    flipped: _gameProfile != null && _gameProfile!.playerColor.toLowerCase() == 'black',
                    onPositionChanged: _onBoardPositionChanged,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Game info panel
              _buildGameInfoPanel(),
            ],
          ),
        ),
        // Vertical divider
        Container(width: 2, color: RetroColors.borderMedium),
        // Right panel - Tutor and move table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Tutor console (top)
                Expanded(
                  flex: 2,
                  child: TutorConsole(
                    currentMove: _currentAnalysis,
                    useTypewriterEffect: true,
                    typewriterDelayMs: 15,
                  ),
                ),
                const SizedBox(height: 8),
                // Full move table (bottom) - shows ALL moves
                Expanded(
                  flex: 3,
                  child: MoveTable(
                    allMoves: _boardController.allMoves,
                    problems: _gameProfile?.moves ?? [],
                    currentHalfMoveIndex: _currentMoveIndex,
                    playerColor: _gameProfile?.playerColor ?? 'white',
                    onMoveSelected: _goToHalfMove,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfoPanel() {
    if (_gameProfile == null) {
      return RetroPanel(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('No game loaded', style: RetroTextStyles.uiText),
            SizedBox(height: 4),
            Text(
              'Use File menu to load a PGN file.',
              style: RetroTextStyles.uiText,
            ),
            SizedBox(height: 4),
            Text(
              'Keyboard: ← → to navigate moves',
              style: RetroTextStyles.uiText,
            ),
          ],
        ),
      );
    }

    return RetroPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player info
          Text(
            '${_gameProfile!.player} vs ${_gameProfile!.opponent}',
            style: RetroTextStyles.uiText.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${_gameProfile!.playerColor.toUpperCase()} | ${_gameProfile!.gameMode}',
            style: RetroTextStyles.uiText.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatBox(
                label: 'Blunders',
                value: '${_gameProfile!.blunderCount}',
              ),
              const SizedBox(width: 6),
              _StatBox(
                label: 'Mistakes',
                value: '${_gameProfile!.mistakeCount}',
              ),
              const SizedBox(width: 6),
              _StatBox(
                label: 'Inaccuracies',
                value: '${_gameProfile!.inaccuracyCount}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Push-ups Due: ${_gameProfile!.pushups}',
                style: RetroTextStyles.monoText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _gameProfile!.pushups > 0
                      ? const Color(0xFFCC0000)
                      : RetroColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _gameProfile!.playerType,
                style: RetroTextStyles.uiText.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _loadPgn(String pgn, String username) async {
    setState(() {
      _showPgnDialog = false;
      _isLoading = true;
      _statusText = 'Analyzing game...';
    });

    try {
      final result = await _maeService.analyzeGame(
        pgn: pgn,
        username: username,
      );

      if (result != null) {
        // Load PGN into the board controller for interactive replay
        if (!_boardController.loadPgn(pgn)) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Failed to parse PGN moves.\nPlease check the PGN format.';
            _statusText = 'PGN parse error.';
          });
          return;
        }

        // Go to starting position to see the initial board
        _boardController.goToStart();

        setState(() {
          _gameProfile = MaeGameProfile.fromJson(result);
          _isLoading = false;
          _statusText =
              'Analysis complete. ${_gameProfile!.moves.length} problems found. '
              'Engine: Stockfish 16 | Depth: 18';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to analyze game.\n\n'
              'Please check that the backend server is running\n'
              'and the PGN format is valid.';
          _statusText = 'Analysis failed.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
        _statusText = 'Connection error.';
      });
    }
  }

  void _onBoardPositionChanged() {
    setState(() {
      _updateStatusText();
    });
  }

  /// Go to a specific half-move index (called from the move table)
  void _goToHalfMove(int halfMoveIndex) {
    _boardController.goToMove(halfMoveIndex);
    setState(() {
      _updateStatusText();
    });
  }

  void _goToStart() {
    setState(() {
      _boardController.goToStart();
      _updateStatusText();
    });
  }

  void _goToPrevious() {
    setState(() {
      _boardController.goToPrevious();
      _updateStatusText();
    });
  }

  void _goToNext() {
    setState(() {
      _boardController.goToNext();
      _updateStatusText();
    });
  }

  void _goToEnd() {
    setState(() {
      _boardController.goToEnd();
      _updateStatusText();
    });
  }

  void _updateStatusText() {
    if (_gameProfile == null) {
      _statusText = 'Ready. Use File > Load PGN to analyze a game.';
    } else {
      final moveNum = _boardController.currentMoveIndex + 1;
      final total = _boardController.totalMoves;
      final turn = _boardController.isWhiteToMove ? 'White' : 'Black';
      _statusText = 'Position after move $moveNum of $total | $turn to move';

      // Show eval if we have analysis for current position
      if (_currentAnalysis != null) {
        _statusText += ' | Eval: ${_currentAnalysis!.evalDisplay}';
      }
    }
  }

  void _showAbout() {
    setState(() {
      _errorMessage =
          'Chess Analysis Tool v1.0\n\n'
          'MAE (Move Analysis Engine)\n'
          'Powered by Stockfish 16\n\n'
          'Keyboard shortcuts:\n'
          '← → Navigate moves\n'
          'Home/End Jump to start/end\n\n'
          '© 1999-2026\n'
          'Best viewed at 1024×768';
    });
  }
}

/// Small stat display box
class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: RetroColors.borderMedium),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: RetroTextStyles.monoText.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(label, style: RetroTextStyles.uiText.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
