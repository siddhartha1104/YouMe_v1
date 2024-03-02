import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youme/api/apis.dart';
import 'dart:developer';
import 'package:youme/main.dart';
import 'package:youme/screens/auth/login_screen.dart';
import 'package:youme/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      // again enter in normal screen mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          statusBarColor: Colors.white));

      if (FirebaseAuth.instance.currentUser != null) {
        log('\nUser: ${APIs.auth.currentUser}');
        log('\nUserAdditionalInfo: ${APIs.auth.currentUser}');
        //Navigate to homescreen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        //Navigate to Login Screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 217, 235),
      // appBar: AppBar(
      //   backgroundColor: const Color.fromARGB(255, 171, 125, 174),
      //   // leading: const Icon(Icons.arrow_back),
      //   centerTitle: true,
      //   title: Text(
      //     'Welcome to YouMe',
      //     style: GoogleFonts.ubuntu(),
      //   ),
      // ),
      body: Stack(
        children: [
          Positioned(
            // height: mq.height * .90,
            left: mq.width * .10,
            width: mq.width * .80,
            bottom: mq.height * .30,
            child: Image.asset(
              'assets/images/youme_png.png',
            ),
          ),
        ],
      ),
    );
  }
}
