import 'dart:io';
import 'package:flutter/services.dart';

class WidgetUpdater {
  static const _channel = MethodChannel('com.karthik.local_hub/widget');

  static Future<void> update() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }
}