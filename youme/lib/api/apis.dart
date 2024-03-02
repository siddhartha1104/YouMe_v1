import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:youme/models/chat_user.dart';
import 'package:youme/models/message.dart';

class APIs {
  //for auth
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for storing data from firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing  firebase Storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  //to return current user
  static User get user => auth.currentUser!;

  //for accesing firebase messaging (Push Notification)
  static FirebaseMessaging fmessaging = FirebaseMessaging.instance;

  //for storing selfInfo
  static late ChatUser me;

  //for getting firebase messaging token (push notification)
  static Future<void> getFirebaseMessagingToken() async {
    await fmessaging.requestPermission();

    await fmessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('push_token: $t');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // for sending push notification
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": chatUser.name,
          "body": msg,
          "android_channel_id": "chats",
        },
        "data": {
          "some_data": "User ID: ${me.id}",
        },
      };

      var res = await post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key = AAAAjlrpL2c:APA91bGcrdJOd6ff0A7MJyrpicpJ9dCts5mlNlF0SHZKajfx-PH7U3nxeRsYhK_2Y_6Wgf8daOS9ArMnFRGakCXi1O-yfR2f0ELPuw-Z8IoisnTeSrsqJcSbXZjlGyYmsKTshEA9hVo8 '
        },
        body: jsonEncode(body),
      );
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotification: $e');
    }
  }

  //checking that user already exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection("users").doc(user.uid).get()).exists;
  }

  //adding a user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection("users")
        .where('email', isEqualTo: email)
        .get();

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exist

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      //user doesn't exist
      return false;
    }
  }

  //getting current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection("users").doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        APIs.updateToken();
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  //creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: 'Using YouMe is Fun !!',
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  //for getting id's of knows user from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUserId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  //for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    return firestore
        .collection('users')
        .where('id', whereIn: userIds)
        .snapshots();
  }

  //adding an user to chat list when first message is sent
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  //for updating userInformation
  static Future<void> updateUserInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': me.name, 'about': me.about});
  }

  // for updataing dp
  static Future<void> updateProfilePicture(File file) async {
    //getting image file extesion
    final ext = file.path.split('.').last;
    log('Extension: $ext');
    //storing file ref with path
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data transfered: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({
      'image': me.image,
    });
  }

  //for getting push token and updating token in firestore
  static Future<void> updateToken() async {
    firestore.collection('users').doc(user.uid).update({
      'push_token': me.pushToken,
    });
  }

  ///***********ChatScreen Realted APIs**************************/

  //this will privide unique UID for two users
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  //for accessing individual user messages from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // helps to send message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final Message message = Message(
        told: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        fromld: user.uid,
        sent: time);

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  //update blue tick
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromld)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last msg of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //Send images in chat
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    //getting image file extesion
    final ext = file.path.split('.').last;
    //storing file ref with path
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data transfered: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //delete Message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .delete();
    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }
}
