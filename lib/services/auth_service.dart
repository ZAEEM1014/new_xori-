import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xori/services/cloudinary_service.dart';
import 'package:get/get.dart';
import 'package:xori/models/user_model.dart';
import 'package:xori/services/firestore_service.dart';

class AuthService {
  // Change password (requires re-authentication)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user is currently signed in.');
    }
    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(cred);
      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Use GetX to retrieve the singleton instance
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Signup: upload image, create user, save Firestore, send verification
  Future<(UserCredential?, String?)> signUpWithEmail({
    required String username,
    required String email,
    required String password,
    File? profileImage,
    required List<String> personalityTraits,
  }) async {
    try {
      print('[DEBUG] AuthService: Starting signUpWithEmail');
      String? profileImageUrl;
      if (profileImage != null) {
        print('[DEBUG] AuthService: Uploading profile image to Cloudinary');
        profileImageUrl =
            await _cloudinaryService.uploadProfileImage(email, profileImage);
        print('[DEBUG] AuthService: Profile image uploaded to Cloudinary: ' +
            (profileImageUrl ?? 'null'));
        if (profileImageUrl == null || profileImageUrl.isEmpty) {
          print('[DEBUG] AuthService: Cloudinary URL missing after upload');
          return (null, "Image upload failed. Please try again.");
        }
      } else {
        print('[DEBUG] AuthService: No profile image provided');
        return (null, "Profile image is required.");
      }
      if (personalityTraits.isEmpty || personalityTraits.length != 3) {
        print(
            '[DEBUG] AuthService: Invalid personality traits: $personalityTraits');
        return (null, "Please select exactly 3 personality traits.");
      }
      print('[DEBUG] AuthService: Creating user in FirebaseAuth');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[DEBUG] AuthService: User created in FirebaseAuth');
      final user = userCredential.user;
      if (user == null) {
        print('[DEBUG] AuthService: User is null after creation');
        return (null, "User creation failed.");
      }
      print('[DEBUG] AuthService: Saving user to Firestore');
      final userModel = UserModel(
        uid: user.uid,
        username: username,
        email: email,
        profileImageUrl: profileImageUrl,
        createdAt: DateTime.now(),
        bio: personalityTraits.join(' | '),
      );
      try {
        await _firestoreService.saveUser(userModel);
        print('[DEBUG] AuthService: User saved to Firestore successfully');

        // Verify the document was actually created
        final savedUser = await _firestoreService.getUser(user.uid);
        if (savedUser != null) {
          print(
              '[DEBUG] AuthService: Verified user document exists in Firestore');
          print(
              '[DEBUG] AuthService: Saved user data: profileImageUrl=${savedUser.profileImageUrl}, bio=${savedUser.bio}');
        } else {
          print(
              '[DEBUG] AuthService: WARNING - User document not found after save');
          return (null, "User data was not saved properly to database");
        }
      } catch (firestoreError) {
        print('[DEBUG] AuthService: Firestore save failed: $firestoreError');
        return (null, "Failed to save user data: $firestoreError");
      }
      // Send email verification
      try {
        print('[DEBUG] AuthService: Sending email verification');
        await user.sendEmailVerification();
        print('[DEBUG] AuthService: Email verification sent successfully');
      } catch (verificationError) {
        print(
            '[DEBUG] AuthService: Email verification failed: $verificationError');
        // Don't fail signup if verification email fails to send
      }

      return (userCredential, null);
    } catch (e, st) {
      print('[DEBUG] AuthService: Exception: ' + e.toString());
      print(st);
      return (null, e.toString());
    }
  }

  // Login: only allow verified users
  Future<(UserCredential?, String?)> signInWithEmail(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        return (null, "Login failed. Please try again.");
      }
      // Check email verification
      if (!user.emailVerified) {
        return (
          null,
          "Please verify your email before logging in. Check your inbox for a verification email."
        );
      }

      return (userCredential, null);
    } catch (e) {
      return (null, e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<String?> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null; // Success
      } else if (user?.emailVerified == true) {
        return "Email is already verified.";
      } else {
        return "No user found. Please sign up first.";
      }
    } catch (e) {
      return _handleAuthException(e).toString();
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        final actionCodeSettings = ActionCodeSettings(
          url: 'https://xori-63f3f.firebaseapp.com', // Change to your app's URL
          handleCodeInApp: true,
          androidPackageName: 'com.example.xori',
          androidInstallApp: true,
          androidMinimumVersion: '21',
          iOSBundleId: 'com.example.xori',
        );
        await user.sendEmailVerification(actionCodeSettings);
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if email exists (removed: not supported in latest firebase_auth)

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return Exception(
              'Looks like you already have an account! Please sign in instead.');
        case 'invalid-email':
          return Exception('Please check your email format and try again.');
        case 'operation-not-allowed':
          return Exception(
              'Something\'s not right on our end. Please contact support.');
        case 'weak-password':
          return Exception(
              'Your password should be at least 6 characters with numbers and letters.');
        case 'user-disabled':
          return Exception(
              'Your account is currently paused. Please contact support for help.');
        case 'user-not-found':
          return Exception(
              'We couldn\'t find your account. Would you like to create one?');
        case 'wrong-password':
          return Exception(
              'Hmm, that password doesn\'t match our records. Want to try again?');
        case 'too-many-requests':
          return Exception(
              'Taking a short break for security. Please try again in a few minutes.');
        case 'network-request-failed':
          return Exception(
              'Having trouble connecting. Please check your internet connection.');
        case 'invalid-verification-code':
          return Exception(
              'The verification code seems incorrect. Please try again.');
        case 'invalid-verification-id':
          return Exception(
              'Your verification session expired. Please request a new code.');
        case 'quota-exceeded':
          return Exception(
              'We\'re a bit busy right now. Please try again in a few minutes.');
        default:
          return Exception('Something went wrong. Please try again.');
      }
    }
    return Exception('Oops! Something unexpected happened. Please try again.');
  }
}
