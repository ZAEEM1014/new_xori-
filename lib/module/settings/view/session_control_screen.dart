import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../constants/app_colors.dart';
import '../controller/session_control_controller.dart';

class SessionControlScreen extends GetView<SessionControlController> {
  const SessionControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Session Control',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: controller.sessions.length + 1, // +1 for logout all button
                    itemBuilder: (context, index) {
                      if (index == controller.sessions.length) {
                        // Logout all devices button
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
                            child: TextButton(
                              onPressed: controller.logOutAllDevices,
                              child: const Text(
                                'Logout of all Devices',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final session = controller.sessions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.status,
                                    style: TextStyle(
                                      color: session.isActive ? AppColors.textDark : Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${session.deviceName} • ${session.location}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!session.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.yellow,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: GestureDetector(
                                  onTap: () => controller.logOutDevice(session),
                                  child: const Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
