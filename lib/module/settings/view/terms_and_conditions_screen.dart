import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../constants/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Terms & Conditions',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Agreement',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'By using Connecto, you agree to these terms. If you disagree, please discontinue use. We may update these terms periodically, and your continued use implies acceptance of changes.',
                            style: TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Service Usage',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connecto provides language learning tools. Users must not misuse the service, including unauthorized access or distribution of content. We reserve the right to modify or discontinue services.',
                            style: TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Content Guidelines',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Users are responsible for their content. Do not post illegal, offensive, or infringing material. We may remove content violating these guidelines and terminate accounts.',
                            style: TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Legal Disclaimers',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Connecto is provided 'as is' without warranties. We are not liable for any damages arising from your use. These terms are governed by the laws of the jurisdiction where our company is registered.",
                            style: TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
