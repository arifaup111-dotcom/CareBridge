# English Elder Voice Interaction

The Elder Dashboard provides an opt-in English voice assistant. Start with
**“CareBridge”**, then speak naturally. You do not need to repeat the wake
phrase during the conversation. For example:

- “I took my medicine”
- “I had food”
- “I drank water”

Medicine updates use the Elder's existing medicine records. Meal and water
updates use the existing care-reminder records shown on the Family dashboard.
Gemini generates short conversational replies and uses recent turns to
understand follow-up speech. The app sends recognized text, not audio, to an
authenticated Firebase callable function. The Gemini API key is stored as a
Firebase Functions secret and is not included in the mobile app. Voice chat
requires network access and a deployed function.

On Android, enabling voice interaction starts a microphone foreground service
with an ongoing notification. Speech recognition pauses while the phone speaks
to avoid hearing its own reply; the foreground service and notification remain
running and recognition resumes afterward. Android's speech recognizer also
restarts short sessions between utterances, so a brief microphone indicator
change can still occur. Provider gaps, battery use, network use, and offline
availability depend on the device. This is not a dedicated low-power wake-word
engine. When the app is backgrounded, each check-in must begin with the wake
phrase; open-ended conversation is foreground-only. iOS uses foreground-only
speech recognition.

To configure conversational replies, set the Gemini API key as a Firebase
Functions secret and deploy the function from the project root using Node.js
20 or later:

```powershell
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

The deployed function requires Firebase Authentication and App Check. Register
the Android Play Integrity provider and Apple App Attest/DeviceCheck provider
in Firebase App Check; debug builds use debug tokens that must be registered
in the Firebase console.

## Scheduled care reminders

Wake-up, meal, water, exercise, medicine, and appointment reminders use the
existing Firestore schedules and local notification setup. Android posts the
Malayalam reminder notification and uses the device's Malayalam text-to-speech
engine when available. Daily alarms are rebuilt after reboot and device
time/time-zone changes. Appointments are scheduled 24 hours before their saved
local date and time; deleted, cancelled, invalid, and past reminder times are
not scheduled. If notification permission is denied, Android may still speak
the reminder, but cannot show its notification.

Allow notifications and exact alarms for on-time Android reminders. When exact
alarm access is denied, reminders fall back to inexact scheduling and may be
delayed by Android. Force-stopping the app prevents Android from delivering its
alarms until CareBridge is opened again. Family schedule changes are synced to
the Elder device when its app receives the Firestore update or is next opened.
On iOS, scheduled notifications are supported; spoken Malayalam in the
background is not provided by this Android-specific TTS service.

The default emergency phrase is **“emergency help”**; built-in phrases include
“emergency sos”, “call for help”, and “please call my emergency contact”. A
configured custom phrase can also be used. Emergency phrases trigger the
existing Emergency SOS handler only while the app is in the foreground.
Background listening is limited to care updates. The manual SOS button and its
existing emergency contact, calling, and location-sharing behavior remain
available independently of voice interaction.
