import 'dart:io';
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
    // Sign up form validation
    ever(signUpUsername, (_) => _validateSignUpForm());
    ever(signUpEmail, (_) => _validateSignUpForm());
    ever(signUpPassword, (_) => _validateSignUpForm());
    ever(signUpConfirmPassword, (_) => _validateSignUpForm());
    ever(selectedTraits, (_) => _validateSignUpForm());
    ever(profileImage, (_) => _validateSignUpForm());

    // Login form validation
    ever(loginEmail, (_) => _validateLoginForm());
    ever(loginPassword, (_) => _validateLoginForm());
  }

  void _validateSignUpForm() {
    isSignUpFormValid.value = signUpUsername.value.trim().isNotEmpty &&
        GetUtils.isEmail(signUpEmail.value.trim()) &&
        signUpPassword.value.length >= 6 &&
        signUpPassword.value == signUpConfirmPassword.value &&
        selectedTraits.length == 3 &&
        profileImage.value != null;
  }

  void _validateLoginForm() {
    isLoginFormValid.value = GetUtils.isEmail(loginEmail.value.trim()) &&
        loginPassword.value.isNotEmpty;
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

  void updateSignUpUsername(String value) => signUpUsername.value = value;
  void updateSignUpEmail(String value) => signUpEmail.value = value;
  void updateSignUpPassword(String value) => signUpPassword.value = value;
  void updateSignUpConfirmPassword(String value) =>
      signUpConfirmPassword.value = value;
  void updateLoginEmail(String value) => loginEmail.value = value;
  void updateLoginPassword(String value) => loginPassword.value = value;

  // Personality traits management
  void toggleTrait(String trait) {
    if (selectedTraits.contains(trait)) {
      selectedTraits.remove(trait);
    } else {
      if (selectedTraits.length >= 3) {
        _setError("You can only select up to 3 traits");
        return;
      }
      selectedTraits.add(trait);
    }
    _clearMessages();
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

    if (!isSignUpFormValid.value) {
      _setError('Please fill all fields correctly');
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
        _setSuccess(
            'Account created successfully! Please check your email for verification.');
        _clearSignUpForm();
        // Show toast for 2 seconds, then navigate to login
        Get.showSnackbar(GetSnackBar(
          message:
              'Verify your email first, a verification email has been sent to your email address.',
          duration: const Duration(seconds: 2),
        ));
        await Future.delayed(const Duration(seconds: 2));
        Get.offAllNamed('/login');
      } else {
        _setError(error ?? 'Sign up failed. Please try again.');
      }
    } catch (e) {
      _setError('Sign up error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn() async {
    if (isLoading.value) return;

    if (!isLoginFormValid.value) {
      _setError('Please enter valid email and password');
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
