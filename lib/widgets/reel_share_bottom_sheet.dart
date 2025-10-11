import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';
import '../services/auth_service.dart';

class ReelShareBottomSheet extends StatelessWidget {
  final Reel reel;

  const ReelShareBottomSheet({
    Key? key,
    required this.reel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final link = 'https://xori.app/reel/${reel.id}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Share Reel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Link display with copy button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          link,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500, 
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.black54),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: link));
                          if (context.mounted) {
                            Navigator.of(context).pop('copy');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Share via apps button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    label: const Text(
                      'Share via...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      try {
                        final shareText = reel.caption.isNotEmpty 
                            ? '${reel.caption}\n\nWatch this reel: $link'
                            : 'Check out this reel: $link';
                        await Share.share(shareText);
                      } catch (e) {
                        debugPrint('Error sharing reel: $e');
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop('share');
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Future<String?> show(BuildContext context, Reel reel) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReelShareBottomSheet(reel: reel),
    );

    if (result == 'copy') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Track share in Firestore if user shared or copied
    if (result == 'copy' || result == 'share') {
      try {
        final currentUserId = AuthService().currentUser?.uid;
        if (currentUserId != null) {
          await ReelService().shareReel(reel.id, currentUserId);
        }
      } catch (e) {
        debugPrint('Error tracking reel share: $e');
      }
    }

    return result;
  }
}
