import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/reel_model.dart';
import '../models/reel_comment_model.dart';
import '../models/saved_reel_model.dart';

class ReelService {
  static final ReelService _instance = ReelService._internal();
  factory ReelService() => _instance;
  ReelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _reelsCollection = 'reels';
  static const String _usersCollection = 'users';

  Future<String> uploadReel(Reel reel) async {
    try {
      final docRef =
          await _firestore.collection(_reelsCollection).add(reel.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload reel: [${e.toString()}');
    }
  }

  Future<List<Reel>> getAllReels() async {
    try {
      final querySnapshot = await _firestore
          .collection(_reelsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => Reel.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all reels: ${e.toString()}');
    }
  }

  // Like functionality for reels
  Future<void> likeReel(String reelId, String userId) async {
    try {
      // Add like to subcollection
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .collection('likes')
          .doc(userId)
          .set({
        'userId': userId,
        'likedAt': FieldValue.serverTimestamp(),
      });

      // Update like count and likes array in reel document
      await _firestore.collection(_reelsCollection).doc(reelId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to like reel: ${e.toString()}');
    }
  }

  Future<void> unlikeReel(String reelId, String userId) async {
    try {
      // Remove like from subcollection
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .collection('likes')
          .doc(userId)
          .delete();

      // Update likes array in reel document
      await _firestore.collection(_reelsCollection).doc(reelId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to unlike reel: ${e.toString()}');
    }
  }

  // Get like count for a reel
  Stream<int> getLikeCount(String reelId) {
    return _firestore
        .collection(_reelsCollection)
        .doc(reelId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final likes = doc.data()!['likes'];
        if (likes is List) {
          return likes.length;
        }
      }
      return 0;
    });
  }

  // Check if user has liked the reel
  Stream<bool> isReelLikedByUser(String reelId, String userId) {
    return _firestore
        .collection(_reelsCollection)
        .doc(reelId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final likes = doc.data()!['likes'];
        if (likes is List) {
          return likes.contains(userId);
        }
      }
      return false;
    });
  }

  // Comment functionality for reels
  Future<void> addComment(String reelId, ReelComment comment) async {
    try {
      // Add comment to subcollection
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .collection('comments')
          .add(comment.toMap());

      // Update comment count in reel document
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .update({'commentCount': FieldValue.increment(1)});
    } catch (e) {
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }

  // Get comments for a reel
  Stream<List<ReelComment>> streamComments(String reelId) {
    return _firestore
        .collection(_reelsCollection)
        .doc(reelId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReelComment.fromDoc(doc)).toList());
  }

  // Get comment count for a reel
  Stream<int> getCommentCount(String reelId) {
    return _firestore
        .collection(_reelsCollection)
        .doc(reelId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!['commentCount'] ?? 0;
      }
      return 0;
    });
  }

  // Share functionality for reels
  Future<void> shareReel(String reelId, String userId) async {
    try {
      // Add share to subcollection
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .collection('shares')
          .add({
        'userId': userId,
        'sharedAt': FieldValue.serverTimestamp(),
      });

      // Update share count in reel document
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .update({'shareCount': FieldValue.increment(1)});
    } catch (e) {
      throw Exception('Failed to share reel: ${e.toString()}');
    }
  }

  // Get share count for a reel
  Stream<int> getShareCount(String reelId) {
    return _firestore
        .collection(_reelsCollection)
        .doc(reelId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!['shareCount'] ?? 0;
      }
      return 0;
    });
  }

  // Save reel functionality
  Future<void> saveReel(String userId, String reelId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('savedReels')
          .doc(reelId)
          .set({
        'userId': userId,
        'reelId': reelId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save reel: ${e.toString()}');
    }
  }

  Future<void> unsaveReel(String userId, String reelId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('savedReels')
          .doc(reelId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unsave reel: ${e.toString()}');
    }
  }

  // Check if reel is saved by user
  Stream<bool> isReelSavedByUser(String userId, String reelId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('savedReels')
        .doc(reelId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Get saved reels for a user
  Stream<List<SavedReel>> streamSavedReels(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('savedReels')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavedReel.fromDoc(doc)).toList());
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> deleteReel(String reelId) async {
    try {
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete reel: ${e.toString()}');
    }
  }

  Stream<List<Reel>> streamAllReels() {
    try {
      return _firestore
          .collection(_reelsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          return snapshot.docs.map((doc) => Reel.fromDoc(doc)).toList();
        } catch (docError) {
          print('Error parsing reel document: $docError');
          return <Reel>[];
        }
      }).handleError((error) {
        print('Stream error: $error');
        return <Reel>[];
      });
    } catch (e) {
      throw Exception('Failed to stream all reels: ${e.toString()}');
    }
  }

  // Get reels for a specific user
  Stream<List<Reel>> streamUserReels(String userId) {
    try {
      return _firestore
          .collection(_reelsCollection)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          return snapshot.docs.map((doc) => Reel.fromDoc(doc)).toList();
        } catch (docError) {
          print('Error parsing user reel document: $docError');
          return <Reel>[];
        }
      }).handleError((error) {
        print('Stream error for user reels: $error');
        return <Reel>[];
      });
    } catch (e) {
      throw Exception('Failed to stream user reels: ${e.toString()}');
    }
  }

  // Get user reels count
  Future<int> getUserReelsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reelsCollection)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get user reels count: ${e.toString()}');
    }
  }

  // Thumbnail generation and caching functionality
  Future<String?> generateVideoThumbnail(String videoUrl) async {
    try {
      // Generate cache key
      final cacheKey = _generateCacheKey(videoUrl);
      
      // Check if thumbnail is already cached
      final cachedPath = await _getCachedThumbnailPath(cacheKey);
      if (cachedPath != null) {
        return cachedPath;
      }

      // Generate new thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: await _getThumbnailDirectory(),
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        maxWidth: 300,
        timeMs: 1000,
        quality: 85,
      );

      if (thumbnailPath != null) {
        // Cache the thumbnail
        await _cacheThumbnail(cacheKey, thumbnailPath);
        return thumbnailPath;
      }

      return null;
    } catch (e) {
      print('Error generating thumbnail for $videoUrl: $e');
      return null;
    }
  }

  String _generateCacheKey(String videoUrl) {
    final bytes = utf8.encode(videoUrl);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> _getCachedThumbnailPath(String cacheKey) async {
    try {
      final directory = await _getThumbnailDirectory();
      final cachedFile = File('$directory/thumb_$cacheKey.jpg');
      final exists = await cachedFile.exists();
      return exists ? cachedFile.path : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheThumbnail(String cacheKey, String thumbnailPath) async {
    try {
      final directory = await _getThumbnailDirectory();
      final cachedFile = File('$directory/thumb_$cacheKey.jpg');
      final originalFile = File(thumbnailPath);
      
      if (await originalFile.exists()) {
        await originalFile.copy(cachedFile.path);
      }
    } catch (e) {
      print('Error caching thumbnail: $e');
    }
  }

  Future<String> _getThumbnailDirectory() async {
    final directory = await getTemporaryDirectory();
    final thumbnailDir = Directory('${directory.path}/video_thumbnails');
    
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    
    return thumbnailDir.path;
  }

  // Clear thumbnail cache
  Future<void> clearThumbnailCache() async {
    try {
      final directory = await _getThumbnailDirectory();
      final thumbnailDir = Directory(directory);
      
      if (await thumbnailDir.exists()) {
        await thumbnailDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing thumbnail cache: $e');
    }
  }

  // Get cache size
  Future<int> getThumbnailCacheSize() async {
    try {
      final directory = await _getThumbnailDirectory();
      final thumbnailDir = Directory(directory);
      
      if (!await thumbnailDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in thumbnailDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }
}
