import '../module/storyview/view/story_screen.dart';
import '../module/storyview/binding/story_binding.dart';
import 'package:xori/module/settings/binding/settings_binding.dart';
import 'package:xori/module/settings/view/settings_screen.dart';

import '../module/xori_userprofile/view/xori_userprofile_screen.dart';
import '../module/xori_userprofile/binding/xori_userprofile_binding.dart';
import 'package:get/get.dart';
import 'package:xori/module/chat/view/chat_screen.dart';
import 'package:xori/module/chat/binding/chat_binding.dart';
import 'package:xori/module/chat_list/binding/chat_list_binding.dart';
import 'package:xori/module/home/binding/home_binding.dart';
import 'package:xori/module/navbar_wrapper/binding/navwrapper_binding.dart';
import 'package:xori/module/navbar_wrapper/view/navwrapper_screen.dart';
import '../module/auth/view/login_view.dart';
import '../module/auth/view/signup_view.dart';
import '../module/auth/bindings/auth_binding.dart';
import '../module/auth/view/change_password_view.dart';
import '../module/auth/binding/change_password_binding.dart';
import 'app_routes.dart';
import '../module/onboarding/view/onboarding_view.dart';
import '../module/home/view/home_page.dart';
import '../module/chat_list/view/chat_list_screen.dart';
import '../module/add_story/view/add_story_screen.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView()),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.navwrapper,
      page: () => const NavbarWrapper(),
      binding: NavbarWrapperBinding(),
    ),
    GetPage(
      name: AppRoutes.chatList,
      page: () => ChatListScreen(),
      binding: ChatListBinding(),
    ),
    GetPage(name: AppRoutes.addStory, page: () => AddStoryScreen()),
    GetPage(
      name: AppRoutes.chat,
      page: () => ChatScreen(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.xoriUserProfile,
      page: () => const XoriUserProfileScreen(),
      binding: XoriUserProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: '/storyView',
      page: () => StoryViewScreen(),
      binding: StoryBinding(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
    ),
  ];
}
