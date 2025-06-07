import 'dart:convert';
import 'dart:typed_data';

class PanicImage {
  final Uint8List imageBytes;
  final String sender;
  final String receiver;
  final DateTime timestamp;
  final String location;
  final String message;

  PanicImage({
    required this.imageBytes,
    required this.sender,
    required this.receiver,
    required this.timestamp,
    required this.location,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageBytes': base64Encode(imageBytes),
      'sender': sender,
      'receiver': receiver,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'message': message,
    };
  }

  factory PanicImage.fromJson(Map<String, dynamic> json) {
    return PanicImage(
      imageBytes: base64Decode(json['imageBytes']),
      sender: json['sender'],
      receiver: json['receiver'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      message: json['message'],
    );
  }

  static String getConversationKey(String user1, String user2) {
    List<String> users = [user1, user2]..sort();
    return 'conversation_${users[0]}_${users[1]}';
  }
}