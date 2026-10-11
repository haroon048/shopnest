// Background push notifications for the ShopNest web app.
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyBgqVFMQVXRZt4pBrL7qDY0oAzXqeH0KR8',
  appId: '1:223351136809:web:2fc6b2ba6cdbdca010f238',
  messagingSenderId: '223351136809',
  projectId: 'testing-cli-38285',
  authDomain: 'testing-cli-38285.firebaseapp.com',
  storageBucket: 'testing-cli-38285.firebasestorage.app',
});

firebase.messaging();
