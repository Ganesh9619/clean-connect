import 'cleaning_package.dart';
import 'condo.dart';

enum BookingStatus { requested, accepted, completed, cancelled }

class Booking {
  const Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.condo,
    required this.package,
    required this.scheduledAt,
    required this.notes,
    required this.createdAt,
    this.status = BookingStatus.requested,
    this.cleanerId,
    this.cleanerName,
    this.acceptedAt,
    this.completedAt,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final Condo condo;
  final CleaningPackage package;
  final DateTime scheduledAt;
  final String notes;
  final DateTime createdAt;
  final BookingStatus status;
  final String? cleanerId;
  final String? cleanerName;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  int get price => package.priceFor(condo.bedrooms);
  int get cleanerPayout => package.cleanerPayoutFor(condo.bedrooms);

  bool get isOpen => status == BookingStatus.requested;

  Booking copyWith({
    BookingStatus? status,
    String? cleanerId,
    String? cleanerName,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return Booking(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      condo: condo,
      package: package,
      scheduledAt: scheduledAt,
      notes: notes,
      createdAt: createdAt,
      status: status ?? this.status,
      cleanerId: cleanerId ?? this.cleanerId,
      cleanerName: cleanerName ?? this.cleanerName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
