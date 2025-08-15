import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reader_hub_app/UI/Dashboard.dart';

import '../../Modules/CustomSnackBar.dart';
import 'LoginScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController(text: "+966");
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

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
                  'Sign Up',
                  style: GoogleFonts.merriweather(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Color(0xff197e62)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await initiateSignupProcess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff197e62),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  "Already have an account? Login",
                  style: GoogleFonts.merriweather(color: Color(0xff197e62), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> initiateSignupProcess() async {
    /** 
   * تقوم هذه الدالة ببدء عملية تسجيل حساب جديد.
   * تتحقق أولاً من صحة المدخلات، وإذا كانت هناك أخطاء يتم عرض أول خطأ موجود.
   * إذا كانت المدخلات صحيحة، يتم تنفيذ عملية إنشاء الحساب.
   */

    // Validate user inputs
    final errors = _validateInputs();

    // If there are validation errors, show the first error
    if (errors.isNotEmpty) {
      final firstError = errors.values.firstWhere((error) => error != null, orElse: () => null);
      if (firstError != null) {
        showCustomSnackBar(context, firstError, Colors.red, 3);
      }
      return;
    }

    // If no errors, perform signup
    await _performSignup();
  }

  Map<String, String?> _validateInputs() {
    /** 
   * تقوم هذه الدالة بالتحقق من صحة مدخلات المستخدم (الاسم الأول، الاسم الأخير، الهاتف، البريد الإلكتروني، وكلمة المرور).
   * تعيد خريطة تحتوي على الأخطاء لكل حقل إذا وُجدت، وإلا تعيد خريطة فارغة.
   */

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final errors = <String, String?>{};

    // Validate first name
    if (firstName.isEmpty) {
      errors['firstName'] = 'First name is required';
    } else if (firstName.length < 2) {
      errors['firstName'] = 'Must be at least 2 characters';
    }

    // Validate last name
    if (lastName.isEmpty) {
      errors['lastName'] = 'Last name is required';
    } else if (lastName.length < 2) {
      errors['lastName'] = 'Must be at least 2 characters';
    }

    // Validate phone number
    if (phone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!phone.startsWith('+966')) {
      errors['phone'] = 'Must start with +966';
    } else if (phone.length != 13) {
      errors['phone'] = 'Invalid Saudi phone number';
    }

    // Validate email
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (email.contains('@') == false || email.contains('.com') == false) {
      errors['email'] = 'Invalid email format';
    }

    // Validate password
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Must be at least 6 characters';
    }

    return errors;
  }

  Future<void> _performSignup() async {
    /** 
   * تقوم هذه الدالة بإنشاء حساب مستخدم جديد باستخدام Firebase Authentication.
   * بعد إنشاء الحساب يتم حفظ بيانات المستخدم في قاعدة بيانات Firestore.
   * في حال نجاح العملية يتم نقل المستخدم إلى لوحة التحكم، وفي حال وجود أخطاء يتم عرض رسالة خطأ مناسبة.
   */

    // Show loading snackbar while creating the account
    final loadingSnackBar = SnackBar(
      backgroundColor: Color(0xff197e62),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 20),
          Text(
            'Creating account...',
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

    // Simple wait before starting signup
    await Future.delayed(Duration(seconds: 2), () {});

    try {
      // Create user account using email and password
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Save additional user information in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
            'firstName': firstNameController.text.trim(),
            'lastName': lastNameController.text.trim(),
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': DateTime.now(),
            'role': 'User',
          })
          .then((value) async {
            // Fetch the user data again after signup
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userCredential.user!.uid)
                .get()
                .then((userData) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  print('Done');
                  if (mounted) {
                    // Navigate to Dashboard after successful signup
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Dashboard(userData: userData)),
                    );
                  }
                });
          });
    } on FirebaseAuthException catch (e) {
      // Handle specific signup errors
      String errorMessage = 'Signup failed. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists with this email.';
      }
      showCustomSnackBar(context, errorMessage, Colors.red, 3);
    } catch (e) {
      // Handle unexpected errors
      showCustomSnackBar(context, 'An unexpected error occurred.', Colors.red, 3);
    } finally {
      // Hide the loading snackbar regardless of success or failure
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }
}
