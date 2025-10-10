import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/gradient_circle_icon.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  int? _expandedIndex;

  final List<_FaqItem> _faqs = const [
    _FaqItem(
      question: 'How to reset password',
      answer:
          'To reset your password, go to the login page and click on \'Forgot Password\'. Follow the instructions sent to your email.',
    ),
    _FaqItem(
      question: 'How to delete my account',
      answer:
          'To delete your account, please contact our support team. We will guide you through the process and ensure your data is removed securely.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQs Section
            _buildSectionTitle('FAQs'),
            const SizedBox(height: 12),
            ..._faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              return _buildFaqCard(faq, index);
            }).toList(),

            const SizedBox(height: 24),

            // Contact Support Section
            _buildSectionTitle('Contact Support'),
            const SizedBox(height: 12),
            _buildContactCard(),

            const SizedBox(height: 24),

            // Report a Problem Section
            _buildSectionTitle('Report a Problem'),
            const SizedBox(height: 12),
            _buildReportCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildFaqCard(_FaqItem faq, int index) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.iconBorder, width: 1),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              title: Text(
                faq.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              trailing: GradientCircleIcon(
                icon: isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 24,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            if (isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.iconBorder, width: 1),
      ),
      child: ListTile(
        leading: GradientCircleIcon(
          icon: Icons.phone,
          size: 24,
        ),
        title: const Text(
          'Call Us at +45-222-3333',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildReportCard() {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.iconBorder, width: 1),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Email us at Tangerine@life.com',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textLight,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
