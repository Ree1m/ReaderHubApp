import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:reader_hub_app/UI/Authentication/LoginScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    delegateNavigationDirection();
    super.initState();
  }

  delegateNavigationDirection() async {
    await Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 350,
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/Logo.png')),
              ),
            ),
            SizedBox(height: 150),
            SizedBox(
              height: 200,
              child: LoadingIndicator(
                indicatorType: Indicator.ballClipRotatePulse,
                strokeWidth: 10,
                colors: [Color(0xff197e62), Color(0xff4ab993)],
              ),
            ),
            Text(
              'Loading, Please wait...',
              style: GoogleFonts.merriweather(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
