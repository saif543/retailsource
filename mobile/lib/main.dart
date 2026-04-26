import 'package:flutter/material.dart';
import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/shop_owner_register_screen.dart';
import 'screens/auth/stockholder_register_screen.dart';
import 'screens/shop_owner/dashboard_screen.dart';
import 'screens/stockholder/dashboard_screen.dart';
import 'screens/shared/admin_dashboard_screen.dart';

void main() {
  runApp(const SupplyLinkApp());
}

class SupplyLinkApp extends StatelessWidget {
  const SupplyLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SupplyLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.bgWhite,
      ),
      home: const SplashRouter(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register-shop': (context) => const ShopOwnerRegisterScreen(),
        '/register-stock': (context) => const StockholderRegisterScreen(),
        '/shop-dashboard': (context) => const ShopOwnerDashboard(),
        '/stock-dashboard': (context) => const StockholderDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

/// Checks if user is already logged in and routes accordingly
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final user = await AuthService.getUser();
      final role = user?['role'];

      if (role == 'shop_owner') {
        Navigator.pushReplacementNamed(context, '/shop-dashboard');
      } else if (role == 'stockholder') {
        Navigator.pushReplacementNamed(context, '/stock-dashboard');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
