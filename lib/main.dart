import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:reader_hub_app/UI/Authentication/SplashScreen.dart';
import 'package:reader_hub_app/UI/Dashboard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reader\'s Hub', // Reader's Hub
      home: SplashScreen(),
    );
  }
}
