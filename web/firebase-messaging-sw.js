// Import and configure the Firebase SDK
// These scripts are available locally when you build your Flutter web app.
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyBd-lC5yCIlrP4pqaAr3U2Hd1rcCvK25Zw",
    appId: "1:30491497060:web:29e53febbdc056c3104571",
    messagingSenderId: "30491497060",
    projectId: "com-app-project",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((payload) => {
    console.log("Received background message ", payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: "/icons/Icon-192.png",
    };

    return self.registration.showNotification(
        notificationTitle,
        notificationOptions
    );
});
