import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youme/api/apis.dart';
import 'package:youme/helper/my_date_util.dart';
import 'package:youme/main.dart';
import 'package:youme/models/chat_user.dart';
import 'package:youme/models/message.dart';
import 'package:youme/screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  //last msg info (if null --> no msg)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          user: widget.user,
                        )));
          },
          child: StreamBuilder(
              stream: APIs.getLastMessages(widget.user),
              builder: (context, snapshot) {
                final data = snapshot.data?.docs;
                final list =
                    data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

                if (list.isNotEmpty) {
                  _message = list[0];
                }

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .3),
                    child: CachedNetworkImage(
                      width: mq.height * .055,
                      height: mq.height * .055,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person_fill)),
                    ),
                  ),
                  title: Text(
                    widget.user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18),
                  ),

                  // Last Message
                  subtitle: Text(
                      _message != null
                          ? _message!.type == Type.image
                              ? 'Image'
                              : _message!.msg
                          : widget.user.about,
                      maxLines: 1),

                  //last active status
                  trailing: _message == null
                      ? null
                      : _message!.read.isEmpty &&
                              _message!.fromld != APIs.user.uid
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            )
                          : Text(
                              MyDateUtil.getLastMsgTime(
                                  context: context, time: _message!.sent),
                              style: const TextStyle(fontSize: 13),
                            ),
                );
              })),
    );
  }
}
