import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eat_sheet/models/user_model.dart';
import 'package:eat_sheet/providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  late String _selectedGender;
  late String _selectedGoal;
  late String _selectedActivityLevel;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _ageController = TextEditingController(text: widget.user.age.toString());
    _weightController = TextEditingController(
      text: widget.user.weight.toString(),
    );
    _heightController = TextEditingController(
      text: widget.user.height.toString(),
    );
    _selectedGender = widget.user.gender;
    _selectedGoal = widget.user.goal;
    _selectedActivityLevel = widget.user.activityLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        gender: _selectedGender,
        goal: _selectedGoal,
        activityLevel: _selectedActivityLevel,
        updatedAt: DateTime.now(),
      );

      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateUserData(updatedUser);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.error ?? 'Failed to update profile'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty) {
      _showError('Name cannot be empty');
      return false;
    }

    if (_emailController.text.isEmpty) {
      _showError('Email cannot be empty');
      return false;
    }

    if (_ageController.text.isEmpty) {
      _showError('Age cannot be empty');
      return false;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 120) {
      _showError('Age must be between 1 and 120');
      return false;
    }

    if (_weightController.text.isEmpty) {
      _showError('Weight cannot be empty');
      return false;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      _showError('Weight must be a positive number');
      return false;
    }

    if (_heightController.text.isEmpty) {
      _showError('Height cannot be empty');
      return false;
    }

    final height = double.tryParse(_heightController.text);
    if (height == null || height <= 0) {
      _showError('Height must be a positive number');
      return false;
    }

    return true;
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
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Age Field
            _buildTextField(
              controller: _ageController,
              label: 'Age',
              icon: Icons.cake,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Gender Dropdown
            _buildDropdown(
              label: 'Gender',
              value: _selectedGender,
              items: ['male', 'female', 'other'],
              onChanged: (value) {
                setState(() => _selectedGender = value ?? 'other');
              },
              icon: Icons.wc,
            ),
            const SizedBox(height: 16),

            // Weight Field
            _buildTextField(
              controller: _weightController,
              label: 'Weight (kg)',
              icon: Icons.fitness_center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Height Field
            _buildTextField(
              controller: _heightController,
              label: 'Height (cm)',
              icon: Icons.height,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Goal Dropdown
            _buildDropdown(
              label: 'Goal',
              value: _selectedGoal,
              items: ['lose_weight', 'maintain', 'gain_weight'],
              onChanged: (value) {
                setState(() => _selectedGoal = value ?? 'maintain');
              },
              icon: Icons.tablet,
              displayNames: {
                'lose_weight': 'Lose Weight',
                'maintain': 'Maintain Weight',
                'gain_weight': 'Gain Weight',
              },
            ),
            const SizedBox(height: 16),

            // Activity Level Dropdown
            _buildDropdown(
              label: 'Activity Level',
              value: _selectedActivityLevel,
              items: ['sedentary', 'light', 'moderate', 'active', 'veryActive'],
              onChanged: (value) {
                setState(() => _selectedActivityLevel = value ?? 'moderate');
              },
              icon: Icons.directions_run,
              displayNames: {
                'sedentary': 'Sedentary',
                'light': 'Light Activity',
                'moderate': 'Moderate Activity',
                'active': 'Very Active',
                'veryActive': 'Extremely Active',
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade600),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    Map<String, String>? displayNames,
  }) {
    final displayMap = displayNames ?? {for (var item in items) item: item};

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(displayMap[item] ?? item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
