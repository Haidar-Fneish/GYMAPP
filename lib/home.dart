import 'package:flutter/material.dart';
import 'package:gym_app_project/profile.dart';
import 'calorie.dart';
import 'comment_page.dart';
import 'explore.dart';
import 'Maps.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_post.dart';
import 'package:share_plus/share_plus.dart';
import 'courses.dart';


class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int myIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> pages = [
   HomePage(),
   ExplorePage(),
   const MapsPage(),
   CaloriesPage(),
   ProfilePage(),
  ];

  final String appId = 'e43bfa08';
  final String appKey = '1d81898bcefe7695ed3b765026cdb4ef';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1, // Subtle shadow for depth
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'GYMHUB',
          style:  GoogleFonts.lora(
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
      drawer: DrawerContent(),
      body: pages[myIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Calories'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class DrawerContent extends StatefulWidget {
  const DrawerContent({Key? key}) : super(key: key);

  @override
  State<DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userPlan;

  @override
  void initState() {
    super.initState();
    _loadUserPlan();
  }

  Future<void> _loadUserPlan() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userPlan = doc.data()?['plan'] as String?;
        });
      }
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                await _auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddPostPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddPostPopup();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(
                  _auth.currentUser?.email ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Post'),
            onTap: () {
              Navigator.pop(context);
              _showAddPostPopup(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Courses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoursesPage(),
                ),
              );
            },
          ),
          if (_userPlan == 'gym_owner')
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Gym Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gym-management');
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }
}

class Post {
  final String username;
  final String userImage;
  final String postImage;
  final String caption;

  Post({
    required this.username,
    required this.userImage,
    required this.postImage,
    required this.caption,
  });
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deletePost(String postId, String userId) async {
    if (_auth.currentUser?.uid != userId) return;
    
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Future<void> _reportPost(String postId) async {
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reportedBy': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error reporting post: $e');
    }
  }

  void _showPostOptions(BuildContext context, String postId, String userId) {
    final bool isOwner = _auth.currentUser?.uid == userId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(postId, userId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.black),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _reportPost(postId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post reported successfully'),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('following')
          .snapshots(),
      builder: (context, followingSnapshot) {
        if (followingSnapshot.hasError) {
          return Center(child: Text('Error: ${followingSnapshot.error}'));
        }

        if (followingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get list of followed user IDs
        final followingIds = followingSnapshot.data?.docs
            .map((doc) => doc.id)
            .toList() ?? [];
        
        // Add current user's ID to see their own posts
        followingIds.add(_auth.currentUser?.uid ?? '');

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('posts')
              .where('userId', whereIn: followingIds)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.hasError) {
              return Center(child: Text('Error: ${postsSnapshot.error}'));
            }

            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = postsSnapshot.data?.docs ?? [];

            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No posts to show',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow some users to see their posts here',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;
                final timestamp = post['timestamp'] as Timestamp?;
                final timeAgo = timestamp != null
                    ? _getTimeAgo(timestamp.toDate())
                    : 'Just now';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(post['userId'])
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.hasError) {
                              return const Text('Error loading user');
                            }

                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Loading...');
                            }

                            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                            final userName = userData?['name'] ?? 'Anonymous';
                            final userEmail = post['userEmail'] ?? '';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        subtitle: Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.black),
                          onPressed: () => _showPostOptions(
                            context,
                            postId,
                            post['userId'],
                          ),
                        ),
                        onTap: () {
                          // Only navigate if the post is not from the current user
                          if (post['userId'] != _auth.currentUser?.uid) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(userId: post['userId']),
                              ),
                            );
                          }
                        },
                      ),
                      AspectRatio(
                        aspectRatio: 4/3,
                        child: Image.network(
                          post['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          post['caption'] ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            LikeButton(
                              postId: postId,
                              initialLikes: post['likes'] ?? 0,
                              likedBy: List<String>.from(post['likedBy'] ?? []),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.black),
                              onPressed: () async {
                                try {
                                  await Share.share(
                                    'Check out this post by ${post['userEmail']}: ${post['caption']}',
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error sharing post: $e'),
                                      backgroundColor: Colors.black,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class LikeButton extends StatefulWidget {
  final String postId;
  final int initialLikes;
  final List<String> likedBy;

  const LikeButton({
    Key? key,
    required this.postId,
    required this.initialLikes,
    required this.likedBy,
  }) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool isLiked;
  late int likeCount;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    isLiked = widget.likedBy.contains(_auth.currentUser?.uid);
    likeCount = widget.initialLikes;
  }

  Future<void> _toggleLike() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      await _firestore.collection('posts').doc(widget.postId).update({
        'likes': likeCount,
        'likedBy': isLiked
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      // Revert the state if the update fails
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border_rounded,
            color: isLiked ? Colors.red : Colors.grey,
          ),
          onPressed: _toggleLike,
        ),
        Text('$likeCount'),
      ],
    );
  }
}