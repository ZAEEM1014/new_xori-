import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../constants/app_colors.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Help & Support',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'FAQs',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_faqs.length, (index) {
                      final item = _faqs[index];
                      final expanded = _expandedIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ExpansionPanelList(
                          elevation: 0,
                          expandedHeaderPadding: EdgeInsets.zero,
                          expansionCallback: (panelIndex, isExpanded) {
                            setState(() {
                              _expandedIndex = expanded ? null : index;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              canTapOnHeader: true,
                              isExpanded: expanded,
                              headerBuilder: (context, isExpanded) {
                                return ListTile(
                                  title: Text(
                                    item.question,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                              body: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.answer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 34,
                      width: 234,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1), // light background
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          width: 1.2,
                          color: Colors
                              .transparent, // border hidden under gradient
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Gradient icon box
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: AppColors.appGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Call Us at +45-222-3333',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Report a Problem',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Text(
                        'Email us at Tangerine@life.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(
                              0xFF9E9E9E), // lighter gray placeholder tone
                          fontWeight: FontWeight.w400,
                        ),
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

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
