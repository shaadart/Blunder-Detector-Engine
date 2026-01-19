import 'package:flutter/widgets.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'retro_theme.dart';
import 'retro_widgets.dart';

/// Standard chess board colors (Chess.com style)
class ChessBoardColors {
  // Chess.com green theme (most recognizable)
  static const Color lightSquare = Color(0xFFEEEED2); // Light cream
  static const Color darkSquare = Color(0xFF769656); // Forest green

  // Move highlight colors (yellow-green tint)
  static const Color lastMoveLight = Color(0xFFF6F669);
  static const Color lastMoveDark = Color(0xFFBACA44);

  // Coordinate colors
  static const Color coordOnLight = Color(0xFF769656);
  static const Color coordOnDark = Color(0xFFFFFFFF);

  // Board border
  static const Color boardBorder = Color(0xFF312E2B);
}

/// Chess piece characters (Unicode)
class ChessPieces {
  static const String whiteKing = '♔';
  static const String whiteQueen = '♕';
  static const String whiteRook = '♖';
  static const String whiteBishop = '♗';
  static const String whiteKnight = '♘';
  static const String whitePawn = '♙';
  static const String blackKing = '♚';
  static const String blackQueen = '♛';
  static const String blackRook = '♜';
  static const String blackBishop = '♝';
  static const String blackKnight = '♞';
  static const String blackPawn = '♟';
  static const String empty = '';

  /// Get Unicode piece from chess library piece
  static String fromChessPiece(chess_lib.Piece? piece) {
    if (piece == null) return '';

    final isWhite = piece.color == chess_lib.Color.WHITE;
    switch (piece.type) {
      case chess_lib.PieceType.KING:
        return isWhite ? whiteKing : blackKing;
      case chess_lib.PieceType.QUEEN:
        return isWhite ? whiteQueen : blackQueen;
      case chess_lib.PieceType.ROOK:
        return isWhite ? whiteRook : blackRook;
      case chess_lib.PieceType.BISHOP:
        return isWhite ? whiteBishop : blackBishop;
      case chess_lib.PieceType.KNIGHT:
        return isWhite ? whiteKnight : blackKnight;
      case chess_lib.PieceType.PAWN:
        return isWhite ? whitePawn : blackPawn;
      default:
        return '';
    }
  }

  /// ASCII mode alternatives
  static const Map<String, String> asciiPieces = {
    '♔': 'K',
    '♕': 'Q',
    '♖': 'R',
    '♗': 'B',
    '♘': 'N',
    '♙': 'P',
    '♚': 'k',
    '♛': 'q',
    '♜': 'r',
    '♝': 'b',
    '♞': 'n',
    '♟': 'p',
  };
}

/// Game controller that manages chess position and move history
class ChessGameController {
  final chess_lib.Chess _chess = chess_lib.Chess();
  final List<String> _moveHistory = [];
  int _currentMoveIndex = -1; // -1 = starting position
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

