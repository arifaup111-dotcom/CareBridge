# CareBridge Elder Dashboard - Clean Build

This package intentionally excludes Flutter/Gradle/Kotlin generated caches and the machine-specific android/local.properties file. Flutter will regenerate them on the computer where the project is opened.

## First run
1. Open this folder in VS Code.
2. Connect the Vivo Y73 with USB debugging enabled.
3. In Terminal run:

flutter clean
flutter pub get
flutter devices
flutter run -d <VIVO_DEVICE_ID>

If only one Android device is connected, `flutter run` is also fine.

## If Gradle/Kotlin cache errors appear
Close Flutter/Android Studio, then run:

cd android
.\\gradlew --stop
cd ..
flutter clean
flutter pub get
flutter run

Do NOT copy an old `build`, `.gradle`, `.kotlin`, `.dart_tool`, or GeneratedPluginRegistrant.java into this project.

## Emergency SOS validation
1. Configure a safe test emergency contact and enable location sharing.
2. Open Elder Dashboard and tap **EMERGENCY SOS**.
3. Confirm the prompt and verify that the app records the emergency, shares location when permitted, and places the call to the configured contact.
4. Verify the contact receives the location text when location and SMS permissions are granted.

## English voice interaction
1. Open the Elder Dashboard, enable **English voice assistant**, and grant microphone permission.
2. Configure `GEMINI_API_KEY` as a Firebase Functions secret and deploy with `firebase deploy --only functions`. Never add the Gemini key to Flutter or Android files.
3. On Android, keep the persistent CareBridge voice notification visible. Say **“Sara”** to begin, then speak naturally without repeating the wake phrase. Android speech recognition may transcribe the wake phrase as **“Sarah”**; both are accepted. Verify the assistant greets the Elder and responds to the follow-up request.
   Ask **“What are the medicines today?”** and verify the spoken reply lists each medicine in time order with its scheduled time and dosage. Verify this question does not mark medicine as taken.
   Ask **“What appointments do I have today?”** and verify the spoken reply lists today's appointments in time order with available doctor, specialty, and hospital details. Verify appointments on other days and cancelled appointments are not included.
   After a meal, water, exercise, or medicine reminder, say **“I had it,” “done,”** or **“completed.”** Verify the recent Android reminder is recorded in Firestore and its category or medicine shows as completed in the Family dashboard. For a scheduled medicine, also try **“I had my 12 PM medicine”** (using a time that actually matches a saved medicine) or say its name. To track a specific meal, say **“I had breakfast,” “lunch completed,”** or **“dinner done.”** If there is no recent reminder or multiple medicines match, the assistant should clarify rather than guessing.
4. With the app open and voice listening enabled, say a configured emergency phrase (the default is **“emergency help”**) and verify it enters the existing SOS workflow. Background emergency phrases intentionally do not place calls.
5. Disable the voice assistant and verify its persistent notification/listener stops.

Android uses the device's speech-recognition provider in short, automatically restarted English recognition sessions, requesting offline recognition where supported. Recognition pauses during spoken replies to prevent feedback, while the foreground service and notification stay running. Provider behavior, battery use, network needs, and recognition gaps vary; this is not a dedicated low-power wake-word engine and must be validated on the target phone. iOS voice listening is foreground-only.

## Scheduled reminders
1. Configure wake-up, meal, water, and exercise times from the Elder Dashboard's **Daily care reminders** settings.
2. Add medicines with different times and appointments with a saved date/time. Verify each item has a stable schedule and that an appointment alarm is set for 24 hours before it.
3. Edit and delete a medicine, appointment, or daily reminder, then verify the previous alarm is replaced or cancelled.
4. Restart CareBridge and verify pending alarms are not duplicated. On Android, reboot the phone and change the device time zone to verify local-time recurrence is rebuilt.
5. On an Android device with Malayalam TTS data installed, lock the screen and remove CareBridge from recents (do not force-stop it); verify the Malayalam notification and announcement. Disable Malayalam TTS or notification permission and verify the available fallback.

The planner unit tests cover daily schedules, duplicate times, per-medicine time/ID planning, 24-hour appointment timing, cancelled appointments, and invalid dates. Device alarm delivery, reboot recovery, exact-alarm access, Malayalam TTS availability, and battery-vendor behavior still require physical-device verification. Force-stop suppresses Android alarms until the app is opened again; denied exact-alarm access may delay reminders.
