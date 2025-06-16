import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/booking.dart';
import '../../core/models/service.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/custom_card.dart';
import '../../main.dart'; // Import AuthWrapper
import 'service_management_dialog.dart';
import 'booking_optimizer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedTab = 'bookings';
  List<Booking> _bookings = [];
  List<CleaningService> _services = [];
  List<User> _cleaners = [];
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedServiceId;
  BookingStatus? _selectedStatus;
  String _sortBy = 'date'; // 'date', 'status', 'cleaner'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final bookings = await storage.getBookings();
    final services = await storage.getServices();
    final cleaners = auth.getCleaners();

    setState(() {
      _bookings = bookings;
      _services = services;
      _cleaners = cleaners;
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

  void _goToServices() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _assignCleaner(Booking booking, String cleanerId) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final updatedBooking = Booking(
      id: booking.id,
      serviceId: booking.serviceId,
      dateTime: booking.dateTime,
      address: booking.address,
      contactName: booking.contactName,
      contactPhone: booking.contactPhone,
      status: booking.status,
      cleanerId: cleanerId,
    );
    await storage.saveBooking(updatedBooking);
    _loadData();
  }

  Future<void> _handleServiceAction(CleaningService? service) async {
    final result = await showDialog<CleaningService>(
      context: context,
      builder: (context) => ServiceManagementDialog(service: service),
    );

    if (result == null) return;

    final storage = Provider.of<StorageService>(context, listen: false);
    final services = List<CleaningService>.from(_services);

    if (service == null) {
      // Adding new service
      services.add(result);
    } else {
      // Updating existing service
      final index = services.indexWhere((s) => s.id == service.id);
      services[index] = result;
    }

    await storage.saveServices(services);
    _loadData();
  }

  Widget _buildServicesManagement() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          service.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${service.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${service.estimatedDuration.inMinutes} minutes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleServiceAction(service),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteService(service),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteService(CleaningService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete ${service.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = Provider.of<StorageService>(context, listen: false);
      final services = List<CleaningService>.from(_services);
      services.removeWhere((s) => s.id == service.id);
      await storage.saveServices(services);
      _loadData();
    }
  }

  List<Booking> get filteredBookings {
    return _bookings.where((booking) {
      if (_searchQuery.isNotEmpty &&
          !booking.contactName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) &&
          !booking.address.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_startDate != null && booking.dateTime.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && booking.dateTime.isAfter(_endDate!)) {
        return false;
      }
      if (_selectedServiceId != null &&
          booking.serviceId != _selectedServiceId) {
        return false;
      }
      if (_selectedStatus != null && booking.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      switch (_sortBy) {
        case 'date':
          return a.dateTime.compareTo(b.dateTime);
        case 'status':
          return a.status.index.compareTo(b.status.index);
        case 'cleaner':
          final aName = _cleaners
              .firstWhere(
                (c) => c.id == a.cleanerId,
                orElse: () => User(
                  id: '',
                  username: '',
                  name: '',
                  role: UserRole.cleaner,
                ),
              )
              .name;
          final bName = _cleaners
              .firstWhere(
                (c) => c.id == b.cleanerId,
                orElse: () => User(
                  id: '',
                  username: '',
                  name: '',
                  role: UserRole.cleaner,
                ),
              )
              .name;
          return aName.compareTo(bName);
        default:
          return 0;
      }
    });
  }

  Future<void> _autoAssignUnassignedBookings() async {
    // Get suggestions for all unassigned bookings
    final suggestions = BookingOptimizer.suggestAssignments(
      bookings: _bookings,
      cleaners: _cleaners,
    );

    if (suggestions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unassigned bookings to process')),
      );
      return;
    }

    // Preview the suggestions before applying
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Assignment Suggestions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: suggestions.entries.map((entry) {
                final cleaner = _cleaners.firstWhere((c) => c.id == entry.key);
                final bookings = entry.value;
                return CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleaner.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('${bookings.length} new assignments:'),
                      const SizedBox(height: 4),
                      ...bookings.map((booking) {
                        final service = _services.firstWhere(
                          (s) => s.id == booking.serviceId,
                          orElse: () => CleaningService(
                            id: '',
                            name: 'Unknown Service',
                            description: '',
                            price: 0,
                            estimatedDuration: const Duration(minutes: 60),
                          ),
                        );                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '• ${service.name} at ${booking.dateTime.hour.toString().padLeft(2, '0')}:${booking.dateTime.minute.toString().padLeft(2, '0')} - ${booking.address}',
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Apply Suggestions'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = Provider.of<StorageService>(context, listen: false);

      // Apply all suggestions
      for (final entry in suggestions.entries) {
        final cleanerId = entry.key;
        final bookings = entry.value;

        for (final booking in bookings) {
          final updatedBooking = Booking(
            id: booking.id,
            serviceId: booking.serviceId,
            dateTime: booking.dateTime,
            address: booking.address,
            contactName: booking.contactName,
            contactPhone: booking.contactPhone,
            status: booking.status,
            cleanerId: cleanerId,
          );
          await storage.saveBooking(updatedBooking);
        }
      }

      // Reload data to reflect changes
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully assigned all bookings'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildBookingsList() {
    final hasUnassignedBookings = _bookings.any(
      (b) => b.cleanerId == null || b.cleanerId?.isEmpty == true,
    );

    return Column(
      children: [
        if (hasUnassignedBookings)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _autoAssignUnassignedBookings,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Auto-Assign All Unassigned Bookings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Search bookings',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedServiceId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Services'),
                        ),
                        ..._services.map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedServiceId = value),
                      decoration: const InputDecoration(
                        labelText: 'Filter by Service',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<BookingStatus>(
                      value: _selectedStatus,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        ...BookingStatus.values.map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.name)),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedStatus = value),
                      decoration: const InputDecoration(
                        labelText: 'Filter by Status',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _startDate == null
                            ? 'Start Date'
                            : _startDate!.toLocal().toString().split(' ')[0],
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _endDate == null
                            ? 'End Date'
                            : _endDate!.toLocal().toString().split(' ')[0],
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort by:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ToggleButtons(
                    isSelected: [
                      _sortBy == 'date',
                      _sortBy == 'status',
                      _sortBy == 'cleaner',
                    ],
                    onPressed: (index) {
                      setState(() {
                        _sortBy = index == 0
                            ? 'date'
                            : index == 1
                            ? 'status'
                            : 'cleaner';
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Date'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Status'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Cleaner'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              final service = _services.firstWhere(
                (s) => s.id == booking.serviceId,
                orElse: () => CleaningService(
                  id: '',
                  name: 'Unknown',
                  price: 0.0,
                  description: 'Not found',
                  estimatedDuration: const Duration(minutes: 60),
                ),
              );
              final cleaner = _cleaners.firstWhere(
                (c) => c.id == booking.cleanerId,
                orElse: () => User(
                  id: '',
                  username: '',
                  name: '',
                  role: UserRole.cleaner,
                ),
              );

              return CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _buildStatusChip(booking.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${booking.dateTime.toLocal().toString().split(' ')[0]}',
                    ),
                    Text(
                      'Time: ${booking.dateTime.toLocal().toString().split(' ')[1].substring(0, 5)}',
                    ),
                    Text('Customer: ${booking.contactName}'),
                    Text('Address: ${booking.address}'),
                    Text('Phone: ${booking.contactPhone}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: cleaner.id.isEmpty
                              ? ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCleanerAssignment(booking),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Assign Cleaner'),
                                )
                              : Row(
                                  children: [
                                    const Icon(Icons.person),
                                    const SizedBox(width: 8),
                                    Text('Cleaner: ${cleaner.name}'),
                                  ],
                                ),
                        ),
                        if (cleaner.id.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _showCleanerAssignment(booking),
                            icon: const Icon(Icons.edit),
                            label: const Text('Change'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCleanerOverview() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cleaners.length,
      itemBuilder: (context, index) {
        final cleaner = _cleaners[index];
        final cleanerBookings = _bookings
            .where((b) => b.cleanerId == cleaner.id)
            .toList();
        final completedBookings = cleanerBookings
            .where((b) => b.status == BookingStatus.completed)
            .length;
        final todayBookings = cleanerBookings.where((b) {
          final now = DateTime.now();
          return b.dateTime.year == now.year &&
              b.dateTime.month == now.month &&
              b.dateTime.day == now.day;
        }).length;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cleaner.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Today\'s Tasks'),
                        Text(
                          '$todayBookings',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Total Tasks'),
                        Text(
                          '${cleanerBookings.length}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Completed'),
                        Text(
                          '$completedBookings',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Completion Rate'),
                        Text(
                          cleanerBookings.isEmpty
                              ? '0%'
                              : '${(completedBookings / cleanerBookings.length * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == BookingStatus.completed
            ? Colors.green.withOpacity(0.1)
            : status == BookingStatus.pending
            ? Colors.orange.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == BookingStatus.completed
              ? Colors.green
              : status == BookingStatus.pending
              ? Colors.orange
              : Colors.blue,
        ),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: status == BookingStatus.completed
              ? Colors.green
              : status == BookingStatus.pending
              ? Colors.orange
              : Colors.blue,
        ),
      ),
    );
  }

  Future<void> _showAISuggestions(Booking booking) async {
    final recommendations = BookingOptimizer.recommendCleanersForBooking(
      bookings: _bookings,
      cleaners: _cleaners,
      serviceId: booking.serviceId,
    );

    if (!mounted) return;

    final cleaner = await showDialog<User>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Recommended Cleaners'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              final score = recommendation.score;
              return ListTile(
                title: Text(recommendation.cleaner.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${(recommendation.combinedScore * 100).toStringAsFixed(0)}%',
                    ),
                    Text('Today\'s Tasks: ${score.todayWorkload}'),
                    Text(
                      'Completion Rate: ${(score.completionRate * 100).toStringAsFixed(0)}%',
                    ),
                    Text(
                      'Service Experience: ${(score.serviceExperience * 100).toStringAsFixed(0)}%',
                    ),
                    Text('Rating: ${score.rating.toStringAsFixed(1)} ⭐'),
                  ],
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(context).pop(recommendation.cleaner),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (cleaner != null) {
      await _assignCleaner(booking, cleaner.id);
    }
  }

  Future<void> _showCleanerAssignment(Booking booking) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Cleaner'),
        content: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, 'ai');
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get AI Suggestions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, 'manual');
                },
                icon: const Icon(Icons.list),
                label: const Text('Choose Manually'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result == 'ai') {
      await _showAISuggestions(booking);
    } else {
      final cleaner = await showDialog<User>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Cleaner'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _cleaners.length,
              itemBuilder: (context, index) {
                final cleaner = _cleaners[index];
                final cleanerBookings = _bookings
                    .where(
                      (b) =>
                          b.cleanerId == cleaner.id &&
                          b.status != BookingStatus.completed,
                    )
                    .length;
                return ListTile(
                  title: Text(cleaner.name),
                  subtitle: Text('Current Tasks: $cleanerBookings'),
                  onTap: () => Navigator.of(context).pop(cleaner),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (cleaner != null) {
        await _assignCleaner(booking, cleaner.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTab == 'bookings'
            ? 'Bookings Management'
            : _selectedTab == 'services'
                ? 'Services Management'
                : 'Cleaner Overview'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: _goToServices,
          tooltip: 'Go to Services',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      'bookings',
                      'Bookings',
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'services',
                      'Services',
                      Icons.cleaning_services,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'cleaners',
                      'Cleaners',
                      Icons.people,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedTab == 'bookings'
                ? _buildBookingsList()
                : _selectedTab == 'services'
                ? _buildServicesManagement()
                : _buildCleanerOverview(),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 'services'
          ? FloatingActionButton(
              onPressed: () => _handleServiceAction(null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
