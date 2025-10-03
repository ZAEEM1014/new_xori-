import 'package:get/get.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class XoriUserProfileController extends GetxController {
  final String uid;
  final FirestoreService _firestoreService = FirestoreService();

  // Observables
  var user = UserModel.empty.obs;
  var isLoading = true.obs;
  var isFollowing = false.obs;
  var activeTab = 0.obs; // 0 = Posts, 1 = Tagged

  XoriUserProfileController(this.uid);

  @override
  void onInit() {
    super.onInit();
    _listenToUser();
  }

  void _listenToUser() {
    try {
      _firestoreService.streamUserByUid(uid).listen(
        (userModel) {
          try {
            if (userModel != null) {
              user.value = userModel;
            }
            isLoading.value = false;
          } catch (e) {
            print(
                '[DEBUG] XoriUserProfileController: Error updating user data: $e');
            isLoading.value = false;
          }
        },
        onError: (error) {
          print(
              '[DEBUG] XoriUserProfileController: Error listening to user stream: $error');
          isLoading.value = false;
        },
      );
    } catch (e) {
      print(
          '[DEBUG] XoriUserProfileController: Error setting up user stream: $e');
      isLoading.value = false;
    }
  }

  void toggleFollow() {
    isFollowing.value = !isFollowing.value;
    // Optionally update followers count in Firestore
  }

  void changeTab(int index) {
    activeTab.value = index;
  }
}
