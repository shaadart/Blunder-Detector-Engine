import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart'; // We will create this next

void main() {
  runApp(const MaeChessApp());
}

class MaeChessApp extends StatelessWidget {
  const MaeChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAE Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep Charcoal
        primaryColor: const Color(0xFF00E5FF), // Cyan Accent
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF00FF), // Magenta for Risk
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}