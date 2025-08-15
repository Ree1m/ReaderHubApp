import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reader_hub_app/Modules/CustomSnackBar.dart';
import 'package:reader_hub_app/UI/AdminScreens/AdminDashboard.dart';
import 'package:reader_hub_app/UI/Authentication/SignUpScreen.dart';
import 'package:reader_hub_app/UI/Dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: ListView(
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/Logo.png'), fit: BoxFit.contain),
                ),
              ),
              Center(
                child: Text(
                  'Login',
                  style: GoogleFonts.merriweather(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await initiateLoginProcess(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff197e62),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
                child: Text(
                  "Don't have an account? Sign up",
                  style: GoogleFonts.merriweather(color: Color(0xff197e62), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future initiateLoginProcess(BuildContext context) async {
    /** 
   * تقوم هذه الدالة ببدء عملية تسجيل الدخول.
   * تتحقق أولاً من صحة البريد الإلكتروني وكلمة المرور، ثم تعرض شريط تحميل أثناء التحقق.
   * إذا تم تسجيل الدخول بنجاح، يتم توجيه المستخدم إلى لوحة التحكم الخاصة به حسب الدور.
   * في حال فشل المصادقة أو عدم العثور على الملف الشخصي، يتم عرض رسالة خطأ.
   */

    // Check if email is empty or invalid
    if (emailController.text.isEmpty || emailController.text.contains('@') == false) {
      showCustomSnackBar(context, 'Email is not valid', Colors.red, 2);
    }
    // Check if password is empty
    else if (passwordController.text.isEmpty) {
      showCustomSnackBar(context, 'Password is not valid', Colors.red, 2);
    } else {
      // Show a loading snackbar while verifying credentials
      final loadingSnackBar = SnackBar(
        backgroundColor: Color(0xff197e62),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 20),
            Text(
              'Verifying your account...',
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 30),
      );
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

      // Wait for 2 seconds before starting authentication
      await Future.delayed(Duration(seconds: 2), () {});

      try {
        // Attempt to sign in with email and password
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            )
            .then((value) async {
              // Fetch user data from Firestore
              await FirebaseFirestore.instance.collection('Users').doc(value.user!.uid).get().then((
                userData,
              ) {
                if (userData.exists) {
                  // Hide loading snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // Navigate based on user role
                  if (userData.data()!['role'] == 'Admin') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboard(userData: userData)),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Dashboard(userData: userData)),
                    );
                  }
                } else {
                  // Hide loading snackbar and show error if user profile not found
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  showCustomSnackBar(context, 'Profile not found', Colors.red, 2);
                }
              });
            });
      } catch (e) {
        // Hide loading snackbar and show error if authentication fails
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showCustomSnackBar(context, 'Invalid credentials', Colors.red, 2);
      }
    }
  }
}
