// lib/screens/auth/shop_owner_register_screen.dart
//
// Registration form for Shop Owners.
// Collects: full name, phone, email, shop name, category,
//           address, district, area, password.
// Submits to POST /api/auth/register

import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'login_screen.dart';

class ShopOwnerRegisterScreen extends StatefulWidget {
  const ShopOwnerRegisterScreen({super.key});

  @override
  State<ShopOwnerRegisterScreen> createState() =>
      _ShopOwnerRegisterScreenState();
}

class _ShopOwnerRegisterScreenState extends State<ShopOwnerRegisterScreen> {
  // One controller per text field
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedCategory;
  String? _selectedDistrict;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  // Options for dropdowns
  final List<String> _categories = [
    'Grocery',
    'Pharmacy',
    'Stationery',
    'Hardware',
    'Clothing',
    'Electronics',
    'Food & Beverage',
    'Other',
  ];

  final List<String> _districts = [
    'Dhaka',
    'Chattogram',
    'Sylhet',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Mymensingh',
    'Rangpur',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Basic validation
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _shopNameController.text.isEmpty ||
        _selectedCategory == null ||
        _addressController.text.isEmpty ||
        _selectedDistrict == null ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms of Service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Replace with real API call
    // await AuthService.register({
    //   'name': _nameController.text,
    //   'phone': _phoneController.text,
    //   'email': _emailController.text,
    //   'shop_name': _shopNameController.text,
    //   'category': _selectedCategory,
    //   'address': _addressController.text,
    //   'district': _selectedDistrict,
    //   'area': _areaController.text,
    //   'password': _passwordController.text,
    //   'role': 'shop_owner',
    // });

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
          backgroundColor: AppColors.supplierGreen,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue header ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Shop Owner Registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Create your shop account',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.storefront,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in your details to get started',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Scrollable form ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Personal Information card
                  _SectionCard(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    children: [
                      _FormField(
                        label: 'Full Name',
                        required: true,
                        child: _buildTextField(
                            _nameController, 'Enter your full name'),
                      ),
                      _FormField(
                        label: 'Phone Number',
                        required: true,
                        child: _buildTextField(
                          _phoneController,
                          '+880 1XXX XXXXXX',
                          type: TextInputType.phone,
                        ),
                      ),
                      _FormField(
                        label: 'Email Address',
                        child: _buildTextField(
                          _emailController,
                          'Enter your email (optional)',
                          type: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Shop Information card
                  _SectionCard(
                    icon: Icons.storefront_outlined,
                    title: 'Shop Information',
                    children: [
                      _FormField(
                        label: 'Shop Name',
                        required: true,
                        child: _buildTextField(
                            _shopNameController, 'Enter your shop name'),
                      ),
                      _FormField(
                        label: 'Shop Category',
                        required: true,
                        child: _buildDropdown(
                          value: _selectedCategory,
                          hint: 'Select shop category',
                          items: _categories,
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                      ),
                      _FormField(
                        label: 'Shop Address',
                        required: true,
                        child: TextField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                              'Enter your complete shop address'),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              label: 'District',
                              required: true,
                              child: _buildDropdown(
                                value: _selectedDistrict,
                                hint: 'Select district',
                                items: _districts,
                                onChanged: (v) =>
                                    setState(() => _selectedDistrict = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              label: 'Area/Thana',
                              required: true,
                              child: _buildTextField(
                                  _areaController, 'Enter area name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Use Current Location button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: use geolocator package to fill address
                          },
                          icon: const Icon(Icons.location_on_outlined,
                              color: AppColors.primary),
                          label: const Text(
                            'Use Current Location',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Security card
                  _SectionCard(
                    icon: Icons.lock_outline,
                    title: 'Security',
                    children: [
                      _FormField(
                        label: 'Password',
                        required: true,
                        sublabel: 'At least 6 characters',
                        child: _buildPasswordField(
                          _passwordController,
                          'Create a strong password',
                          _obscurePassword,
                          () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      _FormField(
                        label: 'Confirm Password',
                        required: true,
                        child: _buildPasswordField(
                          _confirmPasswordController,
                          'Confirm your password',
                          _obscureConfirm,
                          () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Terms checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleRegister,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(
                        _isLoading ? 'Creating...' : 'Create Shop Account',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // What happens next info box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.supplierGreen, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'What happens next?',
                              style: TextStyle(
                                color: AppColors.supplierGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• We\'ll verify your phone number with OTP\n'
                          '• You can start posting product demands immediately\n'
                          '• Get matched with nearby suppliers automatically',
                          style: TextStyle(
                              color: Color(0xFF2E7D32), fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign In link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(
                              color: AppColors.textGrey, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
        ],
      ),
    );
  }

  // ── Field builders ─────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  Widget _buildTextField(TextEditingController c, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
        controller: c,
        keyboardType: type,
        decoration: _inputDecoration(hint));
  }

  Widget _buildPasswordField(TextEditingController c, String hint, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textGrey,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ── Form field with label ─────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final String? sublabel;
  final Widget child;

  const _FormField({
    required this.label,
    this.required = false,
    this.sublabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                      text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(sublabel!,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
