import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF9900); // Orange color for login button
  static const Color yellow = Color(0xFFFFEF12); // Yellow color for gradient
  static const Color textDark = Color(0xFF000000);
  static const Color textLight = Color(0xFF757575);
  static const Color white = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF5F5F5);
    static const Color divider = Color(0xFFEAEAEA);
    static const Color iconBorder = Color(0xFFE0E0E0);
    static const Color error = Color(0xFFFF3B30); // Logout/Error
    static const Color cardShadow = Color(0xFFFFD580); // Light yellow shadow
    static const Color chatBubbleYellow = Color(0xFFFFE066); // Chat bubble yellow
    static const Color linkColor = Color(0xFFFF9900); // For "Forgot Password?" and "Register Now"

static const LinearGradient appGradient = LinearGradient(
      colors: [primary, yellow],
  stops: [0.0, 3.0], // Orange 90%, Yellow only 10%
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

}
