import 'package:flutter/material.dart';

class Constants {
  // Session
  static const int inactivityTimeoutSeconds = 120;
  static const int sessionWarningSeconds = 30;

  // Secure Storage Keys
  static const String secureDbKey = 'CIPHERTASK_SECURE_DB_KEY_V1';
  static const String secureLastEmail = 'CIPHERTASK_LAST_EMAIL_V1';

  // Hive Boxes
  static const String usersBox = 'cipher_users_box_v1';
  static const String todosBox = 'cipher_todos_box_v1';

  // Crypto Labels
  static const String fieldKeyLabel = 'CIPHERTASK_FIELD_KEY_V1';
  static const String aesGcmPayloadVersion = 'v1';

  // Navigation / UI
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Theme
  static const Color dsBlack = Color(0xFF0B0B0F);
  static const Color dsCrimson = Color(0xFFB11226);
  static const Color dsTeal = Color(0xFF1AA6B7);
}