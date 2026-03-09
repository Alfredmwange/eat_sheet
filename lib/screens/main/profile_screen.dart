import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eat_sheet/models/user_model.dart';
import 'package:eat_sheet/providers/user_provider.dart';
import 'package:eat_sheet/providers/theme_provider.dart';
import 'package:eat_sheet/services/auth.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      context.read<UserProvider>().loadUserData(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No user data found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final user = userProvider.user!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header Section
                _buildProfileHeader(user, context),

                // User Details Section
                _buildUserDetails(user, context),

                // Settings Section
                _buildSettingsSection(context),

                // Contact Us Section
                _buildContactUsSection(context),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? Icon(Icons.person, size: 50, color: Colors.grey.shade600)
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Email
          const SizedBox(height: 8),
          Text(
            user.email,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),

          // Edit Profile Button
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(User user, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTitle('Personal Information'),
          const SizedBox(height: 12),
          _buildDetailItem('Gender', _formatGender(user.gender)),
          _buildDetailItem('Age', '${user.age} years'),
          _buildDetailItem('Weight', '${user.weight.toStringAsFixed(1)} kg'),
          _buildDetailItem('Height', '${user.height.toStringAsFixed(1)} cm'),
          const Divider(height: 20),
          _buildDetailItem('Goal', _formatGoal(user.goal)),
          _buildDetailItem(
            'Activity Level',
            _formatActivityLevel(user.activityLevel),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTitle('Settings'),
          const SizedBox(height: 16),

          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.blue.shade600,
                ),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Logout Button
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: Colors.orange.shade600),
            title: const Text('Logout'),
            onTap: () => _showConfirmationDialog(
              context,
              'Logout',
              'Are you sure you want to logout?',
              () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          // Delete Account Button
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
            title: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red.shade600),
            ),
            onTap: () => _showConfirmationDialog(
              context,
              'Delete Account',
              'This action cannot be undone. All your data will be permanently deleted. Are you sure?',
              () async {
                final userProvider = context.read<UserProvider>();
                final success = await userProvider.deleteAccount();
                if (mounted) {
                  if (success) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          userProvider.error ?? 'Failed to delete account',
                        ),
                      ),
                    );
                  }
                }
              },
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactUsSection(BuildContext context) {
    const appEmail = 'support@eatsheet.com';
    const appWebsite = 'www.eatsheet.com';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTitle('Contact Us'),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.email, color: Colors.blue.shade600),
            title: const Text('Email'),
            subtitle: const Text(appEmail),
            onTap: () {
              // TODO: Implement email functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Email: $appEmail')));
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.language, color: Colors.blue.shade600),
            title: const Text('Website'),
            subtitle: const Text(appWebsite),
            onTap: () {
              // TODO: Implement website link functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Website: $appWebsite')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Other';
    }
  }

  String _formatGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'maintain':
        return 'Maintain Weight';
      case 'gain_weight':
        return 'Gain Weight';
      default:
        return 'Maintain Weight';
    }
  }

  String _formatActivityLevel(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light Activity';
      case 'moderate':
        return 'Moderate Activity';
      case 'active':
        return 'Very Active';
      case 'veryactive':
        return 'Extremely Active';
      default:
        return 'Moderate Activity';
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
