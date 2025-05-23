import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/gym_owner_profile.dart';

class GymOwnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create or update gym owner profile
  Future<void> createOrUpdateProfile(GymOwnerProfile profile) async {
    await _firestore.collection('gym_owners').doc(profile.id).set(profile.toMap());
    
    // Update user's role in users collection
    await _firestore.collection('users').doc(profile.userId).update({
      'role': 'gym_owner',
      'gymOwnerProfileId': profile.id,
    });
  }

  // Get gym owner profile by ID
  Future<GymOwnerProfile?> getProfile(String profileId) async {
    final doc = await _firestore.collection('gym_owners').doc(profileId).get();
    if (doc.exists) {
      return GymOwnerProfile.fromMap({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // Get gym owner profile by user ID
  Future<GymOwnerProfile?> getProfileByUserId(String userId) async {
    final query = await _firestore
        .collection('gym_owners')
        .where('userId', isEqualTo: userId)
        .get();
    
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return GymOwnerProfile.fromMap({...doc.data(), 'id': doc.id});
    }
    return null;
  }

  // Upload gym photos
  Future<List<String>> uploadPhotos(String profileId, List<File> photos) async {
    List<String> photoUrls = [];
    for (var photo in photos) {
      final ref = _storage.ref().child('gym_owners/$profileId/photos/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(photo);
      final url = await ref.getDownloadURL();
      photoUrls.add(url);
    }
    return photoUrls;
  }

  // Upload gym videos
  Future<List<String>> uploadVideos(String profileId, List<File> videos) async {
    List<String> videoUrls = [];
    for (var video in videos) {
      final ref = _storage.ref().child('gym_owners/$profileId/videos/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(video);
      final url = await ref.getDownloadURL();
      videoUrls.add(url);
    }
    return videoUrls;
  }

  // Add a post to the gym profile
  Future<void> addPost(String profileId, String postId) async {
    await _firestore.collection('gym_owners').doc(profileId).update({
      'posts': FieldValue.arrayUnion([postId])
    });
  }

  // Remove a post from the gym profile
  Future<void> removePost(String profileId, String postId) async {
    await _firestore.collection('gym_owners').doc(profileId).update({
      'posts': FieldValue.arrayRemove([postId])
    });
  }

  // Update business hours
  Future<void> updateBusinessHours(String profileId, Map<String, dynamic> hours) async {
    await _firestore.collection('gym_owners').doc(profileId).update({
      'businessHours': hours,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  // Update amenities
  Future<void> updateAmenities(String profileId, List<String> amenities) async {
    await _firestore.collection('gym_owners').doc(profileId).update({
      'amenities': amenities,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  // Update membership plans
  Future<void> updateMembershipPlans(String profileId, List<String> plans, Map<String, dynamic> pricing) async {
    await _firestore.collection('gym_owners').doc(profileId).update({
      'membershipPlans': plans,
      'pricing': pricing,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  // Set verification status
  Future<void> setVerificationStatus(String profileId, bool isVerified) async {
    await _firestore.collection('gym_owners').doc(profileId).update({
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  // Get all gym owner profiles
  Stream<List<GymOwnerProfile>> getAllProfiles() {
    return _firestore
        .collection('gym_owners')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymOwnerProfile.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Search gyms by name or location
  Future<List<GymOwnerProfile>> searchGyms(String query) async {
    final nameQuery = await _firestore
        .collection('gym_owners')
        .where('gymName', isGreaterThanOrEqualTo: query)
        .where('gymName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    final addressQuery = await _firestore
        .collection('gym_owners')
        .where('address', isGreaterThanOrEqualTo: query)
        .where('address', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    final results = {...nameQuery.docs, ...addressQuery.docs};
    return results
        .map((doc) => GymOwnerProfile.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get verified gyms
  Stream<List<GymOwnerProfile>> getVerifiedGyms() {
    return _firestore
        .collection('gym_owners')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymOwnerProfile.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
} 