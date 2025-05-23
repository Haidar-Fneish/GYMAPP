import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import '../models/gym.dart';

class GymService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new gym
  Future<String> addGym({
    required String ownerId,
    required String name,
    required String description,
    required String openTime,
    required String address,
    required String phoneNumber,
    required List<File> photos,
    File? video,
    required LatLng location,
  }) async {
    // Upload photos
    List<String> photoUrls = [];
    for (var photo in photos) {
      final ref = _storage.ref().child('gyms/$ownerId/${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}');
      await ref.putFile(photo);
      photoUrls.add(await ref.getDownloadURL());
    }

    // Upload video if provided
    String? videoUrl;
    if (video != null) {
      final ref = _storage.ref().child('gyms/$ownerId/${DateTime.now().millisecondsSinceEpoch}_${video.path.split('/').last}');
      await ref.putFile(video);
      videoUrl = await ref.getDownloadURL();
    }

    // Create gym document
    final docRef = await _firestore.collection('gyms').add({
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'openTime': openTime,
      'address': address,
      'phoneNumber': phoneNumber,
      'photoUrls': photoUrls,
      'videoUrl': videoUrl,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'rating': 0.0,
      'totalRatings': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Get all gyms
  Stream<List<Gym>> getGyms() {
    return _firestore
        .collection('gyms')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Gym.fromFirestore(doc)).toList());
  }

  // Get gyms by owner
  Stream<List<Gym>> getGymsByOwner(String ownerId) {
    return _firestore
        .collection('gyms')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Gym.fromFirestore(doc)).toList());
  }

  // Rate a gym
  Future<void> rateGym(String gymId, double rating) async {
    final gymRef = _firestore.collection('gyms').doc(gymId);
    
    await _firestore.runTransaction((transaction) async {
      final gymDoc = await transaction.get(gymRef);
      if (gymDoc.exists) {
        final currentRating = gymDoc.data()?['rating'] ?? 0.0;
        final totalRatings = gymDoc.data()?['totalRatings'] ?? 0;
        
        final newTotalRatings = totalRatings + 1;
        final newRating = ((currentRating * totalRatings) + rating) / newTotalRatings;
        
        transaction.update(gymRef, {
          'rating': newRating,
          'totalRatings': newTotalRatings,
        });
      }
    });
  }

  // Delete a gym
  Future<void> deleteGym(String gymId) async {
    final gymDoc = await _firestore.collection('gyms').doc(gymId).get();
    if (gymDoc.exists) {
      final gym = Gym.fromFirestore(gymDoc);
      
      // Delete photos
      for (var photoUrl in gym.photoUrls) {
        try {
          await _storage.refFromURL(photoUrl).delete();
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }
      
      // Delete video if exists
      if (gym.videoUrl != null) {
        try {
          await _storage.refFromURL(gym.videoUrl!).delete();
        } catch (e) {
          print('Error deleting video: $e');
        }
      }
      
      // Delete gym document
      await _firestore.collection('gyms').doc(gymId).delete();
    }
  }
} 