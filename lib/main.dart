import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/push/notification_service.dart';
import 'core/storage/prefs_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // [FLOW NOTIF 1 - STARTUP] Begitu app baru dibuka, langsung siapin Channel notifikasi Android (arus_push_high)
  // lewat notification_service.dart supaya nanti notif bisa muncul melayang (heads-up) + bunyi.
  await NotificationService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ArusApp(),
    ),
  );
}
