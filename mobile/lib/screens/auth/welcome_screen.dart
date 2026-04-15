// lib/screens/auth/welcome_screen.dart
//
// This is the FIRST screen users see when they open the app.
// It has two buttons: Shop Owner and Supplier/Stockholder.
// Tapping a button navigates to that role's registration screen.

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'shop_owner_register_screen.dart';
import 'stockholder_register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Logo icon ────────────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: Colors.white,
                  size: 44,
                ),
              ),

              const SizedBox(height: 32),

              // ── Headline ─────────────────────────────────────────────────
              const Text(
                'Welcome to\nRetailSource',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // ── Subtitle ─────────────────────────────────────────────────
              const Text(
                'Connect directly with suppliers and shop\nowners. No middlemen, better prices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // ── Shop Owner button ─────────────────────────────────────────
              _RoleButton(
                label: 'I am a Shop Owner',
                icon: Icons.storefront_outlined,
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShopOwnerRegisterScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Supplier button ───────────────────────────────────────────
              _RoleButton(
                label: 'I am a Supplier/Stockholder',
                icon: Icons.warehouse_outlined,
                color: AppColors.supplierGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StockholderRegisterScreen(),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ── Sign In link ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable role selection button ───────────────────────────────────────────
class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
