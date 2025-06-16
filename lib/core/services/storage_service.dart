import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service.dart';
import '../models/booking.dart';

class StorageService {
  static const String _servicesKey = 'services';
  static const String _bookingsKey = 'bookings';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Services
  Future<List<CleaningService>> getServices() async {
    final String? servicesJson = _prefs.getString(_servicesKey);
    if (servicesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(servicesJson);
    return decoded.map((json) => CleaningService.fromJson(json)).toList();
  }

  Future<void> saveServices(List<CleaningService> services) async {
    final String encoded = jsonEncode(
      services.map((service) => service.toJson()).toList(),
    );
    await _prefs.setString(_servicesKey, encoded);
  }

  // Bookings
  Future<List<Booking>> getBookings() async {
    final String? bookingsJson = _prefs.getString(_bookingsKey);
    if (bookingsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(bookingsJson);
    return decoded.map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> saveBookings(List<Booking> bookings) async {
    final String encoded = jsonEncode(
      bookings.map((booking) => booking.toJson()).toList(),
    );
    await _prefs.setString(_bookingsKey, encoded);
  }

  Future<void> addBooking(Booking booking) async {
    final bookings = await getBookings();
    bookings.add(booking);
    await saveBookings(bookings);
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final bookings = await getBookings();
    final index = bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      bookings[index].status = status;
      await saveBookings(bookings);
    }
  }

  Future<void> saveBooking(Booking booking) async {
    final bookings = await getBookings();
    final index = bookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      bookings[index] = booking;
    } else {
      bookings.add(booking);
    }
    await saveBookings(bookings);
  }
}
