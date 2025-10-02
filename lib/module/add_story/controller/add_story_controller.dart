import 'dart:io';
import 'package:get/get.dart';

class AddStoryController extends GetxController {
  var selectedImage = Rx<File?>(null);

  // Mock function: later you can replace with image picker
  void pickImage(File image) {
    selectedImage.value = image;
  }

  void clearImage() {
    selectedImage.value = null;
  }
}
