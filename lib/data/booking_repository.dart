import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/cleaning_package.dart';
import '../models/condo.dart';

enum AcceptOutcome { accepted, alreadyTaken, unavailable }

class AcceptResult {
  const AcceptResult(this.outcome, this.booking);

  final AcceptOutcome outcome;
  final Booking? booking;
}

class BookingException implements Exception {
  const BookingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Everything the app needs from a backend. Screens only talk to this
/// interface, so the in-memory demo backend and a Firestore backend are
/// interchangeable.
abstract class BookingRepository {
  /// Packages live on the backend so prices can change without an app update.
  Future<List<CleaningPackage>> fetchPackages();

  /// Emits the current bookings immediately, then again on every change.
  Stream<List<Booking>> watchBookings();

  Future<Booking> createBooking({
    required AppUser client,
    required Condo condo,
    required CleaningPackage package,
    required DateTime scheduledAt,
    required String notes,
  });

  /// Must be atomic: when several cleaners accept the same booking at once,
  /// exactly one gets [AcceptOutcome.accepted]. In Firestore this is a
  /// transaction (or a Cloud Function) that only writes while the booking is
  /// still `requested`.
  Future<AcceptResult> acceptBooking({
    required String bookingId,
    required AppUser cleaner,
  });

  Future<Booking> completeBooking({
    required String bookingId,
    required AppUser cleaner,
  });

  Future<Booking> cancelBooking({
    required String bookingId,
    required AppUser client,
  });
}
