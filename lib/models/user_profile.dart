import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String bio;
  final String? profilePictureUrl;
  final double weight;
  final double height;
  final double bodyFat;
  final Map<String, double> prs;
  final String plan;
  final String? videoUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.bio,
    this.profilePictureUrl,
    required this.weight,
    required this.height,
    required this.bodyFat,
    required this.prs,
    required this.plan,
    this.videoUrl,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      weight: (data['weight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      bodyFat: (data['bodyFat'] ?? 0.0).toDouble(),
      prs: Map<String, double>.from(data['prs'] ?? {}),
      plan: data['plan'] ?? 'Basic User',
      videoUrl: data['videoUrl'],
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      name: map['name'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String?,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      bodyFat: (map['bodyFat'] as num?)?.toDouble() ?? 0.0,
      prs: Map<String, double>.from(map['prs'] as Map? ?? {}),
      plan: map['plan'] as String? ?? 'Basic Plan',
      videoUrl: map['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'bio': bio,
      'profilePictureUrl': profilePictureUrl,
      'weight': weight,
      'height': height,
      'bodyFat': bodyFat,
      'prs': prs,
      'plan': plan,
      'videoUrl': videoUrl,
    };
  }
} 