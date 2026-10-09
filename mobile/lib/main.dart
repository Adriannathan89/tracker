import 'package:flutter/material.dart';
import 'app.dart';
import 'ui/brand_fonts.dart';
import 'core/api_client.dart';
import 'core/app_controller.dart';
import 'core/config.dart';
import 'core/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await loadBrandFonts();
    final base = AppConfig.apiBase;
    final preferences = SecureStore();
    final controller = AppController(
      ApiClient(base, SessionStore(base, preferences), IoTransport()),
      preferences,
    );
    runApp(TrackerApp(controller: controller));
    controller.start();
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Konfigurasi aplikasi tidak valid: $e'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
