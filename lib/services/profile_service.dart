import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserProfile> getUserProfile({String? userId}) async {
    final String targetUserId = userId ?? _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(targetUserId).get();
    
    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    data['uid'] = targetUserId;
    return UserProfile.fromMap(data);
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    File? profilePicture,
    File? video,
    double? weight,
    double? height,
    double? bodyFat,
    Map<String, double>? prs,
  }) async {
    final userId = _auth.currentUser!.uid;
    String? profilePictureUrl;
    String? videoUrl;

    if (profilePicture != null) {
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');
      await ref.putFile(profilePicture);
      profilePictureUrl = await ref.getDownloadURL();
    }

    if (video != null) {
      final ref = _storage.ref().child('profile_videos/$userId.mp4');
      await ref.putFile(video);
      videoUrl = await ref.getDownloadURL();
    }

    await _firestore.collection('users').doc(userId).update({
      'name': name,
      'bio': bio,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bodyFat != null) 'bodyFat': bodyFat,
      if (prs != null) 'prs': prs,
    });
  }

  Future<bool> isFollowing(String targetUserId) async {
    final userId = _auth.currentUser!.uid;
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  Future<void> followUser(String targetUserId) async {
    final userId = _auth.currentUser!.uid;
    
    // Add to current user's following
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(targetUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add to target user's followers
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(userId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final userId = _auth.currentUser!.uid;
    
    // Remove from current user's following
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .doc(targetUserId)
        .delete();

    // Remove from target user's followers
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(userId)
        .delete();
  }

  Future<List<UserProfile>> getFollowingList(String userId) async {
    // Get the list of following IDs
    final followingSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();

    if (followingSnapshot.docs.isEmpty) {
      return [];
    }

    // Get all followed users in a single query
    final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: followingIds)
        .get();

    return usersSnapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return UserProfile.fromMap(data);
    }).toList();
  }
} 