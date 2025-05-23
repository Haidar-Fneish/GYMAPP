import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/gym_owner_profile.dart';
import '../services/gym_owner_service.dart';
import 'edit_gym_owner_profile_screen.dart';

class GymOwnerProfileScreen extends StatefulWidget {
  final String profileId;

  const GymOwnerProfileScreen({Key? key, required this.profileId}) : super(key: key);

  @override
  _GymOwnerProfileScreenState createState() => _GymOwnerProfileScreenState();
}

class _GymOwnerProfileScreenState extends State<GymOwnerProfileScreen> {
  final GymOwnerService _service = GymOwnerService();
  final ImagePicker _picker = ImagePicker();
  GymOwnerProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('Loading gym owner profile with ID: ${widget.profileId}');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('Fetching profile from Firestore...');
      final profile = await _service.getProfile(widget.profileId);
      print('Profile fetched: ${profile != null ? 'Success' : 'Not found'}');
      
      if (profile == null) {
        setState(() {
          _error = 'Profile not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickPhotos() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty && _profile != null) {
      try {
        final List<File> photos = images.map((xFile) => File(xFile.path)).toList();
        final photoUrls = await _service.uploadPhotos(_profile!.id, photos);
        
        setState(() {
          _profile = _profile!.copyWith(
            photoUrls: [..._profile!.photoUrls, ...photoUrls],
          );
        });
        
        await _service.createOrUpdateProfile(_profile!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photos: $e')),
        );
      }
    }
  }

  Future<void> _pickVideos() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && _profile != null) {
      try {
        final videoFile = File(video.path);
        final videoUrls = await _service.uploadVideos(_profile!.id, [videoFile]);
        
        setState(() {
          _profile = _profile!.copyWith(
            videoUrls: [..._profile!.videoUrls, ...videoUrls],
          );
        });
        
        await _service.createOrUpdateProfile(_profile!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.gymName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGymOwnerProfileScreen(profile: _profile!),
                ),
              );
              _loadProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gym Preview Section
            Container(
              height: 200,
              width: double.infinity,
              child: _profile!.photoUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: _profile!.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          _profile!.photoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error_outline, size: 50),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.add_photo_alternate, size: 50),
                      ),
                    ),
            ),

            // Add Media Buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Add Photos'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickVideos,
                    icon: const Icon(Icons.video_library),
                    label: const Text('Add Videos'),
                  ),
                ],
              ),
            ),

            // Gym Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _profile!.gymName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (_profile!.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.verified, color: Colors.blue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profile!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Information
                  _buildInfoSection('Contact', [
                    _buildInfoRow(Icons.location_on, _profile!.address),
                    _buildInfoRow(Icons.phone, _profile!.phoneNumber),
                    _buildInfoRow(Icons.email, _profile!.email),
                  ]),

                  // Business Hours
                  _buildInfoSection('Business Hours', [
                    for (var entry in _profile!.businessHours.entries)
                      _buildInfoRow(Icons.access_time, '${entry.key}: ${entry.value}'),
                  ]),

                  // Amenities
                  _buildInfoSection('Amenities', [
                    Wrap(
                      spacing: 8,
                      children: _profile!.amenities
                          .map((amenity) => Chip(label: Text(amenity)))
                          .toList(),
                    ),
                  ]),

                  // Membership Plans
                  _buildInfoSection('Membership Plans', [
                    for (var plan in _profile!.membershipPlans)
                      ListTile(
                        title: Text(plan),
                        trailing: Text('\$${_profile!.pricing[plan] ?? 'N/A'}'),
                      ),
                  ]),

                  // Videos Section
                  if (_profile!.videoUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Gym Videos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _profile!.videoUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
} 