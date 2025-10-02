import 'package:get/get.dart';
import 'package:xori/data/demo_top_bar.dart';
import 'package:xori/data/demo_statuses.dart';
import 'package:xori/data/demo_posts.dart';

class HomeController extends GetxController {
  // Top bar is a single map
  final RxMap<String, dynamic> topBar = demoTopBar.obs;

  // Statuses is a list of maps
  final RxList<Map<String, dynamic>> statuses = demoStatuses.obs;

  // Posts is a list of maps
  final RxList<Map<String, dynamic>> posts = demoPosts.obs;
}
