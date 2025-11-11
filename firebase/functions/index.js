const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Video Call Token Functions
const videoCallTokens = require("./videoCallTokens.js");
exports.generateVideoCallTokens = videoCallTokens.generateVideoCallTokens;
exports.refreshVideoCallToken = videoCallTokens.refreshVideoCallToken;

const kFcmTokensCollection = "fcm_tokens";
const kPushNotificationsCollection = "ff_push_notifications";
const kSchedulerIntervalMinutes = 60;
const firestore = admin.firestore();

const kPushNotificationRuntimeOpts = {
  timeoutSeconds: 540,
  memory: "2GB",
};

exports.addFcmToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return "Failed: Unauthenticated calls are not allowed.";
  }
  const userDocPath = data.userDocPath;
  const fcmToken = data.fcmToken;
  const deviceType = data.deviceType;
  if (
    typeof userDocPath === "undefined" ||
    typeof fcmToken === "undefined" ||
    typeof deviceType === "undefined" ||
    userDocPath.split("/").length <= 1 ||
    fcmToken.length === 0 ||
    deviceType.length === 0
  ) {
    return "Invalid arguments encoutered when adding FCM token.";
  }
  if (context.auth.uid != userDocPath.split("/")[1]) {
    return "Failed: Authenticated user doesn't match user provided.";
  }
  const existingTokens = await firestore
    .collectionGroup(kFcmTokensCollection)
    .where("fcm_token", "==", fcmToken)
    .get();
  var userAlreadyHasToken = false;
  for (var doc of existingTokens.docs) {
    const user = doc.ref.parent.parent;
    if (user.path != userDocPath) {
      // Should never have the same FCM token associated with multiple users.
      await doc.ref.delete();
    } else {
      userAlreadyHasToken = true;
    }
  }
  if (userAlreadyHasToken) {
    return "FCM token already exists for this user. Ignoring...";
  }
  await getUserFcmTokensCollection(userDocPath).doc().set({
    fcm_token: fcmToken,
    device_type: deviceType,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return "Successfully added FCM token!";
});

exports.sendPushNotificationsTrigger = functions
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document(`${kPushNotificationsCollection}/{id}`)
  .onCreate(async (snapshot, _) => {
    try {
      // Ignore scheduled push notifications on create
      const scheduledTime = snapshot.data().scheduled_time || "";
      if (scheduledTime) {
        return;
      }

      await sendPushNotifications(snapshot);
    } catch (e) {
      console.log(`Error: ${e}`);
      await snapshot.ref.update({ status: "failed", error: `${e}` });
    }
  });

exports.sendScheduledPushNotifications = functions.pubsub
  .schedule(`every ${kSchedulerIntervalMinutes} minutes synchronized`)
  .onRun(async (_) => {
    const minutesToMilliseconds = (minutes) => minutes * 60 * 1000;
    function currentTimeDownToNearestMinute() {
      // Add a second to the current time to avoid minute boundary issues.
      const currentTime = new Date(new Date().getTime() + 1000);
      // Remove seconds and milliseconds to get the time down to the minute.
      currentTime.setSeconds(0, 0);
      return currentTime;
    }

    // Determine the cutoff times for this round of push notifications.
    const intervalMs = minutesToMilliseconds(kSchedulerIntervalMinutes);
    const upperCutoffTime = currentTimeDownToNearestMinute();
    const lowerCutoffTime = new Date(upperCutoffTime.getTime() - intervalMs);
    // Send push notifications that we've scheduled.
    const scheduledNotifications = await firestore
      .collection(kPushNotificationsCollection)
      .where("scheduled_time", ">", lowerCutoffTime)
      .where("scheduled_time", "<=", upperCutoffTime)
      .get();
    for (var snapshot of scheduledNotifications.docs) {
      try {
        await sendPushNotifications(snapshot);
      } catch (e) {
        console.log(`Error: ${e}`);
        await snapshot.ref.update({ status: "failed", error: `${e}` });
      }
    }
  });

