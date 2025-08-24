import 'package:flutter/material.dart';

// Empty implementation of fluttertoast
class Fluttertoast {
  static Future<bool?> showToast({
    required String msg,
    Toast? toastLength,
    int timeInSecForIosWeb = 1,
    double? fontSize,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    bool webShowClose = false,
    webBgColor = "linear-gradient(to right, #00b09b, #96c93d)",
    webPosition = "right",
  }) async {
    // Do nothing, just return success
    return true;
  }

  static void cancel() {
    // Do nothing
  }
}

// Enums to match the original API
enum Toast { LENGTH_SHORT, LENGTH_LONG }

enum ToastGravity { TOP, BOTTOM, CENTER, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, CENTER_LEFT, CENTER_RIGHT } 