class UserModel {
  /// Returns a map with only uid and profileImageUrl
  Map<String, dynamic> toUidAndProfileImageMap() {
    return {
      'uid': uid,
      'profileImageUrl': profileImageUrl,
    };
  }

  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  final String bio;
  final List<String> personalityTraits;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.bio,
    this.personalityTraits = const [],
  });

  // Empty user model
  static UserModel empty = UserModel(
    uid: '',
    username: '',
    email: '',
    profileImageUrl: null,
    createdAt: DateTime.now(),
    bio: '',
    personalityTraits: [],
  );

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'bio': bio,
      'personalityTraits': personalityTraits,
    };
  }

  // Create model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      bio: json['bio'] ?? '',
      personalityTraits: List<String>.from(json['personalityTraits'] ?? []),
    );
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? profileImageUrl,
    DateTime? createdAt,
    String? bio,
    List<String>? personalityTraits,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      personalityTraits: personalityTraits ?? this.personalityTraits,
    );
  }
}
