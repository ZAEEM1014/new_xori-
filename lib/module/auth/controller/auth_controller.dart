import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xori/models/user_model.dart';
import 'package:xori/services/auth_service.dart';
import 'package:xori/services/firestore_service.dart';

class AuthController extends GetxController {
  // Services
  late final AuthService _authService;
  late final FirestoreService _firestoreService;

  // Observable state
  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Personality traits
  final RxList<String> selectedTraits = <String>[].obs;
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

  // Form fields - Sign Up
  final RxBool isSignUpPasswordVisible = false.obs;
  final RxBool isSignUpConfirmPasswordVisible = false.obs;
  final Rxn<File> profileImage = Rxn<File>();
  final RxString signUpUsername = ''.obs;
  final RxString signUpEmail = ''.obs;
  final RxString signUpPassword = ''.obs;
  final RxString signUpConfirmPassword = ''.obs;

  // Form fields - Sign In
  final RxBool isLoginPasswordVisible = false.obs;
  final RxString loginEmail = ''.obs;
  final RxString loginPassword = ''.obs;

  // Validation errors
  final RxString usernameError = ''.obs;
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxString loginEmailError = ''.obs;
  final RxString loginPasswordError = ''.obs;

  // Validation states
  final RxBool isSignUpFormValid = false.obs;
  final RxBool isLoginFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _setupAuthStateListener();
    _setupFormValidation();
  }

  void _initializeServices() {
    try {
      _authService = Get.find<AuthService>();
      _firestoreService = Get.find<FirestoreService>();
    } catch (e) {
      _setError('Services not initialized properly');
    }
  }

  void _setupAuthStateListener() {
    // Listen to Firebase Auth state changes
    ever(firebaseUser, _handleAuthStateChange);
    firebaseUser.bindStream(_authService.authStateChanges);
  }

  void _setupFormValidation() {
    // Remove real-time validation - only validate on button click
    // Basic form completeness check without showing errors
    ever(signUpUsername, (_) => _checkFormCompleteness());
    ever(signUpEmail, (_) => _checkFormCompleteness());
    ever(signUpPassword, (_) => _checkFormCompleteness());
    ever(signUpConfirmPassword, (_) => _checkFormCompleteness());
    ever(selectedTraits, (_) => _checkFormCompleteness());
    ever(profileImage, (_) => _checkFormCompleteness());

    // Login form completeness check
    ever(loginEmail, (_) => _checkLoginFormCompleteness());
    ever(loginPassword, (_) => _checkLoginFormCompleteness());
  }

  void _validateSignUpForm() {
    // Don't clear errors - we want to show them when validation is triggered
    bool isValid = true;

    // Username validation
    if (signUpUsername.value.trim().isEmpty) {
      usernameError.value = 'Username is required';
      isValid = false;
    } else if (signUpUsername.value.trim().length < 3) {
      usernameError.value = 'Username must be at least 3 characters';
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$')
        .hasMatch(signUpUsername.value.trim())) {
      usernameError.value =
          'Username can only contain letters, numbers, and underscores';
      isValid = false;
    }

    // Email validation
    if (signUpEmail.value.trim().isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(signUpEmail.value.trim())) {
      emailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    // Password validation
    if (signUpPassword.value.isEmpty) {
      passwordError.value = 'Password is required';
      isValid = false;
    } else if (signUpPassword.value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    } else if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)')
        .hasMatch(signUpPassword.value)) {
      passwordError.value =
          'Password must contain at least one letter and one number';
      isValid = false;
    }

    // Confirm password validation
    if (signUpConfirmPassword.value.isEmpty) {
      confirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    } else if (signUpPassword.value != signUpConfirmPassword.value) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    // Additional validations
    if (selectedTraits.length != 3) {
      isValid = false;
    }

    if (profileImage.value == null) {
      isValid = false;
    }

    isSignUpFormValid.value = isValid;
  }

  void _validateLoginForm() {
    // Don't clear errors - we want to show them when validation is triggered
    bool isValid = true;

    // Email validation
    if (loginEmail.value.trim().isEmpty) {
      loginEmailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(loginEmail.value.trim())) {
      loginEmailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    // Password validation
    if (loginPassword.value.isEmpty) {
      loginPasswordError.value = 'Password is required';
      isValid = false;
    }

    isLoginFormValid.value = isValid;
  }

  void _clearValidationErrors() {
    usernameError.value = '';
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
  }

  // Check form completeness without showing validation errors
  void _checkFormCompleteness() {
    isSignUpFormValid.value = signUpUsername.value.trim().isNotEmpty &&
        signUpEmail.value.trim().isNotEmpty &&
        signUpPassword.value.isNotEmpty &&
        signUpConfirmPassword.value.isNotEmpty &&
        selectedTraits.length == 3 &&
        profileImage.value != null;
  }

  void _checkLoginFormCompleteness() {
    isLoginFormValid.value =
        loginEmail.value.trim().isNotEmpty && loginPassword.value.isNotEmpty;
  }

  // Check if signup form is valid after validation (used on button click)
  bool _isSignUpFormValidOnSubmit() {
    return usernameError.value.isEmpty &&
        emailError.value.isEmpty &&
        passwordError.value.isEmpty &&
        confirmPasswordError.value.isEmpty &&
        selectedTraits.length == 3 &&
        profileImage.value != null;
  }

  // Check if login form is valid after validation (used on button click)
  bool _isLoginFormValidOnSubmit() {
    return loginEmailError.value.isEmpty && loginPasswordError.value.isEmpty;
  }

  // Handle authentication state changes
  void _handleAuthStateChange(User? user) async {
    if (user == null) {
      this.user.value = null;
      return;
    }

    try {
      await _loadUserData(user.uid);
    } catch (e) {
      _setError('Error checking authentication: ${e.toString()}');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _firestoreService.getUser(uid);
      if (userData != null) {
        user.value = userData;
      } else {
        _setError('User data not found');
      }
    } catch (e) {
      _setError('Error loading user data: ${e.toString()}');
    }
  }

  // UI Control Methods
  void toggleSignUpPasswordVisibility() => isSignUpPasswordVisible.toggle();
  void toggleSignUpConfirmPasswordVisibility() =>
      isSignUpConfirmPasswordVisible.toggle();
  void toggleLoginPasswordVisibility() => isLoginPasswordVisible.toggle();

  void updateSignUpUsername(String value) {
    signUpUsername.value = value;
    // Clear validation errors when user starts typing
    usernameError.value = '';
  }

  void updateSignUpEmail(String value) {
    signUpEmail.value = value;
    // Clear validation errors when user starts typing
    emailError.value = '';
  }

  void updateSignUpPassword(String value) {
    signUpPassword.value = value;
    // Clear validation errors when user starts typing
    passwordError.value = '';
  }

  void updateSignUpConfirmPassword(String value) {
    signUpConfirmPassword.value = value;
    // Clear validation errors when user starts typing
    confirmPasswordError.value = '';
  }

  void updateLoginEmail(String value) {
    loginEmail.value = value;
    // Clear validation errors when user starts typing
    loginEmailError.value = '';
  }

  void updateLoginPassword(String value) {
    loginPassword.value = value;
    // Clear validation errors when user starts typing
    loginPasswordError.value = '';
  }

  // Personality traits management
  void toggleTrait(String trait) {
    try {
      if (selectedTraits.contains(trait)) {
        selectedTraits.remove(trait);
      } else {
        if (selectedTraits.length >= 3) {
          _setError("You can only select up to 3 personality traits");
          return;
        }
        selectedTraits.add(trait);
      }
      _clearMessages();
    } catch (e) {
      _setError('Error selecting trait: ${e.toString()}');
    }
  }

  // Image picker methods
  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
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
      _setError('Failed to pick image: ${e.toString()}');
    }
  }

  void removeProfileImage() {
    profileImage.value = null;
  }

  // Authentication methods
  Future<void> signUp() async {
    if (isLoading.value) return;

    // Clear previous messages
    _clearMessages();

    // Validate form only when button is clicked
    _validateSignUpForm();

    if (!_isSignUpFormValidOnSubmit()) {
      _setError('Please correct all errors and fill all required fields');
      return;
    }

    // Additional validations
    if (selectedTraits.length != 3) {
      _setError('Please select exactly 3 personality traits');
      return;
    }

    if (profileImage.value == null) {
      _setError('Please select a profile image');
      return;
    }

    isLoading.value = true;
    _clearMessages();

    try {
      // Check if username already exists
      final usernameExists =
          await _firestoreService.usernameExists(signUpUsername.value.trim());
      if (usernameExists) {
        _setError('Username already taken. Please choose another one.');
        return;
      }

      final (credential, error) = await _authService.signUpWithEmail(
        username: signUpUsername.value.trim(),
        email: signUpEmail.value.trim(),
        password: signUpPassword.value,
        profileImage: profileImage.value!,
        personalityTraits: selectedTraits.toList(),
      );

      if (credential != null && error == null) {
        _setSuccess('Account created successfully!');
        _clearSignUpForm();

        // Show email verification dialog
        await _showEmailVerificationDialog();

        Get.offAllNamed('/login');
      } else {
        _setError(error ?? 'Sign up failed. Please try again.');
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        _setError(_getFirebaseAuthErrorMessage(e));
      } else {
        _setError('Sign up error: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn() async {
    if (isLoading.value) return;

    // Clear previous messages
    _clearMessages();

    // Validate form only when button is clicked
    _validateLoginForm();

    if (!_isLoginFormValidOnSubmit()) {
      _setError('Please correct all errors in the form');
      return;
    }

    isLoading.value = true;
    _clearMessages();

    try {
      final (credential, error) = await _authService.signInWithEmail(
        loginEmail.value.trim(),
        loginPassword.value,
      );

      if (credential != null && error == null) {
        _setSuccess('Login successful! Welcome back.');
        _clearLoginForm();
        // Navigate to navwrapper on successful login
        Get.offAllNamed('/navwrapper');
      } else {
        _setError(error ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        _setError(_getFirebaseAuthErrorMessage(e));
      } else {
        _setError('Login error: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    if (isLoading.value) return;

    isLoading.value = true;
    _clearMessages();

    try {
      await _authService.signOut();
      user.value = null;
      _clearAllForms();
      _setSuccess('Signed out successfully');
    } catch (e) {
      _setError('Sign out error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (isLoading.value) return;

    if (email.trim().isEmpty) {
      _setError('Please enter your email address');
      return;
    }

    if (!GetUtils.isEmail(email.trim())) {
      _setError('Please enter a valid email address');
      return;
    }

    isLoading.value = true;
    _clearMessages();

    try {
      await _authService.sendPasswordResetEmail(email.trim());
      _setSuccess('Password reset email sent. Please check your inbox.');
    } catch (e) {
      if (e is FirebaseAuthException) {
        _setError(_getFirebaseAuthErrorMessage(e));
      } else {
        _setError('Error sending password reset email: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    if (isLoading.value) return;

    isLoading.value = true;
    _clearMessages();

    try {
      await _authService.resendVerificationEmail();
      _setSuccess('Verification email sent. Please check your inbox.');
    } catch (e) {
      _setError('Error sending verification email: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkEmailVerificationStatus() async {
    try {
      return await _authService.checkEmailVerified();
    } catch (e) {
      _setError('Error checking email verification: ${e.toString()}');
      return false;
    }
  }

  // Helper methods
  void _setError(String message) {
    errorMessage.value = message;
    successMessage.value = '';
  }

  void _setSuccess(String message) {
    successMessage.value = message;
    errorMessage.value = '';
  }

  void _clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  void _clearSignUpForm() {
    signUpUsername.value = '';
    signUpEmail.value = '';
    signUpPassword.value = '';
    signUpConfirmPassword.value = '';
    profileImage.value = null;
    selectedTraits.clear();
  }

  void _clearLoginForm() {
    loginEmail.value = '';
    loginPassword.value = '';
  }

  void _clearAllForms() {
    _clearSignUpForm();
    _clearLoginForm();
    _clearValidationErrors();
    loginEmailError.value = '';
    loginPasswordError.value = '';
  }

  // Show email verification dialog
  Future<void> _showEmailVerificationDialog() async {
    return Get.dialog(
      AlertDialog(
        title: const Text('Email Verification'),
        content: const Text(
          'A verification email has been sent to your email address. Please verify your email before logging in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  // Getters for UI
  bool get hasError => errorMessage.value.isNotEmpty;
  bool get hasSuccess => successMessage.value.isNotEmpty;
  bool get isSignedIn => firebaseUser.value != null;
  bool get isEmailVerified => firebaseUser.value?.emailVerified ?? false;
  String get currentUserEmail => firebaseUser.value?.email ?? '';
  String get currentUsername => user.value?.username ?? '';
  String? get currentUserProfileImage => user.value?.profileImageUrl;
  String get currentUserBio => user.value?.bio ?? '';

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