async function sendPushNotifications(snapshot) {
  const notificationData = snapshot.data();
  const title = notificationData.notification_title || "";
  const body = notificationData.notification_text || "";
  const imageUrl = notificationData.notification_image_url || "";
  const sound = notificationData.notification_sound || "";
  const parameterData = notificationData.parameter_data || "";
  const targetAudience = notificationData.target_audience || "";
  const initialPageName = notificationData.initial_page_name || "";
  const userRefsStr = notificationData.user_refs || "";
  const batchIndex = notificationData.batch_index || 0;
  const numBatches = notificationData.num_batches || 0;
  const status = notificationData.status || "";

  if (status !== "" && status !== "started") {
    console.log(`Already processed ${snapshot.ref.path}. Skipping...`);
    return;
  }

  if (title === "" || body === "") {
    await snapshot.ref.update({ status: "failed" });
    return;
  }

  const userRefs = userRefsStr === "" ? [] : userRefsStr.trim().split(",");
  var tokens = new Set();
  if (userRefsStr) {
    for (var userRef of userRefs) {
      const userTokens = await firestore
        .doc(userRef)
        .collection(kFcmTokensCollection)
        .get();
      userTokens.docs.forEach((token) => {
        if (typeof token.data().fcm_token !== undefined) {
          tokens.add(token.data().fcm_token);
        }
      });
    }
  } else {
    var userTokensQuery = firestore.collectionGroup(kFcmTokensCollection);
    // Handle batched push notifications by splitting tokens up by document
    // id.
    if (numBatches > 0) {
      userTokensQuery = userTokensQuery
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAt(getDocIdBound(batchIndex, numBatches))
        .endBefore(getDocIdBound(batchIndex + 1, numBatches));
    }
    const userTokens = await userTokensQuery.get();
    userTokens.docs.forEach((token) => {
      const data = token.data();
      const audienceMatches =
        targetAudience === "All" || data.device_type === targetAudience;
      if (audienceMatches && typeof data.fcm_token !== undefined) {
        tokens.add(data.fcm_token);
      }
    });
  }

  const tokensArr = Array.from(tokens);
  var messageBatches = [];
  for (let i = 0; i < tokensArr.length; i += 500) {
    const tokensBatch = tokensArr.slice(i, Math.min(i + 500, tokensArr.length));
    const messages = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl: imageUrl }),
      },
      data: {
        initialPageName,
        parameterData,
      },
      android: {
        notification: {
          ...(sound && { sound: sound }),
        },
      },
      apns: {
        payload: {
          aps: {
            ...(sound && { sound: sound }),
          },
        },
      },
      tokens: tokensBatch,
    };
    messageBatches.push(messages);
  }

  var numSent = 0;
  await Promise.all(
    messageBatches.map(async (messages) => {
      const response = await admin.messaging().sendEachForMulticast(messages);
      numSent += response.successCount;
    }),
  );

  await snapshot.ref.update({ status: "succeeded", num_sent: numSent });
}

function getUserFcmTokensCollection(userDocPath) {
  return firestore.doc(userDocPath).collection(kFcmTokensCollection);
}

function getDocIdBound(index, numBatches) {
  if (index <= 0) {
    return "users/(";
  }
  if (index >= numBatches) {
    return "users/}";
  }
  const numUidChars = 62;
  const twoCharOptions = Math.pow(numUidChars, 2);

  var twoCharIdx = (index * twoCharOptions) / numBatches;
  var firstCharIdx = Math.floor(twoCharIdx / numUidChars);
  var secondCharIdx = Math.floor(twoCharIdx % numUidChars);
  const firstChar = getCharForIndex(firstCharIdx);
  const secondChar = getCharForIndex(secondCharIdx);
  return "users/" + firstChar + secondChar;
}

function getCharForIndex(charIdx) {
  if (charIdx < 10) {
    return String.fromCharCode(charIdx + "0".charCodeAt(0));
  } else if (charIdx < 36) {
    return String.fromCharCode("A".charCodeAt(0) + charIdx - 10);
  } else {
    return String.fromCharCode("a".charCodeAt(0) + charIdx - 36);
  }
}

// Import Supabase client and axios for onUserCreated function
const { createClient } = require("@supabase/supabase-js");
const axios = require("axios");

