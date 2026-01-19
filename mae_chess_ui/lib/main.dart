import 'package:flutter/widgets.dart';
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
        return const Directionality(
          textDirection: TextDirection.ltr,
          child: RetroChessAnalyzer(),
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

  // State
  MaeGameProfile? _gameProfile;
  int _currentMoveIndex = 0;
  bool _isLoading = false;
  bool _showPgnDialog = false;
  String? _errorMessage;
  final ChessPosition _currentPosition = ChessPosition.initial();
  String _statusText = 'Ready. Use File > Load PGN to analyze a game.';

  MaeAnalysisResult? get _currentMove {
    if (_gameProfile == null ||
        _currentMoveIndex < 0 ||
        _currentMoveIndex >= _gameProfile!.moves.length) {
      return null;
    }
    return _gameProfile!.moves[_currentMoveIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF008080), // Classic teal desktop
      child: Center(
        child: Stack(
          children: [
            // Main window
            _buildMainWindow(),
            // Dialog overlay
            if (_showPgnDialog) _buildDialogOverlay(),
            if (_isLoading) _buildLoadingOverlay(),
            if (_errorMessage != null) _buildErrorOverlay(),
          ],
        ),
      ),
    );
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
              // Board area
              RetroPanel(
                child: ChessBoardPanel(
                  position: _currentPosition,
                  currentMoveIndex: _currentMoveIndex,
                  totalMoves: _gameProfile?.moves.length ?? 0,
                  onFirstMove: () => _goToMove(0),
                  onPreviousMove: () => _goToMove(_currentMoveIndex - 1),
                  onNextMove: () => _goToMove(_currentMoveIndex + 1),
                  onLastMove: () =>
                      _goToMove((_gameProfile?.moves.length ?? 1) - 1),
                  boardSize: 320,
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
                    currentMove: _currentMove,
                    useTypewriterEffect: true,
                    typewriterDelayMs: 15,
                  ),
                ),
                const SizedBox(height: 8),
                // Move table (bottom)
                Expanded(
                  flex: 3,
                  child: MoveTable(
                    moves: _gameProfile?.moves ?? [],
                    selectedIndex: _gameProfile != null
                        ? _currentMoveIndex
                        : null,
                    onMoveSelected: _goToMove,
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
          ],
        ),
      );
    }

    return RetroPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatBox(
                label: 'Blunders',
                value: '${_gameProfile!.blunderCount}',
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'Avg Diff',
                value: '${_gameProfile!.avgDifficulty}',
              ),
              const SizedBox(width: 8),
              _StatBox(label: 'Push-ups', value: '${_gameProfile!.pushups}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Player Type: ${_gameProfile!.playerType}',
            style: RetroTextStyles.uiText.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOverlay() {
    return Container(
      color: const Color(0x80000000),
      child: PgnLoadDialog(
        onLoad: _loadPgn,
        onCancel: () => setState(() => _showPgnDialog = false),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0x80000000),
      child: const RetroLoadingDialog(
        message: 'Analyzing game with MAE Engine...',
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: const Color(0x80000000),
      child: RetroMessageDialog(
        title: 'Error',
        message: _errorMessage!,
        onOk: () => setState(() => _errorMessage = null),
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
        setState(() {
          _gameProfile = MaeGameProfile.fromJson(result);
          _currentMoveIndex = 0;
          _isLoading = false;
          _statusText =
              'Analysis complete. ${_gameProfile!.moves.length} moves analyzed. '
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

  void _goToMove(int index) {
    if (_gameProfile == null) return;

    final newIndex = index.clamp(0, _gameProfile!.moves.length - 1);
    if (newIndex != _currentMoveIndex) {
      setState(() {
        _currentMoveIndex = newIndex;
        _statusText =
            'Move ${_currentMoveIndex + 1} of ${_gameProfile!.moves.length} | '
            'Eval: ${_currentMove?.evalDisplay ?? "N/A"}';
      });
    }
  }

  void _showAbout() {
    setState(() {
      _errorMessage =
          'Chess Analysis Tool v1.0\n\n'
          'MAE (Move Analysis Engine)\n'
          'Powered by Stockfish 16\n\n'
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
