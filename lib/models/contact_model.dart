import 'package:cloud_firestore/cloud_firestore.dart';

/// A simple but complete contact model for Firestore
class ContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? profileImageUrl;
  final Timestamp createdAt;
  final bool isBlocked;
  final String? lastMessage;
  final Timestamp? lastMessageTime;

  ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.profileImageUrl,
    required this.createdAt,
    this.isBlocked = false,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map, String docId) {
    return ContactModel(
      id: docId,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isBlocked: map['isBlocked'] ?? false,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'isBlocked': isBlocked,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
    };
  }
}
