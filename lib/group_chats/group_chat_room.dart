import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';

import '../allConstants/color_constants.dart';
import '../allConstants/firestore_constants.dart';
import '../allConstants/size_constants.dart';
import '../allConstants/text_field_constants.dart';
import '../allWidgets/common_widgets.dart';
import '../providers/chat_provider.dart';
import 'group_info.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';

class GroupChatRoom extends StatefulWidget {
  final String groupChatId, groupName;

  GroupChatRoom({required this.groupName, required this.groupChatId, Key? key})
      : super(key: key);

  @override
  State<GroupChatRoom> createState() => _GroupChatRoomState();
}

class _GroupChatRoomState extends State<GroupChatRoom> {
  final TextEditingController _message = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? imageFile;
  late ChatProvider chatProvider;

  List<QueryDocumentSnapshot> listMessages = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  final ScrollController scrollController = ScrollController();
  late stt.SpeechToText _speech;
  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }
  String imageUrl = '';
  bool isLoading = false;

  void uploadImageFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadImageFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendImage(imageUrl);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }
  Future pickImage()
  async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    File image=File(pickedFile!.path);
    imageClassification(image);
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chatProvider = context.read<ChatProvider>();
    scrollController.addListener(_scrollListener);
    _speech = stt.SpeechToText();
    loadModel();

}
  Future loadModel()
  async {
    Tflite.close();
    String res;
    res=(await Tflite.loadModel(model: "assets/model.tflite",labels: "assets/labels.txt"))!;
    print("Models loading status: $res");
  }
  Future imageClassification(File image)
  async {
    final List? recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      print(recognitions);
      recognitions!.forEach((e)
      {
        _message.text =
            _message.text + '${e['label']}';
        _message.selection = TextSelection.fromPosition(TextPosition(offset: _message.text.length));

      });

    });
  }
  final FocusNode focusNode = FocusNode();
  bool _isListening = false;
  final TextEditingController textEditingController = TextEditingController();

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenFor: Duration(milliseconds: 60000),
          onResult: (val) => setState(() {
            _message.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendBy": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time":  DateTime.now().millisecondsSinceEpoch.toString(),
      };

      _message.clear();

      await _firestore
          .collection('groups')
          .doc(widget.groupChatId)
          .collection('chats')
          .add(chatData);
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void onSendImage(String url) async {

      Map<String, dynamic> chatData = {
        "sendBy": _auth.currentUser!.displayName,
        "message": url,
        "type": "img",
        "time":  DateTime.now().millisecondsSinceEpoch.toString(),
      };

      _message.clear();

      await _firestore
          .collection('groups')
          .doc(widget.groupChatId)
          .collection('chats')
          .add(chatData);
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  }
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
              onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupInfo(
                        groupName: widget.groupName,
                        groupId: widget.groupChatId,
                      ),
                    ),
                  ),
              icon: Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          buildListMessage(),
          buildMessageInput()
        ],
      ),
    );
  }


  Widget buildItem(int index, DocumentSnapshot? documentSnapshot) {
    Map<String, dynamic> chatMap =
    documentSnapshot?.data()   as Map<String, dynamic>;
    if (documentSnapshot != null) {
      if (chatMap['sendBy'] == _auth.currentUser!.displayName) {
        // right side (my message)

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                chatMap['type'] == "text"
                    ? messageBubble(
                  chatContent: chatMap['message'],

                  color: AppColors.spaceLight,
                  textColor: AppColors.white,
                  margin:  EdgeInsets.only(right: Sizes.dimen_10),
                )
                    : chatMap['type'] == "img"
                    ? Container(
                  margin: const EdgeInsets.only(
                      right: Sizes.dimen_10, top: Sizes.dimen_10),
                  child: chatImage(
                          imageSrc: chatMap['message'], onTap: () {}
                          ),

                )
                    : const SizedBox.shrink(),
                isMessageSent(index)
                    ? Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Sizes.dimen_20),
                  ),
                  child:
                      Icon(
                        Icons.account_circle,
                        size: 35,
                        color: AppColors.greyColor,
                      )
    )

                    : Container(
                  width: 35,
                ),
              ],
            ),
            isMessageSent(index)
                ? Container(
              margin: const EdgeInsets.only(
                  right: Sizes.dimen_50,
                  top: Sizes.dimen_6,
                  bottom: Sizes.dimen_8),
              child: Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(
                    int.parse(chatMap['time']),
                  ),
                ),
                style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: Sizes.dimen_12,
                    fontStyle: FontStyle.italic),
              ),
            )
                : const SizedBox.shrink(),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                isMessageReceived(index)
                // left side (received message)
                    ? Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Sizes.dimen_20),
                  ),
                  child: Icon(
                        Icons.account_circle,
                        size: 35,
                        color: AppColors.greyColor,
                      )
                ): Container(
                  width: 35,
                ),
                chatMap['type'] == "text"
                    ? messageBubble(
                  color: AppColors.burgundy,
                  textColor: AppColors.white,
                  chatContent: chatMap['message'],
                  margin: const EdgeInsets.only(left: Sizes.dimen_10),
                )
                    : chatMap['type'] == "img"

                    ? Container(
                  margin: const EdgeInsets.only(
                      left: Sizes.dimen_10, top: Sizes.dimen_10),
                  child: chatImage(
                      imageSrc: chatMap['message'], onTap: () {}
                  ),
                )
                    : const SizedBox.shrink(),
              ],
            ),
            isMessageReceived(index)
                ? Container(
              margin: const EdgeInsets.only(
                  left: Sizes.dimen_50,
                  top: Sizes.dimen_6,
                  bottom: Sizes.dimen_8),
              child: Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(
                    int.parse(chatMap['time']),
                  ),
                ),
                style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: Sizes.dimen_12,
                    fontStyle: FontStyle.italic),
              ),
            )
                : const SizedBox.shrink(),
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  bool isMessageSent(int index) {

    if ((index > 0 &&
        listMessages[index - 1].get(FirestoreConstants.sendBy) !=
            _auth.currentUser?.displayName) ||
        index == 0) {
      print('sent');
      return true;
    } else {
      return false;
    }
  }

  bool isMessageReceived(int index) {

    if ((index > 0 &&
        listMessages[index - 1].get(FirestoreConstants.sendBy) ==
            _auth.currentUser?.displayName) ||
        index == 0) {
      print('recieved');

      return true;
    } else {
      return false;
    }
  }

  Widget buildListMessage() {
    return Flexible(
      child: widget.groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
          stream:  _firestore
              .collection('groups')
              .doc(widget.groupChatId)
              .collection('chats')
              .orderBy('time')
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              listMessages = snapshot.data!.docs;
              if (listMessages.isNotEmpty) {
                return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: snapshot.data?.docs.length,
                    reverse: false,

                    controller: scrollController,
                    itemBuilder: (context, index) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child: buildItem(index, snapshot.data?.docs[index]),
                        ));
              } else {
                return const Center(
                  child: Text('No messages...'),
                );
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.burgundy,
                ),
              );
            }
          })
          : const Center(
        child: CircularProgressIndicator(
          color: AppColors.burgundy,
        ),
      ),
    );
  }
  Widget buildMessageInput() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        children: [
          Wrap(
            direction: Axis.vertical,
            children: [
              Container(
                  margin:  EdgeInsets.only(right: Sizes.dimen_4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Sizes.dimen_30),
                  ),
                  child: InkWell(
                    onTap: pickImage,
                    child: CircleAvatar(
                      backgroundColor: Color(0xff0570f7),
                      child: Image.asset("assets/icon_model.png",fit: BoxFit.fill,),
                    ),
                  )
              ),
              Container(
                margin:  EdgeInsets.only(right: Sizes.dimen_4),
                decoration: BoxDecoration(
                  color: AppColors.burgundy,
                  borderRadius: BorderRadius.circular(Sizes.dimen_30),
                ),
                child: IconButton(
                  onPressed: getImage,
                  icon: const Icon(
                    Icons.camera_alt,
                    size: Sizes.dimen_28,
                  ),
                  color: AppColors.white,
                ),
              ),

            ],
          ),

          Tooltip(
            message: 'press again to stop',
            child: IconButton(
              onPressed: () {
                _listen();
              },
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_off_outlined,
                size: 25,
              ),
            ),
          ),
          Flexible(
              child: TextField(
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                controller: _message,
                decoration:  InputDecoration(
                    hintText: 'Write text ...',
                    fillColor: Colors.grey[400],
                    enabled: true,
                    filled: true
                ),
                onSubmitted: (value) {
                  onSendMessage();
                },
              )),
          Container(
            margin: const EdgeInsets.only(left: Sizes.dimen_4),
            decoration: BoxDecoration(
              color: AppColors.burgundy,
              borderRadius: BorderRadius.circular(Sizes.dimen_30),
            ),
            child: IconButton(
              onPressed: () {
                onSendMessage();
              },
              icon: const Icon(Icons.send_rounded),
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

}
