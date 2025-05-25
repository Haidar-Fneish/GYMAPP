import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String courseId;
  final String courseTitle;
  final String studentId;
  final String studentName;
  final String instructorId;
  final String instructorName;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool isRead;
  final Map<String, int> unreadCount;

  Chat({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.studentId,
    required this.studentName,
    required this.instructorId,
    required this.instructorName,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.isRead,
    this.unreadCount = const {},
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      courseTitle: map['courseTitle'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      instructorId: map['instructorId'] as String,
      instructorName: map['instructorName'] as String,
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'] as String,
      isRead: map['isRead'] as bool? ?? false,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'studentId': studentId,
      'studentName': studentName,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'isRead': isRead,
      'unreadCount': unreadCount,
    };
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String? ?? '',
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'User',
      content: map['content'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
} 