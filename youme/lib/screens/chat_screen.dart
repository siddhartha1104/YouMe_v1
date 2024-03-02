import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youme/api/apis.dart';
import 'package:youme/main.dart';
import 'package:youme/models/chat_user.dart';
import 'package:youme/models/message.dart';
import 'package:youme/screens/view_profile_screen.dart';
import 'package:youme/widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Message> _list = [];

  //for handaling message text changes
  final _textController = TextEditingController();

  //this will check if image is uploading or not
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 234, 188, 237),
          elevation: 3,
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
        ),
        // backgroundColor: Color.fromARGB(255, 138, 138, 154),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getAllMessages(widget.user),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    //if data is loading
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const SizedBox();

                    //if some or all data is loaded then show it
                    case ConnectionState.active:
                    case ConnectionState.done:
                      final data = snapshot.data?.docs;
                      _list = data
                              ?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                          [];

                      if (_list.isNotEmpty) {
                        return ListView.builder(
                            reverse: true,
                            itemCount: _list.length,
                            padding: EdgeInsets.only(top: mq.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return MessageCard(
                                message: _list[index],
                              );
                            });
                      } else {
                        return const Center(
                            child: Text(
                          'Say hi!! 👋',
                          style: TextStyle(fontSize: 25),
                        ));
                      }
                  }
                },
              ),
            ),

            //progress indicator for showing uploading
            if (_isUploading)
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),

            //chat imput field
            _chatInput(),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewProfileScreen(
                      user: widget.user,
                    )));
      },
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black54,
              )),
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * .3),
            child: CachedNetworkImage(
              width: mq.height * .044,
              height: mq.height * .044,
              imageUrl: widget.user.image,
              errorWidget: (context, url, error) =>
                  const CircleAvatar(child: Icon(CupertinoIcons.person_fill)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold),
              ),
              const Text(
                'last seen not available',
                style: TextStyle(
                  color: Colors.black54,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .015),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 6,
                    minLines: 1,
                    enableSuggestions: true,
                    autocorrect: true,
                    decoration: const InputDecoration(
                      hintText: 'Message..',
                      contentPadding: EdgeInsets.only(left: 20),
                      border: InputBorder.none,
                    ),
                  )),

                  //send photo form gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Picking multiple images image.
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);

                        //uploading and sending images one by one
                        for (var i in images) {
                          log('image Path: ${i.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.image,
                        size: 28,
                      )),

                  //click image from camera button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          //to reduce image quality by 20 percent
                          // imageQuality: 70,
                        );
                        if (image != null) {
                          log('image Path: ${image.path}');

                          setState(() => _isUploading = true);

                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 28,
                      )),
                  SizedBox(
                    width: mq.width * .02,
                  ),
                ],
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            minWidth: 0,
            //send Message button
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: const Color.fromARGB(255, 176, 62, 191),
            elevation: 5,
            child: const Icon(
              Icons.send,
              size: 28,
            ),
          )
        ],
      ),
    );
  }
}
