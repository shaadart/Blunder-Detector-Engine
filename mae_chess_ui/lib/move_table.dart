import 'package:flutter/widgets.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';
import 'mae_service.dart';

/// Chess piece symbols for move notation
class MoveSymbols {
  static const String king = '♔';
  static const String queen = '♕';
  static const String rook = '♖';
  static const String bishop = '♗';
  static const String knight = '♘';
  static const String pawn = '';
  
  /// Format move with piece symbol (e.g., "Nf3" -> "♘f3")
  static String formatMove(String san) {
    if (san.isEmpty) return '';
    final firstChar = san[0];
    switch (firstChar) {
      case 'K': return '$king${san.substring(1)}';
      case 'Q': return '$queen${san.substring(1)}';
      case 'R': return '$rook${san.substring(1)}';
      case 'B': return '$bishop${san.substring(1)}';
      case 'N': return '$knight${san.substring(1)}';
      default: return san; // Pawn moves and castling stay as-is
    }
  }
}

/// Move table showing ALL moves with white/black per row
/// Only highlights problematic moves with colors
class MoveTable extends StatelessWidget {
  final List<String> allMoves; // All moves from the game
  final List<MaeAnalysisResult> problems; // Only the problematic moves
  final int currentHalfMoveIndex; // Current position (-1 = start)
  final String playerColor; // "white" or "black"
  final ValueChanged<int>? onMoveSelected; // Callback with half-move index

  const MoveTable({
    super.key,
    required this.allMoves,
    required this.problems,
    required this.currentHalfMoveIndex,
    required this.playerColor,
    this.onMoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      backgroundColor: const Color(0xFFFFFFFF),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header
          _buildHeader(),
          // Table body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: RetroColors.tableHeader,
        border: Border(
          bottom: BorderSide(color: RetroColors.tableBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: const [
          SizedBox(width: 35, child: Text('#', style: RetroTextStyles.tableHeader)),
          Expanded(child: Text('White', style: RetroTextStyles.tableHeader)),
          Expanded(child: Text('Black', style: RetroTextStyles.tableHeader)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (allMoves.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No moves loaded.\nUse File > Load PGN to analyze a game.',
            style: RetroTextStyles.uiText,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calculate number of full move pairs
    final numRows = (allMoves.length + 1) ~/ 2;

    return RetroScrollView(
      child: Column(
        children: List.generate(numRows, (rowIndex) {
          final whiteHalfMoveIndex = rowIndex * 2;
          final blackHalfMoveIndex = rowIndex * 2 + 1;
          
          final whiteSan = whiteHalfMoveIndex < allMoves.length 
              ? allMoves[whiteHalfMoveIndex] 
              : null;
          final blackSan = blackHalfMoveIndex < allMoves.length 
              ? allMoves[blackHalfMoveIndex] 
              : null;

          return _MoveRow(
            moveNumber: rowIndex + 1,
            whiteSan: whiteSan,
            blackSan: blackSan,
            whiteHalfMoveIndex: whiteHalfMoveIndex,
            blackHalfMoveIndex: blackHalfMoveIndex,
            currentHalfMoveIndex: currentHalfMoveIndex,
            whiteProblem: _getProblemAt(rowIndex + 1, true),
            blackProblem: _getProblemAt(rowIndex + 1, false),
            playerColor: playerColor,
            isEven: rowIndex % 2 == 0,
            onWhiteTap: whiteSan != null 
                ? () => onMoveSelected?.call(whiteHalfMoveIndex)
                : null,
            onBlackTap: blackSan != null 
                ? () => onMoveSelected?.call(blackHalfMoveIndex)
                : null,
          );
        }),
      ),
    );
  }

  /// Find if there's a problem at a specific move number for a color
  MaeAnalysisResult? _getProblemAt(int moveNumber, bool isWhite) {
    final isPlayerWhite = playerColor.toLowerCase() == 'white';
    // Problems are only for the player's color
    if (isWhite != isPlayerWhite) return null;
    
    for (final problem in problems) {
      if (problem.moveNumber == moveNumber) {
        return problem;
      }
    }
    return null;
  }
}

class _MoveRow extends StatelessWidget {
  final int moveNumber;
  final String? whiteSan;
  final String? blackSan;
  final int whiteHalfMoveIndex;
  final int blackHalfMoveIndex;
  final int currentHalfMoveIndex;
  final MaeAnalysisResult? whiteProblem;
  final MaeAnalysisResult? blackProblem;
  final String playerColor;
  final bool isEven;
  final VoidCallback? onWhiteTap;
  final VoidCallback? onBlackTap;

  const _MoveRow({
    required this.moveNumber,
    this.whiteSan,
    this.blackSan,
    required this.whiteHalfMoveIndex,
    required this.blackHalfMoveIndex,
    required this.currentHalfMoveIndex,
    this.whiteProblem,
    this.blackProblem,
    required this.playerColor,
    required this.isEven,
    this.onWhiteTap,
    this.onBlackTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isEven ? RetroColors.tableRowEven : RetroColors.tableRowOdd;
    
    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        border: const Border(
          bottom: BorderSide(color: RetroColors.tableBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Move number
          SizedBox(
            width: 35,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$moveNumber.',
                style: RetroTextStyles.tableCell.copyWith(
                  color: RetroColors.borderMedium,
                ),
              ),
            ),
          ),
          // White's move
          Expanded(
            child: _MoveCell(
              san: whiteSan,
              problem: whiteProblem,
              isSelected: currentHalfMoveIndex == whiteHalfMoveIndex,
              onTap: onWhiteTap,
            ),
          ),
          // Black's move
          Expanded(
            child: _MoveCell(
              san: blackSan,
              problem: blackProblem,
              isSelected: currentHalfMoveIndex == blackHalfMoveIndex,
              onTap: onBlackTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveCell extends StatelessWidget {
  final String? san;
  final MaeAnalysisResult? problem;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MoveCell({
    this.san,
    this.problem,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (san == null) {
      return const SizedBox.shrink();
    }

    // Determine background color based on problem severity
    Color? bgColor;
    Color textColor = RetroColors.textPrimary;
    
    if (isSelected) {
      bgColor = RetroColors.selectedRow;
      textColor = RetroColors.selectedRowText;
    } else if (problem != null) {
      switch (problem!.severity) {
        case 'blunder':
          bgColor = const Color(0xFFE88388); // Red for blunder
          break;
        case 'mistake':
          bgColor = const Color(0xFFF7C045); // Orange for mistake
          break;
        case 'inaccuracy':
          bgColor = const Color(0xFFF7F45A); // Yellow for inaccuracy
          break;
      }
    }

    final formattedMove = MoveSymbols.formatMove(san!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          formattedMove,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            color: textColor,
            fontWeight: problem != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
