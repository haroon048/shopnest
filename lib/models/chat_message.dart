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
  // Message ka status: 'sent' (✓) -> 'delivered' (✓✓) -> 'seen' (✓✓ blue)
  final String status;
  // Jin users ne apne liye delete kiya (unko ye message nahi dikhega)
  final List<String> deletedFor;
  // Sab ke liye delete hua to true (text/image saaf, "deleted" likha dikhega)
  final bool deletedForEveryone;
  // Reply: jis message ka jawab hai (khaali ho to reply nahi)
  final String replyToId;
  final String replyToText;
  final String replyToName;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.imageUrl,
    required this.type,
    this.status = 'sent',
    this.deletedFor = const [],
    this.deletedForEveryone = false,
    this.replyToId = '',
    this.replyToText = '',
    this.replyToName = '',
    required this.createdAt,
  });

  bool get isImage => type == 'image';
  bool get hasReply => replyToText.isNotEmpty;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      type: map['type'] ?? 'text',
      status: map['status'] ?? 'sent',
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      deletedForEveryone: map['deletedForEveryone'] ?? false,
      replyToId: map['replyToId'] ?? '',
      replyToText: map['replyToText'] ?? '',
      replyToName: map['replyToName'] ?? '',
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
  final String lastSenderId; // aakhri message kisne bheja
  final String lastMessageStatus; // aakhri message ka status (tick ke liye)
  final DateTime? lastMessageAt;
  // Kaun typing kar raha hai (uid, khaali = koi nahi)
  final String typingBy;
  // Jin users ne ye chat apni list se delete ki
  final List<String> deletedFor;

  ChatThread({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.buyerId,
    required this.sellerId,
    this.storeId = '',
    required this.lastMessage,
    this.lastSenderId = '',
    this.lastMessageStatus = 'sent',
    required this.lastMessageAt,
    this.typingBy = '',
    this.deletedFor = const [],
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
      lastSenderId: map['lastSenderId'] ?? '',
      lastMessageStatus: map['lastMessageStatus'] ?? 'sent',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      typingBy: map['typingBy'] ?? '',
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
    );
  }
}
