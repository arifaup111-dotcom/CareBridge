# CareBridge — Admin Module Update

Base project: your uploaded CareBridge_Admin_Dashboard_Final.zip
(folder: CareBridge_Elder_Dashboard_FIXED). Everything else in that
upload is untouched — only the three files below changed.

## Files changed

| File | What changed |
|---|---|
| `lib/screens/admin_dashboard.dart` | Added a live stats overview (Elders / Families / Connected / Unconnected counts) above the two existing action cards. Added a logout confirmation dialog (previously logged out immediately on tap — one accidental tap signed the admin out with no undo). Added pull-to-refresh. |
| `lib/screens/manage_users_screen.dart` | Added a search box (name/email) and role filter chips (All/Elder/Family/Admin) above the user list. Legacy caregiver profiles are presented under Family. Added a "LINKED" badge for connected family accounts. Password reset flow unchanged — still requires the existing confirmation. |
| `lib/screens/connect_elder_screen.dart` | **Fixed a real bug:** the family-connections list used `FutureBuilder` with a one-shot query. After connecting, `setState` from the saving-spinner happened to refetch, so it looked fine — but after *disconnecting*, nothing called `setState`, so the "Connected to: X" line stayed on screen until you manually reopened the page. Switched to a live `StreamBuilder` so both actions reflect immediately, for every admin session, without depending on which button happens to trigger a rebuild. Also added a confirmation dialog before disconnecting (previously instant, no undo) and a stale-link indicator if a connected elder account is ever deleted separately. |

## Scope respected

Per your own `ADMIN_DASHBOARD_SETUP.md` already in this project, Admin
stays limited to account viewing + password reset, and Family–Elder
connection. No delete-user, no medicine/appointment/health access was
added — that would be scope creep past what your PRD defines for this
role.

## What to copy into your existing project

Only these three files changed — same paths, straight replace:

```
lib/screens/admin_dashboard.dart        <- replace
lib/screens/manage_users_screen.dart    <- replace
lib/screens/connect_elder_screen.dart   <- replace
```

No pubspec changes, no new packages, no manifest changes. Everything
used here (`cloud_firestore`, `firebase_auth`, `flutter/material`) was
already imported in your original files.

## To run

```bash
flutter clean
flutter pub get
flutter run
```

`flutter clean` isn't strictly required for a Dart-only change like
this, but worth doing if you haven't rebuilt in a while.

## One thing worth checking on your end

Your Firestore security rules need to let a signed-in `admin`-role
user read the whole `users` collection and update *other* users'
`linkedElderId` field — not just their own document. If your rules are
still in Firebase's default test mode this already works, but test
mode expires after 30 days. If you hit a `permission-denied` error
when opening either admin screen, that's the rules, not this code —
happy to write the exact rule for that if you hit it.
