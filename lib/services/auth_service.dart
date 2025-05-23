import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_owner_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful for user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error during sign in: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      throw message;
    } catch (e) {
      print('Unexpected error during sign in: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name, String plan) async {
    try {
      print('Attempting to register user with email: $email');
      
      // First create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User created successfully with UID: ${userCredential.user?.uid}');

      final userId = userCredential.user!.uid;
      final now = FieldValue.serverTimestamp();

      // Create the user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'name': name,
        'email': email,
        'plan': plan,
        'bio': 'Welcome to Gym App! Update your profile to get started.',
        'weight': 0.0,
        'height': 0.0,
        'bodyFat': 0.0,
        'prs': {
          'Bench Press': 0.0,
          'Squat': 0.0,
          'Deadlift': 0.0,
        },
        'createdAt': now,
      });
      print('User document created in Firestore');

      // If the plan is 'Gym Owner', create a gym owner profile
      if (plan == 'Gym Owner') {
        final gymOwnerRef = _firestore.collection('gym_owners').doc();
        final gymOwnerProfile = GymOwnerProfile(
          id: gymOwnerRef.id,
          userId: userId,
          gymName: '$name\'s Gym',
          description: 'Welcome to our gym! We are currently setting up our profile.',
          photoUrls: [],
          videoUrls: [],
          address: '',
          location: const GeoPoint(0, 0), // Default location
          phoneNumber: '',
          email: email,
          amenities: [],
          businessHours: {
            'Monday': '9:00 AM - 9:00 PM',
            'Tuesday': '9:00 AM - 9:00 PM',
            'Wednesday': '9:00 AM - 9:00 PM',
            'Thursday': '9:00 AM - 9:00 PM',
            'Friday': '9:00 AM - 9:00 PM',
            'Saturday': '10:00 AM - 6:00 PM',
            'Sunday': '10:00 AM - 6:00 PM',
          },
          rating: 0.0,
          totalRatings: 0,
          followers: [],
          posts: [],
          isVerified: false,
          membershipPlans: [],
          pricing: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create the gym owner profile
        await gymOwnerRef.set(gymOwnerProfile.toMap());
        print('Gym owner profile created with ID: ${gymOwnerRef.id}');
        
        // Update user document with gym owner role and profile ID
        await _firestore.collection('users').doc(userId).update({
          'role': 'gym_owner',
          'gymOwnerProfileId': gymOwnerRef.id,
        });
        print('User document updated with gym owner role and profile ID');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error during registration: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      throw message;
    } catch (e) {
      print('Unexpected error during registration: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Attempting to sign out user: ${_auth.currentUser?.uid}');
      await _auth.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Error during sign out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }
} 