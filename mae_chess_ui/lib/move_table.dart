import 'package:flutter/widgets.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';
import 'mae_service.dart';

/// Classic HTML-table style move list
class MoveTable extends StatelessWidget {
  final List<MaeAnalysisResult> moves;
  final int? selectedIndex;
  final ValueChanged<int>? onMoveSelected;

  const MoveTable({
    super.key,
    required this.moves,
    this.selectedIndex,
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
      child: Row(
        children: [
          _HeaderCell(text: '#', width: 40),
          _HeaderCell(text: 'Played', width: 60),
          _HeaderCell(text: 'Best', width: 60),
          _HeaderCell(text: 'Eval', width: 60),
          _HeaderCell(text: 'Type', flex: 1),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (moves.isEmpty) {
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

    return RetroScrollView(
      child: Column(
        children: List.generate(moves.length, (index) {
          return _MoveRow(
            move: moves[index],
            index: index,
            isSelected: selectedIndex == index,
            isEven: index % 2 == 0,
            onTap: () => onMoveSelected?.call(index),
          );
        }),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;

  const _HeaderCell({required this.text, this.width, this.flex});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: RetroColors.tableBorder, width: 1),
        ),
      ),
      child: Text(
        text,
        style: RetroTextStyles.tableHeader,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex!, child: child);
    }
    return child;
  }
}

class _MoveRow extends StatelessWidget {
  final MaeAnalysisResult move;
  final int index;
  final bool isSelected;
  final bool isEven;
  final VoidCallback? onTap;

  const _MoveRow({
    required this.move,
    required this.index,
    required this.isSelected,
    required this.isEven,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine row background based on classification
    Color rowColor;
    if (isSelected) {
      rowColor = RetroColors.selectedRow;
    } else if (_isMistake()) {
      rowColor = RetroColors.mistake;
    } else if (_isInaccuracy()) {
      rowColor = RetroColors.inaccuracy;
    } else {
      rowColor = isEven ? RetroColors.tableRowEven : RetroColors.tableRowOdd;
    }

    final textColor = isSelected
        ? RetroColors.selectedRowText
        : RetroColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: rowColor,
          border: const Border(
            bottom: BorderSide(color: RetroColors.tableBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Move number (clickable link style)
            _DataCell(
              width: 40,
              child: Text(
                '${move.moveNumber}',
                style: RetroTextStyles.linkText.copyWith(
                  color: isSelected
                      ? RetroColors.selectedRowText
                      : RetroColors.linkBlue,
                ),
              ),
            ),
            // Played move
            _DataCell(
              width: 60,
              child: Text(
                move.played,
                style: RetroTextStyles.tableCell.copyWith(
                  color: textColor,
                  fontFamily: 'Courier New',
                ),
              ),
            ),
            // Best move
            _DataCell(
              width: 60,
              child: Text(
                move.bestMove,
                style: RetroTextStyles.tableCell.copyWith(
                  color: textColor,
                  fontFamily: 'Courier New',
                ),
              ),
            ),
            // Evaluation
            _DataCell(
              width: 60,
              child: Text(
                move.evalAfter,
                style: RetroTextStyles.tableCell.copyWith(
                  color: textColor,
                  fontFamily: 'Courier New',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Classification type
            _DataCell(
              flex: 1,
              child: Text(
                move.severity.toUpperCase(),
                style: RetroTextStyles.tableCell.copyWith(color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isMistake() {
    return move.severity == 'blunder' || move.severity == 'mistake';
  }

  bool _isInaccuracy() {
    return move.severity == 'inaccuracy';
  }
}

class _DataCell extends StatelessWidget {
  final Widget child;
  final double? width;
  final int? flex;

  const _DataCell({required this.child, this.width, this.flex});

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: RetroColors.tableBorder, width: 1),
        ),
      ),
      child: child,
    );

    if (flex != null) {
      return Expanded(flex: flex!, child: container);
    }
    return container;
  }
}

/// Compact move table for smaller spaces
class CompactMoveTable extends StatelessWidget {
  final List<MaeAnalysisResult> moves;
  final int? selectedIndex;
  final ValueChanged<int>? onMoveSelected;

  const CompactMoveTable({
    super.key,
    required this.moves,
    this.selectedIndex,
    this.onMoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const Center(
        child: Text('No moves', style: RetroTextStyles.uiText),
      );
    }

    return RetroScrollView(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: List.generate(moves.length, (index) {
            final move = moves[index];
            final isSelected = selectedIndex == index;

            return GestureDetector(
              onTap: () => onMoveSelected?.call(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? RetroColors.selectedRow
                      : _getMoveColor(move),
                  border: Border.all(color: RetroColors.tableBorder, width: 1),
                ),
                child: Text(
                  '${move.moveNumber}. ${move.moveUci}',
                  style: RetroTextStyles.monoText.copyWith(
                    fontSize: 11,
                    color: isSelected
                        ? RetroColors.selectedRowText
                        : RetroColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _getMoveColor(MaeAnalysisResult move) {
    if (move.delta > 0.5) return RetroColors.mistake;
    if (move.delta > 0.2) return RetroColors.inaccuracy;
    return RetroColors.tableRowEven;
  }
}
