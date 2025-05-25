import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/chat_service.dart';
import 'models/chat.dart';
import 'chat.dart';
import 'models/course.dart';
import 'services/course_service.dart';
import 'screens/course_details_screen.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({Key? key}) : super(key: key);

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isPremium = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserPlan();
  }

  Future<void> _checkUserPlan() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData != null) {
      setState(() {
        isPremium = userData['plan'] == 'Premium User' || userData['plan'] == 'Gym Owner';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Courses",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Available Courses'),
            Tab(text: 'My Courses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Available Courses Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Course>>(
            stream: _courseService.getPublishedCourses(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = snapshot.data ?? [];
                    final filteredCourses = courses.where((course) {
                      return course.title.toLowerCase().contains(_searchQuery) ||
                          course.description.toLowerCase().contains(_searchQuery) ||
                          course.creatorName.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredCourses.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No courses available'
                              : 'No courses found matching "$_searchQuery"',
                          style: const TextStyle(fontSize: 16),
                        ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                      itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final alreadySubscribed = course.subscribers.contains(currentUserId);
                  return CourseCard(
                    course: course,
                    isSubscribed: alreadySubscribed,
                    onSubscribe: () {
                      if (alreadySubscribed) {
                        // Show popup message
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Already Subscribed'),
                            content: const Text('You are already subscribed (:'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        _courseService.subscribeToCourse(course.id);
                      }
                    },
                    onUnsubscribe: () => _courseService.unsubscribeFromCourse(course.id),
                  );
                },
              );
            },
                ),
              ),
            ],
          ),
          // My Courses Tab
          StreamBuilder<List<Course>>(
            stream: _courseService.getSubscribedCourses(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = snapshot.data ?? [];

              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('You haven\'t subscribed to any courses yet'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _tabController.animateTo(0);
                        },
                        child: const Text('Browse Courses'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return CourseCard(
                    course: course,
                    isSubscribed: true,
                    onSubscribe: () => _courseService.subscribeToCourse(course.id),
                    onUnsubscribe: () => _courseService.unsubscribeFromCourse(course.id),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: isPremium
          ? FloatingActionButton(
              onPressed: () => _showCreateCourseDialog(context),
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showCreateCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateCourseDialog(),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final bool isSubscribed;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;

  const CourseCard({
    Key? key,
    required this.course,
    required this.isSubscribed,
    required this.onSubscribe,
    required this.onUnsubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == course.creatorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isSubscribed ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailsScreen(course: course),
            ),
          );
        } : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.photoUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  course.photoUrls.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${course.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By ${course.creatorName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${course.subscribers.length} subscribers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubscribed ? onUnsubscribe : onSubscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubscribed ? Colors.grey : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isSubscribed ? 'Unsubscribe' : 'Subscribe',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isSubscribed) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final chatService = ChatService();
                            final auth = FirebaseAuth.instance;
                            
                            try {
                              // Create a new chat if it doesn't exist
                              final chatId = await chatService.createChat(
                                courseId: course.id,
                                courseTitle: course.title,
                                studentId: auth.currentUser!.uid,
                                studentName: auth.currentUser!.displayName ?? 'User',
                                instructorId: course.creatorId,
                                instructorName: course.creatorName,
                              );

                              if (context.mounted) {
                                // Navigate to the chat screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chat: Chat(
                                        id: chatId,
                                        courseId: course.id,
                                        courseTitle: course.title,
                                        studentId: auth.currentUser!.uid,
                                        studentName: auth.currentUser!.displayName ?? 'User',
                                        instructorId: course.creatorId,
                                        instructorName: course.creatorName,
                                        lastMessageTime: DateTime.now(),
                                        lastMessage: '',
                                        isRead: true,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error creating chat: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat, color: Colors.black),
                          tooltip: 'Chat with instructor',
                        ),
                      ],
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Course'),
                                content: const Text('Are you sure you want to delete this course? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await CourseService().deleteCourse(course.id);
                                        if (context.mounted) {
                                          Navigator.pop(context); // Close dialog
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Course deleted successfully')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          Navigator.pop(context); // Close dialog
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error deleting course: $e')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete course',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateCourseDialog extends StatefulWidget {
  const CreateCourseDialog({Key? key}) : super(key: key);

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final List<WorkoutPlan> _workoutPlans = [];
  final List<File> _videos = [];
  final List<File> _photos = [];
  final CourseService _courseService = CourseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videos.add(File(video.path));
      });
    }
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _photos.add(File(photo.path));
      });
    }
  }

  void _addWorkoutPlan() {
    showDialog(
      context: context,
      builder: (context) => const AddWorkoutPlanDialog(),
    ).then((workoutPlan) {
      if (workoutPlan != null) {
        setState(() {
          _workoutPlans.add(workoutPlan);
        });
      }
    });
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _courseService.createCourse(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        workoutPlans: _workoutPlans,
        videos: _videos,
        photos: _photos,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating course: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Course',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
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
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Workout Plans',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._workoutPlans.map((plan) => Card(
                    child: ListTile(
                      title: Text(plan.title),
                      subtitle: Text('${plan.duration} min • ${plan.difficulty}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _workoutPlans.remove(plan);
                          });
                        },
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addWorkoutPlan,
                icon: const Icon(Icons.add),
                label: const Text('Add Workout Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Add Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Add Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_videos.isNotEmpty || _photos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._videos.map((video) => Chip(
                          label: const Text('Video'),
                          onDeleted: () {
                            setState(() {
                              _videos.remove(video);
                            });
                          },
                        )),
                    ..._photos.map((photo) => Chip(
                          label: const Text('Photo'),
                          onDeleted: () {
                            setState(() {
                              _photos.remove(photo);
                            });
                          },
                        )),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddWorkoutPlanDialog extends StatefulWidget {
  const AddWorkoutPlanDialog({Key? key}) : super(key: key);

  @override
  State<AddWorkoutPlanDialog> createState() => _AddWorkoutPlanDialogState();
}

class _AddWorkoutPlanDialogState extends State<AddWorkoutPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String _difficulty = 'Beginner';
  final List<Exercise> _exercises = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => const AddExerciseDialog(),
    ).then((exercise) {
      if (exercise != null) {
        setState(() {
          _exercises.add(exercise);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Workout Plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Plan Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
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
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                items: ['Beginner', 'Intermediate', 'Advanced']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _difficulty = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Exercises',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._exercises.map((exercise) => Card(
                    child: ListTile(
                      title: Text(exercise.name),
                      subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _exercises.remove(exercise);
                          });
                        },
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      WorkoutPlan(
                        title: _titleController.text,
                        description: _descriptionController.text,
                        exercises: _exercises,
                        duration: int.parse(_durationController.text),
                        difficulty: _difficulty,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({Key? key}) : super(key: key);

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  File? _video;
  File? _photo;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _video = File(video.path);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _photo = File(photo.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Exercise',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Add Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Add Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_video != null || _photo != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_video != null)
                      Chip(
                        label: const Text('Video'),
                        onDeleted: () {
                          setState(() {
                            _video = null;
                          });
                        },
                      ),
                    if (_photo != null)
                      Chip(
                        label: const Text('Photo'),
                        onDeleted: () {
                          setState(() {
                            _photo = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      Exercise(
                        name: _nameController.text,
                        description: _descriptionController.text,
                        sets: int.parse(_setsController.text),
                        reps: int.parse(_repsController.text),
                        videoUrl: _video?.path,
                        photoUrl: _photo?.path,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 