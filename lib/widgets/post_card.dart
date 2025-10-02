import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xori/constants/app_colors.dart';

import '../constants/app_assets.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.inputBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(

            leading: CircleAvatar(
              radius: 23,
              backgroundImage: AssetImage(post["profilePic"]),
            ),
            title: Text(
              post["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(post["time"]),
            trailing: SvgPicture.asset(
              AppAssets.favourite, // 👈 your custom favourite icon
              height: 24,
              width: 24,
            ),
          ),

          // Post Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.asset(post["postImage"], fit: BoxFit.cover),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.only(top: 12.0,left: 12,right: 12),
            child: Text(
              post["caption"],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      post["likes"],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10,),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.comment, // 👈 your custom comment icon
                      height: 19,
                      width: 19,
                      color:
                          AppColors.textDark, // optional if you want to tint it
                    ),
                    const SizedBox(width: 4),
                    Text(post["comments"],style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,)),
                  ],
                ),
                SizedBox(width: 10,),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppAssets.share, // 👈 your custom comment icon
                      height: 24,
                      width: 24,
                      color:
                          AppColors.textDark, // optional if you want to tint it
                    ),
                    const SizedBox(width: 4),
                    Text(post["shares"],style: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
