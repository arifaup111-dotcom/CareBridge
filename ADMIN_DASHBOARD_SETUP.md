# CareBridge Admin Dashboard

The Admin dashboard provides these system-management tools:

1. User account management
   - View registered users from `users`.
   - Search users by name, profile email, or phone number, and filter by role.
   - Edit a user's display name and profile email.
   - Send Firebase password-reset links to the user's Firebase sign-in email.
2. Contact change approvals
   - Review phone and email change requests submitted by Elder and Family
     accounts.
   - Approve a request to update `users/{uid}.phone` and/or
     `users/{uid}.email`, or reject it while preserving current details.
   - Approval changes the CareBridge profile only; it does not change Firebase
     Authentication phone or email sign-in credentials.
3. Family–Elder connection
   - Select a Family account and an Elder account.
   - Store the relationship as `users/{familyUid}.linkedElderId`.
   - View existing Family–Elder connections.
   - Disconnect a Family from its Elder.

The Admin dashboard also displays live Elder, Family, and connection counts.
Medicines, appointments, health records, and emergencies remain in the
Elder/Family workflows.

## Admin account setup

There is no public Admin registration. Create the administrator account
yourself in Firebase Console:

1. In **Authentication → Users**, add an email/password user. Use an email
   controlled by the organization.
2. Copy the user's Firebase Authentication UID.
3. In **Firestore Database**, create `users/{adminUid}` using that exact UID
   as the document ID, with at least:

   ```text
   name: Admin
   email: admin@example.com
   role: admin
   ```

The app checks that the email/password authentication succeeds and that this
profile's `role` is exactly `admin`. An ordinary account is signed out and
denied access. Sign in from the **Admin sign in** link on the login screen;
the general login screen also routes a valid admin profile to the dashboard.

## Admin workflow

- **Contact Change Approvals:** open pending Elder or Family requests, check
  the account and requested phone/email details, then approve or reject.
- **User Account Management:** search by name, profile email, or phone; filter
  by account type; edit display name/profile email; send password reset links.
- **Family–Elder Connection:** connect or disconnect Family accounts using an
  Elder's public Elder ID.
- Review the dashboard's live Elder, Family, linked, unlinked, and pending
  contact-change totals.

## Family/Elder profiles

Registered accounts are stored in:

`users/{uid}`

with fields such as:

```text
name
email
role: family | elder | admin
linkedElderId: <elder uid>   // family accounts after Admin connects them
```

The Firebase Authentication sign-in email is stored separately in
`userPrivate/{uid}.authEmail`; profile email edits do not change sign-in
credentials. Access to this private document is limited to that user and Admin.

The Family Dashboard resolves its elder from `linkedElderId`.

Phone and email change requests are stored in `phoneChangeRequests`. Family
members submit changed contact details for Admin approval; an approval updates
the CareBridge profile only, not Firebase Authentication credentials. Deploy
the updated Firestore rules before using contact-change approvals:

```powershell
firebase deploy --only firestore:rules
```
