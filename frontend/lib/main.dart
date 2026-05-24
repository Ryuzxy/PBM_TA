import 'package:flutter/material.dart';
import 'Splash/splash_1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Services/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Memuat tema yang tersimpan
  await ThemeManager.loadTheme(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'SmartDrop',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: currentTheme.bgColor,
            primaryColor: currentTheme.accentColor,
            brightness: currentTheme.bgColor.computeLuminance() > 0.5
                ? Brightness.light
                : Brightness.dark,
          ),
          home: const SplashScreen1(),
        );
      },
    );
  }
}