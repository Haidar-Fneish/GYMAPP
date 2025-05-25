import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all chats for the current user
  Stream<List<Chat>> getUserChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Chat.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get all chats for a course owner/instructor
  Stream<List<Chat>> getInstructorChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('instructorId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Chat.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get messages for a specific chat
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap({
                ...doc.data(),
                'id': doc.id,
                'chatId': chatId,
              }))
          .toList();
    });
  }

  // Create a new chat
  Future<String> createChat({
    required String courseId,
    required String courseTitle,
    required String studentId,
    required String studentName,
    required String instructorId,
    required String instructorName,
  }) async {
    // Check if chat already exists
    final existingChat = await _firestore
        .collection('chats')
        .where('courseId', isEqualTo: courseId)
        .where('studentId', isEqualTo: studentId)
        .where('instructorId', isEqualTo: instructorId)
        .get();

    if (existingChat.docs.isNotEmpty) {
      return existingChat.docs.first.id;
    }

    final chatRef = await _firestore.collection('chats').add({
      'courseId': courseId,
      'courseTitle': courseTitle,
      'studentId': studentId,
      'studentName': studentName,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'participants': [studentId, instructorId],
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessage': 'Chat started',
      'isRead': false,
      'unreadCount': {
        studentId: 0,
        instructorId: 0,
      },
    });

    return chatRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) throw Exception('User data not found');

    // Get chat data
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data();
    if (chatData == null) throw Exception('Chat not found');

    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    // Determine the other participant
    final otherParticipantId = chatData['studentId'] == userId
        ? chatData['instructorId']
        : chatData['studentId'];

    // Add message to chat
    batch.set(messageRef, {
      'senderId': userId,
      'senderName': userData['name'],
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update chat metadata
    batch.update(chatRef, {
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessage': content,
      'isRead': false,
      'unreadCount.${otherParticipantId}': FieldValue.increment(1),
    });

    // Commit both operations atomically
    await batch.commit();
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'isRead': true,
      'unreadCount.${userId}': 0,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Get unread message count for a user
  Stream<int> getUnreadMessageCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = (data['unreadCount']?[userId] ?? 0) as int;
        total += unreadCount;
      }
      return total;
    });
  }
} 