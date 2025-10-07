import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/auth_service.dart';

class EditProfileController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final AuthService _authService = Get.find<AuthService>();

  // Controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final Rxn<File> profileImage = Rxn<File>();
  final RxString profileImageUrl = ''.obs;
  final RxList<String> selectedTraits = <String>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Personality traits
  final List<String> allTraits = [
    "Parent",
    "Foodie",
    "Traveler",
    "Artist",
    "Musician",
    "Sports Fan",
    "Bookworm",
    "Pet Lover",
    "Nature Enthusiast",
    "Tech Geek"
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void _loadUserData() async {
    try {
      isLoading.value = true;
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userData = await _firestoreService.getUser(currentUser.uid);
        if (userData != null) {
          usernameController.text = userData.username;
          emailController.text = userData.email;
          profileImageUrl.value = userData.profileImageUrl ?? '';
          
          // Load personality traits directly from user data
          if (userData.personalityTraits.isNotEmpty) {
            selectedTraits.value = userData.personalityTraits.where((trait) => allTraits.contains(trait)).toList();
          } else if (userData.bio.isNotEmpty) {
            // Fallback: parse bio to get personality traits for backward compatibility
            final traits = userData.bio.split(' | ');
            selectedTraits.value = traits.where((trait) => allTraits.contains(trait)).toList();
          }
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to load user data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTrait(String trait) {
    if (selectedTraits.contains(trait)) {
      selectedTraits.remove(trait);
    } else {
      if (selectedTraits.length >= 3) {
        errorMessage.value = "You can only select up to 3 personality traits";
        return;
      }
      selectedTraits.add(trait);
    }
    _clearMessages();
  }

  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        profileImage.value = File(pickedFile.path);
        _clearMessages();
      }
    } catch (e) {
      errorMessage.value = 'Failed to pick image: $e';
    }
  }

  void removeProfileImage() {
    profileImage.value = null;
    profileImageUrl.value = '';
  }

  Future<void> updateProfile() async {
    if (isUpdating.value) return;

    _clearMessages();

    // Validate form
    if (usernameController.text.trim().isEmpty) {
      errorMessage.value = 'Username is required';
      return;
    }

    if (selectedTraits.length != 3) {
      errorMessage.value = 'Please select exactly 3 personality traits';
      return;
    }

    try {
      isUpdating.value = true;
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      String? updatedImageUrl = profileImageUrl.value;

      // Upload new image if selected
      if (profileImage.value != null) {
        updatedImageUrl = await _cloudinaryService.uploadProfileImage(
          emailController.text.trim(),
          profileImage.value!,
        );
        if (updatedImageUrl == null) {
          errorMessage.value = 'Failed to upload image';
          return;
        }
      }

      // Get original user data to preserve creation date
      final originalUser = await _firestoreService.getUser(currentUser.uid);
      
      // Create updated user model
      final updatedUser = UserModel(
        uid: currentUser.uid,
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        profileImageUrl: updatedImageUrl,
        createdAt: originalUser?.createdAt ?? DateTime.now(),
        bio: selectedTraits.join(' | '),
        personalityTraits: selectedTraits.toList(),
      );

      // Update in Firestore
      await _firestoreService.saveUser(updatedUser);

      successMessage.value = 'Profile updated successfully!';
      
      // Clear the selected image since it's now uploaded
      profileImage.value = null;
      profileImageUrl.value = updatedImageUrl;

      // Go back after a delay
      Future.delayed(const Duration(seconds: 2), () {
        Get.back();
      });

    } catch (e) {
      errorMessage.value = 'Failed to update profile: $e';
    } finally {
      isUpdating.value = false;
    }
  }

  void _clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  bool get hasError => errorMessage.value.isNotEmpty;
  bool get hasSuccess => successMessage.value.isNotEmpty;
}
