import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/auth_service.dart';
import 'core/models/user.dart';
import 'features/services/services_page.dart';
import 'features/booking/bookings_page.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/cleaner/cleaner_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final authService = AuthService(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storageService),
        Provider.value(value: authService),
      ],
      child: const CleanProApp(),
    ),
  );
}

class CleanProApp extends StatelessWidget {
  const CleanProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanPro',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final currentUser = authService.getCurrentUser();

        if (currentUser == null) {
          return const HomePage();
        }

        // Redirect to appropriate dashboard based on role
        switch (currentUser.role) {
          case UserRole.admin:
            return const AdminDashboard();
          case UserRole.cleaner:
            return const CleanerDashboard();
          default:
            return const HomePage();
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final currentUser = authService.getCurrentUser();

        return Scaffold(
          appBar: AppBar(
            title: const Text('CleanPro'),
            actions: [
              if (currentUser != null)
                IconButton(
                  icon: const Icon(Icons.dashboard),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => currentUser.role == UserRole.admin
                            ? const AdminDashboard()
                            : const CleanerDashboard(),
                      ),
                      (route) => false,
                    );
                  },
                  tooltip: 'Go to Dashboard',
                )
              else
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
            ],
          ),
          body: const ServicesPage(),
        );
      },
    );
  }
}
