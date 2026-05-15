import 'package:flutter/material.dart';

const kVettiBlue   = Color(0xFF0073BB);
const kVettiWhite  = Color(0xFFFFFFFF);
const kVettiGray   = Color(0xFFE1E1E1);
const kVettiGrayDk = Color(0xFF757575);

final vettiTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: kVettiBlue,
    primary: kVettiBlue,
    surface: kVettiWhite,
  ),
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: kVettiBlue,
    foregroundColor: kVettiWhite,
    elevation: 0,
    centerTitle: false,
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: kVettiWhite,
    unselectedLabelColor: Colors.white70,
    indicatorColor: kVettiWhite,
    indicatorSize: TabBarIndicatorSize.tab,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kVettiBlue,
      foregroundColor: kVettiWhite,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kVettiBlue, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: kVettiGray),
    ),
    color: kVettiWhite,
  ),
);
