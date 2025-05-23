import 'package:cloud_firestore/cloud_firestore.dart';

class GymOwnerProfile {
  final String id;
  final String userId;
  final String gymName;
  final String description;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final String address;
  final GeoPoint location;
  final String phoneNumber;
  final String email;
  final List<String> amenities;
  final Map<String, String> businessHours;
  final double rating;
  final int totalRatings;
  final List<String> followers;
  final List<String> posts;
  final bool isVerified;
  final List<String> membershipPlans;
  final Map<String, dynamic> pricing;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymOwnerProfile({
    required this.id,
    required this.userId,
    required this.gymName,
    required this.description,
    required this.photoUrls,
    required this.videoUrls,
    required this.address,
    required this.location,
    required this.phoneNumber,
    required this.email,
    required this.amenities,
    required this.businessHours,
    required this.rating,
    required this.totalRatings,
    required this.followers,
    required this.posts,
    required this.isVerified,
    required this.membershipPlans,
    required this.pricing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GymOwnerProfile.fromMap(Map<String, dynamic> map) {
    return GymOwnerProfile(
      id: map['id'] as String,
      userId: map['userId'] as String,
      gymName: map['gymName'] as String,
      description: map['description'] as String,
      photoUrls: List<String>.from(map['photoUrls'] as List),
      videoUrls: List<String>.from(map['videoUrls'] as List),
      address: map['address'] as String,
      location: map['location'] as GeoPoint,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String,
      amenities: List<String>.from(map['amenities'] as List),
      businessHours: Map<String, String>.from(map['businessHours'] as Map),
      rating: (map['rating'] as num).toDouble(),
      totalRatings: map['totalRatings'] as int,
      followers: List<String>.from(map['followers'] as List),
      posts: List<String>.from(map['posts'] as List),
      isVerified: map['isVerified'] as bool,
      membershipPlans: List<String>.from(map['membershipPlans'] as List),
      pricing: Map<String, dynamic>.from(map['pricing'] as Map),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'gymName': gymName,
      'description': description,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'address': address,
      'location': location,
      'phoneNumber': phoneNumber,
      'email': email,
      'amenities': amenities,
      'businessHours': businessHours,
      'rating': rating,
      'totalRatings': totalRatings,
      'followers': followers,
      'posts': posts,
      'isVerified': isVerified,
      'membershipPlans': membershipPlans,
      'pricing': pricing,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GymOwnerProfile copyWith({
    String? id,
    String? userId,
    String? gymName,
    String? description,
    List<String>? photoUrls,
    List<String>? videoUrls,
    String? address,
    GeoPoint? location,
    String? phoneNumber,
    String? email,
    List<String>? amenities,
    Map<String, String>? businessHours,
    double? rating,
    int? totalRatings,
    List<String>? followers,
    List<String>? posts,
    bool? isVerified,
    List<String>? membershipPlans,
    Map<String, dynamic>? pricing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymOwnerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymName: gymName ?? this.gymName,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      address: address ?? this.address,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      amenities: amenities ?? this.amenities,
      businessHours: businessHours ?? this.businessHours,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      followers: followers ?? this.followers,
      posts: posts ?? this.posts,
      isVerified: isVerified ?? this.isVerified,
      membershipPlans: membershipPlans ?? this.membershipPlans,
      pricing: pricing ?? this.pricing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 