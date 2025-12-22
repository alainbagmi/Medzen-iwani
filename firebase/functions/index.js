const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

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
// =============================================================================
// onUserCreated - Creates user records in Supabase and EHRbase when Firebase Auth user is created
// =============================================================================
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  const startTime = Date.now();
  console.log(`🚀 onUserCreated triggered for: ${user.email} ${user.uid}`);

  // Get configuration
  const config = functions.config();
  const SUPABASE_URL = config.supabase?.url;
  const SUPABASE_SERVICE_KEY = config.supabase?.service_key;
  const EHRBASE_URL = config.ehrbase?.url;
  const EHRBASE_USERNAME = config.ehrbase?.username;
  const EHRBASE_PASSWORD = config.ehrbase?.password;

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    console.error("❌ Missing Supabase configuration");
    return;
  }

  const axios = require("axios");
  const { createClient } = require("@supabase/supabase-js");
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let supabaseUserId = null;
  let ehrId = null;

  try {
    // Step 1: Create Supabase Auth user
    console.log("📝 Step 1: Creating Supabase Auth user...");

    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: user.email,
      email_confirm: true,
      user_metadata: {
        firebase_uid: user.uid,
        display_name: user.displayName || null,
        phone_number: user.phoneNumber || null,
      },
    });

    if (authError) {
      if (authError.message && authError.message.includes("already been registered")) {
        console.log("⚠️  Supabase Auth user already exists, fetching existing user...");
        const { data: existingUsers } = await supabase.auth.admin.listUsers();
        const existingUser = existingUsers?.users?.find((u) => u.email === user.email);
        if (existingUser) {
          supabaseUserId = existingUser.id;
          console.log(`✅ Found existing Supabase Auth user: ${supabaseUserId}`);
        }
      } else {
        console.error(`❌ Supabase Auth error: ${authError.message}`);
      }
    } else if (authData?.user) {
      supabaseUserId = authData.user.id;
      console.log(`✅ Supabase Auth user created: ${supabaseUserId}`);
    }

    // Step 2: Create Supabase users table record (minimal fields only)
    if (supabaseUserId) {
      console.log("📝 Step 2: Creating Supabase users table record...");

      const { error: insertError } = await supabase.from("users").upsert(
        {
          id: supabaseUserId,
          firebase_uid: user.uid,
          email: user.email,
          account_status: "active",
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: "id" }
      );

      if (insertError) {
        console.error(`❌ Supabase users table error: ${insertError.code} - ${JSON.stringify(insertError)}`);
      } else {
        console.log("✅ Supabase users table record created");
      }
    }

    // Step 3: Check for existing EHR linkage or create new EHR
    if (supabaseUserId && EHRBASE_URL && EHRBASE_USERNAME && EHRBASE_PASSWORD) {
      console.log("📝 Step 3: Checking for existing EHR linkage...");

      // Check if EHR already exists for this user
      const { data: existingEhr } = await supabase
        .from("electronic_health_records")
        .select("ehr_id")
        .eq("patient_id", supabaseUserId)
        .single();

      if (existingEhr?.ehr_id) {
        ehrId = existingEhr.ehr_id;
        console.log(`⚠️  EHR already exists: ${ehrId}`);
      } else {
        // Create new EHR in EHRbase
        console.log("📝 Step 3b: Creating new EHRbase EHR...");
        try {
          const ehrResponse = await axios.post(
            `${EHRBASE_URL}/rest/openehr/v1/ehr`,
            undefined, // No body - EHRbase creates default EHR_STATUS
            {
              auth: {
                username: EHRBASE_USERNAME,
                password: EHRBASE_PASSWORD,
              },
              headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
                Prefer: "return=representation",
              },
              validateStatus: (status) => status === 201 || status === 204,
            }
          );

          // Extract EHR ID from Location header or ETag header
          if (ehrResponse.headers.location) {
            ehrId = ehrResponse.headers.location.split("/").pop();
          } else if (ehrResponse.headers.etag) {
            ehrId = ehrResponse.headers.etag.replace(/"/g, "");
          } else if (ehrResponse.data?.ehr_id?.value) {
            ehrId = ehrResponse.data.ehr_id.value;
          }

          if (ehrId) {
            console.log(`✅ EHRbase EHR created: ${ehrId}`);
          } else {
            console.error("❌ Could not extract EHR ID from response");
          }
        } catch (ehrError) {
          console.error(`❌ EHRbase error: ${ehrError.message}`);
        }
      }

      // Step 4: Create electronic_health_records linkage
      if (ehrId) {
        console.log("📝 Step 4: Creating electronic_health_records entry...");
        const { error: ehrLinkError } = await supabase.from("electronic_health_records").insert({
          patient_id: supabaseUserId,
          ehr_id: ehrId,
          ehr_status: "active",
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });

        if (ehrLinkError) {
          console.error(`❌ electronic_health_records error: ${JSON.stringify(ehrLinkError)}`);
        } else {
          console.log("✅ electronic_health_records entry created");
        }
      }
    } else if (!EHRBASE_URL) {
      console.log("⚠️  EHRbase not configured - skipping EHR creation");
    }

    // Step 5: Update Firestore user document
    console.log("📝 Step 5: Updating Firestore user document...");
    await firestore.collection("users").doc(user.uid).set(
      {
        uid: user.uid,
        email: user.email,
        display_name: user.displayName || null,
        phone_number: user.phoneNumber || null,
        created_time: admin.firestore.FieldValue.serverTimestamp(),
        supabase_user_id: supabaseUserId,
        ehr_id: ehrId,
      },
      { merge: true }
    );
    console.log("✅ Firestore user document updated");

    const duration = Date.now() - startTime;
    console.log("🎉 Success! User created in all systems");
    console.log(`   Firebase UID: ${user.uid}`);
    console.log(`   Supabase ID: ${supabaseUserId}`);
    console.log(`   EHR ID: ${ehrId || "N/A"}`);
    console.log(`   Duration: ${duration}ms`);
  } catch (error) {
    console.error(`❌ onUserCreated error: ${error.message}`);
    console.error(error.stack);
  }
});

// =============================================================================
// onUserDeleted - Cleans up user records when Firebase Auth user is deleted
// =============================================================================
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const firestore = admin.firestore();
  await firestore.collection("users").doc(user.uid).delete();
});
