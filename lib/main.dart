import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:xori/module/add_story/controller/add_story_controller.dart';
import 'package:xori/module/auth/controller/auth_controller.dart';
import 'package:xori/module/home/controller/home_controller.dart';
import 'package:xori/module/profile/controller/profile_controller.dart';
import 'package:xori/services/auth_service.dart';
import 'package:xori/services/firestore_service.dart';
import 'package:xori/services/cloudinary_service.dart';
import 'package:xori/services/story_service.dart';
import 'package:xori/services/message_service.dart';
import 'package:xori/routes/app_pages.dart';
import 'package:xori/routes/app_routes.dart';
import 'package:xori/services/onboarding_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xori/module/auth/controller/change_password_controller.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDe41yhq4g2H07XoSbYRFpYee-eKnq5ONc",
        appId: "1:2904749167:android:2b12ccf73eed0bedab899a",
        messagingSenderId: "2904749167",
        projectId: "xori-63f3f",
        storageBucket: "xori-63f3f.firebasestorage.app",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error during initialization: $e');
    return;
  }

  // Initialize services in dependency order
  Get.put(CloudinaryService(), permanent: true);
  Get.put(FirestoreService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(StoryService(), permanent: true);

  // Initialize MessageService after its dependencies
  final messageService = MessageService();
  Get.put(messageService, permanent: true);

  // Initialize main controller
  Get.put(AuthController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  Get.put(AddStoryController(), permanent: true);
  Get.put(ChangePasswordController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService.hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Show splash or loading
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final bool seen = snapshot.data!;
        final user = FirebaseAuth.instance.currentUser;
        String initialRoute;
        if (!seen) {
          initialRoute = AppRoutes.onboarding;
        } else if (user != null) {
          initialRoute = AppRoutes.navwrapper;
        } else {
          initialRoute = AppRoutes.login;
        }
        return GetMaterialApp(
          title: 'Xori',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          defaultTransition: Transition.fade,
          initialRoute: initialRoute,
          getPages: AppPages.pages,
        );
      },
    );
  }
}
