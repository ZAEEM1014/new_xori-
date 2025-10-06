import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reel_model.dart';

class ReelService {
  static final ReelService _instance = ReelService._internal();
  factory ReelService() => _instance;
  ReelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reelsCollection = 'reels';

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

  Future<void> likeReel(String reelId, String userId) async {
    try {
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .collection('likes')
          .doc(userId)
          .set({'likedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to like reel: ${e.toString()}');
    }
  }

  Future<void> unlikeReel(String reelId, String userId) async {
    try {
      await _firestore
          .collection(_reelsCollection)
          .doc(reelId)
          .collection('likes')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unlike reel: ${e.toString()}');
    }
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
}
