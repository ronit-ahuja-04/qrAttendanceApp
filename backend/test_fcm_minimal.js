const admin = require("firebase-admin");
const serviceAccount = require("./firebase-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const token = "d349pgQh6ZBbch0oYO0qMl:APA91bGIeCUaCfOHelgoY8xp1puGN5MfNNBfdG3PF5YiGtMDXBdArhxw_fPxGkrOM88DP7KIyuc7jH8ajzvzxS-HuFnQkDEccQpK7rcVomULExbyIv4WldI";

const stringifiedData = {
  type: "TEST",
  click_action: "FLUTTER_NOTIFICATION_CLICK"
};

const payload = {
  notification: {
    title: "PWA Notification Success! 🎉",
    body: "If you see this on your computer/phone browser, the Service Worker is working perfectly!",
  },
  data: stringifiedData,
  token: token,
  apns: {
    payload: {
      aps: {
        sound: "default",
        contentAvailable: true,
      },
    },
  },
};

admin.messaging().send(payload)
  .then((response) => {
    console.log("Successfully sent message to PWA:", response);
    process.exit(0);
  })
  .catch((error) => {
    console.log("Error sending message:", error);
    process.exit(1);
  });
