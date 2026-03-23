import 'package:classscan/features/kiosk/presentation/kiosk_screen.dart';
import 'package:flutter/material.dart';
import 'package:classscan/features/main/presentation/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const MainScreen());
          case '/kiosk':
            return MaterialPageRoute(builder: (context) => const KioskScreen());
          default:
            return MaterialPageRoute(builder: (context) => const MainScreen());
        }
      },
    );
  }
}
