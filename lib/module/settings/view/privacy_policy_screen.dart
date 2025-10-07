import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Privacy Policy',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider under app bar
            const SizedBox(height: 304),
            Divider(color: AppColors.divider, thickness: 1),
            const SizedBox(height: 18),
            // Privacy policy text
            Text(
              'Your privacy is important to us. This policy explains how we collect, use, and protect your personal information.\n\n'
              '1. Information Collection: We collect data to improve our services.\n\n'
              '2. How We Use Your Information: We may use your data to contact you, provide customer support, and improve our app.\n\n'
              '3. Data Security: We implement various security measures to ensure the protection of your data.',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
