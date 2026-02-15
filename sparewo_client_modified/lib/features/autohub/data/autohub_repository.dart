// lib/features/autohub/data/autohub_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:uuid/uuid.dart';

class AutoHubRepository {
  final FirebaseFirestore _firestore;

  AutoHubRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('service_bookings');

  Future<ServiceBooking> createBooking(ServiceBooking booking) async {
    // Generate a booking number if one wasn't provided (though provider usually handles this)
    final bookingNumber =
        booking.bookingNumber ??
        'SW-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${const Uuid().v4().substring(0, 4).toUpperCase()}';

    final bookingWithMeta = booking.copyWith(
      bookingNumber: bookingNumber,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = _bookings.doc(booking.id!.isNotEmpty ? booking.id : null);

    // Ensure we use the ID from the doc ref if it was auto-generated
    final finalBooking = bookingWithMeta.copyWith(id: docRef.id);

    await docRef.set(finalBooking.toJson());

    return finalBooking;
  }

  Future<List<TimeSlot>> getAvailableTimeSlots(DateTime date) async {
    // Returns the static list of available slots as per the original app logic.
    return TimeSlot.getAvailableSlots();
  }

  Future<ServiceBooking?> getBookingById(String bookingId) async {
    final doc = await _bookings.doc(bookingId).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data();
    if (data == null) return null;
    return ServiceBooking.fromJson(data).copyWith(id: doc.id);
  }

  Stream<List<ServiceBooking>> getUserBookings(String userId) {
    return _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ServiceBooking.fromJson(data).copyWith(id: doc.id);
          }).toList();
        });
  }
}
