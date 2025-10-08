import 'package:get/get.dart';

class SessionControlController extends GetxController {
  // final AuthService _authService = Get.find<AuthService>();
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = false.obs;
  final RxList<SessionDevice> sessions = <SessionDevice>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSessions();
  }

  void _loadSessions() {
    // Mock session data - In a real app, you'd fetch this from your backend
    sessions.value = [
      SessionDevice(
        deviceName: 'iPhone 14 Pro',
        location: 'San Francisco, CA',
        status: 'Currently Active',
        isActive: true,
        lastActive: DateTime.now(),
      ),
      SessionDevice(
        deviceName: 'MacBook Pro',
        location: 'San Francisco, CA',
        status: 'Last Active',
        isActive: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SessionDevice(
        deviceName: 'iPad Pro',
        location: 'San Francisco, CA',
        status: 'Last Active',
        isActive: false,
        lastActive: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> logOutDevice(SessionDevice device) async {
    try {
      isLoading.value = true;

      // In a real app, you would call your backend API to invalidate the session
      // For now, we'll just remove it from the local list
      sessions.remove(device);

      Get.snackbar(
        'Success',
        'Device logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log out device: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logOutAllDevices() async {
    try {
      isLoading.value = true;

      // In a real app, you would call your backend API to invalidate all sessions
      // For now, we'll clear the list except for the current device
      sessions.removeWhere((device) => !device.isActive);

      Get.snackbar(
        'Success',
        'All other devices logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log out all devices: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class SessionDevice {
  final String deviceName;
  final String location;
  final String status;
  final bool isActive;
  final DateTime lastActive;

  SessionDevice({
    required this.deviceName,
    required this.location,
    required this.status,
    required this.isActive,
    required this.lastActive,
  });
}
