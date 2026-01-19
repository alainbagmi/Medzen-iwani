// Firebase Cloud Messaging Service Worker
// Handles background notifications and message reception

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyCPr8GVwzLXqA5T5pZbJgQBzfkxQKJDKp4',
  authDomain: 'medzen-bf20e.firebaseapp.com',
  projectId: 'medzen-bf20e',
  storageBucket: 'medzen-bf20e.appspot.com',
  messagingSenderId: '1050768253649',
  appId: '1:1050768253649:web:3fa70b5fda0e0c4d88cc42'
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

// Handle incoming background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw] Received background message:', payload);

  // Customize notification here
  const notificationTitle = payload.notification?.title || 'MedZen Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new message',
    icon: payload.notification?.icon || '/mylestech.logo.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.notificationId || 'medzen-notification',
    requireInteraction: payload.data?.requireInteraction === 'true',
    actions: payload.data?.actions ? JSON.parse(payload.data.actions) : [],
    data: payload.data || {}
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw] Notification clicked:', event);
  event.notification.close();

  // Handle action button clicks
  if (event.action) {
    const actionData = event.notification.data?.actionData || {};
    const action = actionData[event.action];
    if (action?.url) {
      event.waitUntil(
        clients.matchAll({ type: 'window' }).then((clientList) => {
          // Check if there's a window/tab open with the target URL
          for (const client of clientList) {
            if (client.url === action.url && 'focus' in client) {
              return client.focus();
            }
          }
          // If not, open a new window
          return clients.openWindow(action.url);
        })
      );
    }
    return;
  }

  // Default: open the app
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      // Check if the app is already open
      for (const client of clientList) {
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      // If not, open a new window
      return clients.openWindow('/');
    })
  );
});

// Handle notification dismissals
self.addEventListener('notificationclose', (event) => {
  console.log('[firebase-messaging-sw] Notification closed:', event);
});
