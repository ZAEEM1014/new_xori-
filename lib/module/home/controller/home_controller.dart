import 'package:get/get.dart';
import 'package:xori/data/demo_top_bar.dart';
import 'package:xori/services/post_service.dart';
import 'package:xori/services/story_service.dart';
import 'package:xori/models/post_model.dart';
import 'package:xori/models/story_model.dart';
import 'dart:async';
import 'dart:developer' as dev;

class HomeController extends GetxController {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  // Stream subscriptions
  StreamSubscription<List<Post>>? _postsStreamSubscription;
  StreamSubscription<List<StoryModel>>? _currentUserStoriesSubscription;

  // Top bar is a single map
  final RxMap<String, dynamic> topBar = demoTopBar.obs;

  // Stories data - functional implementation
  final RxList<Map<String, dynamic>> statuses = <Map<String, dynamic>>[].obs;
  final RxList<StoryModel> currentUserStories = <StoryModel>[].obs;
  final RxList<StoryModel> followingUsersStories = <StoryModel>[].obs;
  final RxBool isLoadingStories = false.obs;
  final RxString storiesErrorMessage = ''.obs;

  // Posts from Firestore
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _startPostsStream();
    _initializeStories();
  }

  @override
  void onClose() {
    _postsStreamSubscription?.cancel();
    _currentUserStoriesSubscription?.cancel();
    super.onClose();
  }

  void _startPostsStream() {
    isLoading.value = true;
    errorMessage.value = '';

    _postsStreamSubscription = _postService.streamAllPosts().listen(
      (List<Post> fetchedPosts) {
        try {
          posts.assignAll(fetchedPosts);
          errorMessage.value = '';
        } catch (e) {
          errorMessage.value = 'Failed to process posts: ${e.toString()}';
          print('Error processing posts: $e');
        } finally {
          isLoading.value = false;
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to load posts: ${error.toString()}';
        print('Error in posts stream: $error');
        isLoading.value = false;
      },
    );
  }

  Future<void> refreshPosts() async {
    // Restart the stream for refresh
    _postsStreamSubscription?.cancel();
    _startPostsStream();
  }

  // Backward compatibility method
  Future<void> fetchAllPosts() async {
    _startPostsStream();
  }

  /// Initialize stories with proper structure:
  /// Index 0: Add Story Box
  /// Index 1: Current User's Story Box (if available)
  /// Index 2+: Following Users' Story Boxes
  void _initializeStories() {
    try {
      dev.log('🚀 Initializing stories...', name: 'StoryController');
      isLoadingStories.value = true;
      storiesErrorMessage.value = '';

      // Start listening to current user stories
      _startCurrentUserStoriesStream();

      // Fetch following users stories
      _fetchFollowingUsersStories();
    } catch (e) {
      dev.log('❌ Error initializing stories: $e', name: 'StoryController');
      storiesErrorMessage.value = 'Failed to initialize stories';
      isLoadingStories.value = false;
    }
  }

  /// Start stream for current user's active stories
  void _startCurrentUserStoriesStream() {
    try {
      _currentUserStoriesSubscription =
          _storyService.getCurrentUserActiveStories().listen(
        (List<StoryModel> userStories) {
          try {
            dev.log(
                '📱 Current user stories updated: ${userStories.length} stories',
                name: 'StoryController');
            currentUserStories.assignAll(userStories);
            _buildStatusesList();
          } catch (e) {
            dev.log('❌ Error processing current user stories: $e',
                name: 'StoryController');
          }
        },
        onError: (error) {
          dev.log('❌ Error in current user stories stream: $error',
              name: 'StoryController');
          storiesErrorMessage.value = 'Failed to load your stories';
        },
      );
    } catch (e) {
      dev.log('❌ Error starting current user stories stream: $e',
          name: 'StoryController');
    }
  }

  /// Fetch stories from users that current user is following
  Future<void> _fetchFollowingUsersStories() async {
    try {
      final followingStories =
          await _storyService.getActiveStoriesOfFollowingUsers();
      dev.log(
          '👥 Following users stories fetched: ${followingStories.length} stories',
          name: 'StoryController');

      // Group stories by user to show one story box per user
      final Map<String, StoryModel> uniqueUserStories = {};
      for (final story in followingStories) {
        if (!uniqueUserStories.containsKey(story.userId)) {
          uniqueUserStories[story.userId] = story;
        }
      }

      followingUsersStories.assignAll(uniqueUserStories.values.toList());
      dev.log(
          '👥 Unique following user stories: ${followingUsersStories.length} users',
          name: 'StoryController');

      _buildStatusesList();
      isLoadingStories.value = false;
    } catch (e) {
      dev.log('❌ Error fetching following users stories: $e',
          name: 'StoryController');
      storiesErrorMessage.value = 'Failed to load following stories';
      isLoadingStories.value = false;
    }
  }

  /// Build the statuses list with proper structure
  void _buildStatusesList() {
    try {
      final List<Map<String, dynamic>> newStatuses = [];

      // Index 0: Add Story Box
      newStatuses.add({
        'name': 'Your Story',
        'image': '',
        'isAdd': 'true',
      });

      // Index 1: Current User's Story Box (if available)
      if (currentUserStories.isNotEmpty) {
        final currentUserStory = currentUserStories.first;
        newStatuses.add({
          'name': 'You',
          'image': currentUserStory.storyUrl,
          'isAdd': 'false',
          'storyModel': currentUserStory,
          'isCurrentUser': true,
        });
        dev.log('✅ Added current user story box', name: 'StoryController');
      }

      // Index 2+: Following Users' Story Boxes
      for (final story in followingUsersStories) {
        newStatuses.add({
          'name': story.username,
          'image': story.storyUrl,
          'isAdd': 'false',
          'storyModel': story,
          'isCurrentUser': false,
        });
      }

      statuses.assignAll(newStatuses);
      dev.log(
          '✅ Stories list built: ${statuses.length} items (1 add + ${currentUserStories.isNotEmpty ? 1 : 0} current user + ${followingUsersStories.length} following)',
          name: 'StoryController');
    } catch (e) {
      dev.log('❌ Error building statuses list: $e', name: 'StoryController');
    }
  }

  /// Refresh stories data
  Future<void> refreshStories() async {
    try {
      dev.log('🔄 Refreshing stories...', name: 'StoryController');
      isLoadingStories.value = true;
      storiesErrorMessage.value = '';

      // Cancel existing subscriptions
      _currentUserStoriesSubscription?.cancel();

      // Restart initialization
      _initializeStories();
    } catch (e) {
      dev.log('❌ Error refreshing stories: $e', name: 'StoryController');
      storiesErrorMessage.value = 'Failed to refresh stories';
      isLoadingStories.value = false;
    }
  }

  /// Handle story tap based on story type
  void handleStoryTap(Map<String, dynamic> status) {
    try {
      final bool isAdd = status['isAdd'] == 'true';

      if (isAdd) {
        dev.log('➕ Navigating to add story', name: 'StoryController');
        Get.toNamed('/addStory');
      } else {
        dev.log('👁️ Opening story viewer for: ${status['name']}',
            name: 'StoryController');
        // Navigate to story viewer with the story data
        Get.toNamed('/storyView', arguments: status);
      }
    } catch (e) {
      dev.log('❌ Error handling story tap: $e', name: 'StoryController');
    }
  }
}
