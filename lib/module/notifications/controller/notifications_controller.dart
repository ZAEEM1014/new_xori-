import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/notification_model.dart';
import '../../../models/follow_user_model.dart';
import '../../../services/notification_service.dart';
import '../../../services/follow_service.dart';
import '../../../routes/app_routes.dart';
import '../../../data/sample_notifications.dart';

class NotificationsController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  final FollowService _followService = FollowService();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt unreadCount = 0.obs;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      _loadNotifications();
      _loadUnreadCount();
    }
  }

  void _loadNotifications() {
    if (currentUserId == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    // For testing, load sample notifications
    // In production, use the Firebase stream below
    _loadSampleNotifications();

    /*
    _notificationService.getNotificationsStream(currentUserId!).listen(
      (notificationsList) {
        notifications.value = notificationsList;
        isLoading.value = false;
      },
      onError: (error) {
        print('Error loading notifications: $error');
        errorMessage.value = 'Failed to load notifications';
        isLoading.value = false;
      },
    );
    */
  }

  void _loadSampleNotifications() {
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      notifications.value = SampleNotifications.getSampleNotifications();
      isLoading.value = false;

      // Set unread count
      final unreadNotifications = notifications.where((n) => !n.isRead).length;
      unreadCount.value = unreadNotifications;
    });
  }

  void _loadUnreadCount() {
    if (currentUserId == null) return;

    // For testing, this is handled in _loadSampleNotifications
    // In production, use the Firebase stream below

    /*
    _notificationService.getUnreadCount(currentUserId!).listen(
      (count) {
        unreadCount.value = count;
      },
      onError: (error) {
        print('Error loading unread count: $error');
      },
    );
    */
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifications.refresh();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      await _notificationService.markAllAsRead(currentUserId!);

      // Update local state
      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      notifications.refresh();

      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      Get.snackbar(
        'Error',
        'Failed to mark notifications as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      notifications.removeWhere((n) => n.id == notificationId);

      Get.snackbar(
        'Success',
        'Notification deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error deleting notification: $e');
      Get.snackbar(
        'Error',
        'Failed to delete notification',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> followUser(
      String userId, String username, String profileImageUrl) async {
    if (currentUserId == null) return;

    try {
      // Create a FollowUser object for the target user
      final targetUser = FollowUser(
        userId: userId,
        username: username,
        userPhotoUrl: profileImageUrl,
        followedAt: Timestamp.now(),
      );

      await _followService.toggleFollow(currentUserId!, targetUser);
      Get.snackbar(
        'Success',
        'User followed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error following user: $e');
      Get.snackbar(
        'Error',
        'Failed to follow user',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void handleNotificationTap(NotificationModel notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        // Navigate to post details or home
        Get.toNamed(AppRoutes.home);
        break;
      case NotificationType.follow:
        // Navigate to user profile
        Get.toNamed(
          AppRoutes.xoriUserProfile,
          parameters: {'uid': notification.senderUserId},
        );
        break;
      case NotificationType.message:
        // Navigate to chat
        if (notification.chatId != null) {
          Get.toNamed(
            AppRoutes.chat,
            arguments: {
              'chatId': notification.chatId,
              'otherUserId': notification.senderUserId,
              'otherUserName': notification.senderUsername,
            },
          );
        } else {
          Get.toNamed(AppRoutes.chatList);
        }
        break;
    }
  }

  Future<void> refreshNotifications() async {
    if (currentUserId != null) {
      _loadNotifications();
      _loadUnreadCount();
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
