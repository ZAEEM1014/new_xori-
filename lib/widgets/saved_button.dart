import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xori/constants/app_colors.dart';
import '../services/saved_service.dart';

class SavedButton extends StatefulWidget {
  final String postId;
  final double size;
  const SavedButton({Key? key, required this.postId, this.size = 28})
      : super(key: key);

  @override
  State<SavedButton> createState() => _SavedButtonState();
}

class _SavedButtonState extends State<SavedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isSaved = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final saved = await SavedService().isPostSaved(user.uid, widget.postId);
    setState(() {
      _isSaved = saved;
      _loading = false;
    });
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    if (_isSaved) {
      await SavedService().unsavePost(user.uid, widget.postId);
      setState(() {
        _isSaved = false;
        _loading = false;
      });
    } else {
      await SavedService().savePost(user.uid, widget.postId);
      setState(() {
        _isSaved = true;
        _loading = false;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? SizedBox(
            width: widget.size,
            height: widget.size,
            child: const CircularProgressIndicator(strokeWidth: 2))
        : GestureDetector(
            onTap: _toggleSave,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: _isSaved
                  ? ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return AppColors.appGradient.createShader(bounds);
                      },
                      child: Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        size: widget.size,
                      ),
                    )
                  : Icon(
                      Icons.bookmark_border,
                      color: AppColors.textDark,
                      size: widget.size,
                    ),
            ),
          );
  }
}
