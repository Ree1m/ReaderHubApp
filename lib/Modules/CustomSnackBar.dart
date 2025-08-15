
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

showCustomSnackBar(BuildContext context,String message, Color color,int seconds){
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Center(
          child: Text(
            message.toString(),
            style: GoogleFonts.merriweather(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: color,
      duration: Duration(seconds: seconds),
    ),
  );
}