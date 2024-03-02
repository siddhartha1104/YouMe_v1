import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youme/api/apis.dart';
import 'package:youme/helper/dialogs.dart';
import 'package:youme/main.dart';
import 'package:youme/models/chat_user.dart';
import 'package:youme/screens/profile_screen.dart';
import 'package:youme/widgets/chat_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ///for storing all users
  List<ChatUser> _list = [];

  //for storing searched iteams
  final List<ChatUser> _searchList = [];

  //for storing search status
  bool _isSerching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSerching) {
            setState(() {
              _isSerching = !_isSerching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(Icons.home),
            actions: [
              //User Search button
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSerching = !_isSerching;
                  });
                },
                icon: Icon(_isSerching
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search),
              ),

              // More settings button
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                                user: APIs.me,
                              )));
                },
                icon: const Icon(Icons.more_vert),
              )
            ],
            centerTitle: true,
            title: _isSerching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search by Name, Email..'),
                    autofocus: true,
                    style: const TextStyle(fontSize: 18, letterSpacing: .5),

                    //when searched then update search List
                    onChanged: (val) {
                      //search logic
                      _searchList.clear();

                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.name.toUpperCase().contains(val.toUpperCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toUpperCase().contains(val.toUpperCase())) {
                          _searchList.add(i);
                        }
                        setState(() {
                          _searchList;
                        });
                      }
                    },
                  )
                : Text(
                    'YouMe',
                    style: GoogleFonts.pacifico(),
                  ),
          ),

          //Floating button to add new user
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUserDialog();
              },
              child: const Icon(Icons.add_comment_rounded),
            ),
          ),
          body: StreamBuilder(
            stream: APIs.getMyUserId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

                //if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(
                              child: CircularProgressIndicator());

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;

                          _list = data
                                  ?.map((e) => ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                itemCount: _isSerching
                                    ? _searchList.length
                                    : _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ChatUserCard(
                                    user: _isSerching
                                        ? _searchList[index]
                                        : _list[index],
                                  );
                                  // return Text('Name: ${list[index]}');
                                });
                          } else {
                            return const Center(
                                child: Text(
                              'No Connections found!',
                              style: TextStyle(fontSize: 25),
                            ));
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  //for adding new user

  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add,
                    size: 28,
                  ),
                  Text('   Add User'),
                ],
              ),
              content: TextFormField(
                maxLines: null,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: 'email id',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('cancel'),
                ),
                //add user button
                MaterialButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (email.isNotEmpty) {
                      await APIs.addChatUser(email).then((value) {
                        if (!value) {
                          Dialogs.showSnachbar(context, 'No user Found!!');
                        }
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ));
  }
}
