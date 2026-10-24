

https://github.com/user-attachments/assets/7321d9eb-d644-4df8-a3a9-865727a21c28



# SparkNest — condo cleaning booking (Flutter demo)

SparkNest connects condo owners with independent cleaners. A client signs up, enters their condo details, picks a cleaning package and submits a booking. Every available cleaner is notified, and the first cleaner to accept gets the job.

This repository is a working demo of that core loop, built with Flutter for iOS, Android and web from one codebase.

![SparkNest demo: client and two cleaners side by side](docs/demo.png)

## Demo




## What the demo shows

**Client**
- Sign up as a client or a cleaner
- Condo profile: building, address, tower, unit, bedrooms, bathrooms, pets, access notes
- Three packages (Standard, Deep Clean, Move In / Move Out), priced by unit size
- Pick a date and start time, add notes, request the booking
- Live status: finding a cleaner → confirmed (with cleaner name) → completed
- Cancel while no cleaner has accepted yet

**Cleaner**
- Availability switch (offline cleaners are not notified)
- Push-style banner when a new job is booked
- Open jobs list with payout, time, building and size. Tower, unit and access notes stay private until the job is accepted
- Accept job: exactly one cleaner wins. Others see "Taken by Maria" and a message if they tapped too late
- My jobs: full address, access notes, client contact, mark completed, earnings

**Demo view**

On a wide screen, one client and two cleaners (Maria and Ana) run side by side against the same backend. On a phone-sized screen, a switcher at the top flips between the three devices. **Reset demo** clears everything.

## Run it

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.47 or newer).

```bash
flutter pub get

# Web (Chrome)
flutter run -d chrome

# iOS simulator (macOS with Xcode)
open -a Simulator
flutter run -d ios

# Android emulator (Android Studio)
flutter run -d android
```

Tip for recording on iOS: an iPad simulator in landscape shows all three phones side by side. On an iPhone simulator, use the Client / Maria / Ana switcher.

Run the tests:

```bash
flutter test
```

Build the static web demo (for Netlify Drop, GitHub Pages or any static host):

```bash
flutter build web --release
# upload build/web
```

## How it is built

```
lib/
  models/           Condo, CleaningPackage, Booking, AppUser
  data/
    booking_repository.dart            backend interface used by every screen
    in_memory_booking_repository.dart  demo backend with simulated latency
    sample_data.dart                   packages, demo cleaners, sample condo
  session/          per-device state: signed-in user, condo, availability, banner
  features/
    auth/           sign up
    client/         condo form, home with packages and bookings, booking screen
    cleaner/        open jobs, accept, my jobs, complete
    demo/           three-device shell, phone frame, push-style banners
test/
  booking_repository_test.dart   accept race, cancel and complete rules, pricing
```

- **State:** `provider` with a `ChangeNotifier` session per device.
- **Backend seam:** screens only depend on `BookingRepository`. The demo uses `InMemoryBookingRepository`, so it runs anywhere with no accounts or keys.
- **Accept rule:** `acceptBooking` checks and writes the booking with no await in between, so concurrent accepts cannot both succeed. A test fires two accepts at once and asserts exactly one wins.

## Production backend (next step)

The demo backend is intentionally in memory. The production version swaps in Firebase behind the same interface:

| Demo | Production |
|---|---|
| `Session.signUp` | Firebase Auth (email or phone) |
| `InMemoryBookingRepository` | `FirestoreBookingRepository` (bookings, condos, packages collections) |
| `acceptBooking` check-and-set | Cloud Function running a Firestore transaction that only writes while status is `requested` |
| In-app banners | Firebase Cloud Messaging, sent by a Cloud Function when a booking is created or changes status |
| `sample_data.dart` packages | `packages` collection, editable without an app release |

iOS builds without a Mac are possible with Codemagic (cloud builds straight to TestFlight).

Out of scope for this demo: payments and cleaner payouts, chat, ratings, recurring bookings, live location, admin dashboard.
