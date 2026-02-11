import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/settings_service.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yatay mod zorla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Tam ekran modu
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Servisleri başlat
  await settingsService.init();
  await authService.init();
  await configService.loadConfig();

  runApp(const ELiARApp());
}

class ELiARApp extends StatelessWidget {
  const ELiARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELiAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF616161),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          toolbarHeight: 48,
          backgroundColor: Color(0xFF616161),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}
