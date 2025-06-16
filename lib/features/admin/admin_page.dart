import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/service.dart';
import '../../core/models/booking.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/custom_card.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _serviceController = TextEditingController();
  Map<String, List<String>> _cleanerStats = {};
  String? _selectedService;
  List<CleaningService> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final services = await storage.getServices();
    final bookings = await storage.getBookings();

    final stats = <String, List<String>>{};

    for (final booking in bookings.where(
      (b) => b.status == BookingStatus.completed,
    )) {
      if (!stats.containsKey(booking.serviceId)) {
        stats[booking.serviceId] = [];
      }
      if (booking.cleanerId != null) {
        stats[booking.serviceId]!.add(booking.cleanerId!);
      }
    }

    setState(() {
      _services = services;
      _cleanerStats = stats;
    });
  }

  String? _getBestCleaner(String serviceId) {
    if (!_cleanerStats.containsKey(serviceId) ||
        _cleanerStats[serviceId]!.isEmpty) {
      return null;
    }

    final cleanerCounts = <String, int>{};
    for (final cleanerId in _cleanerStats[serviceId]!) {
      cleanerCounts[cleanerId] = (cleanerCounts[cleanerId] ?? 0) + 1;
    }

    String? bestCleaner;
    int maxCount = 0;

    cleanerCounts.forEach((cleanerId, count) {
      if (count > maxCount) {
        maxCount = count;
        bestCleaner = cleanerId;
      }
    });

    return bestCleaner;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Best Cleaner',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    decoration: const InputDecoration(
                      labelText: 'Select Service',
                      border: OutlineInputBorder(),
                    ),
                    items: _services.map((service) {
                      return DropdownMenuItem(
                        value: service.id,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedService = value);
                      if (value != null) {
                        final bestCleaner = _getBestCleaner(value);
                        if (bestCleaner != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Best cleaner ID: $bestCleaner'),
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No data available for this service',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Service Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                final completedTasks = _cleanerStats[service.id]?.length ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completed Tasks: $completedTasks',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (completedTasks > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Best Cleaner ID: ${_getBestCleaner(service.id)}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
