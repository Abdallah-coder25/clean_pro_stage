import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/service.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../booking/booking_form_page.dart';
import '../admin/admin_dashboard.dart';
import '../cleaner/cleaner_dashboard.dart';
import '../auth/login_page.dart';
import '../../core/widgets/custom_card.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<CleaningService> _services = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final services = await storage.getServices();
    setState(() {
      _services = services;
      if (_services.isEmpty) {
        _addDefaultServices();
      }
    });
  }

  Future<void> _addDefaultServices() async {
    final defaultServices = [
      CleaningService(
        id: '1',
        name: 'Standard Home Cleaning',
        description:
            'Basic dusting, vacuuming, mopping, and surface cleaning for all rooms.',
        price: 80.0,
        estimatedDuration: const Duration(hours: 2),
      ),
      CleaningService(
        id: '2',
        name: 'Deep Cleaning',
        description:
            'Intensive cleaning of hard-to-reach areas, behind furniture, and detailed scrubbing.',
        price: 150.0,
        estimatedDuration: const Duration(hours: 4),
      ),
      CleaningService(
        id: '3',
        name: 'Move-In/Move-Out Cleaning',
        description:
            'Full cleaning of empty homes, including inside cabinets, fridge, oven, and baseboards.',
        price: 200.0,
        estimatedDuration: const Duration(hours: 5),
      ),
      CleaningService(
        id: '4',
        name: 'Post-Construction Cleaning',
        description:
            'Removal of dust, paint spots, and debris after renovation or construction work.',
        price: 250.0,
        estimatedDuration: const Duration(hours: 6),
      ),
      CleaningService(
        id: '5',
        name: 'Office Cleaning',
        description:
            'Regular cleaning of office desks, floors, trash bins, and restrooms.',
        price: 120.0,
        estimatedDuration: const Duration(hours: 3),
      ),
      CleaningService(
        id: '6',
        name: 'Window Cleaning',
        description:
            'Interior and exterior window washing for homes or offices (ground level only).',
        price: 100.0,
        estimatedDuration: const Duration(hours: 2),
      ),
      CleaningService(
        id: '7',
        name: 'Carpet Cleaning',
        description:
            'Steam or dry cleaning of carpets to remove stains and dirt.',
        price: 120.0,
        estimatedDuration: const Duration(hours: 3),
      ),
      CleaningService(
        id: '8',
        name: 'Upholstery Cleaning',
        description: 'Cleaning of sofas, chairs, and fabric furniture.',
        price: 100.0,
        estimatedDuration: const Duration(hours: 2),
      ),
      CleaningService(
        id: '9',
        name: 'Fridge & Oven Cleaning',
        description:
            'Detailed scrubbing of interior and exterior surfaces of kitchen appliances.',
        price: 80.0,
        estimatedDuration: const Duration(minutes: 90),
      ),
      CleaningService(
        id: '10',
        name: 'Bathroom Deep Clean',
        description:
            'Disinfecting and scrubbing of sinks, toilets, showers, tiles, and mirrors.',
        price: 90.0,
        estimatedDuration: const Duration(hours: 2),
      ),
      CleaningService(
        id: '11',
        name: 'Laundry & Folding',
        description:
            'Washing, drying, folding clothes (requires in-home laundry setup).',
        price: 60.0,
        estimatedDuration: const Duration(hours: 2),
      ),
      CleaningService(
        id: '12',
        name: 'Green/Eco-Friendly Cleaning',
        description: 'Cleaning using eco-safe and non-toxic products only.',
        price: 100.0,
        estimatedDuration: const Duration(hours: 3),
      ),
      CleaningService(
        id: '13',
        name: 'Pet Hair Removal',
        description:
            'Special vacuuming and cleaning focused on removing pet hair from furniture and floors.',
        price: 90.0,
        estimatedDuration: const Duration(hours: 2),
      ),
      CleaningService(
        id: '14',
        name: 'After-Party Cleaning',
        description:
            'Trash removal, dishwashing, floor cleaning, and furniture reset after events.',
        price: 150.0,
        estimatedDuration: const Duration(hours: 4),
      ),
    ];

    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.saveServices(defaultServices);
    setState(() {
      _services = defaultServices;
    });
  }

  List<CleaningService> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((service) {
      return service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  void _navigateToDashboard(BuildContext context, User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => user.role == UserRole.admin
            ? const AdminDashboard()
            : const CleanerDashboard(),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToBooking(BuildContext context, CleaningService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFormPage(service: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final currentUser = authService.getCurrentUser();

        return Scaffold(
          appBar: AppBar(
            title: const Text('CleanPro Services'),
            actions: [
              if (currentUser != null)
                IconButton(
                  icon: const Icon(Icons.dashboard),
                  onPressed: () => _navigateToDashboard(context, currentUser),
                  tooltip: 'Go to Dashboard',
                )
              else
                TextButton.icon(
                  onPressed: () => _navigateToLogin(context),
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: _services.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _services
                            .where((service) => service.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .length,
                        itemBuilder: (context, index) {
                          final filteredServices = _services
                              .where((service) => service.name
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                              .toList();
                          final service = filteredServices[index];
                          return CustomCard(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookingFormPage(service: service),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            service.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ),
                                        Text(
                                          '\$${service.price.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color:
                                                    Theme.of(context).primaryColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(service.description),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Estimated time: ${service.estimatedDuration.inMinutes} minutes',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BookingFormPage(service: service),
                                            ),
                                          );
                                        },
                                        child: const Text('Book Now'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
