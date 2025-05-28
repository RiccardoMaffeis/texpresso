package com.example.texpresso

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    // Registriamo manualmente tutti i plugin, incluso video_player_android
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}