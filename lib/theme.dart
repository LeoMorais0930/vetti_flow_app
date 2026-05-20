import 'package:flutter/material.dart';

const kVettiBlue   = Color(0xFF1976D2); // Primary Blue
const kVettiWhite  = Color(0xFFFFFFFF);
const kVettiBackground = Color(0xFFF5F7F9); // Lighter background for contrast
const kVettiGray   = Color(0xFFE0E0E0);
const kVettiGrayDk = Color(0xFF757575);

final vettiTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: kVettiBlue,
    primary: kVettiBlue,
    surface: kVettiWhite,
    background: kVettiBackground,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: kVettiBackground,
  
  appBarTheme: const AppBarTheme(
    backgroundColor: kVettiBlue,
    foregroundColor: kVettiWhite,
    elevation: 2,
    centerTitle: false,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
  ),
  
  tabBarTheme: const TabBarTheme(
    labelColor: kVettiWhite,
    unselectedLabelColor: Colors.white70,
    indicatorColor: kVettiWhite,
    indicatorSize: TabBarIndicatorSize.tab,
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kVettiBlue,
      foregroundColor: kVettiWhite,
      minimumSize: const Size(double.infinity, 50),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kVettiBlue,
      minimumSize: const Size(double.infinity, 50),
      side: const BorderSide(color: kVettiBlue, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kVettiGray)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kVettiGray)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kVettiBlue, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: kVettiGrayDk, fontSize: 14),
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
  ),
  
  cardTheme: CardTheme(
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: kVettiWhite,
    margin: const EdgeInsets.only(bottom: 16),
  ),

  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 24,
    backgroundColor: kVettiWhite,
    titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
  ),

  dividerTheme: const DividerThemeData(
    thickness: 1,
    color: kVettiGray,
    space: 24,
  ),
);
