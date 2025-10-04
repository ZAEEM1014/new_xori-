import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String storyId;
  final String userId;
  final String username;
  final String userProfileImage;
  final String storyUrl;
  final DateTime postedAt;
  final DateTime expiresAt;
  final List<String> viewedBy;

  StoryModel({
    required this.storyId,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.storyUrl,
    required this.postedAt,
    required this.expiresAt,
    required this.viewedBy,
  });

  factory StoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return StoryModel(
      storyId: docId,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userProfileImage: map['userProfileImage'] ?? '',
      storyUrl: map['storyUrl'] ?? '',
      postedAt: (map['postedAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'storyUrl': storyUrl,
      'postedAt': Timestamp.fromDate(postedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
    };
  }
}