// Firebase Auth trigger: Create Supabase user + EHRbase EHR when Firebase user is created
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  const startTime = Date.now();
  console.log(
    `🚀 onUserCreated triggered for: ${user.email} ${user.uid}`
  );

  try {
    // Get configuration from Firebase Functions config
    const config = functions.config();
    const SUPABASE_URL = config.supabase?.url;
    const SUPABASE_SERVICE_KEY = config.supabase?.service_key;
    const EHRBASE_URL = config.ehrbase?.url;
    const EHRBASE_USERNAME = config.ehrbase?.username;
    const EHRBASE_PASSWORD = config.ehrbase?.password;

    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
      throw new Error(
        "Missing Supabase configuration. Run: firebase functions:config:set supabase.url=... supabase.service_key=..."
      );
    }

    if (!EHRBASE_URL || !EHRBASE_USERNAME || !EHRBASE_PASSWORD) {
      throw new Error(
        "Missing EHRbase configuration. Run: firebase functions:config:set ehrbase.url=... ehrbase.username=... ehrbase.password=..."
      );
    }

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    let supabaseUserId;
    let ehrId;

    // STEP 1: Create or retrieve Supabase Auth user (IDEMPOTENT)
    console.log("📝 Step 1: Creating or retrieving Supabase Auth user...");

    const { data: existingUsers } = await supabase.auth.admin.listUsers();
    const existingUser = existingUsers.users.find((u) => u.email === user.email);

    if (existingUser) {
      // User exists from previous attempt - reuse existing ID
      supabaseUserId = existingUser.id;
      console.log(
        `⚠️  Supabase Auth user already exists: ${supabaseUserId}`
      );
      console.log("   (This is OK - continuing with existing user ID)");
    } else {
      // Create new Supabase Auth user
      const { data: authData, error: authError } =
        await supabase.auth.admin.createUser({
          email: user.email,
          email_confirm: true,
          user_metadata: {
            firebase_uid: user.uid,
            email_verified: user.emailVerified || false,
          },
        });

      if (authError) {
        throw new Error(`Supabase Auth error: ${authError.message}`);
      }

      supabaseUserId = authData.user.id;
      console.log(`✅ Supabase Auth user created: ${supabaseUserId}`);
    }

    // STEP 2: Create or update Supabase users table record (IDEMPOTENT)
    console.log("📝 Step 2: Creating or updating Supabase users table record...");

    const { data: existingUserRecord } = await supabase
      .from("users")
      .select("id")
      .eq("id", supabaseUserId)
      .maybeSingle();

    if (existingUserRecord) {
      console.log("⚠️  Users table record already exists - skipping");
    } else {
      // Insert minimal record - FlutterFlow will handle additional fields
      const { error: userError } = await supabase.from("users").insert({
        id: supabaseUserId,
        firebase_uid: user.uid,
        email: user.email,
        // created_at is auto-generated by database
        // FlutterFlow will populate: first_name, last_name, full_name, phone_number, etc.
      });

      if (userError) {
        throw new Error(`Supabase users table error: ${userError.message}`);
      }

      console.log("✅ Supabase users table record created (minimal - FlutterFlow will populate rest)");
    }

    // STEP 3: Check for existing EHR linkage (IDEMPOTENT)
    console.log("📝 Step 3: Checking for existing EHR linkage...");

    const { data: existingEhrRecord } = await supabase
      .from("electronic_health_records")
      .select("ehr_id")
      .eq("patient_id", supabaseUserId)
      .maybeSingle();

    if (existingEhrRecord && existingEhrRecord.ehr_id) {
      // EHR exists from previous attempt - reuse existing ID
      ehrId = existingEhrRecord.ehr_id;
      console.log(`⚠️  EHR already exists: ${ehrId}`);
      console.log("   (This is OK - skipping EHR creation)");
    } else {
      // STEP 3b: Create new EHRbase EHR
      console.log("📝 Step 3b: Creating new EHRbase EHR...");

      const ehrResponse = await axios.post(
        `${EHRBASE_URL}/rest/openehr/v1/ehr`,
        undefined,  // No body - EHRbase creates default EHR_STATUS
        {
          auth: {
            username: EHRBASE_USERNAME,
            password: EHRBASE_PASSWORD,
          },
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      console.log("📊 EHRbase response headers:", JSON.stringify(ehrResponse.headers));

      // Extract EHR ID from Location header (e.g., ".../ehr/uuid") or ETag header
      // EHRbase returns 201 with empty body - ID is in headers
      if (ehrResponse.headers.location) {
        // Extract UUID from location URL (last segment after final /)
        ehrId = ehrResponse.headers.location.split('/').pop();
      } else if (ehrResponse.headers.etag) {
        // Remove quotes from ETag header
        ehrId = ehrResponse.headers.etag.replace(/"/g, '');
      } else {
        throw new Error(`EHRbase response missing location/etag headers: ${JSON.stringify(ehrResponse.headers)}`);
      }

      console.log(`✅ EHRbase EHR created: ${ehrId}`);

      // STEP 4: Create electronic_health_records entry
      console.log("📝 Step 4: Creating electronic_health_records entry...");

      const { error: ehrRecordError } = await supabase
        .from("electronic_health_records")
        .insert({
          patient_id: supabaseUserId,
          ehr_id: ehrId,
          created_at: new Date().toISOString(),
        });

      if (ehrRecordError) {
        throw new Error(
          `electronic_health_records error: ${ehrRecordError.message}`
        );
      }

      console.log("✅ electronic_health_records entry created");
    }

    // STEP 5: Update Firestore user document with supabase_user_id
    console.log("📝 Step 5: Updating Firestore user document...");

    await firestore.collection("users").doc(user.uid).set(
      {
        supabase_user_id: supabaseUserId,
      },
      { merge: true }
    );

    console.log("✅ Firestore user document updated");

    // Success!
    const duration = Date.now() - startTime;
    console.log("🎉 Success! User created across all 4 systems");
    console.log(`   Firebase UID: ${user.uid}`);
    console.log(`   Supabase ID: ${supabaseUserId}`);
    console.log(`   EHR ID: ${ehrId}`);
    console.log(`   Duration: ${duration}ms`);
  } catch (error) {
    console.error("❌ onUserCreated failed:", error.message);
    console.error("Stack trace:", error.stack);
    throw error; // Re-throw to mark function as failed
  }
});

