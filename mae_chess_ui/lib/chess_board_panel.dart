import 'package:flutter/widgets.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';

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

/// Represents a chess position
class ChessPosition {
  final List<List<String>> board;
  final bool whiteToMove;

  const ChessPosition({required this.board, this.whiteToMove = true});

  /// Starting position
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

  /// Empty board
  factory ChessPosition.empty() {
    return ChessPosition(board: List.generate(8, (_) => List.filled(8, '')));
  }
}

/// Left panel containing the chess board and navigation controls
class ChessBoardPanel extends StatelessWidget {
  final ChessPosition position;
  final int currentMoveIndex;
  final int totalMoves;
  final VoidCallback? onFirstMove;
  final VoidCallback? onPreviousMove;
  final VoidCallback? onNextMove;
  final VoidCallback? onLastMove;
  final bool asciiMode;
  final double boardSize;
  final String? highlightedSquare; // e.g., "e4"
  final String? lastMoveFrom;
  final String? lastMoveTo;

  const ChessBoardPanel({
    super.key,
    required this.position,
    this.currentMoveIndex = 0,
    this.totalMoves = 0,
    this.onFirstMove,
    this.onPreviousMove,
    this.onNextMove,
    this.onLastMove,
    this.asciiMode = false,
    this.boardSize = 320,
    this.highlightedSquare,
    this.lastMoveFrom,
    this.lastMoveTo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chess board with thick black border
        Container(
          decoration: RetroBorders.blackBorder(3),
          child: _buildBoard(),
        ),
        const SizedBox(height: 8),
        // Navigation buttons
        _buildNavigationButtons(),
        const SizedBox(height: 4),
        // Move counter
        Text(
          'Move $currentMoveIndex of $totalMoves',
          style: RetroTextStyles.uiText,
        ),
      ],
    );
  }

  Widget _buildBoard() {
    final squareSize = boardSize / 8;

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Column(
        children: List.generate(8, (row) {
          return Row(
            children: List.generate(8, (col) {
              return _buildSquare(row, col, squareSize);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildSquare(int row, int col, double size) {
    final isLight = (row + col) % 2 == 0;
    final piece = position.board[row][col];
    final squareName = _getSquareName(row, col);

    // Check if this square is highlighted
    final isHighlighted =
        squareName == highlightedSquare ||
        squareName == lastMoveFrom ||
        squareName == lastMoveTo;

    Color baseColor = isLight ? RetroColors.boardLight : RetroColors.boardDark;
    if (isHighlighted) {
      // Yellow highlight for last move
      baseColor = isLight ? const Color(0xFFF7F769) : const Color(0xFFBBCA2B);
    }

    return Container(
      width: size,
      height: size,
      color: baseColor,
      child: Center(
        child: Text(
          asciiMode ? (ChessPieces.asciiPieces[piece] ?? '') : piece,
          style: TextStyle(
            fontSize: asciiMode ? size * 0.6 : size * 0.8,
            fontFamily: asciiMode ? 'Courier New' : null,
            color: _isWhitePiece(piece)
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF000000),
            shadows: _isWhitePiece(piece)
                ? [
                    const Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 0,
                      color: Color(0xFF000000),
                    ),
                  ]
                : null,
          ),
        ),
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
          onPressed: onFirstMove,
          enabled: currentMoveIndex > 0,
        ),
        const SizedBox(width: 4),
        RetroIconButton(
          label: '<',
          onPressed: onPreviousMove,
          enabled: currentMoveIndex > 0,
        ),
        const SizedBox(width: 4),
        RetroIconButton(
          label: '>',
          onPressed: onNextMove,
          enabled: currentMoveIndex < totalMoves,
        ),
        const SizedBox(width: 4),
        RetroIconButton(
          label: '>|',
          onPressed: onLastMove,
          enabled: currentMoveIndex < totalMoves,
        ),
      ],
    );
  }
}

/// Coordinate labels for the board
class BoardCoordinates extends StatelessWidget {
  final double boardSize;
  final bool showFiles;
  final bool showRanks;

  const BoardCoordinates({
    super.key,
    required this.boardSize,
    this.showFiles = true,
    this.showRanks = true,
  });

  @override
  Widget build(BuildContext context) {
    final squareSize = boardSize / 8;

    return SizedBox(
      width: boardSize + (showRanks ? 16 : 0),
      height: boardSize + (showFiles ? 16 : 0),
      child: Stack(
        children: [
          // Rank labels (1-8 on left)
          if (showRanks)
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: 14,
                height: boardSize,
                child: Column(
                  children: List.generate(8, (i) {
                    return SizedBox(
                      height: squareSize,
                      child: Center(
                        child: Text(
                          '${8 - i}',
                          style: RetroTextStyles.uiText.copyWith(fontSize: 10),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          // File labels (a-h on bottom)
          if (showFiles)
            Positioned(
              left: showRanks ? 14 : 0,
              bottom: 0,
              child: SizedBox(
                width: boardSize,
                height: 14,
                child: Row(
                  children: List.generate(8, (i) {
                    return SizedBox(
                      width: squareSize,
                      child: Center(
                        child: Text(
                          String.fromCharCode('a'.codeUnitAt(0) + i),
                          style: RetroTextStyles.uiText.copyWith(fontSize: 10),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
