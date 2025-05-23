import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Gym {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String openTime;
  final String address;
  final String phoneNumber;
  final List<String> photoUrls;
  final String? videoUrl;
  final LatLng location;
  final double rating;
  final int totalRatings;

  Gym({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.openTime,
    required this.address,
    required this.phoneNumber,
    required this.photoUrls,
    this.videoUrl,
    required this.location,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  factory Gym.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Gym(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      openTime: data['openTime'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      videoUrl: data['videoUrl'],
      location: LatLng(
        data['location']['latitude'] ?? 0.0,
        data['location']['longitude'] ?? 0.0,
      ),
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }
} 