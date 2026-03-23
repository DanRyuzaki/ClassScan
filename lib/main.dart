import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classscan/firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      runApp(const _NoConnectionApp());
      return;
    }
  }
  runApp(const MyApp());
}

class _NoConnectionApp extends StatefulWidget {
  const _NoConnectionApp();
  @override
  State<_NoConnectionApp> createState() => _NoConnectionAppState();
}

class _NoConnectionAppState extends State<_NoConnectionApp> {
  bool _retrying = false;
  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      runApp(const MyApp());
    } catch (_) {
      setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFF444444),
                  size: 56,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Connection',
                  style: TextStyle(
                    color: Color(0xFFF0F0F0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ClassScan requires an internet connection to start.\n'
                  'Please check your network and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _retrying ? null : _retry,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _retrying ? 0.6 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAEEA00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _retrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
