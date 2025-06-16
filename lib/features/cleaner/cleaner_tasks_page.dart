import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/service.dart';
import '../../core/models/booking.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/custom_card.dart';

class CleanerTasksPage extends StatefulWidget {
  const CleanerTasksPage({super.key});

  @override
  State<CleanerTasksPage> createState() => _CleanerTasksPageState();
}

class _CleanerTasksPageState extends State<CleanerTasksPage> {
  List<Booking> _tasks = [];
  List<CleaningService> _services = [];
  String _filter = 'all'; // all, incomplete, completed
  String _sort = 'time'; // time, location

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.getCurrentUser();

    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final bookings = await storage.getBookings();
    final services = await storage.getServices();

    setState(() {
      final now = DateTime.now();
      _tasks = bookings.where((booking) {
        if (booking.cleanerId != currentUser.id) return false;

        if (_filter == 'completed' &&
            booking.status != BookingStatus.completed) {
          return false;
        }
        if (_filter == 'incomplete' &&
            booking.status == BookingStatus.completed) {
          return false;
        }

        return booking.dateTime.year == now.year &&
            booking.dateTime.month == now.month &&
            booking.dateTime.day == now.day;
      }).toList();

      _services = services;
      _sortTasks();
    });
  }

  void _sortTasks() {
    setState(() {
      if (_sort == 'time') {
        _tasks.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } else {
        _tasks.sort((a, b) => a.address.compareTo(b.address));
      }
    });
  }

  List<Booking> get _filteredTasks {
    switch (_filter) {
      case 'incomplete':
        return _tasks
            .where((task) => task.status == BookingStatus.pending)
            .toList();
      case 'completed':
        return _tasks
            .where((task) => task.status == BookingStatus.completed)
            .toList();
      default:
        return _tasks;
    }
  }

  String _getServiceName(String serviceId) {
    final service = _services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => CleaningService(
        id: '',
        name: 'Unknown Service',
        description: '',
        price: 0,
        estimatedDuration: const Duration(hours: 0),
      ),
    );
    return service.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sort = value;
                _sortTasks();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'time', child: Text('Sort by Time')),
              const PopupMenuItem(
                value: 'location',
                child: Text('Sort by Location'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Show All')),
              const PopupMenuItem(
                value: 'incomplete',
                child: Text('Show Incomplete'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Show Completed'),
              ),
            ],
          ),
        ],
      ),
      body: _filteredTasks.isEmpty
          ? const Center(child: Text('No tasks for today'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TaskCard(
                    task: task,
                    serviceName: _getServiceName(task.serviceId),
                    onStatusChanged: (status) async {
                      final storage = Provider.of<StorageService>(
                        context,
                        listen: false,
                      );

                      // Update the booking with a cleanerId when completing
                      if (status == BookingStatus.completed) {
                        final updatedBooking = Booking(
                          id: task.id,
                          serviceId: task.serviceId,
                          dateTime: task.dateTime,
                          address: task.address,
                          contactName: task.contactName,
                          contactPhone: task.contactPhone,
                          status: status,
                          cleanerId: 'cleaner1', // Assign a dummy cleanerId
                        );
                        await storage.saveBooking(updatedBooking);
                      } else {
                        await storage.updateBookingStatus(task.id, status);
                      }
                      _loadTasks();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Booking task;
  final String serviceName;
  final Function(BookingStatus) onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.serviceName,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return CustomCard(
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
                      timeFormat.format(task.dateTime),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              if (task.status == BookingStatus.pending)
                TextButton.icon(
                  onPressed: () => onStatusChanged(BookingStatus.completed),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark Complete'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on),
            title: Text(task.address),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person),
            title: Text(task.contactName),
            subtitle: Text(task.contactPhone),
          ),
        ],
      ),
    );
  }
}
