import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/player_service.dart';
import 'services/equalizer_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0e0e12),
  ));
  runApp(const VishaApp());
}

class VishaApp extends StatelessWidget {
  const VishaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerService()),
        ChangeNotifierProvider(create: (_) => EqualizerService()),
      ],
      child: MaterialApp(
        title: 'Visha Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0e0e12),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7c5cfc),
            secondary: Color(0xFFa78bfa),
            surface: Color(0xFF16161d),
            background: Color(0xFF0e0e12),
          ),
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
