import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../profile/controller/profile_controller.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _sectionTitle('Account'),
          _accountCard(context),
          const SizedBox(height: 16),
          _sectionTitle('Security'),
          _securityCard(),
          const SizedBox(height: 16),
          _sectionTitle('Appearance'),
          _appearanceCard(),
          const SizedBox(height: 16),
          _sectionTitle('Legal & Support'),
          _legalSupportCard(),
          const SizedBox(height: 16),
          _sectionTitle('Logout'),
          _logoutCard(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
      );

  Widget _accountCard(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.white,
      child: Column(
        children: [
          Obx(() => ListTile(
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Edit profile, picture, bio'),
                trailing: _arrowIcon(),
                onTap: () => Get.toNamed(AppRoutes.editProfile),
              )),
          const Divider(height: 1, color: AppColors.divider),
          ListTile(
            leading: Icon(Icons.lock_outline, color: AppColors.textLight),
            title: const Text('Change Password'),
            trailing: _arrowIcon(),
            onTap: () {
              Get.toNamed('/changePassword');
            },
          ),
        ],
      ),
    );
  }

  Widget _securityCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: AppColors.white,
        child: Column(
          children: [
            SwitchListTile(
              value: false,
              onChanged: (v) {},
              secondary: Icon(Icons.security, color: AppColors.textLight),
              title: const Text('Two-Factor Authentication'),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: Icon(Icons.computer, color: AppColors.textLight),
              title: const Text('Session Control'),
              trailing: _arrowIcon(),
              onTap: () => Get.toNamed(AppRoutes.sessionControl),
            ),
          ],
        ),
      );

  Widget _appearanceCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: AppColors.white,
        child: SwitchListTile(
          value: false,
          onChanged: (v) {},
          secondary: Icon(Icons.nightlight_round, color: AppColors.textLight),
          title: const Text('Dark Mode'),
        ),
      );

  Widget _legalSupportCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: AppColors.white,
        child: Column(
          children: [
            ListTile(
              leading:
                  Icon(Icons.privacy_tip_outlined, color: AppColors.textLight),
              title: const Text('Privacy Policy'),
              trailing: _arrowIcon(),
              onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading:
                  Icon(Icons.description_outlined, color: AppColors.textLight),
              title: const Text('Terms & Conditions'),
              trailing: _arrowIcon(),
              onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: Icon(Icons.help_outline, color: AppColors.textLight),
              title: const Text('Help & Support'),
              trailing: _arrowIcon(),
              onTap: () => Get.toNamed(AppRoutes.helpAndSupport),
            ),
          ],
        ),
      );

  Widget _logoutCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: AppColors.white,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Account'),
              trailing: _arrowIcon(),
              onTap: () {},
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: const Text('Log Out',
                  style: TextStyle(color: AppColors.error)),
              trailing: _arrowIcon(),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // Replace below with your login route
                Get.offAllNamed('/login');
              },
            ),
          ],
        ),
      );

  Widget _arrowIcon() => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.yellow, width: 2),
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: AppColors.yellow),
      );
}
