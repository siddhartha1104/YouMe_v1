import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youme/api/apis.dart';
import 'package:youme/main.dart';
import 'package:youme/screens/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:youme/helper/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _handelGoogleBtnClick() {
    //For showing Progress bar
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      //for hiding progress bar
      Navigator.pop(context);
      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if ((await APIs.userExists())) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch (e) {
      log('\n_signInWithGoogle: $e');
      Dialogs.showSnachbar(
          // ignore: use_build_context_synchronously
          context,
          'Something went Wrong. Check your Internet connection');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 217, 235),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 171, 125, 174),
        centerTitle: true,
        title: Text(
          'Welcome to YouMe',
          style: GoogleFonts.ubuntu(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            height: mq.height * .55,
            left: mq.width * .20,
            width: mq.width * .60,
            child: Image.asset(
              'assets/images/youme_png.png',
            ),
          ),
          Positioned(
            bottom: mq.height * .25,
            left: mq.width * .09,
            width: mq.width * .8,
            height: mq.width * .15,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 1,
                backgroundColor: const Color.fromARGB(255, 218, 186, 220),
              ),
              onPressed: () {
                _handelGoogleBtnClick();
              },
              icon: Image.asset(
                'assets/images/google.png',
                height: mq.height * .04,
              ),
              label: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 22),
                  children: [
                    TextSpan(text: ' Login with'),
                    TextSpan(
                        text: ' Google',
                        style: TextStyle(fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
