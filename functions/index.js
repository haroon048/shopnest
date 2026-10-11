const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

// Jab bhi naya chat message bane → doosre bande ko push bhejo
exports.onChatMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const msg = event.data.data();
    const chatId = event.params.chatId;

    // Doosra participant (recipient) dhoondo
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    const participants = chatDoc.data()?.participants || [];
    const recipientId = participants.find((p) => p !== msg.senderId);
    if (!recipientId) return;

    // Uske FCM tokens nikalo
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const tokens = userDoc.data()?.fcmTokens || [];
    if (!tokens.length) return;

    // Push bhejo
    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: msg.senderName || 'New message',
        body: msg.type === 'image' ? 'Sent a photo' : (msg.text || 'New message'),
      },
      data: { chatId: chatId, type: 'chat' },
    });
  }
);
