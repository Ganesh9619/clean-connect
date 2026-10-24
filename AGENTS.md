# AGENTS.md

Context for any coding agent or new chat working in this repository.

## What this is

SparkNest is a Flutter demo of a two-sided cleaning marketplace: clients book condo cleans, available cleaners are notified, and the first cleaner to accept gets the job.

## Decisions already made

- Flutter, one codebase for iOS, Android and web. State with `provider` (`ChangeNotifier`). Material 3. Only `provider` and `intl` as dependencies.
- Screens talk only to `BookingRepository` (`lib/data/booking_repository.dart`). The demo uses `InMemoryBookingRepository`. Do not put backend logic in widgets.
- Production backend is Firebase: Auth, Firestore, a Cloud Function for the atomic accept (transaction that only writes while status is `requested`), and FCM for notifications. It will be a new `FirestoreBookingRepository` behind the same interface.
- Tower, unit and access notes are hidden from cleaners until they accept.
- Price = package base price for up to 2 bedrooms, plus a per-bedroom charge above that. Cleaner payout is 80% of the price.
- Production scope when the in-memory store is replaced: sign-up for both roles, condo profile, packages editable without an app update, booking, push to cleaners, single-accept lock, statuses (requested, accepted, completed, cancelled), TestFlight and Play internal testing. Out of scope: payments and payouts, chat, ratings, recurring bookings, live GPS, web admin.

## Layout

- `lib/models/` data classes
- `lib/data/` repository interface, in-memory backend, sample data
- `lib/session/` per-device session (user, condo, availability, banner)
- `lib/features/{auth,client,cleaner,demo}/` screens
- `test/booking_repository_test.dart` backend rules, including the accept race

## Commands

- `flutter pub get`
- `flutter analyze` must report no issues
- `flutter test` must pass
- `flutter run -d chrome` (or `-d ios`, `-d android`)
- `flutter build web --release` produces the static demo in `build/web`

## Next steps

1. Firebase: `flutterfire configure`, add `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`; implement `FirestoreBookingRepository`; add the accept Cloud Function; switch `DemoShell` for a single-user app shell in production builds.
2. Real push notifications through FCM, triggered by Cloud Functions on booking create and status change.
3. App icons, splash screen, and store builds (Codemagic for iOS if no Mac is available).
