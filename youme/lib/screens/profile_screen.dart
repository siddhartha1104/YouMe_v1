import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youme/api/apis.dart';
import 'package:youme/helper/dialogs.dart';
import 'package:youme/main.dart';
import 'package:youme/models/chat_user.dart';
import 'package:youme/screens/auth/login_screen.dart';

///user Profile Screen to show user info
class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Profile',
            // style: GoogleFonts.roboto(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),

        //Floating button to add new user
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            // backgroundColor: Color.fromARGB(255, 210, 229, 239),
            onPressed: () async {
              //for showing the progress dialog
              Dialogs.showProgressBar(context);

              //sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  //for hiding progress dialog
                  Navigator.pop(context);

                  /// for moving to home screen
                  Navigator.pop(context);

                  //replacing home screen with login screen
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                });
              });
            },
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
          ),
        ),

        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * .02),
                  Stack(
                    children: [
                      //Profile picture

                      _image != null
                          ?

                          //local image
                          ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * .1),
                              child: Image.file(
                                File(_image!),
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                              ),
                            )
                          :

                          // image from server
                          ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * .1),
                              child: CachedNetworkImage(
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                                imageUrl: widget.user.image,
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                        child:
                                            Icon(CupertinoIcons.person_fill)),
                              ),
                            ),

                      //dp edit button
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: MaterialButton(
                          onPressed: () {
                            _showBottomSheet();
                          },
                          shape: const CircleBorder(),
                          color: Colors.white,
                          elevation: 2,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: mq.height * .02),
                  Text(widget.user.email,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 16)),
                  SizedBox(height: mq.height * .05),

                  //Name input field
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'Your Name',
                      label: const Text('Name'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),

                  //about input field
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.info_outline),
                      hintText: 'bio',
                      label: const Text('About'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: mq.height * .07),

                  //update profile button
                  ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: Size(mq.width * .4, mq.height * .06),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          APIs.updateUserInfo().then((value) {
                            Dialogs.showSnachbar(context, 'update sucessful');
                          });
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'Update',
                        style: TextStyle(fontSize: 18),
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //bottomSheet for selecting a dp for user
  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        )),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              const Text(
                'Pick Profile Picture',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: mq.height * .02),

              //dp selection from gallery and camera buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //from gallery
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: Size(mq.width * .3, mq.height * .13),
                      ),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          log('image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          //for hiding bottom sheet
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('assets/images/gallery.png')),

                  //from camera
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: Size(mq.width * .3, mq.height * .13),
                      ),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (image != null) {
                          log('image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));

                          //for hiding bottom sheet
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('assets/images/camera.png')),
                ],
              )
            ],
          );
        });
  }
}
