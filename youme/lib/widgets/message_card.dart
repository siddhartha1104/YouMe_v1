import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import 'package:youme/api/apis.dart';
import 'package:youme/helper/dialogs.dart';
import 'package:youme/helper/my_date_util.dart';
import 'package:youme/main.dart';
import 'package:youme/models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;
  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  String url = '';

  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromld;
    return InkWell(
        onLongPress: () {
          _showBottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage());
  }

  Widget _blueMessage() {
    //update blue tick
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .01
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 13, 14, 14),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30))),
            child: widget.message.type == Type.text
                ?
                //show text
                Text(
                    widget.message.msg,
                    style: const TextStyle(
                        fontSize: 16, letterSpacing: .5, color: Colors.white),
                  )
                :
                // show image
                ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image, size: 70),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormatedTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            //for adding some space
            SizedBox(width: mq.width * .04),

            //double tick icon for message read
            if (widget.message.read.isNotEmpty)
              //double tick icon
              const Icon(Icons.done_all_outlined, color: Colors.blue),

            const SizedBox(
              width: 3,
            ),

            //sent time
            Text(
              MyDateUtil.getFormatedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .01
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 66, 13, 93),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30))),
            child: widget.message.type == Type.text
                ?
                //show text
                Text(
                    widget.message.msg,
                    style: const TextStyle(
                        fontSize: 16, letterSpacing: .5, color: Colors.white),
                  )
                :
                // show image
                ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image, size: 70),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  //bottomSheet for modifying message
  void _showBottomSheet(bool isMe) {
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
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
              ),

              widget.message.type == Type.text
                  ?
                  //Copy Option
                  _OptionItem(
                      icon: const Icon(
                        Icons.copy,
                      ),
                      name: 'Copy',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          // for hiding bottom sheet
                          Navigator.pop(context);
                          Dialogs.showSnachbar(context, 'Text Copied!');
                        });
                      })
                  :
                  //save Image Option
                  _OptionItem(
                      icon: const Icon(
                        Icons.download,
                      ),
                      name: 'Save',
                      onTap: () async {
                        try {
                          log('Image URL: ${widget.message.msg}');
                          Dialogs.showProgressBar(context);
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'YouMe')
                              .then((success) {
                            Navigator.pop(context);
                            if (success != null && success) {
                              Dialogs.showSnachbar(
                                  context, 'Image saved ucessfully!!');
                            }
                          });
                        } catch (e) {
                          log('download img error: $e');
                        }
                      }),

              // if (widget.message.type == Type.text && isMe)
              //   //edit Option
              //   _OptionItem(
              //       icon: const Icon(
              //         Icons.edit,
              //         color: Colors.blue,
              //       ),
              //       name: 'Edit',
              //       onTap: () {
              //         Navigator.pop(context);
              //       }),

              //Delete Option
              if (isMe)
                _OptionItem(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    name: 'Delete',
                    onTap: () {
                      APIs.deleteMessage(widget.message).then((value) {
                        //for hiding bottom sheet
                        Navigator.pop(context);
                      });
                    }),

              SizedBox(
                height: mq.height * .040,
              ),
            ],
          );
        });
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
          left: mq.width * .05,
          top: mq.height * .015,
          bottom: mq.height * .025,
        ),
        child: Row(
          children: [
            icon,
            Flexible(
                child: Text(
              '  $name',
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
            ))
          ],
        ),
      ),
    );
  }
}
