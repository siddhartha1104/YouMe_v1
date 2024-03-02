import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:flutter_notification_channel/notification_importance.dart';
import 'package:youme/screens/splash_screen.dart';
import 'firebase_options.dart';

//Global object for accessing screen
late Size mq;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // To Enter in Full screen Mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  //for setting screen orientation to potrait Only
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) {
    _initilizationFirebase();
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouMe..',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // fontFamily: "ProtestRevolution",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 171, 125, 174),
          elevation: 1,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

_initilizationFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var result = await FlutterNotificationChannel.registerNotificationChannel(
      description: 'For showing message Notification',
      id: 'chats',
      importance: NotificationImportance.IMPORTANCE_HIGH,
      name: 'Chats');
  log('\nNotification channel result: $result');
}
