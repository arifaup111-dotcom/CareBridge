# CareBridge Elder Voice Update

This build updates the Elder Dashboard for the voice-first workflow discussed for the CareBridge project.

## What is included

### 1. Malayalam speech input
- Keeps the existing `speech_to_text` Malayalam recognition path.
- The elder can speak Malayalam naturally.

### 2. Voice-first / no-button workflow
- Android uses one microphone foreground service for wake-word monitoring. The Elder Dashboard provides a persisted Hands-free assistant switch to enable or disable it.
- After a normal answer, it returns to listening automatically.
- The microphone button remains available for manual wake-name input.
- Hands-free wake-up requires the configured assistant name at the start of speech; other words and names do not activate it.
- If no assistant name has been saved, the Elder's profile name is used and saved as the wake name. The legacy default `Care` also migrates to the profile name; a different saved assistant name remains unchanged and can be edited in the profile.
- After the wake name alone, the assistant responds and starts listening for one request; command speech is submitted after a shorter pause.
- Android `SpeechRecognizer` is session-based speech-to-text, not a dedicated, always-on wake-word engine. It ends sessions on silence or after results. The service therefore retries serially with increasing backoff (up to 30 seconds) after session termination/errors; it does not provide uninterrupted low-power DSP wake detection. `EXTRA_PREFER_OFFLINE` is a preference only and the installed recognition provider may still require network access.
- To obtain true continuous on-device wake-word detection, integrate an engine such as Picovoice Porcupine with a provisioned access key and a model generated for the user's configured wake phrase. Neither key nor model is present in this project, so that engine cannot be activated here.
- Android requires microphone foreground services to be started while the app is eligible to do so and to show an ongoing notification. The service may continue while the display is off or another app is open, but OS policies, force-stop, battery restrictions, manufacturer task killers, or loss of the system speech provider can stop it. It cannot run while the phone is powered off. Wake-word detection on a locked screen has not been validated on a physical device.
- For longer background operation, the user may need to set CareBridge's Android battery usage to Unrestricted/Don't optimize in system settings. This is device-specific and does not override force-stop or Android microphone foreground-service rules.

## Test on a physical Android phone

1. Install the debug build, open Elder Dashboard, and grant microphone permission. Grant notification permission so the ongoing service notification is visible.
2. Confirm the Hands-free assistant switch is on and the notification says it is listening for the configured name.
3. Leave it idle for several minutes and observe the system microphone indicator and CareBridge notification. SpeechRecognizer sessions can still end on device/provider timeouts; the service retries with increasing waits, so this is not equivalent to an always-on DSP engine.
4. Say unrelated words without the configured name. They must not be sent to CareBridge's intent handler.
5. Say the configured name with and without a command, then confirm a single response and return to the wake state.
6. Repeat with CareBridge backgrounded and screen locked. Record phone model, Android version, recognition provider, and whether battery optimization is enabled; those conditions affect results.
7. Turn Hands-free assistant off and confirm the service notification disappears and the microphone indicator stops.
8. Repeat after denying microphone or notification permission and after disabling network access. A provider that does not supply offline speech recognition may not be able to recognize the wake name without network.

### 3. Medicine voice intent
Malayalam/English requests containing the medicine intent are handled locally instead of being sent to Gemini.

Examples:
- "ഇന്നത്തെ മരുന്നിന്റെ ലിസ്റ്റ്"
- "എന്റെ മരുന്ന് എപ്പോഴാണ്?"
- "മരുന്ന്"
- "Which medicine should I take now?"

The app reads `elders/{elderId}/medicines`, uses the stored `name`, `dosage`, and `time`, and chooses the current/next medicine based on the device time. Requests asking for today's list read the full medicine schedule.

### 4. Appointment voice intent
Malayalam/English requests containing doctor/appointment/consultation intent are handled locally.

Examples:
- "ഇന്ന് ഡോക്ടറെ കാണിക്കാനുണ്ടോ?"
- "ഇന്ന് appointment ഉണ്ടോ?"
- "ഇന്ന് consultation ഉണ്ടോ?"
- "Do I have a doctor appointment today?"
- "doctor appointment undo"

The app reads `elders/{elderId}/appointments` and returns only appointments whose stored date matches today's device date. Mentions of a doctor as part of a symptom conversation are kept in chat instead of being treated as an appointment query.

### 5. General health conversation
- Common symptoms such as headache are handled as a supportive conversation.
- The assistant responds empathetically and may ask one brief clarifying question.
- It does not diagnose or recommend medicine; for severe or urgent symptoms it directs the elder to Emergency SOS or nearby help.

### 6. Emergency voice intent
Built-in rescue phrases include Malayalam phrases such as:
- `രക്ഷിക്കൂ`
- `രക്ഷിക്കണം`
- `സഹായിക്കൂ`
- `അടിയന്തര സഹായം`
- `എന്നെ സഹായിക്കൂ`

The elder can also save a custom emergency word/phrase. The custom phrase is stored in Firestore and loaded when the Elder Dashboard starts.

When a critical phrase is recognized:
1. Voice listening stops.
2. The primary emergency contact is loaded from Firestore.
3. Current location is recorded when location sharing is enabled.
4. The emergency event is stored under `elders/{elderId}/emergencies`.
5. Android places a direct phone call to the stored primary contact.

The emergency contact is stored under:
`elders/{elderId}/settings/emergency`
with `contactName` and `contactNumber`.

## First-time setup for emergency calling

1. Open Elder Dashboard.
2. Open the Emergency Contact section.
3. Enter the primary contact name and phone number.
4. Save it.
5. Allow Phone permission when Android asks.
6. If location sharing is enabled, allow Location permission.
7. Set a custom emergency phrase if required.

## Validation order

1. Say `എന്റെ മരുന്ന് എപ്പോഴാണ്?`
2. Say `ഇന്നത്തെ മരുന്നിന്റെ ലിസ്റ്റ്`
3. Say `ഇന്ന് ഡോക്ടറെ കാണിക്കാനുണ്ടോ?`
4. Set a custom emergency phrase and test only with a safe test contact.
5. Verify that the dashboard automatically starts listening again after medicine/appointment responses.

## Important

Emergency calling is real phone functionality. Use a test contact while validating the feature. Do not use a real emergency phrase unless you intend to place the call.
