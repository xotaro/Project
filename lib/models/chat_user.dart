import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../allConstants/firestore_constants.dart';

class ChatUser extends Equatable {
  final String id;
  final String photoUrl;
  final String displayName;
  final String aboutMe;
  final String status;


  const ChatUser(
      {required this.id,
      required this.photoUrl,
      required this.displayName,
      required this.aboutMe,
      required this.status});

  ChatUser copyWith({
    String? id,
    String? photoUrl,
    String? nickname,
    String? phoneNumber,
    String? email,
    String? statusf,
  }) =>
      ChatUser(
          id: id ?? this.id,
          photoUrl: photoUrl ?? this.photoUrl,
          displayName: nickname ?? displayName,
          aboutMe: email ?? aboutMe,
        status: statusf ?? status,
      );

  Map<String, dynamic> toJson() => {
        FirestoreConstants.displayName: displayName,
        FirestoreConstants.photoUrl: photoUrl,
        FirestoreConstants.aboutMe: aboutMe,
        FirestoreConstants.status: status,

  };
  factory ChatUser.fromDocument(DocumentSnapshot snapshot) {
    String photoUrl = "";
    String nickname = "";
    String aboutMe = "";
    String status = "";


    try {
      photoUrl = snapshot.get(FirestoreConstants.photoUrl);
      nickname = snapshot.get(FirestoreConstants.displayName);
      status = snapshot.get(FirestoreConstants.status);
      aboutMe = snapshot.get(FirestoreConstants.aboutMe);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return ChatUser(
        id: snapshot.id,
        photoUrl: photoUrl,
        displayName: nickname,
        aboutMe: aboutMe,
      status: status);
  }
  @override
  // TODO: implement props
  List<Object?> get props => [id, photoUrl, displayName, aboutMe,status];
}
