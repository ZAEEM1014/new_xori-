import 'package:xori/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/constants/app_assets.dart';
import 'package:xori/widgets/app_text_button.dart';
import 'package:xori/widgets/gradient_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class OnboardingView extends StatefulWidget {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _completed = false;
  bool _navigating = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    // Remove navigation from animation complete
    _controller.addStatusListener((status) {
      // No navigation here
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dragOffset = 0.0;
        _completed = false;
        _navigating = false;
        _controller.reset();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Positioned images (circles)
            Positioned(
              top: 122,
              left: 30,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage(AppAssets.ellipse76),
              ),
            ),
            Positioned(
              top: 59,
              left: 201,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage(AppAssets.ellipse85),
              ),
            ),
            Positioned(
              top: 145,
              left: 300,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage(AppAssets.ellipse77),
              ),
            ),
            Positioned(
              top: 316,
              left: 279,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage(AppAssets.ellipse75),
              ),
            ),
            Positioned(
              top: 384,
              left: 69,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage(AppAssets.ellipse84),
              ),
            ),
            Positioned(
              top: 274,
              left: -26,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage(AppAssets.ellipse78),
              ),
            ),
            // Center main image
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 188),
                child: CircleAvatar(
                  radius: 77,
                  backgroundImage: AssetImage(AppAssets.ellipse74),
                ),
              ),
            ),
            // Gradient dots
            Positioned(
              top: 125,
              left: 138,
              child: _gradientDot(),
            ),
            Positioned(
              top: 155,
              left: 255,
              child: _gradientDot(),
            ),
            Positioned(
              top: 208,
              left: 303,
              child: _gradientDot(),
            ),
            Positioned(
              top: 274,
              left: 250,
              child: _gradientDot(),
            ),
            Positioned(
              top: 385,
              left: 225,
              child: _gradientDot(),
            ),

            Positioned(
              top: 385,
              left: 128,
              child: _gradientDot(),
            ),

            Positioned(
              top: 323,
              left: 48,
              child: _gradientDot(),
            ),

            Positioned(
              top: 200,
              left: 89,
              child: _gradientDot(),
            ),
            // Content
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Be Seen. Be You✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Share your vibe, connect with friends, and join the new social era.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Button size and padding
                        const double buttonSize = 48;
                        const double horizontalPadding = 8;
                        final double trackHeight = 56;
                        final double trackRadius = 28;
                        final double trackWidth = constraints.maxWidth;
                        final double maxDrag =
                            trackWidth - buttonSize - horizontalPadding * 2;
                        return SizedBox(
                          height: trackHeight,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) async {
                              if (_completed || _navigating) return;
                              double newOffset = min(
                                  max(0, _dragOffset + details.delta.dx),
                                  maxDrag);
                              if (newOffset >= maxDrag) {
                                setState(() {
                                  _dragOffset = maxDrag;
                                  _completed = true;
                                  _navigating = true;
                                });
                                await OnboardingService.setOnboardingSeen();
                                Get.toNamed('/signup');
                              } else {
                                setState(() {
                                  _dragOffset = newOffset;
                                });
                              }
                            },
                            onHorizontalDragEnd: (details) {
                              if (_completed || _navigating) return;
                              if (_dragOffset < maxDrag) {
                                setState(() {
                                  _dragOffset = 0;
                                });
                              }
                            },
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: trackHeight,
                                  width: trackWidth,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(trackRadius),
                                    color: AppColors.inputBackground,
                                  ),
                                ),
                                Positioned(
                                  left: horizontalPadding + _dragOffset,
                                  top: (trackHeight - buttonSize) / 2,
                                  child: Container(
                                    height: buttonSize,
                                    width: buttonSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Container(
                                      height: buttonSize,
                                      width: buttonSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.appGradient,
                                      ),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          AppAssets.heartIcon,
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: buttonSize + horizontalPadding * 2,
                                  right: buttonSize + horizontalPadding * 2,
                                  top: 0,
                                  height: trackHeight,
                                  child: Center(
                                    child: Text(
                                      'Swipe to Get Started',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: horizontalPadding,
                                  top: (trackHeight - 32) / 2,
                                  child: SvgPicture.asset(
                                    AppAssets.rewindForwardIcon,
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AppTextButton(
                          text: 'Login',
                          onPressed: () async {
                            await OnboardingService.setOnboardingSeen();
                            Get.toNamed('/login');
                          },
                          textStyle: const TextStyle(
                            fontSize: 15,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  Widget _gradientDot() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.appGradient,
      ),
    );
  }
}
