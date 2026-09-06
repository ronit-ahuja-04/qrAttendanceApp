importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: 'AIzaSyB4AhUwkfkiR1ta6TLPd7hjTrDZlPu_1qI',
    appId: '1:380742054455:web:c4d3fc3ae3cab6890605b2',
    messagingSenderId: '380742054455',
    projectId: 'attendance-monitoring-sy-89218',
    authDomain: 'attendance-monitoring-sy-89218.firebaseapp.com',
    storageBucket: 'attendance-monitoring-sy-89218.firebasestorage.app',
    measurementId: 'G-59C4W6MHN8'
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    
    // Default values
    let notificationTitle = payload.notification?.title || 'Notification';
    let notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/favicon.png', // Fallback icon
        data: payload.data
    };

    // Show the notification in the PWA
    return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Click handler for deep-linking in PWA
self.addEventListener('notificationclick', function(event) {
    event.notification.close();
    
    const payloadData = event.notification.data;
    
    // Default app URL (can be customized based on payload data)
    let targetUrl = '/'; 
    if (payloadData && payloadData.type) {
       targetUrl = '/#/'; // Flutter hash routing root, app handles navigation via AmsGlobals
    }

    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
            // Check if there is already a window/tab open with the target URL
            for (let i = 0; i < windowClients.length; i++) {
                let client = windowClients[i];
                // If so, just focus it.
                if (client.url.includes(targetUrl) && 'focus' in client) {
                    return client.focus();
                }
            }
            // If not, then open the target URL in a new window/tab.
            if (clients.openWindow) {
                return clients.openWindow(targetUrl);
            }
        })
    );
});
