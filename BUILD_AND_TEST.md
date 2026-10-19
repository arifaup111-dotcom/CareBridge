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

## Elder Malayalam voice validation
1. Open Elder Dashboard.
2. Allow microphone permission.
3. Say: "ഇന്നത്തെ മരുന്നിന്റെ ലിസ്റ്റ്".
4. Say: "ഇന്ന് ഡോക്ടറെ കാണിക്കാനുണ്ടോ".
5. Configure a test emergency contact, then say: "രക്ഷിക്കണം" only with a safe test number.

The app recognizes Malayalam voice, routes medicine questions to Firestore medicine data, appointment questions to today's Firestore appointments, and emergency phrases to the emergency contact workflow. Gemini is used for general conversation rather than these application-specific intents.
