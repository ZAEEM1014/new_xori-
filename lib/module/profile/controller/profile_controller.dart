import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  // User data from Firestore
  var user = UserModel.empty.obs;
  var name = "".obs;
  var bio = "".obs;
  var profileImageUrl = "".obs;
  var isLoading = true.obs;

  var posts = 100.obs;
  var followers = 1500.obs;
  var following = 100.obs;

  var activeTab = 0.obs; // 0 = Posts, 1 = Tagged

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user document from Firestore directly
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          name.value = data['username'] ?? '';
          profileImageUrl.value = data['profileImageUrl'] ?? '';

          // Use personalityTraits from Firestore as bio display
          final personalityTraits =
              List<String>.from(data['personalityTraits'] ?? []);
          bio.value = personalityTraits.join(' | '); // Join traits with pipes
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    activeTab.value = index;
  }
}
