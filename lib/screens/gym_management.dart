import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/gym.dart';
import '../services/gym_service.dart';
import '../services/auth_service.dart';

class GymManagementScreen extends StatefulWidget {
  const GymManagementScreen({Key? key}) : super(key: key);

  @override
  _GymManagementScreenState createState() => _GymManagementScreenState();
}

class _GymManagementScreenState extends State<GymManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gymService = GymService();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<File> _selectedPhotos = [];
  File? _selectedVideo;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  
  final MapController _mapController = MapController();
  List<Gym> _gyms = [];
  Gym? _selectedGym;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  void _loadGyms() {
    _gymService.getGyms().listen((gyms) {
      setState(() {
        _gyms = gyms;
      });
    });
  }

  Future<void> _pickPhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    setState(() {
      _selectedPhotos = images.map((image) => File(image.path)).toList();
    });
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_selectedLocation!, 15.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    }
  }

  Future<void> _searchLocation() async {
    if (_addressController.text.isEmpty) return;
    
    try {
      final locations = await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
        });
        _mapController.move(_selectedLocation!, 15.0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find location')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _gymService.addGym(
        ownerId: user.uid,
        name: _nameController.text,
        description: _descriptionController.text,
        openTime: _openTimeController.text,
        address: _addressController.text,
        phoneNumber: _phoneController.text,
        photos: _selectedPhotos,
        video: _selectedVideo,
        location: _selectedLocation!,
      );

      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _openTimeController.clear();
    _addressController.clear();
    _phoneController.clear();
    setState(() {
      _selectedPhotos = [];
      _selectedVideo = null;
      _selectedLocation = null;
    });
  }

  void _showGymDetails(Gym gym) {
    setState(() {
      _selectedGym = gym;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gym.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (gym.photoUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gym.photoUrls.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.network(
                        gym.photoUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                gym.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text('Open: ${gym.openTime}'),
              Text('Address: ${gym.address}'),
              Text('Phone: ${gym.phoneNumber}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  Text('${gym.rating.toStringAsFixed(1)} (${gym.totalRatings} ratings)'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement rating functionality
                },
                child: const Text('Rate this gym'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Management'),
      ),
      body: Row(
        children: [
          // Form Section
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Gym Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _openTimeController,
                      decoration: const InputDecoration(labelText: 'Opening Hours'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter opening hours' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter an address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.photo_library),
                      label: Text('Select Photos (${_selectedPhotos.length})'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: Text(_selectedVideo == null
                          ? 'Select Video'
                          : 'Video Selected'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _searchLocation,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Location'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Add Gym'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Map Section
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(0, 0),
                    initialZoom: 13.0,
                    onTap: (_, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_selectedLocation != null)
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ..._gyms.map((gym) => Marker(
                              point: gym.location,
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showGymDetails(gym),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
                if (_selectedGym != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: ListTile(
                        title: Text(_selectedGym!.name),
                        subtitle: Text(_selectedGym!.address),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            Text(_selectedGym!.rating.toStringAsFixed(1)),
                          ],
                        ),
                        onTap: () => _showGymDetails(_selectedGym!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _openTimeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 