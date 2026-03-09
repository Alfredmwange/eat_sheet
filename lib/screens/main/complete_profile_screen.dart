import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eat_sheet/models/user_model.dart';
import 'package:eat_sheet/providers/user_provider.dart';
import 'package:eat_sheet/services/auth.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalWeightController = TextEditingController();

  // Dropdown values
  String _selectedGender = 'male';
  String _selectedGoal = 'maintain';
  String _selectedActivityLevel = 'moderate';

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      // Create user data
      final userData = User(
        id: currentUser.uid,
        name: _nameController.text.trim(),
        email: currentUser.email ?? '',
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        goalWeight: double.parse(_goalWeightController.text),
        gender: _selectedGender,
        goal: _selectedGoal,
        activityLevel: _selectedActivityLevel,
        dietaryGoals: {}, // Will be calculated later
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateUserData(userData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile completed successfully!')),
          );
          // Navigate back to dashboard to show the main content
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          _showError(userProvider.error ?? 'Failed to save profile');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error saving profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 64,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tell us about yourself',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This information helps us personalize your nutrition tracking experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Age Field
                _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Please enter a valid age (1-120)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Gender Dropdown
                _buildDropdown(
                  label: 'Gender',
                  value: _selectedGender,
                  items: ['male', 'female', 'other'],
                  displayNames: {
                    'male': 'Male',
                    'female': 'Female',
                    'other': 'Other',
                  },
                  icon: Icons.wc,
                  onChanged: (value) {
                    setState(() => _selectedGender = value ?? 'male');
                  },
                ),

                const SizedBox(height: 20),

                // Weight Field
                _buildTextField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  icon: Icons.fitness_center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Height Field
                _buildTextField(
                  controller: _heightController,
                  label: 'Height (cm)',
                  icon: Icons.height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your height';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Goal Weight Field
                _buildTextField(
                  controller: _goalWeightController,
                  label: 'Goal Weight (kg)',
                  icon: Icons.flag,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your goal weight';
                    }
                    final goalWeight = double.tryParse(value);
                    if (goalWeight == null || goalWeight <= 0) {
                      return 'Please enter a valid goal weight';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Goal Dropdown
                _buildDropdown(
                  label: 'Fitness Goal',
                  value: _selectedGoal,
                  items: ['lose_weight', 'maintain', 'gain_weight'],
                  displayNames: {
                    'lose_weight': 'Lose Weight',
                    'maintain': 'Maintain Weight',
                    'gain_weight': 'Gain Weight',
                  },
                  icon: Icons.tablet,
                  onChanged: (value) {
                    setState(() => _selectedGoal = value ?? 'maintain');
                  },
                ),

                const SizedBox(height: 20),

                // Activity Level Dropdown
                _buildDropdown(
                  label: 'Activity Level',
                  value: _selectedActivityLevel,
                  items: [
                    'sedentary',
                    'light',
                    'moderate',
                    'active',
                    'veryActive',
                  ],
                  displayNames: {
                    'sedentary': 'Sedentary (little to no exercise)',
                    'light': 'Light (light exercise 1-3 days/week)',
                    'moderate': 'Moderate (moderate exercise 3-5 days/week)',
                    'active': 'Active (hard exercise 6-7 days/week)',
                    'veryActive':
                        'Very Active (very hard exercise & physical job)',
                  },
                  icon: Icons.directions_run,
                  onChanged: (value) {
                    setState(
                      () => _selectedActivityLevel = value ?? 'moderate',
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Complete Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip for now button (optional)
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Map<String, String> displayNames,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(displayNames[item] ?? item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
