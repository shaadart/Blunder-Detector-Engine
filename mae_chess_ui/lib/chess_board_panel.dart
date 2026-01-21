import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';

/// Game controller that manages chess position and move history
/// Uses chess package for logic, flutter_chess_board for display
class ChessGameController {
  final chess_lib.Chess _chess = chess_lib.Chess();
  final List<String> _moveHistory = [];
  int _currentMoveIndex = -1;
  String? _lastMoveFrom;
  String? _lastMoveTo;

  ChessGameController();

  /// Get all moves in the game (SAN notation)
  List<String> get allMoves => List.unmodifiable(_moveHistory);

  /// Load a PGN and parse all moves
  bool loadPgn(String pgn) {
    _chess.reset();
    _moveHistory.clear();
    _currentMoveIndex = -1;
    _lastMoveFrom = null;
    _lastMoveTo = null;

    try {
      // Pre-process PGN to handle Chess.com format
      String cleanedPgn = _preprocessPgn(pgn);

      // Parse the PGN using the chess package (YOUR WORKING CODE)
      if (!_chess.load_pgn(cleanedPgn)) {
        return false;
      }

      // Get the move history with verbose info (contains from/to squares)
      final history = _chess.getHistory({'verbose': true});
      for (var move in history) {
        _moveHistory.add((move as Map)['san'].toString());
      }

      // Reset to starting position for replay
      _chess.reset();
      _currentMoveIndex = -1;

      return true;
    } catch (e) {
      print('PGN Load Error: $e');
      return false;
    }
  }

  /// Pre-process PGN to handle various formats (Chess.com, Lichess, etc.)
  String _preprocessPgn(String pgn) {
    // Normalize line endings and collapse weird whitespace
    String cleaned = pgn.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Strip BOM and trim
    cleaned = cleaned.replaceAll('\ufeff', '').trim();

    // Remove clock annotations {[%clk ...]} and any comments in braces
    cleaned = cleaned.replaceAll(RegExp(r'\{[^}]*\}'), '');
    // Remove any unmatched '{' to end-of-string (truncated annotations)
    cleaned = cleaned.replaceAll(RegExp(r'\{[^}]*$'), '');

    // Remove eval annotations like [%eval ...] and other bracketed inline commands
    cleaned = cleaned.replaceAll(RegExp(r'\[%[^\]]*\]'), '');
    // Remove any unmatched '[%' to end-of-string
    cleaned = cleaned.replaceAll(RegExp(r'\[%[^\]]*$'), '');
    // Remove numeric annotation glyphs (NAGs) like $12
    cleaned = cleaned.replaceAll(RegExp(r'\$\d+'), '');

    // Fix Chess.com's "1... e5" notation - remove the redundant "..." move numbers
    cleaned = cleaned.replaceAll(RegExp(r'\d+\.\.\.\s*'), '');

    // Remove move variations in parentheses (e.g., (1... Nf6 2. ...)) to simplify parsing
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), '');
    // Remove any unmatched '(' to end-of-string
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*$'), '');

    // Attempt 1: find move section by newline then 1.
    var moveStartMatch = RegExp(r'\n\s*1\.\s').firstMatch(cleaned);

    if (moveStartMatch == null) {
      // Attempt 2: find first occurrence of '1.' anywhere (no newline required)
      moveStartMatch = RegExp(r'1\.\s').firstMatch(cleaned);
    }

    if (moveStartMatch != null) {
      final moveStart = moveStartMatch.start;
      var headers = cleaned.substring(0, moveStart);
      var moves = cleaned.substring(moveStart);

      // Normalize whitespace in moves: replace any sequence of whitespace with single space
      moves = moves.replaceAll(RegExp(r'\s+'), ' ').trim();

      cleaned = '${headers.trim()}\n\n${moves.trim()}';
      return cleaned.trim();
    }

    // Final fallback: if no '1.' found, try extracting after last header bracket
    final lastBracket = cleaned.lastIndexOf(']');
    if (lastBracket != -1 && lastBracket + 1 < cleaned.length) {
      var headers = cleaned.substring(0, lastBracket + 1);
      var movesSection = cleaned.substring(lastBracket + 1);
      movesSection = movesSection.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (movesSection.isNotEmpty) {
        cleaned = '${headers.trim()}\n\n${movesSection.trim()}';
      }
    }

    return cleaned.trim();
  }

  /// Reset to starting position
  void reset() {
    _chess.reset();
    _moveHistory.clear();
    _currentMoveIndex = -1;
    _lastMoveFrom = null;
    _lastMoveTo = null;
  }

  /// Go to a specific move index (-1 = starting position)
  void goToMove(int index) {
    if (index < -1) index = -1;
    if (index >= _moveHistory.length) index = _moveHistory.length - 1;

    // Reset to start
    _chess.reset();
    _lastMoveFrom = null;
    _lastMoveTo = null;

    // Replay moves up to index
    for (int i = 0; i <= index && i < _moveHistory.length; i++) {
      _chess.move(_moveHistory[i]);
    }

    // Get the last move info for highlighting
    if (index >= 0) {
      final history = _chess.getHistory({'verbose': true});
      if (history.isNotEmpty) {
        final lastMove = history.last as Map;
        _lastMoveFrom = lastMove['from']?.toString();
        _lastMoveTo = lastMove['to']?.toString();
      }
    }

    _currentMoveIndex = index;
  }

  /// Go to first position
  void goToStart() => goToMove(-1);

  /// Go to previous move
  void goToPrevious() => goToMove(_currentMoveIndex - 1);

  /// Go to next move
  void goToNext() => goToMove(_currentMoveIndex + 1);

  /// Go to last move
  void goToEnd() => goToMove(_moveHistory.length - 1);

  /// Get current move index
  int get currentMoveIndex => _currentMoveIndex;

  /// Get total moves
  int get totalMoves => _moveHistory.length;

  /// Can go back?
  bool get canGoBack => _currentMoveIndex >= 0;

  /// Can go forward?
  bool get canGoForward => _currentMoveIndex < _moveHistory.length - 1;

  /// Whose turn is it?
  bool get isWhiteToMove => _chess.turn == chess_lib.Color.WHITE;

  /// Get the FEN of current position
  String get fen => _chess.fen;

  /// Get last move from square
  String? get lastMoveFrom => _lastMoveFrom;

  /// Get last move to square
  String? get lastMoveTo => _lastMoveTo;
}