      // Parse the PGN
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
      return false;
    }
  }

  /// Pre-process PGN to handle various formats (Chess.com, Lichess, etc.)
  String _preprocessPgn(String pgn) {
    // Remove clock annotations {[%clk ...]}
    String cleaned = pgn.replaceAll(RegExp(r'\{[^}]*\}'), '');

    // Remove eval annotations like [%eval ...]
    cleaned = cleaned.replaceAll(RegExp(r'\[%[^\]]*\]'), '');

    // Fix Chess.com's "1... e5" notation - the library expects "1. e4 e5" format
    // Replace "N..." with just the move (remove the redundant move number for black)
    cleaned = cleaned.replaceAll(RegExp(r'\d+\.\.\.\s*'), '');

    // Split into header and moves sections
    // Find the first move number pattern to separate headers from moves
    final moveStartMatch = RegExp(r'\n\s*1\.\s').firstMatch(cleaned);
    if (moveStartMatch != null) {
      final moveStart = moveStartMatch.start;
      var headers = cleaned.substring(0, moveStart);
      var moves = cleaned.substring(moveStart);

      // Replace newlines with spaces in moves section only
      moves = moves.replaceAll(RegExp(r'\s+'), ' ').trim();

      cleaned = '$headers\n\n$moves';
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

  /// Get piece at square (e.g., "e4")
  String getPieceAt(String square) {
    final piece = _chess.get(square);
    return ChessPieces.fromChessPiece(piece);
  }

  /// Get piece at row/col (row 0 = rank 8, col 0 = file a)
  String getPieceAtRowCol(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return getPieceAt('$file$rank');
  }

  /// Get last move from square
  String? get lastMoveFrom => _lastMoveFrom;

  /// Get last move to square
  String? get lastMoveTo => _lastMoveTo;

  /// Whose turn is it?
  bool get isWhiteToMove => _chess.turn == chess_lib.Color.WHITE;

  /// Get the FEN of current position
  String get fen => _chess.fen;
}

/// Interactive chess board panel with move navigation
class InteractiveChessBoardPanel extends StatefulWidget {
  final ChessGameController controller;
  final double boardSize;
  final bool asciiMode;
  final bool flipped;
  final VoidCallback? onPositionChanged;

  const InteractiveChessBoardPanel({
    super.key,
    required this.controller,
    this.boardSize = 320,
    this.asciiMode = false,
    this.flipped = false,
    this.onPositionChanged,
  });

  @override
  State<InteractiveChessBoardPanel> createState() =>
      _InteractiveChessBoardPanelState();
}

class _InteractiveChessBoardPanelState
    extends State<InteractiveChessBoardPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coordinate labels + Board
        _buildBoardWithCoordinates(),
        const SizedBox(height: 8),
        // Navigation buttons
        _buildNavigationButtons(),
        const SizedBox(height: 4),
        // Move counter and turn indicator
        _buildMoveInfo(),
      ],
    );
  }

  Widget _buildBoardWithCoordinates() {
    // Industry standard chess board with clean border
    return Container(
      decoration: BoxDecoration(
        color: ChessBoardColors.boardBorder,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: _buildBoard(),
      ),
    );
  }

  Widget _buildBoard() {
    final squareSize = widget.boardSize / 8;

    return SizedBox(
      width: widget.boardSize,
      height: widget.boardSize,
      child: Column(
        children: List.generate(8, (row) {
          final actualRow = widget.flipped ? (7 - row) : row;
          return Row(
            children: List.generate(8, (col) {
              final actualCol = widget.flipped ? (7 - col) : col;
              return _buildSquare(actualRow, actualCol, squareSize, row, col);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildSquare(
    int row,
    int col,
    double size,
    int displayRow,
    int displayCol,
  ) {
    final isLight = (row + col) % 2 == 0;
    final piece = widget.controller.getPieceAtRowCol(row, col);
    final squareName = _getSquareName(row, col);

    // Check if this square is highlighted (last move)
    final isLastMoveFrom = squareName == widget.controller.lastMoveFrom;
    final isLastMoveTo = squareName == widget.controller.lastMoveTo;
    final isHighlighted = isLastMoveFrom || isLastMoveTo;

    // Standard Chess.com colors
    Color baseColor = isLight
        ? ChessBoardColors.lightSquare
        : ChessBoardColors.darkSquare;
    if (isHighlighted) {
      baseColor = isLight
          ? ChessBoardColors.lastMoveLight
          : ChessBoardColors.lastMoveDark;
    }

    // Determine if we should show coordinates
    final showRank = displayCol == 0; // Left edge
    final showFile = displayRow == 7; // Bottom edge

    final rankNum = widget.flipped ? (displayRow + 1) : (8 - displayRow);
    final fileChar = String.fromCharCode(
      'a'.codeUnitAt(0) + (widget.flipped ? (7 - displayCol) : displayCol),
    );

    final coordColor = isLight
        ? ChessBoardColors.coordOnLight
        : ChessBoardColors.coordOnDark;

    return Container(
      width: size,
      height: size,
      color: baseColor,
      child: Stack(
        children: [
          // Rank coordinate (left edge, top-left of square)
          if (showRank)
            Positioned(
              top: 1,
              left: 2,
              child: Text(
                '$rankNum',
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w700,
                  color: coordColor,
                  height: 1.0,
                ),
              ),
            ),
          // File coordinate (bottom edge, bottom-right of square)
          if (showFile)
            Positioned(
              bottom: 1,
              right: 2,
              child: Text(
                fileChar,
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w700,
                  color: coordColor,
                  height: 1.0,
                ),
              ),
            ),
          // Chess piece - centered
          Center(child: _buildPiece(piece, size)),
        ],
      ),
    );
  }

  Widget _buildPiece(String piece, double size) {
    if (piece.isEmpty) return const SizedBox.shrink();

    final isWhite = _isWhitePiece(piece);

    // Industry standard piece rendering
    // White pieces: white fill with thin black outline
    // Black pieces: black fill
    return Text(
      piece,
      style: TextStyle(
        fontSize: size * 0.82,
        height: 1.0,
        color: isWhite ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        shadows: isWhite
            ? const [
                // Multiple shadows to create outline effect for white pieces
                Shadow(offset: Offset(-1, -1), color: Color(0xFF000000)),
                Shadow(offset: Offset(1, -1), color: Color(0xFF000000)),
                Shadow(offset: Offset(-1, 1), color: Color(0xFF000000)),
                Shadow(offset: Offset(1, 1), color: Color(0xFF000000)),
                Shadow(offset: Offset(0, -1), color: Color(0xFF000000)),
                Shadow(offset: Offset(0, 1), color: Color(0xFF000000)),
                Shadow(offset: Offset(-1, 0), color: Color(0xFF000000)),
                Shadow(offset: Offset(1, 0), color: Color(0xFF000000)),
              ]
            : const [
                // Subtle shadow for black pieces
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 1,
                  color: Color(0x40000000),
                ),
              ],
      ),
    );
  }

  String _getSquareName(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  bool _isWhitePiece(String piece) {
    return ['♔', '♕', '♖', '♗', '♘', '♙'].contains(piece);
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

/// Legacy ChessPosition class for compatibility
class ChessPosition {
  final List<List<String>> board;
  final bool whiteToMove;

  const ChessPosition({required this.board, this.whiteToMove = true});

  factory ChessPosition.initial() {
    return ChessPosition(
      board: [
        ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
        ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
        ['', '', '', '', '', '', '', ''],
        ['', '', '', '', '', '', '', ''],
        ['', '', '', '', '', '', '', ''],
        ['', '', '', '', '', '', '', ''],
        ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
        ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'],
      ],
      whiteToMove: true,
    );
  }

  factory ChessPosition.empty() {
    return ChessPosition(board: List.generate(8, (_) => List.filled(8, '')));
  }
}
