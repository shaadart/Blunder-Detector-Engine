import 'package:flutter/widgets.dart';

/// Retro Windows 95/98 Color Palette
/// No gradients. Solid colors only.
class RetroColors {
  RetroColors._();

  // Core window colors
  static const Color windowBackground = Color(0xFFC0C0C0);
  static const Color panelBackground = Color(0xFFE0E0E0);

  // Border colors for 3D beveled effect
  static const Color borderDark = Color(0xFF404040);
  static const Color borderLight = Color(0xFFFFFFFF);
  static const Color borderMedium = Color(0xFF808080);

  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color linkBlue = Color(0xFF0000EE);
  static const Color linkVisited = Color(0xFF551A8B);

  // Title bar
  static const Color titleBarActive = Color(0xFF000080);
  static const Color titleBarInactive = Color(0xFF808080);
  static const Color titleBarText = Color(0xFFFFFFFF);

  // Move classification colors
  static const Color mistake = Color(0xFFF2B6C6);
  static const Color inaccuracy = Color(0xFFFFF4A8);
  static const Color good = Color(0xFFB6F2B6);
  static const Color brilliant = Color(0xFFB6D4F2);

  // Chess board
  static const Color boardLight = Color(0xFFEEEED2);
  static const Color boardDark = Color(0xFF769656);
  static const Color boardBorder = Color(0xFF000000);

  // Table colors
  static const Color tableRowEven = Color(0xFFFFFFFF);
  static const Color tableRowOdd = Color(0xFFE8E8E8);
  static const Color tableBorder = Color(0xFF808080);
  static const Color tableHeader = Color(0xFFC0C0C0);

  // Selection
  static const Color selectedRow = Color(0xFF000080);
  static const Color selectedRowText = Color(0xFFFFFFFF);
}

/// Retro Typography - System fonts from the 90s
class RetroFonts {
  RetroFonts._();

  // UI fonts (in order of preference)
  static const String uiFont = 'Verdana, Arial, Tahoma, sans-serif';

  // Tutor/console text
  static const String tutorFont = 'Times New Roman, serif';

  // Monospace for eval/engine
  static const String monoFont = 'Courier New, Courier, monospace';

  // Font sizes (small, dense layout)
  static const double sizeSmall = 11.0;
  static const double sizeDefault = 12.0;
  static const double sizeMedium = 13.0;
  static const double sizeLarge = 14.0;
  static const double sizeTitle = 12.0;
}

/// Common text styles
class RetroTextStyles {
  RetroTextStyles._();

  static const TextStyle uiText = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeDefault,
    color: RetroColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle menuText = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeDefault,
    color: RetroColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle titleBarText = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeTitle,
    fontWeight: FontWeight.bold,
    color: RetroColors.titleBarText,
    decoration: TextDecoration.none,
  );

  static const TextStyle linkText = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeDefault,
    color: RetroColors.linkBlue,
    decoration: TextDecoration.underline,
  );

  static const TextStyle tutorText = TextStyle(
    fontFamily: 'Times New Roman',
    fontSize: RetroFonts.sizeMedium,
    color: RetroColors.textPrimary,
    height: 1.3,
    decoration: TextDecoration.none,
  );

  static const TextStyle monoText = TextStyle(
    fontFamily: 'Courier New',
    fontSize: RetroFonts.sizeDefault,
    color: RetroColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle statusBarText = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeSmall,
    color: RetroColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle tableHeader = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeDefault,
    fontWeight: FontWeight.bold,
    color: RetroColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle tableCell = TextStyle(
    fontFamily: 'Verdana',
    fontSize: RetroFonts.sizeSmall,
    color: RetroColors.textPrimary,
    decoration: TextDecoration.none,
  );
}

/// Border decorations for the classic Windows 95 look
class RetroBorders {
  RetroBorders._();

  /// Raised/outset border (default button state)
  static BoxDecoration get raised => const BoxDecoration(
    color: RetroColors.panelBackground,
    border: Border(
      top: BorderSide(color: RetroColors.borderLight, width: 2),
      left: BorderSide(color: RetroColors.borderLight, width: 2),
      bottom: BorderSide(color: RetroColors.borderDark, width: 2),
      right: BorderSide(color: RetroColors.borderDark, width: 2),
    ),
  );

  /// Sunken/inset border (pressed button state)
  static BoxDecoration get sunken => const BoxDecoration(
    color: RetroColors.panelBackground,
    border: Border(
      top: BorderSide(color: RetroColors.borderDark, width: 2),
      left: BorderSide(color: RetroColors.borderDark, width: 2),
      bottom: BorderSide(color: RetroColors.borderLight, width: 2),
      right: BorderSide(color: RetroColors.borderLight, width: 2),
    ),
  );

  /// Window frame border
  static BoxDecoration get windowFrame => const BoxDecoration(
    color: RetroColors.windowBackground,
    border: Border(
      top: BorderSide(color: RetroColors.borderLight, width: 2),
      left: BorderSide(color: RetroColors.borderLight, width: 2),
      bottom: BorderSide(color: RetroColors.borderDark, width: 2),
      right: BorderSide(color: RetroColors.borderDark, width: 2),
    ),
  );

  /// Panel inset (for content areas)
  static BoxDecoration get panelInset => const BoxDecoration(
    color: RetroColors.panelBackground,
    border: Border(
      top: BorderSide(color: RetroColors.borderMedium, width: 1),
      left: BorderSide(color: RetroColors.borderMedium, width: 1),
      bottom: BorderSide(color: RetroColors.borderLight, width: 1),
      right: BorderSide(color: RetroColors.borderLight, width: 1),
    ),
  );

  /// Status bar top border only
  static BoxDecoration get statusBar => const BoxDecoration(
    color: RetroColors.windowBackground,
    border: Border(top: BorderSide(color: RetroColors.borderMedium, width: 1)),
  );

  /// Simple black border (for chess board)
  static BoxDecoration blackBorder(double width) => BoxDecoration(
    border: Border.all(color: RetroColors.boardBorder, width: width),
  );
}
