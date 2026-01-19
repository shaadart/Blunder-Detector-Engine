import 'package:flutter/widgets.dart';
import 'retro_theme.dart';
import 'retro_widgets.dart';

/// Classic Windows 95 style dialog for loading PGN
class PgnLoadDialog extends StatefulWidget {
  final void Function(String pgn, String username) onLoad;
  final VoidCallback onCancel;

  const PgnLoadDialog({
    super.key,
    required this.onLoad,
    required this.onCancel,
  });

  @override
  State<PgnLoadDialog> createState() => _PgnLoadDialogState();
}

class _PgnLoadDialogState extends State<PgnLoadDialog> {
  final TextEditingController _pgnController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _pgnFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill with sample PGN for testing
    _pgnController.text = '''[Event "Live Chess"]
[Site "Chess.com"]
[Date "2024.01.15"]
[White "Player1"]
[Black "Player2"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 1-0''';
    _usernameController.text = 'Player1';
  }

  @override
  void dispose() {
    _pgnController.dispose();
    _usernameController.dispose();
    _pgnFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        height: 400,
        decoration: RetroBorders.windowFrame,
        child: Column(
          children: [
            // Title bar
            _buildTitleBar(),
            // Content
            Expanded(
              child: Container(
                color: RetroColors.windowBackground,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username field
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Username:',
                            style: RetroTextStyles.uiText,
                          ),
                        ),
                        Expanded(
                          child: _buildTextField(
                            _usernameController,
                            _usernameFocusNode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // PGN label
                    const Text('Paste PGN:', style: RetroTextStyles.uiText),
                    const SizedBox(height: 4),
                    // PGN text area
                    Expanded(child: _buildTextArea()),
                    const SizedBox(height: 8),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        RetroButton(text: 'OK', width: 75, onPressed: _onLoad),
                        const SizedBox(width: 8),
                        RetroButton(
                          text: 'Cancel',
                          width: 75,
                          onPressed: widget.onCancel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 20,
      color: RetroColors.titleBarActive,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Load PGN',
              style: RetroTextStyles.titleBarText,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              width: 16,
              height: 14,
              decoration: RetroBorders.raised,
              child: const Center(
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: RetroColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(color: RetroColors.borderMedium, width: 1),
          left: BorderSide(color: RetroColors.borderMedium, width: 1),
          bottom: BorderSide(color: RetroColors.borderLight, width: 1),
          right: BorderSide(color: RetroColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EditableText(
        controller: controller,
        focusNode: focusNode,
        style: RetroTextStyles.uiText,
        cursorColor: RetroColors.textPrimary,
        backgroundCursorColor: RetroColors.windowBackground,
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(color: RetroColors.borderMedium, width: 1),
          left: BorderSide(color: RetroColors.borderMedium, width: 1),
          bottom: BorderSide(color: RetroColors.borderLight, width: 1),
          right: BorderSide(color: RetroColors.borderLight, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(4),
        child: EditableText(
          controller: _pgnController,
          focusNode: _pgnFocusNode,
          style: RetroTextStyles.monoText,
          cursorColor: RetroColors.textPrimary,
          backgroundCursorColor: RetroColors.windowBackground,
          maxLines: null,
        ),
      ),
    );
  }

  void _onLoad() {
    final pgn = _pgnController.text.trim();
    final username = _usernameController.text.trim();
    if (pgn.isNotEmpty && username.isNotEmpty) {
      widget.onLoad(pgn, username);
    }
  }
}

/// Simple message dialog
class RetroMessageDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onOk;

  const RetroMessageDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        decoration: RetroBorders.windowFrame,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              height: 20,
              color: RetroColors.titleBarActive,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: RetroTextStyles.titleBarText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              color: RetroColors.windowBackground,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info icon
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: RetroColors.titleBarActive,
                          border: Border.all(color: RetroColors.borderDark),
                        ),
                        child: const Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: RetroColors.titleBarText,
                              fontFamily: 'Times New Roman',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(message, style: RetroTextStyles.uiText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RetroButton(text: 'OK', width: 75, onPressed: onOk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog
class RetroLoadingDialog extends StatelessWidget {
  final String message;

  const RetroLoadingDialog({super.key, this.message = 'Please wait...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        decoration: RetroBorders.windowFrame,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              height: 20,
              color: RetroColors.titleBarActive,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Text(
                'Working...',
                style: RetroTextStyles.titleBarText,
              ),
            ),
            // Content
            Container(
              color: RetroColors.windowBackground,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Retro progress indicator (dots)
                  const _RetroProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(message, style: RetroTextStyles.uiText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetroProgressIndicator extends StatefulWidget {
  const _RetroProgressIndicator();

  @override
  State<_RetroProgressIndicator> createState() =>
      _RetroProgressIndicatorState();
}

class _RetroProgressIndicatorState extends State<_RetroProgressIndicator> {
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _animate();
  }

  void _animate() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index < _dotCount
                ? RetroColors.titleBarActive
                : RetroColors.panelBackground,
            border: Border.all(color: RetroColors.borderDark),
          ),
        );
      }),
    );
  }
}
