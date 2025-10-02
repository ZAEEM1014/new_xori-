import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_assets.dart';
import '../../search/controller/search_controller.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/gradient_button.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchScreen extends GetView<SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar with icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDADADA)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.asset(
                          AppAssets.searchIcon,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users, hashtags, posts...',
                          hintStyle: const TextStyle(
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Suggested for you (no container, just vertical list)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Suggested for you',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _suggestedUser(
                    avatar: AppAssets.profilePic,
                    name: 'alex_photographer',
                    subtitle: 'Followed by 3 friends',
                  ),
                  const SizedBox(height: 12),
                  _suggestedUser(
                    avatar: AppAssets.ellipse75,
                    name: 'sarah_travels',
                    subtitle: 'Popular in your area',
                  ),
                  const SizedBox(height: 12),
                  _suggestedUser(
                    avatar: AppAssets.ellipse76,
                    name: 'mike_fitness',
                    subtitle: 'New to your network',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Trending hashtags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trending hashtags',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  _hashtagChip('#photography'),
                  _hashtagChip('#travel'),
                  _hashtagChip('#fitness'),
                  _hashtagChip('#foodie'),
                  _hashtagChip('#art'),
                  _hashtagChip('#nature'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Pinterest-style staggered grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final images = [
                      AppAssets.searchedImg1,
                      AppAssets.searchedImg2,
                      AppAssets.searchedImg3,
                      AppAssets.searchedImg4,
                      AppAssets.searchedImg5,
                    ];
                    final heights = [160.0, 220.0, 120.0, 180.0, 140.0];
                    return _gridImage(images[index], height: heights[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestedUser({
    required String avatar,
    required String name,
    required String subtitle,
  }) {
    return Row(
      children: [
        CircleAvatar(radius: 20, backgroundImage: AssetImage(avatar)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 28,
          width: 72,
          child: GradientButton(
            text: 'Follow',
            height: 28,
            borderRadius: 8,
            textStyle: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _hashtagChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _gridImage(String asset, {double height = 160}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
      ),
    );
  }
}
