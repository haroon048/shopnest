const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

// Helper: user ke FCM tokens nikalo
async function getTokens(userId) {
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  return userDoc.data()?.fcmTokens || [];
}

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
    const tokens = await getTokens(recipientId);
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

// Jab naya order bane → store owner ko push bhejo
exports.onOrderCreated = onDocumentCreated(
  'orders/{orderId}',
  async (event) => {
    const order = event.data.data();
    const orderId = event.params.orderId;
    const storeId = order.storeId || '';
    if (!storeId) return; // purana order bina store ke — skip

    // Store ka owner dhoondo
    const storeDoc = await admin.firestore().collection('stores').doc(storeId).get();
    const ownerId = storeDoc.data()?.ownerId;
    if (!ownerId || ownerId === order.userId) return;

    const tokens = await getTokens(ownerId);
    if (!tokens.length) return;

    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: 'New order received',
        body: `You have a new order worth Rs ${order.total ?? 0}.`,
      },
      data: { orderId: orderId, type: 'order' },
    });
  }
);

// Jab order ka status badle → customer ko push bhejo
exports.onOrderStatusChanged = onDocumentUpdated(
  'orders/{orderId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === after.status) return; // status nahi badla — skip

    const customerId = after.userId;
    if (!customerId) return;

    const tokens = await getTokens(customerId);
    if (!tokens.length) return;

    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: 'Order Update',
        body: `Your order is now ${after.status}.`,
      },
      data: { orderId: event.params.orderId, type: 'order' },
    });
  }
);
