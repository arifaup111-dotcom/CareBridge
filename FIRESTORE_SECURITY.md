# Firestore Security

The project uses `firestore.rules` for role-based access. The rules allow three principal roles: `elder`, `family`, and `admin`. Legacy `caregiver` profiles are treated as Family for reads and connections; they are not a separate role.

## Data access

- Users can read their own profile. Family can read only its connected Elder profile. Admin can list and read user profiles.
- Family looks up public Elder IDs through `elderDirectory/{elderId}`. This directory contains only `elderUid` and `elderId`, not email or phone details.
- Elders can read medicines, appointments, and care-reminder settings. Only their connected Family account and Admin can change those care plans.
- Care-reminder settings store caregiver-configured meal and water alarm times under `elders/{uid}/settings/careReminders`.
- Emergency settings are readable by the Elder, connected Family, and Admin, and writable only by Admin. Emergency records can be created by the Elder and read by the Elder, connected Family, and Admin.
- Admin profiles must be provisioned manually in Firebase Authentication and `users/{uid}`. Client registration cannot create an Admin profile, and users cannot change their own role.

New Elder registration writes the profile and public directory record in one Firestore batch. Existing Elders backfill their directory record when the Elder ID is loaded from the profile or Family Connection screen. Existing linked Family records continue to reference the Elder UID.

## Rule rollout

The rules have not been deployed. Before applying them to a live Firebase project, review existing application behavior and back up/export data. Once approved by the project operator, run from this directory:

```powershell
firebase deploy --only firestore:rules --project carebridge-b5323
```

Do not deploy until Admin access has been verified against a provisioned `users/{adminUid}` profile. Firebase rule deployment changes production access immediately.

To run the local Firestore emulator with these rules:

```powershell
firebase emulators:start --only firestore --project carebridge-b5323
```

The rules were compiled with the local emulator during development; authenticated CRUD and production data migration were not exercised.