/// Interactive chess board panel with professional rendering
class InteractiveChessBoardPanel extends StatefulWidget {
  final ChessGameController controller;
  final double boardSize;
  final bool flipped;
  final VoidCallback? onPositionChanged;

  const InteractiveChessBoardPanel({
    super.key,
    required this.controller,
    this.boardSize = 320,
    this.flipped = false,
    this.onPositionChanged,
  });

  @override
  State<InteractiveChessBoardPanel> createState() =>
      _InteractiveChessBoardPanelState();
}

class _InteractiveChessBoardPanelState
    extends State<InteractiveChessBoardPanel> {
  late ChessBoardController _boardController;

  @override
  void initState() {
    super.initState();
    // Create a fresh board controller
    _boardController = ChessBoardController();
  }

  @override
  void didUpdateWidget(InteractiveChessBoardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update board position when controller changes
    _updateBoardPosition();
  }

  void _updateBoardPosition() {
    // Update the visual board to match the game controller's FEN
    final fen = widget.controller.fen;
    _boardController.loadFen(fen);
  }

  @override
  Widget build(BuildContext context) {
    // Sync board position
    _updateBoardPosition();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBoardWithFrame(),
        const SizedBox(height: 8),
        _buildNavigationButtons(),
        const SizedBox(height: 4),
        _buildMoveInfo(),
      ],
    );
  }

  Widget _buildBoardWithFrame() {
    return Container(
      decoration: BoxDecoration(
        color: ui.Color(0xFF312E2B),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: ui.Color(0x30000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: _buildBoard(),
      ),
    );
  }

  Widget _buildBoard() {
    return SizedBox(
      width: widget.boardSize,
      height: widget.boardSize,
      child: ChessBoard(
        controller: _boardController,
        boardColor: BoardColor.green,
        boardOrientation: widget.flipped
            ? PlayerColor.black
            : PlayerColor.white,
        enableUserMoves: true, 
        
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RetroIconButton(
          label: '|<',
          onPressed: widget.controller.canGoBack ? _goToStart : null,
          enabled: widget.controller.canGoBack,
        ),
        const SizedBox(width: 4),
        RetroIconButton(
          label: '<',
          onPressed: widget.controller.canGoBack ? _goToPrevious : null,
          enabled: widget.controller.canGoBack,
        ),
        const SizedBox(width: 4),
        RetroIconButton(
          label: '>',
          onPressed: widget.controller.canGoForward ? _goToNext : null,
          enabled: widget.controller.canGoForward,
        ),
        const SizedBox(width: 4),
        RetroIconButton(
          label: '>|',
          onPressed: widget.controller.canGoForward ? _goToEnd : null,
          enabled: widget.controller.canGoForward,
        ),
      ],
    );
  }

  Widget _buildMoveInfo() {
    final moveNum = widget.controller.currentMoveIndex + 1;
    final total = widget.controller.totalMoves;
    final turn = widget.controller.isWhiteToMove ? 'White' : 'Black';

    return Column(
      children: [
        Text(
          total > 0 ? 'Move $moveNum of $total' : 'Starting Position',
          style: RetroTextStyles.uiText,
        ),
        Text(
          '$turn to move',
          style: RetroTextStyles.uiText.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  void _goToStart() {
    setState(() {
      widget.controller.goToStart();
    });
    widget.onPositionChanged?.call();
  }

  void _goToPrevious() {
    setState(() {
      widget.controller.goToPrevious();
    });
    widget.onPositionChanged?.call();
  }

  void _goToNext() {
    setState(() {
      widget.controller.goToNext();
    });
    widget.onPositionChanged?.call();
  }

  void _goToEnd() {
    setState(() {
      widget.controller.goToEnd();
    });
    widget.onPositionChanged?.call();
  }
}
