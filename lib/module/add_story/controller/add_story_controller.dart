import 'dart:io';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class AddStoryController extends GetxController {
  Rx<File?> selectedImage = Rx<File?>(null);
  Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  RxBool isCameraInitialized = false.obs;
  RxInt selectedCameraIndex = 0.obs;
  List<CameraDescription> cameras = [];

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        selectedCameraIndex.value = 0;
        await _startCamera(selectedCameraIndex.value);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _startCamera(int cameraIndex) async {
    final controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    cameraController.value = controller;
    isCameraInitialized.value = true;
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;
    selectedCameraIndex.value =
        (selectedCameraIndex.value + 1) % cameras.length;
    isCameraInitialized.value = false;
    await _startCamera(selectedCameraIndex.value);
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setSelectedImage(File(pickedFile.path));
    }
  }

  void setSelectedImage(File image) {
    selectedImage.value = image;
    cameraController.value?.dispose();
    cameraController.value = null;
    isCameraInitialized.value = false;
  }

  void clearImage() {
    selectedImage.value = null;
    _initCamera();
  }

  @override
  void onClose() {
    cameraController.value?.dispose();
    super.onClose();
  }
}
