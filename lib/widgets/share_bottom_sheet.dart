import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';

class ShareBottomSheet extends StatelessWidget {
  final String shareLink;
  final String shareText;
  final VoidCallback? onShareCompleted;

  const ShareBottomSheet({
    Key? key,
    required this.shareLink,
    this.shareText = '',
    this.onShareCompleted,
  }) : super(key: key);

  /// Factory constructor for posts
  factory ShareBottomSheet.forPost(String postId, {VoidCallback? onShareCompleted}) {
    return ShareBottomSheet(
      shareLink: 'https://xori.app/post/$postId',
      shareText: 'Check out this amazing post on Xori!',
      onShareCompleted: onShareCompleted,
    );
  }

  /// Factory constructor for reels
  factory ShareBottomSheet.forReel(String reelId, {VoidCallback? onShareCompleted}) {
    return ShareBottomSheet(
      shareLink: 'https://xori.app/reel/$reelId',
      shareText: 'Check out this awesome reel on Xori!',
      onShareCompleted: onShareCompleted,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Handle bar
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Share',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Link display with copy button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          shareLink,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await _copyLink(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.copy,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Share options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Share via apps button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share, color: Colors.white, size: 20),
                        label: const Text(
                          'Share via Apps',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await _shareViaApps(context);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Copy link button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.link, color: AppColors.primary, size: 20),
                        label: Text(
                          'Copy Link',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await _copyLink(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: shareLink));
      Navigator.of(context).pop('copy');
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copied to clipboard!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Trigger completion callback
      if (onShareCompleted != null) {
        onShareCompleted!();
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to copy link'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareViaApps(BuildContext context) async {
    try {
      final textToShare = shareText.isNotEmpty 
          ? '$shareText\n\n$shareLink' 
          : shareLink;
          
      await Share.share(textToShare);
      Navigator.of(context).pop('share');

      // Trigger completion callback
      if (onShareCompleted != null) {
        onShareCompleted!();
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Helper function to show share bottom sheet
Future<String?> showShareBottomSheet({
  required BuildContext context,
  required String shareLink,
  String shareText = '',
  VoidCallback? onShareCompleted,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ShareBottomSheet(
      shareLink: shareLink,
      shareText: shareText,
      onShareCompleted: onShareCompleted,
    ),
  );
}

/// Helper function to show share bottom sheet for posts
Future<String?> showPostShareBottomSheet({
  required BuildContext context,
  required String postId,
  VoidCallback? onShareCompleted,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ShareBottomSheet.forPost(
      postId,
      onShareCompleted: onShareCompleted,
    ),
  );
}

/// Helper function to show share bottom sheet for reels
Future<String?> showReelShareBottomSheet({
  required BuildContext context,
  required String reelId,
  VoidCallback? onShareCompleted,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ShareBottomSheet.forReel(
      reelId,
      onShareCompleted: onShareCompleted,
    ),
  );
}
