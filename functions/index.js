/**
 * Cloud Functions for Community App
 * - Auto-assign custom claims when admin changes
 * - Safely decrement login count on logout
 */

const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();


// ---------------------------------------------------------------------------
// 1) setAdminClaim (Triggers automatically when a family document is updated)
// ---------------------------------------------------------------------------
exports.setAdminClaim = functions.firestore
  .document("families/{docId}")
  .onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data) return;

    const docId = context.params.docId;
    const isAdmin = data.isAdmin === true;

    // Silent-auth email format used in Flutter:
    const email = `${docId}@families.local`;

    try {
      // Find user by email
      const user = await admin.auth().getUserByEmail(email);

      // Assign new custom claims
      await admin.auth().setCustomUserClaims(user.uid, {
        admin: isAdmin,
        familyId: docId,
      });

      console.log(
        `Custom claims updated → email=${email} | admin=${isAdmin}`
      );
    } catch (e) {
      console.error("Error setting admin claim:", e);
    }
  });


// ---------------------------------------------------------------------------
// 2) decrementLogin (Called by Flutter on logout for NON-admin users)
// ---------------------------------------------------------------------------
exports.decrementLogin = functions.https.onCall(async (request) => {
  const docId = request.data.docId;
  if (!docId) return { success: false, error: "Missing docId" };

  const ref = admin.firestore().collection("families").doc(docId);

  try {
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;

      const cur = snap.data().currentLoggedIn || 0;
      const newVal = cur > 0 ? cur - 1 : 0;

      tx.update(ref, { currentLoggedIn: newVal });
    });

    console.log(`Login count decremented → family ${docId}`);
    return { success: true };
  } catch (e) {
    console.error("decrementLogin error:", e);
    return { success: false, error: e.message };
  }
});
