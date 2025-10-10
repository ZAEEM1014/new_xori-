import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/widgets/custom_app_bar.dart';
import '../../profile/controller/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/gradient_circle_icon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Privacy Policy',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          _sectionTitle('Account'),
          const SizedBox(height: 8),
          _accountSection(context),
          const SizedBox(height: 24),
          _sectionTitle('Security'),
          const SizedBox(height: 8),
          _securitySection(),
          const SizedBox(height: 24),
          _sectionTitle('Appearance'),
          const SizedBox(height: 8),
          _appearanceSection(),
          const SizedBox(height: 24),
          _sectionTitle('Legal & Support'),
          const SizedBox(height: 8),
          _legalSupportSection(),
          const SizedBox(height: 24),
          _sectionTitle('Logout'),
          const SizedBox(height: 8),
          _logoutSection(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 0, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textDark,
          ),
        ),
      );

  Widget _accountSection(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(() => ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: profileController
                          .profileImageUrl.value.isNotEmpty
                      ? NetworkImage(profileController.profileImageUrl.value)
                      : const AssetImage('assets/images/profile1.png')
                          as ImageProvider,
                ),
                title: Text(
                  profileController.name.value.isNotEmpty
                      ? profileController.name.value
                      : 'Username',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                subtitle: const Text(
                  'Edit profile, picture, bio',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                  ),
                ),
                trailing: const GradientCircleIcon(
                    icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
                onTap: () => Get.toNamed(AppRoutes.editProfile),
              )),
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 60),
            color: const Color(0xFFE5E5E5),
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const Icon(Icons.lock_outline,
                color: Color(0xFF8E8E93), size: 24),
            title: const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            trailing: const GradientCircleIcon(
                icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
            onTap: () {
              Get.toNamed('/changePassword');
            },
          ),
        ],
      ),
    );
  }

  Widget _securitySection() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              value: false,
              onChanged: (v) {},
              secondary: const Icon(Icons.security,
                  color: Color(0xFF8E8E93), size: 24),
              title: const Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              activeColor: const Color(0xFF007AFF),
            ),
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 60),
              color: const Color(0xFFE5E5E5),
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.computer,
                  color: Color(0xFF8E8E93), size: 24),
              title: const Text(
                'Session Control',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: const GradientCircleIcon(
                  icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
              onTap: () => Get.toNamed(AppRoutes.sessionControl),
            ),
          ],
        ),
      );

  Widget _appearanceSection() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          value: false,
          onChanged: (v) {},
          secondary: const Icon(Icons.nightlight_round,
              color: Color(0xFF8E8E93), size: 24),
          title: const Text(
            'Dark Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          activeColor: const Color(0xFF007AFF),
        ),
      );

  Widget _legalSupportSection() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: Color(0xFF8E8E93), size: 24),
              title: const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: const GradientCircleIcon(
                  icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
              onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
            ),
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 60),
              color: const Color(0xFFE5E5E5),
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.description_outlined,
                  color: Color(0xFF8E8E93), size: 24),
              title: const Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: const GradientCircleIcon(
                  icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
              onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
            ),
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 60),
              color: const Color(0xFFE5E5E5),
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.help_outline,
                  color: Color(0xFF8E8E93), size: 24),
              title: const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: const GradientCircleIcon(
                  icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
              onTap: () => Get.toNamed(AppRoutes.helpAndSupport),
            ),
          ],
        ),
      );

  Widget _logoutSection(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.delete_outline,
                  color: Color(0xFFFF3B30), size: 24),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: const GradientCircleIcon(
                  icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
              onTap: () => _showDeleteAccountDialog(context),
            ),
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 60),
              color: const Color(0xFFE5E5E5),
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading:
                  const Icon(Icons.logout, color: Color(0xFFFF3B30), size: 24),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              trailing: const GradientCircleIcon(
                  icon: Icons.arrow_forward_ios, size: 24, iconSize: 12),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      );

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => _deleteAccount(context),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Get.offAllNamed('/login');
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(BuildContext context) async {
    try {
      Navigator.of(context).pop(); // Close dialog

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting account...'),
              ],
            ),
          );
        },
      );

      // Get the auth service
      final authService = Get.find<AuthService>();

      // Delete the account
      await authService.deleteAccount();

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login screen
      Get.offAllNamed('/login');

      // Show success message
      Get.snackbar(
        'Account Deleted',
        'Your account has been successfully deleted.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Error',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