// Firebase Auth trigger: Delete user from ALL systems when Firebase user is deleted
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const startTime = Date.now();
  console.log(`🗑️  onUserDeleted triggered for: ${user.email} (${user.uid})`);

  try {
    // Get configuration
    const config = functions.config();
    const SUPABASE_URL = config.supabase?.url;
    const SUPABASE_SERVICE_KEY = config.supabase?.service_key;

    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
      throw new Error("Missing Supabase configuration");
    }

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // STEP 1: Get Supabase user ID from users table
    console.log("📝 Step 1: Finding Supabase user ID...");
    const { data: userData } = await supabase
      .from("users")
      .select("id")
      .eq("firebase_uid", user.uid)
      .maybeSingle();

    if (!userData) {
      console.log("⚠️  No Supabase user found for this Firebase UID");
      // Still delete Firestore doc
      await admin.firestore().collection("users").doc(user.uid).delete();
      console.log("✅ Firestore document deleted");
      return;
    }

    const supabaseUserId = userData.id;
    console.log(`✅ Found Supabase user: ${supabaseUserId}`);

    // STEP 2: Delete from electronic_health_records table
    console.log("📝 Step 2: Deleting electronic_health_records entry...");
    const { error: ehrRecordError } = await supabase
      .from("electronic_health_records")
      .delete()
      .eq("patient_id", supabaseUserId);

    if (ehrRecordError) {
      console.log(`⚠️  electronic_health_records deletion warning: ${ehrRecordError.message}`);
    } else {
      console.log("✅ electronic_health_records entry deleted");
    }

    // NOTE: We do NOT delete from EHRbase - EHR records should be retained for legal/audit reasons
    // Even if a user account is deleted, their medical history must be preserved per HIPAA/GDPR requirements

    // STEP 3: Delete from Supabase users table
    console.log("📝 Step 3: Deleting from Supabase users table...");
    const { error: userDeleteError } = await supabase
      .from("users")
      .delete()
      .eq("id", supabaseUserId);

    if (userDeleteError) {
      console.log(`⚠️  Supabase users table deletion warning: ${userDeleteError.message}`);
    } else {
      console.log("✅ Supabase users table record deleted");
    }

    // STEP 4: Delete from Supabase Auth
    console.log("📝 Step 4: Deleting from Supabase Auth...");
    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(supabaseUserId);

    if (authDeleteError) {
      console.log(`⚠️  Supabase Auth deletion warning: ${authDeleteError.message}`);
    } else {
      console.log("✅ Supabase Auth user deleted");
    }

    // STEP 5: Delete from Firestore
    console.log("📝 Step 5: Deleting from Firestore...");
    await admin.firestore().collection("users").doc(user.uid).delete();
    console.log("✅ Firestore document deleted");

    // Success!
    const duration = Date.now() - startTime;
    console.log("🎉 User deletion completed across all systems");
    console.log(`   Firebase UID: ${user.uid}`);
    console.log(`   Supabase ID: ${supabaseUserId}`);
    console.log(`   Duration: ${duration}ms`);
    console.log("   Note: EHRbase EHR preserved for legal/audit requirements");
  } catch (error) {
    console.error("❌ onUserDeleted failed:", error.message);
    console.error("Stack trace:", error.stack);
    // Don't throw - we want to ensure Firestore cleanup happens even if other steps fail
    try {
      await admin.firestore().collection("users").doc(user.uid).delete();
      console.log("✅ Firestore document deleted (fallback)");
    } catch (firestoreError) {
      console.error("❌ Firestore deletion also failed:", firestoreError.message);
    }
  }
});
