import 'package:flutter/material.dart';

class ColorConstants {
  static const seedColorLight = Colors.deepPurple;
  static const seedColorDark = Colors.deepPurple;

  // Streak colors
  static const streakColorDefault = Color.fromARGB(255, 59, 59, 59);
  static const streakColor3Days = Color(0xFFFF8A65);
  static const streakColor10Days = Color(0xFFFF9800);
  static const streakColor20Days = Color(0xFFFF3D00);
  static const streakColor30Days = Color(0xFFFF1744);
  static const streakColor60Days = Color(0xFF2BFF0A);
  static const streakColor100Days = Color(0xFFD500F9);
  static const streakColor200Days = Color(0xFF651FFF);
  static const streakColor365Days = Color(0xFF0509FF);
  static const streakColor500Days = Color(0xFF0AFFEB);

  // Primary colors (fallback when theme is not directly used)
  static const primary = Colors.deepPurple;
  static final primaryLight = Colors.deepPurple.shade50;

  // General Text Colors
  static const textPrimary = Colors.black87;
  static const textSecondary = Colors.black54;
  static const textWhite = Colors.white;
  static const textGrey = Colors.grey;

  // UI Colors
  static const error = Colors.red;
  static final errorMedium = Colors.red.shade400;

  static const success = Colors.green;
  static final successLight = Colors.green.shade50;
  static final successMedium = Colors.green.shade400;
  static final successDark = Colors.green.shade900;

  static const backgroundWhite = Colors.white;
  static final backgroundGrey = Colors.grey.shade200;

  static final borderGrey = Colors.grey.shade300;
  
  static const iconGrey = Colors.grey;
  static const iconBlue = Colors.blue;
  
  static const buttonDisabled = Colors.grey;
}
