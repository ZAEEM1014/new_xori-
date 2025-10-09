import '../../../services/reel_service.dart';
import '../../../models/reel_model.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/post_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/post_model.dart';

class AddPostController extends GetxController {
  // Observables
  final selectedTab = 0.obs; // 0 = Post, 1 = Reel
  final selectedImage = Rx<File?>(null);
  final isLoading = false.obs;
  final isUploading = false.obs;
  final taggedUsers = <String>[].obs; // List of tagged user IDs

  // Text controllers
  final captionController = TextEditingController();
  final hashtagsController = TextEditingController();

  // Hashtag management
  final RxList<String> parsedHashtags = <String>[].obs;
  final RxList<String> suggestedHashtags = <String>[].obs;

  // Services
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final PostService _postService = PostService();
  final ReelService _reelService = ReelService();
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    // Listen to hashtag input changes
    hashtagsController.addListener(_onHashtagChanged);
    _loadTrendingHashtags();
  }

  @override
  void onClose() {
    captionController.dispose();
    hashtagsController.dispose();
    super.onClose();
  }

  void _onHashtagChanged() {
    final text = hashtagsController.text;
    parsedHashtags.value = _parseHashtags(text);

    // Get hashtag suggestions based on input
    if (text.isNotEmpty) {
      _getHashtagSuggestions(text);
    } else {
      suggestedHashtags.clear();
    }
  }

  Future<void> _loadTrendingHashtags() async {
    try {
      // Get trending hashtags from posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final hashtagCount = <String, int>{};

      for (final doc in postsSnapshot.docs) {
        try {
          final data = doc.data();
          final hashtags = (data['hashtags'] as List?)?.cast<String>() ?? [];

          for (final hashtag in hashtags) {
            hashtagCount[hashtag] = (hashtagCount[hashtag] ?? 0) + 1;
          }
        } catch (e) {
          print('Error processing hashtag from post: $e');
        }
      }

      // Sort hashtags by count and get trending ones
      final sortedHashtags = hashtagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      suggestedHashtags.value =
          sortedHashtags.take(10).map((entry) => entry.key).toList();
    } catch (e) {
      print('Error loading trending hashtags: $e');
    }
  }

  Future<void> _getHashtagSuggestions(String input) async {
    try {
      final lastWord = input.split(' ').last.toLowerCase();
      if (!lastWord.startsWith('#')) return;

      final searchTerm = lastWord.substring(1); // Remove #
      if (searchTerm.isEmpty) return;

      // Search for similar hashtags in existing posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final matchingHashtags = <String>{};

      for (final doc in postsSnapshot.docs) {
        try {
          final data = doc.data();
          final hashtags = (data['hashtags'] as List?)?.cast<String>() ?? [];

          for (final hashtag in hashtags) {
            if (hashtag.toLowerCase().contains(searchTerm)) {
              matchingHashtags.add(hashtag);
              if (matchingHashtags.length >= 5) break;
            }
          }
          if (matchingHashtags.length >= 5) break;
        } catch (e) {
          print('Error processing hashtag suggestion: $e');
        }
      }

      suggestedHashtags.value = matchingHashtags.toList();
    } catch (e) {
      print('Error getting hashtag suggestions: $e');
    }
  }

  // Switch between Post and Reel tabs
  void switchTab(int index) {
    selectedTab.value = index;
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      isLoading.value = true;

      if (selectedTab.value == 1) {
        // For reels, pick video
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 1),
        );

        if (video != null) {
          selectedImage.value = File(video.path);
          Get.snackbar(
            'Success',
            'Video selected successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // For posts, pick image
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );

        if (image != null) {
          selectedImage.value = File(image.path);
          Get.snackbar(
            'Success',
            'Image selected successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick media from gallery: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      isLoading.value = true;

      if (selectedTab.value == 1) {
        // For reels, pick video
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 1),
        );

        if (video != null) {
          selectedImage.value = File(video.path);
          Get.snackbar(
            'Success',
            'Video captured successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // For posts, pick image
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );

        if (image != null) {
          selectedImage.value = File(image.path);
          Get.snackbar(
            'Success',
            'Photo captured successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to capture media: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Remove selected image
  void removeSelectedImage() {
    selectedImage.value = null;
  }

  // Validate post data
  bool _validatePost() {
    if (selectedImage.value == null) {
      Get.snackbar(
        'Validation Error',
        selectedTab.value == 0
            ? 'Please select an image'
            : 'Please select a video',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    if (captionController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please add a caption',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    return true;
  }

  // Create post
  Future<void> createPost() async {
    if (!_validatePost()) return;

    try {
      isUploading.value = true;

      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from Firestore for username and profile image
      final userData = await _firestoreService.getUser(currentUser.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Upload media to Cloudinary
      String? mediaUrl;
      if (selectedTab.value == 1) {
        // For reels (videos)
        mediaUrl = await _cloudinaryService.uploadVideo(selectedImage.value!);
      } else {
        // For posts (images)
        mediaUrl = await _cloudinaryService.uploadImage(selectedImage.value!);
      }

      if (mediaUrl == null) {
        throw Exception('Failed to upload media');
      }

      if (selectedTab.value == 1) {
        // Create Reel object
        final reel = Reel(
          id: '',
          userId: currentUser.uid,
          username: userData.username,
          userPhotoUrl: userData.profileImageUrl ?? '',
          videoUrl: mediaUrl,
          caption: captionController.text.trim(),
          likes: [],
          commentCount: 0,
          shareCount: 0,
          createdAt: Timestamp.now(),
          isDeleted: false,
        );
        final reelId = await _reelService.uploadReel(reel);
        Get.snackbar(
          'Success',
          'Reel created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        print('[DEBUG] Reel created with ID: $reelId');
      } else {
        // Create Post object
        final post = Post(
          id: '',
          userId: currentUser.uid,
          username: userData.username,
          userPhotoUrl: userData.profileImageUrl ?? '',
          caption: captionController.text.trim(),
          hashtags: _parseHashtags(hashtagsController.text.trim()),
          mediaUrls: [mediaUrl],
          mediaType: 'image',
          createdAt: Timestamp.now(),
          likes: [],
          commentCount: 0,
          shareCount: 0,
          location: null,
          mentions: null,
          isDeleted: false,
          taggedUsers: taggedUsers.toList(),
        );
        final postId = await _postService.createPost(post);
        Get.snackbar(
          'Success',
          'Post created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        print('[DEBUG] Post created with ID: $postId');
      }

      // Clear form and navigate back
      _clearForm();
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        selectedTab.value == 1
            ? 'Failed to create reel: ${e.toString()}'
            : 'Failed to create post: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      print('[DEBUG] Error creating post/reel: $e');
    } finally {
      isUploading.value = false;
    }
  }

  // Parse hashtags from text
  List<String> _parseHashtags(String hashtagText) {
    if (hashtagText.isEmpty) return [];

    // Extract hashtags from text
    final words = hashtagText.split(RegExp(r'\s+'));
    final hashtags = <String>[];

    for (final word in words) {
      final trimmed = word.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        // Already has #, validate and clean
        final cleanTag = trimmed.replaceAll(RegExp(r'[^\w#]'), '');
        if (cleanTag.length > 1) hashtags.add(cleanTag.toLowerCase());
      } else {
        // Add # prefix and clean
        final cleanTag = '#${trimmed.replaceAll(RegExp(r'[^\w]'), '')}';
        if (cleanTag.length > 1) hashtags.add(cleanTag.toLowerCase());
      }
    }

    return hashtags.toSet().toList(); // Remove duplicates
  }

  // Add hashtag to input
  void addHashtag(String hashtag) {
    final currentText = hashtagsController.text;
    final hashtags = currentText.isEmpty ? [] : currentText.split(' ');

    if (!hashtags.contains(hashtag)) {
      hashtags.add(hashtag);
      hashtagsController.text = hashtags.join(' ');
    }
  }

  // Remove hashtag from input
  void removeHashtag(String hashtag) {
    final currentText = hashtagsController.text;
    final hashtags = currentText.split(' ');
    hashtags.remove(hashtag);
    hashtagsController.text = hashtags.where((tag) => tag.isNotEmpty).join(' ');
  }

  // Clear form data
  void _clearForm() {
    selectedImage.value = null;
    captionController.clear();
    hashtagsController.clear();
    parsedHashtags.clear();
    suggestedHashtags.clear();
    taggedUsers.clear(); // Clear tagged users
    selectedTab.value = 0;
  }

  // Cancel post creation
  void cancelPost() {
    _clearForm();
    Get.back();
  }

  // Add user to tagged users list
  void addTaggedUser(String userId) {
    if (!taggedUsers.contains(userId)) {
      taggedUsers.add(userId);
    }
  }

  // Remove user from tagged users list
  void removeTaggedUser(String userId) {
    taggedUsers.remove(userId);
  }

  // Clear all tagged users
  void clearTaggedUsers() {
    taggedUsers.clear();
  }

  // Check if user is tagged
  bool isUserTagged(String userId) {
    return taggedUsers.contains(userId);
  }
}
