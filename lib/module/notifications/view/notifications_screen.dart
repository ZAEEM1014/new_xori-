import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/gradient_button.dart';
import '../../../models/notification_model.dart';
import '../controller/notifications_controller.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Notifications',
        onBack: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showOptionsBottomSheet(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Retry',
                  onPressed: controller.refreshNotifications,
                  height: 48,
                  borderRadius: 12,
                ),
              ],
            ),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see notifications here when you have them.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationItem(notification);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () => controller.handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead ? Colors.white : const Color(0xFFF8F9FA),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image with notification icon overlay
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        notification.senderProfileImageUrl.isNotEmpty
                            ? NetworkImage(notification.senderProfileImageUrl)
                            : null,
                    child: notification.senderProfileImageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey, size: 24)
                        : null,
                  ),
                  // Notification type icon overlay
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getNotificationIconColor(notification.type),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: _getNotificationIcon(notification.type),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: notification.senderUsername,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: _getNotificationText(notification),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Action button for follow notifications
            if (notification.type == NotificationType.follow &&
                notification.isFollowBack)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: GradientButton(
                  text: 'Follow',
                  onPressed: () => controller.followUser(
                    notification.senderUserId,
                    notification.senderUsername,
                    notification.senderProfileImageUrl,
                  ),
                  height: 32,
                  borderRadius: 16,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),

            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getNotificationText(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.like:
        return ' liked your post';
      case NotificationType.comment:
        String commentText = notification.message
            .replaceFirst('${notification.senderUsername} commented: "', '')
            .replaceFirst('"', '');
        if (commentText.length > 30) {
          commentText = '${commentText.substring(0, 30)}...';
        }
        return ' commented: "$commentText"';
      case NotificationType.follow:
        return ' started following you';
      case NotificationType.message:
        return ' sent you a message';
    }
  }

  Color _getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return const Color(0xFFFF3040); // Red for likes
      case NotificationType.comment:
        return const Color(0xFF007AFF); // Blue for comments
      case NotificationType.follow:
        return AppColors.primary; // Orange for follows
      case NotificationType.message:
        return const Color(0xFF34C759); // Green for messages
    }
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 12,
        );
      case NotificationType.comment:
        return const Icon(
          Icons.chat_bubble,
          color: Colors.white,
          size: 10,
        );
      case NotificationType.follow:
        return const Icon(
          Icons.person_add,
          color: Colors.white,
          size: 10,
        );
      case NotificationType.message:
        return const Icon(
          Icons.message,
          color: Colors.white,
          size: 10,
        );
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.mark_email_read, color: AppColors.primary),
                title: const Text('Mark all as read'),
                onTap: () {
                  Navigator.pop(context);
                  controller.markAllAsRead();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: AppColors.primary),
                title: const Text('Refresh'),
                onTap: () {
                  Navigator.pop(context);
                  controller.refreshNotifications();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
