import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_owner_profile.dart';
import '../services/gym_owner_service.dart';

class EditGymOwnerProfileScreen extends StatefulWidget {
  final GymOwnerProfile profile;

  const EditGymOwnerProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _EditGymOwnerProfileScreenState createState() => _EditGymOwnerProfileScreenState();
}

class _EditGymOwnerProfileScreenState extends State<EditGymOwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = GymOwnerService();
  late TextEditingController _gymNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late Map<String, String> _businessHours;
  late List<String> _amenities;
  late List<String> _membershipPlans;
  late Map<String, dynamic> _pricing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gymNameController = TextEditingController(text: widget.profile.gymName);
    _descriptionController = TextEditingController(text: widget.profile.description);
    _addressController = TextEditingController(text: widget.profile.address);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _emailController = TextEditingController(text: widget.profile.email);
    _businessHours = Map<String, String>.from(widget.profile.businessHours);
    _amenities = List<String>.from(widget.profile.amenities);
    _membershipPlans = List<String>.from(widget.profile.membershipPlans);
    _pricing = Map<String, dynamic>.from(widget.profile.pricing);
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = widget.profile.copyWith(
        gymName: _gymNameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        businessHours: _businessHours,
        amenities: _amenities,
        membershipPlans: _membershipPlans,
        pricing: _pricing,
        updatedAt: DateTime.now(),
      );

      await _service.createOrUpdateProfile(updatedProfile);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addMembershipPlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Membership Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Plan Name'),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _membershipPlans.add(value);
                    _pricing[value] = 0.0;
                  });
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    final planName = _membershipPlans.last;
                    _pricing[planName] = double.tryParse(value) ?? 0.0;
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _editBusinessHours() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Business Hours'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var entry in _businessHours.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Hours',
                            hintText: 'e.g., 9:00 AM - 5:00 PM',
                          ),
                          controller: TextEditingController(text: entry.value),
                          onSubmitted: (value) {
                            setState(() {
                              _businessHours[entry.key] = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _editAmenities() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Amenities'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var amenity in _amenities)
                ListTile(
                  title: Text(amenity),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _amenities.remove(amenity);
                      });
                    },
                  ),
                ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Add Amenity',
                  hintText: 'e.g., Swimming Pool',
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _amenities.add(value);
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Gym Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _gymNameController,
              decoration: const InputDecoration(
                labelText: 'Gym Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a gym name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Business Hours',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _editBusinessHours,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var entry in _businessHours.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(entry.value),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _editAmenities,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _amenities
                          .map((amenity) => Chip(label: Text(amenity)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Membership Plans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addMembershipPlan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var plan in _membershipPlans)
                      ListTile(
                        title: Text(plan),
                        trailing: Text('\$${_pricing[plan]?.toStringAsFixed(2) ?? '0.00'}'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 