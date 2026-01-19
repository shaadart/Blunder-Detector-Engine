import 'package:flutter/widgets.dart';
import 'retro_theme.dart';

/// Classic Windows 95 style button with beveled 3D effect
/// Implements border inversion on press
class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final bool enabled;

  const RetroButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.enabled = true,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: _isPressed ? RetroBorders.sunken : RetroBorders.raised,
        padding: widget.padding,
        child: Center(
          child: Text(
            widget.text,
            style: RetroTextStyles.uiText.copyWith(
              color: isEnabled
                  ? RetroColors.textPrimary
                  : RetroColors.borderMedium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button for navigation (<<, <, >, >>)
class RetroIconButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final bool enabled;

  const RetroIconButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = 32,
    this.enabled = true,
  });

  @override
  State<RetroIconButton> createState() => _RetroIconButtonState();
}

class _RetroIconButtonState extends State<RetroIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: _isPressed ? RetroBorders.sunken : RetroBorders.raised,
        child: Center(
          child: Text(
            widget.label,
            style: RetroTextStyles.uiText.copyWith(
              fontWeight: FontWeight.bold,
              color: isEnabled
                  ? RetroColors.textPrimary
                  : RetroColors.borderMedium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Windows 95 style window frame
class RetroWindowFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final List<RetroMenuItem>? menuItems;
  final String? statusText;
  final double? width;
  final double? height;

  const RetroWindowFrame({
    super.key,
    required this.title,
    required this.child,
    this.menuItems,
    this.statusText,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: RetroBorders.windowFrame,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          _buildTitleBar(),
          // Menu bar (if provided)
          if (menuItems != null) _buildMenuBar(),
          // Main content
          Expanded(
            child: Container(
              color: RetroColors.windowBackground,
              padding: const EdgeInsets.all(2),
              child: child,
            ),
          ),
          // Status bar (if provided)
          if (statusText != null) _buildStatusBar(),
        ],
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
          // Window icon (small square)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: RetroColors.windowBackground,
              border: Border.all(color: RetroColors.borderDark, width: 1),
            ),
            child: const Center(
              child: Text('♞', style: TextStyle(fontSize: 10)),
            ),
          ),
          // Title
          Expanded(
            child: Text(
              title,
              style: RetroTextStyles.titleBarText,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Window controls
          _WindowControl(label: '_'),
          const SizedBox(width: 2),
          _WindowControl(label: '□'),
          const SizedBox(width: 2),
          _WindowControl(label: '×'),
        ],
      ),
    );
  }

  Widget _buildMenuBar() {
    return Container(
      height: 22,
      color: RetroColors.windowBackground,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: menuItems!.map((item) => _MenuButton(item: item)).toList(),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 20,
      decoration: RetroBorders.statusBar,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Sunken status panel
          Expanded(
            child: Container(
              decoration: RetroBorders.panelInset,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                statusText!,
                style: RetroTextStyles.statusBarText,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowControl extends StatefulWidget {
  final String label;

  const _WindowControl({required this.label});

  @override
  State<_WindowControl> createState() => _WindowControlState();
}

class _WindowControlState extends State<_WindowControl> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 16,
        height: 14,
        decoration: _isPressed ? RetroBorders.sunken : RetroBorders.raised,
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: RetroColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Menu item data
class RetroMenuItem {
  final String label;
  final VoidCallback? onTap;
  final List<RetroMenuItem>? submenu;

  const RetroMenuItem({required this.label, this.onTap, this.submenu});
}

class _MenuButton extends StatefulWidget {
  final RetroMenuItem item;

  const _MenuButton({required this.item});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.item.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: _isHovered ? RetroColors.titleBarActive : null,
          child: Text(
            widget.item.label,
            style: RetroTextStyles.menuText.copyWith(
              color: _isHovered ? RetroColors.titleBarText : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sunken panel for content areas
class RetroPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const RetroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? RetroColors.panelBackground,
        border: const Border(
          top: BorderSide(color: RetroColors.borderMedium, width: 1),
          left: BorderSide(color: RetroColors.borderMedium, width: 1),
          bottom: BorderSide(color: RetroColors.borderLight, width: 1),
          right: BorderSide(color: RetroColors.borderLight, width: 1),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Raised panel
class RetroRaisedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const RetroRaisedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RetroBorders.raised,
      padding: padding,
      child: child,
    );
  }
}

/// Group box with label (classic Windows control)
class RetroGroupBox extends StatelessWidget {
  final String label;
  final Widget child;
  final EdgeInsets padding;

  const RetroGroupBox({
    super.key,
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: RetroColors.borderMedium, width: 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Padding(padding: padding, child: child),
          ),
          Positioned(
            top: -6,
            left: 8,
            child: Container(
              color: RetroColors.windowBackground,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label, style: RetroTextStyles.uiText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal divider
class RetroDivider extends StatelessWidget {
  final double height;

  const RetroDivider({super.key, this.height = 2});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 2,
      child: Column(
        children: [
          Container(height: 1, color: RetroColors.borderMedium),
          Container(height: 1, color: RetroColors.borderLight),
        ],
      ),
    );
  }
}

/// Scrollable area with instant scroll (no inertia)
class RetroScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const RetroScrollView({super.key, required this.child, this.controller});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoGlowScrollBehavior(),
      child: SingleChildScrollView(
        controller: controller,
        physics: const ClampingScrollPhysics(),
        child: child,
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // No overscroll glow
  }
}

/// Text input field (Windows 95 style)
class RetroTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const RetroTextField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: EditableText(
        controller: controller ?? TextEditingController(),
        focusNode: FocusNode(),
        style: RetroTextStyles.uiText,
        cursorColor: RetroColors.textPrimary,
        backgroundCursorColor: RetroColors.windowBackground,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }
}
