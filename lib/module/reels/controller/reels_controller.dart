import 'package:get/get.dart';

class ReelController extends GetxController {
  /// --- Home Heart ---
  var isHomeLiked = false.obs;
  var homeLikeCount = 5000.obs;

  void toggleHomeLike() {
    if (isHomeLiked.value) {
      isHomeLiked.value = false;
      homeLikeCount.value--;
    } else {
      isHomeLiked.value = true;
      homeLikeCount.value++;
    }
  }

  /// --- Favourite Heart ---
  var isFavouriteLiked = false.obs;
  var favouriteLikeCount = 2000.obs;

  void toggleFavouriteLike() {
    if (isFavouriteLiked.value) {
      isFavouriteLiked.value = false;
      favouriteLikeCount.value--;
    } else {
      isFavouriteLiked.value = true;
      favouriteLikeCount.value++;
    }
  }
}
