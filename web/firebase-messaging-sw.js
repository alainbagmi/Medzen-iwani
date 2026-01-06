// Firebase Cloud Messaging Service Worker
// This file MUST be at the root of the web app (/firebase-messaging-sw.js)
// to receive push notifications when the app is in the background

// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBt2MU6Ww2sJ3HkzEIkVvmxIc3HW3GHGmw",
  authDomain: "medzen-bf20e.firebaseapp.com",
  projectId: "medzen-bf20e",
  storageBucket: "medzen-bf20e.appspot.com",
  messagingSenderId: "738878528232",
  appId: "1:738878528232:web:a2c7a3b1c4d5e6f7g8h9i0"
});

// Retrieve Firebase Messaging instance
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  // Extract notification data
  const notificationTitle = payload.notification?.title || payload.data?.title || 'MedZen Notification';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.tag || 'medzen-notification',
    data: payload.data || {},
    // Actions for video call notifications
    actions: payload.data?.type === 'video_call' ? [
      { action: 'accept', title: 'Accept Call' },
      { action: 'decline', title: 'Decline' }
    ] : [],
    // Vibration pattern for urgent notifications
    vibrate: payload.data?.urgent === 'true' ? [200, 100, 200, 100, 200] : [200, 100, 200],
    // Keep notification visible
    requireInteraction: payload.data?.type === 'video_call'
  };

  // Show the notification
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event);

  event.notification.close();

  // Handle action buttons (for video calls)
  if (event.action === 'accept') {
    // Open the app to the video call
    const appointmentId = event.notification.data?.appointmentId;
    const url = appointmentId
      ? `/?appointmentId=${appointmentId}&action=join_call`
      : '/';
    event.waitUntil(clients.openWindow(url));
  } else if (event.action === 'decline') {
    // Just close the notification (already done above)
    console.log('Call declined');
  } else {
    // Default click - open the app
    const clickAction = event.notification.data?.click_action || '/';
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then((clientList) => {
          // Check if the app is already open
          for (const client of clientList) {
            if (client.url.includes(self.location.origin) && 'focus' in client) {
              return client.focus();
            }
          }
          // If not, open a new window
          return clients.openWindow(clickAction);
        })
    );
  }
});

// Handle service worker installation
self.addEventListener('install', (event) => {
  console.log('[firebase-messaging-sw.js] Service worker installed');
  self.skipWaiting();
});

// Handle service worker activation
self.addEventListener('activate', (event) => {
  console.log('[firebase-messaging-sw.js] Service worker activated');
  event.waitUntil(clients.claim());
});
