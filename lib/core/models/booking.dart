enum BookingStatus { pending, completed, cancelled }

class Booking {
  final String id;
  final String serviceId;
  final DateTime dateTime;
  final String address;
  final String contactName;
  final String contactPhone;
  BookingStatus status;
  final String? cleanerId;

  Booking({
    required this.id,
    required this.serviceId,
    required this.dateTime,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    this.status = BookingStatus.pending,
    this.cleanerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'dateTime': dateTime.toIso8601String(),
      'address': address,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'status': status.toString(),
      'cleanerId': cleanerId,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      serviceId: json['serviceId'],
      dateTime: DateTime.parse(json['dateTime']),
      address: json['address'],
      contactName: json['contactName'],
      contactPhone: json['contactPhone'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      cleanerId: json['cleanerId'],
    );
  }
}
