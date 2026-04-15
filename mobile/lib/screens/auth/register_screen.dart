import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = 'shop_owner';
  String _selectedArea = 'Mirpur';
  String _selectedDistrict = 'Dhaka';
  String _selectedCategory = 'Grocery';
  List<String> _selectedCategories = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _areas = [
    'Mirpur',
    'Dhanmondi',
    'Gulshan',
    'Uttara',
    'Mohammadpur',
    'Banani',
    'Motijheel',
    'Farmgate',
  ];

  final List<String> _districts = [
    'Dhaka',
    'Chittagong',
    'Rajshahi',
    'Khulna',
    'Sylhet',
    'Rangpur',
    'Barisal',
    'Mymensingh',
  ];

  final List<String> _categories = [
    'Grocery',
    'Pharmacy',
    'Stationary',
    'Hardware',
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'stockholder' && _selectedCategories.isEmpty) {
      setState(() => _error = 'Select at least one product category');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> result;

      if (_selectedRole == 'shop_owner') {
        result = await AuthService.registerShopOwner(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          shopName: _shopNameController.text.trim(),
          shopCategory: _selectedCategory,
          shopAddress: _addressController.text.trim(),
          district: _selectedDistrict,
          area: _selectedArea,
          email: _emailController.text.trim(),
        );
      } else {
        result = await AuthService.registerStockholder(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          companyName: _shopNameController.text.trim(),
          categories: _selectedCategories,
          warehouseAddress: _addressController.text.trim(),
          district: _selectedDistrict,
          area: _selectedArea,
          email: _emailController.text.trim(),
        );
      }

      if (!mounted) return;

      if (result['statusCode'] == 201) {
        final role = result['user']['role'];
        if (role == 'shop_owner') {
          Navigator.pushReplacementNamed(context, '/shop-dashboard');
        } else if (role == 'stockholder') {
          Navigator.pushReplacementNamed(context, '/stock-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        }
      } else {
        setState(() => _error = result['error'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Get started in less than a minute',
                style: TextStyle(fontSize: 16, color: AppColors.textGrey),
              ),
              const SizedBox(height: 30),

              // Error
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Role selector
              const Text(
                'I am a...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRole = 'shop_owner'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'shop_owner'
                              ? AppColors.primaryBlue
                              : AppColors.cardGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Shop Owner',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedRole == 'shop_owner'
                                  ? Colors.white
                                  : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRole = 'stockholder'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'stockholder'
                              ? AppColors.primaryGreen
                              : AppColors.cardGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Supplier',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedRole == 'stockholder'
                                  ? Colors.white
                                  : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outlined),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '01XXXXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 14),

              // Email (optional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Shop/Company name
              TextFormField(
                controller: _shopNameController,
                decoration: InputDecoration(
                  labelText: _selectedRole == 'shop_owner'
                      ? 'Shop Name'
                      : 'Company Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.store_outlined),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 14),

              // Shop Category dropdown (shop_owner only)
              if (_selectedRole == 'shop_owner') ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Shop Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 14),
              ],

              // Product Categories checkboxes (stockholder only)
              if (_selectedRole == 'stockholder') ...[
                const Text(
                  'Product Categories *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 0,
                  children: _categories.map((cat) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 40,
                      child: CheckboxListTile(
                        title: Text(cat, style: const TextStyle(fontSize: 14)),
                        value: _selectedCategories.contains(cat),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],

              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _selectedRole == 'shop_owner'
                      ? 'Shop Address'
                      : 'Warehouse Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 14),

              // District & Area row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _districts
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDistrict = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedArea,
                      decoration: InputDecoration(
                        labelText: 'Area',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _areas
                          .map((a) =>
                              DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedArea = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter password';
                  if (val.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Confirm password';
                  if (val != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole == 'shop_owner'
                        ? AppColors.primaryBlue
                        : AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
