import 'package:get/get.dart';

class XoriUserProfileController extends GetxController {
  // Example user data (can later come from API)
  var name = "Darwat Clare".obs;
  var bio = "Foodie | Traveler | Photographer".obs;

  var posts = 100.obs;
  var followers = 1500.obs;
  var following = 100.obs;

  var isFollowing = false.obs;
  var activeTab = 0.obs; // 0 = Posts, 1 = Tagged

  void toggleFollow() {
    isFollowing.value = !isFollowing.value;
    followers.value += isFollowing.value ? 1 : -1;
  }

  void changeTab(int index) {
    activeTab.value = index;
  }
}
