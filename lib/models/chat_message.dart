import 'package:cloud_firestore/cloud_firestore.dart';

// Ek chat message: text ya image.
// Firestore: chats/{chatId}/messages/{messageId}
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String imageUrl;
  final String type; // 'text' ya 'image'
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.imageUrl,
    required this.type,
    required this.createdAt,
  });

  bool get isImage => type == 'image';

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// Chat ki ek thread (ek product par buyer-seller ke darmiyan).
// Firestore: chats/{chatId}
class ChatThread {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final String buyerId;
  final String sellerId;
  final String storeId; // chat kis store ki hai
  final String lastMessage;
  final DateTime? lastMessageAt;

  ChatThread({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.buyerId,
    required this.sellerId,
    this.storeId = '',
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory ChatThread.fromMap(Map<String, dynamic> map, String id) {
    return ChatThread(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      storeId: map['storeId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}
