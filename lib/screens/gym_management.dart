import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _showMap = false;
  
  final MapController _mapController = MapController();
  List<Gym> _gyms = [];
  Gym? _selectedGym;

  static const String defaultPhotoUrl = 'https://th.bing.com/th/id/OIP.n3cbxN_NzoA5ArTeTlwNzAHaEm?rs=1&pid=ImgDetMain';

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
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
        photos: _selectedPhotos.isEmpty ? [File(defaultPhotoUrl)] : _selectedPhotos,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          gym.photoUrls[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                gym.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Open: ${gym.openTime}'),
              _buildInfoRow(Icons.location_on, 'Address: ${gym.address}'),
              _buildInfoRow(Icons.phone, 'Phone: ${gym.phoneNumber}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.black),
                  Text(
                    '${gym.rating.toStringAsFixed(1)} (${gym.totalRatings} ratings)',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement rating functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Rate this gym'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'GYMHUB',
          style: GoogleFonts.lora(
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isSmallScreen)
            IconButton(
              icon: Icon(_showMap ? Icons.edit : Icons.map),
              onPressed: () {
                setState(() {
                  _showMap = !_showMap;
                });
              },
            ),
        ],
      ),
      body: isSmallScreen
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return _showMap ? _buildMapSection() : _buildFormSection();
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildFormSection(),
        ),
        Expanded(
          flex: 2,
          child: _buildMapSection(),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Gym',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: _nameController,
                label: 'Gym Name',
                icon: Icons.fitness_center,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _openTimeController,
                label: 'Opening Hours',
                icon: Icons.access_time,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter opening hours' : null,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
      ),
      validator: validator,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _pickPhotos,
          icon: const Icon(Icons.photo_library),
          label: Text('Select Photos (${_selectedPhotos.length})'),
          style: _buttonStyle,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickVideo,
          icon: const Icon(Icons.video_library),
          label: Text(_selectedVideo == null ? 'Select Video' : 'Video Selected'),
          style: _buttonStyle,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _getCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: const Text('Use Current Location'),
          style: _buttonStyle,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: _buttonStyle.copyWith(
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(vertical: 16),
            ),
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return Colors.grey[400]!;
                }
                return Colors.black;
              },
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Add Gym',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.black87,
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
                            color: Colors.black87,
                            size: 30,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
        if (_selectedGym != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    _selectedGym!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    _selectedGym!.address,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        _selectedGym!.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showGymDetails(_selectedGym!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

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