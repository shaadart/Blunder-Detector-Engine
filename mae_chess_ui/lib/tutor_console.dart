import 'dart:async';
import 'package:flutter/widgets.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';
import 'mae_service.dart';

/// Chess tutor console - NOT a chat UI, it's an advisor/console box
class TutorConsole extends StatefulWidget {
  final MaeAnalysisResult? currentMove;
  final bool useTypewriterEffect;
  final int typewriterDelayMs;

  const TutorConsole({
    super.key,
    this.currentMove,
    this.useTypewriterEffect = true,
    this.typewriterDelayMs = 20,
  });

  @override
  State<TutorConsole> createState() => _TutorConsoleState();
}

class _TutorConsoleState extends State<TutorConsole> {
  String _displayedText = '';
  String _fullText = '';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  bool _showCaret = true;
  Timer? _caretTimer;

  @override
  void initState() {
    super.initState();
    _startCaretBlink();
    _updateText();
  }

  @override
  void didUpdateWidget(TutorConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMove != oldWidget.currentMove) {
      _updateText();
    }
  }

  void _startCaretBlink() {
    _caretTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() => _showCaret = !_showCaret);
      }
    });
  }

  void _updateText() {
    _typewriterTimer?.cancel();
    _fullText = _generateTutorText();

    if (widget.useTypewriterEffect && _fullText.isNotEmpty) {
      _displayedText = '';
      _charIndex = 0;
      _startTypewriter();
    } else {
      _displayedText = _fullText;
    }
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(
      Duration(milliseconds: widget.typewriterDelayMs),
      (_) {
        if (_charIndex < _fullText.length) {
          setState(() {
            _displayedText = _fullText.substring(0, _charIndex + 1);
            _charIndex++;
          });
        } else {
          _typewriterTimer?.cancel();
        }
      },
    );
  }

  String _generateTutorText() {
    final move = widget.currentMove;
    if (move == null) {
      return 'Welcome to Chess Analysis Tool.\n\n'
          'Load a game to begin analysis.\n'
          'Use File > Load PGN to import a game.';
    }

    final buffer = StringBuffer();

    // Move header
    buffer.writeln('Move ${move.moveNumber}: ${move.moveUci}');
    buffer.writeln('Classification: ${move.label.toUpperCase()}');
    buffer.writeln();

    // Severity indicator
    if (move.delta > 1.0) {
      buffer.writeln('⚠ SEVERE MISTAKE');
    } else if (move.delta > 0.5) {
      buffer.writeln('! MISTAKE');
    } else if (move.delta > 0.2) {
      buffer.writeln('? INACCURACY');
    } else if (move.delta < -0.5) {
      buffer.writeln('!! EXCELLENT MOVE');
    }
    buffer.writeln();

    // Analysis text
    buffer.writeln('Evaluation: ${move.evalDisplay}');
    buffer.writeln('Win chance: ${move.winChance.toStringAsFixed(1)}%');
    buffer.writeln('Position difficulty: ${move.difficulty}/100');
    buffer.writeln('Risk factor: ${move.risk}/100');

    if (move.bestMove != null && move.bestMove != move.moveUci) {
      buffer.writeln();
      buffer.writeln('Better move: ${move.bestMove}');
      buffer.writeln('Regret: ${move.delta.toStringAsFixed(2)} pawns');
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _caretTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      backgroundColor: const Color(0xFFFFFFFF),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with tutor avatar
          _buildHeader(),
          const RetroDivider(),
          // Console text area
          Expanded(
            child: RetroScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _displayedText,
                        style: RetroTextStyles.tutorText,
                      ),
                      // Blinking caret
                      if (_charIndex < _fullText.length || _showCaret)
                        TextSpan(
                          text: _showCaret ? '█' : ' ',
                          style: RetroTextStyles.monoText.copyWith(
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: RetroColors.panelBackground,
      child: Row(
        children: [
          // Pixel-style avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(color: RetroColors.borderDark, width: 1),
            ),
            child: const Center(
              child: Text(
                '♞',
                style: TextStyle(fontSize: 20, color: RetroColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHESS TUTOR',
                style: RetroTextStyles.uiText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Analysis Engine v1.0',
                style: RetroTextStyles.uiText.copyWith(
                  fontSize: 10,
                  color: RetroColors.borderMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simpler static tutor display (no typewriter)
class TutorDisplay extends StatelessWidget {
  final String title;
  final String content;

  const TutorDisplay({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      backgroundColor: const Color(0xFFFFFFFF),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(4),
            color: RetroColors.panelBackground,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    border: Border.all(color: RetroColors.borderDark, width: 1),
                  ),
                  child: const Center(
                    child: Text('♞', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: RetroTextStyles.uiText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const RetroDivider(),
          // Content
          Expanded(
            child: RetroScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(content, style: RetroTextStyles.tutorText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
