# CareBridge Family Module Update

This version keeps the existing Family Dashboard design and adds functional Family-side care management.

## Implemented
- Elder registration creates a public Elder ID such as `CB-ELD-A1B2C3D4`.
- Elder Profile displays the Elder ID so it can be shared with Family.
- Family Dashboard connects to an Elder using that public Elder ID.
- Family connection is stored in `users/{familyUid}.linkedElderId`.
- Family Elder ID lookup uses the minimal `elderDirectory/{elderId}` record.
- Family can view the connected Elder profile.
- Family Health Status reads the connected Elder's Firestore profile/health fields instead of using hard-coded sample elders.
- Family can add, edit and delete medicines for the connected Elder.
- Family can add, edit and delete appointments for the connected Elder.
- The same `elders/{elderUid}/medicines` and `elders/{elderUid}/appointments` collections are used by the Elder and Family sides.

## Important
The Flutter SDK was not available in the build environment used to package this ZIP, so `flutter analyze`/`flutter run` could not be executed here. Please run `flutter pub get`, `flutter analyze`, and `flutter run` on the development machine before testing the Firebase flows.

## Firebase data expected
`users/{uid}` for profile/role/connection, with Elder accounts containing `elderId`.

`elders/{elderUid}/medicines/{medicineId}` for medicines.

`elders/{elderUid}/appointments/{appointmentId}` for appointments.

Health values are read from `users/{elderUid}.health` when present, with fallback to top-level `heartRate`, `bloodPressure`, `temperature`, and `status` fields.
