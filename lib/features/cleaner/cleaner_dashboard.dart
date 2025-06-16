import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/booking.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/custom_card.dart';
import '../../main.dart'; // Import AuthWrapper

class CleanerDashboard extends StatefulWidget {
  const CleanerDashboard({super.key});

  @override
  State<CleanerDashboard> createState() => _CleanerDashboardState();
}

class _CleanerDashboardState extends State<CleanerDashboard> {
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final currentUser = auth.getCurrentUser();

    if (currentUser == null) {
      if (!mounted) return;
      _goToHome();
      return;
    }

    final allBookings = await storage.getBookings();
    setState(() {
      _bookings = allBookings
          .where(
            (booking) =>
                booking.cleanerId == currentUser.id &&
                booking.status != BookingStatus.completed &&
                booking.dateTime.year == DateTime.now().year &&
                booking.dateTime.month == DateTime.now().month &&
                booking.dateTime.day == DateTime.now().day,
          )
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthWrapper(),
      ),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    _goToHome();
  }

  Future<void> _markAsCompleted(Booking booking) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final updatedBooking = Booking(
      id: booking.id,
      serviceId: booking.serviceId,
      dateTime: booking.dateTime,
      address: booking.address,
      contactName: booking.contactName,
      contactPhone: booking.contactPhone,
      cleanerId: booking.cleanerId,
      status: BookingStatus.completed,
    );
    await storage.saveBooking(updatedBooking);
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goToHome,
            tooltip: 'Go to Home',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _bookings.isEmpty
          ? const Center(
              child: Text('No tasks for today', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time: ${booking.dateTime.hour}:${booking.dateTime.minute.toString().padLeft(2, '0')}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Customer: ${booking.contactName}'),
                                  const SizedBox(height: 4),
                                  Text('Phone: ${booking.contactPhone}'),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () => _markAsCompleted(booking),
                              child: const Text('Mark Complete'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Address:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(booking.address),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
