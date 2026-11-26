---
layout: layout.njk
title: Privacy Policy
updated: 2026-11-26
permalink: /privacy.html
---

This policy explains what personal data the Stepstones meditation app (“the app”) processes, why, and what rights you have. It applies to the iOS and Android apps.

## 1. Who is responsible

The data controller is <span class="placeholder">[CONTROLLER NAME]</span>, <span class="placeholder">[POSTAL ADDRESS]</span>, <span class="placeholder">[COUNTRY]</span>.

Contact for privacy questions: <span class="placeholder">[CONTACT EMAIL]</span>.

We have not appointed a data protection officer, as we are not required to.

## 2. Data we process

### Account data

To use the app you sign in with an email address and password, with Google, or with Apple. Firebase Authentication stores your email address, a user ID, your sign-in method and, when you sign in with Google or Apple, the name and email address that provider shares with us. If you use “Hide My Email” with Apple, we only receive a relay address.

### Profile data

Your profile holds your first and last name, email address, sign-up date, app settings and, if you add them, a profile photo and a home city. The photo is stored in Firebase Storage; a small blurred preview code of it is stored with your profile.

### Home city (optional)

You can pick a city for your profile. When you type a city name, the text is sent through our server to the Google Maps Places API to suggest matching cities and to look up the selected city’s coordinates. We store the city and its coordinates with your profile. The app does not use your device’s GPS or precise location.

### Practice data

For each meditation or chanting session we store the session type, start and end time, duration, the timer or chanting settings used and the chants completed. From this we calculate your statistics (streaks, total minutes, milestones). We keep an internal log of statistics changes to protect their integrity.

### “Practicing now” presence

When you start a practice, the app publishes a presence entry so other signed-in users can see that someone is practicing. It contains your name, profile photo preview, the start time and, if you set one, your home city’s coordinates. Other signed-in users of the app can see this entry.

<span class="placeholder">[CONFIRM: whether presence is shown by default or only when the user opts in, and how long entries stay visible.]</span>

### Apple Health and Health Connect

If you allow it, the app writes your completed sessions as “mindful minutes” to Apple Health (iOS) or Health Connect (Android). The app only writes this data; it does not read other health data. We do not send health data from Apple Health or Health Connect to our servers or use it for advertising. You can revoke access at any time in the Health app or in Health Connect settings.

### Usage analytics

We use Google Analytics for Firebase to understand how the app is used, for example sign-ins, sign-outs and screen views. It collects an app instance ID, device and app information, approximate location derived from your IP address, and on Android the advertising ID (and on iOS the AdServices attribution data), which is included by the Firebase Analytics SDK. We link analytics to your user ID. We do not show ads and do not use this data for advertising.

### Crash reports

Firebase Crashlytics collects crash reports with technical information: device model, operating system version, app version, stack traces and an installation ID.

### Remote Config

Firebase Remote Config lets us change app settings without an update. It uses an installation ID to deliver the configuration.

### Donations

The app does not currently process payments or payment data. <span class="placeholder">[UPDATE if a payment provider is added.]</span>

## 3. Why we process it and on what legal basis

| Purpose | Data | Legal basis (GDPR) |
|---|---|---|
| Providing your account and the app’s features (sign-in, profile, session history, statistics) | Account, profile, practice data | Performance of a contract, Art. 6(1)(b) |
| City search and showing nearby practitioners | Home city and coordinates | Consent, Art. 6(1)(a), given by choosing a city; you can remove it at any time |
| Showing that you are practicing | Presence entry | <span class="placeholder">[Art. 6(1)(b) or (a) — depends on whether presence is opt-in]</span> |
| Writing mindful minutes to Apple Health / Health Connect | Session times | Explicit consent, Art. 6(1)(a) and Art. 9(2)(a), given in the system permission dialog |
| Usage analytics | Analytics data | <span class="placeholder">[Consent, Art. 6(1)(a) — the app currently has no consent prompt]</span> |
| Crash reports and app stability | Crash data | Legitimate interest in a working, secure app, Art. 6(1)(f) |
| Protecting statistics and security | Statistics log, auth data | Legitimate interest, Art. 6(1)(f) |

## 4. Who processes your data

We use Google services as our processor: Firebase Authentication, Cloud Firestore, Cloud Storage for Firebase, Cloud Functions, Remote Config, Google Analytics for Firebase, Crashlytics and the Google Maps Places API. Firestore data is stored in the europe-west3 (Frankfurt, Germany) region. Some Firebase services, including Authentication, Analytics and Crashlytics, may process data in the United States. These transfers are covered by Google’s Data Processing Terms, the EU–US Data Privacy Framework and the EU Standard Contractual Clauses.

If you sign in with Apple or Google, the sign-in is also governed by that company’s own privacy policy. Apple Health and Health Connect data stays on your device and in your Apple or Google account under their terms.

We do not sell your data or share it with anyone else, except where required by law.

## 5. How long we keep it

- Account, profile and practice data: until you delete your account.
- Presence entries: <span class="placeholder">[RETENTION PERIOD]</span>.
- Analytics data: <span class="placeholder">[2 / 14 months — set in Firebase Analytics settings]</span>.
- Crash reports: 90 days.
- Backups, if any: <span class="placeholder">[BACKUP RETENTION]</span>.

## 6. Deleting your account

You can delete your account in the app, or ask us by email. See [Delete your account](/delete-account) for the steps and what is deleted.

## 7. Your rights

Under the GDPR you have the right to:

- access your data and get a copy of it;
- correct inaccurate data (you can edit your profile in the app);
- have your data deleted;
- restrict or object to processing based on legitimate interest;
- data portability;
- withdraw consent at any time, without affecting earlier processing.

To use these rights, email <span class="placeholder">[CONTACT EMAIL]</span>. We reply within one month. You can also complain to a data protection authority, in particular in the EU country where you live or work. Our lead authority is <span class="placeholder">[SUPERVISORY AUTHORITY]</span>.

## 8. Children

The app is not meant for children under 16. We do not knowingly collect data from them. <span class="placeholder">[CONFIRM minimum age.]</span>

## 9. Security

Data is encrypted in transit and at rest by Google Cloud. Access rules ensure only you can read and change your own profile and practice data.

## 10. Changes

We will update this page when the app’s data use changes and change the date above. For significant changes we will also tell you in the app.
