import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF7B4B94);
  static const Color accentColor = Color(0xFFC5A5CF);
  static const Color backgroundColor = Colors.white;
  static const Color secondaryColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF333333);
  static const Color borderColor = Color(0xFFDDDDDD);
  
  // Spacing
  static const double smallPadding = 8.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  
  // Border radius
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // Typography
  static const String fontFamily = 'Roboto';
  
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    color: textColor,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}