import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/food_service.dart';

// ─────────────────────────────────────────────
// FoodEntry model
// ─────────────────────────────────────────────

class FoodEntry {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String meal;

  const FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meal,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal': meal,
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        name: json['name'] as String,
        calories: json['calories'] as int,
        protein: json['protein'] as int,
        carbs: json['carbs'] as int,
        fat: json['fat'] as int,
        meal: json['meal'] as String,
      );
}

// ─────────────────────────────────────────────
// AddMealScreen
// ─────────────────────────────────────────────

class AddMealScreen extends StatefulWidget {
  final void Function(FoodEntry entry) onFoodLogged;
  const AddMealScreen({super.key, required this.onFoodLogged});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goTo(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Meal',
            style: TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _TabBar(currentPage: _currentPage, onTabTap: _goTo),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (p) => setState(() => _currentPage = p),
        children: [
          _CameraPage(onFoodLogged: widget.onFoodLogged),
          _ManualPage(onFoodLogged: widget.onFoodLogged),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int currentPage;
  final void Function(int) onTabTap;
  const _TabBar({required this.currentPage, required this.onTabTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _Tab(
              label: '📷  Camera',
              active: currentPage == 0,
              onTap: () => onTabTap(0)),
          const SizedBox(width: 12),
          _Tab(
              label: '✏️  Manual',
              active: currentPage == 1,
              onTap: () => onTabTap(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F86E1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Camera Page — food photo recognition
// ─────────────────────────────────────────────

enum _ScanState { idle, loading, results, notFound, error }

class _CameraPage extends StatefulWidget {
  final void Function(FoodEntry) onFoodLogged;
  const _CameraPage({required this.onFoodLogged});

  @override
  State<_CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<_CameraPage> {
  final _picker = ImagePicker();
  _ScanState _state = _ScanState.idle;
  File? _capturedImage;
  List<FoodSearchResult> _results = [];
  FoodSearchResult? _selected;
  String _errorMessage = '';
  String _selectedMeal = 'Breakfast';
  final List<String> _meals = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];
  final _servingCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _servingCtrl.dispose();
    super.dispose();
  }

  double get _serving => double.tryParse(_servingCtrl.text) ?? 100;

  Future<void> _takePhoto() async {
    // Request camera permission first
    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermissionDialog();
      return;
    }

    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission is required to scan food.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    // Open camera
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (photo == null || !mounted) return;

    setState(() {
      _capturedImage = File(photo.path);
      _state = _ScanState.loading;
      _results = [];
      _selected = null;
    });

    await _recognise(_capturedImage!);
  }

  Future<void> _pickFromGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted && !mounted) return;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (photo == null || !mounted) return;

    setState(() {
      _capturedImage = File(photo.path);
      _state = _ScanState.loading;
      _results = [];
      _selected = null;
    });

    await _recognise(_capturedImage!);
  }

  Future<void> _recognise(File image) async {
    try {
      final results = await FoodService.recognizeFood(image);
      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _state = _ScanState.notFound;
          _errorMessage =
              'No meal found.\nMake sure the food is clearly visible and try again.';
        });
      } else {
        setState(() {
          _state = _ScanState.results;
          _results = results;
          _selected = results.first;
        });
      }
    } on FoodServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _capturedImage = null;
      _results = [];
      _selected = null;
      _errorMessage = '';
      _servingCtrl.text = '100';
    });
  }

  void _log() {
    if (_selected == null) return;
    final nutrients = _selected!.forServing(_serving);
    widget.onFoodLogged(FoodEntry(
      name: '${_selected!.name} (${_serving.toStringAsFixed(0)}g)',
      calories: nutrients['calories']!,
      protein: nutrients['protein']!,
      carbs: nutrients['carbs']!,
      fat: nutrients['fat']!,
      meal: _selectedMeal,
    ));
    Navigator.pop(context);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
            'Camera access has been permanently denied. Please enable it in your device settings to scan food.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ScanState.idle     => _buildIdle(),
      _ScanState.loading  => _buildLoading(),
      _ScanState.results  => _buildResults(),
      _ScanState.notFound => _buildNotFound(),
      _ScanState.error    => _buildError(),
    };
  }

  // ── Idle: prompt to take photo ──────────────
  Widget _buildIdle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Main camera button
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: const Color(0xFF1F86E1), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F86E1).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 52, color: Color(0xFF1F86E1)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Take a Photo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Point your camera at your meal',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ]),

          const SizedBox(height: 16),

          // Pick from gallery
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F86E1),
                side: const BorderSide(color: Color(0xFF1F86E1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // How it works card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF1F86E1), size: 16),
                  SizedBox(width: 6),
                  Text('How it works',
                      style: TextStyle(
                          color: Color(0xFF1F86E1),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                _HowItWorksStep(
                    number: '1', text: 'Take or upload a photo of your meal'),
                _HowItWorksStep(
                    number: '2', text: 'AI identifies the food items'),
                _HowItWorksStep(
                    number: '3',
                    text: 'Nutritional data is fetched automatically'),
                _HowItWorksStep(
                    number: '4', text: 'Select your portion and log it'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading: analysing photo ────────────────
  Widget _buildLoading() {
    return Column(
      children: [
        // Show captured image
        if (_capturedImage != null)
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(0)),
                  child: Image.file(_capturedImage!,
                      fit: BoxFit.cover),
                ),
                // Dark overlay
                Container(color: Colors.black54),
                // Loading indicator on top
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: Color(0xFF1F86E1), strokeWidth: 3),
                      SizedBox(height: 20),
                      Text('Analysing your meal…',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Identifying food items',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Results: food identified ────────────────
  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Captured image thumbnail
          if (_capturedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(_capturedImage!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover),
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Detected foods list
          const Text('Detected Foods',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),

          ..._results.asMap().entries.map((entry) {
            final food = entry.value;
            final isSelected = _selected == food;
            return GestureDetector(
              onTap: () => setState(() => _selected = food),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F4FD)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1F86E1)
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: Color(0xFF1F86E1), size: 20)
                    else
                      Icon(Icons.radio_button_unchecked,
                          color: Colors.grey.shade300, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF1A1A2E)
                                      : Colors.black87)),
                          if (food.brand != null &&
                              food.brand!.isNotEmpty)
                            Text(food.brand!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Text('${food.caloriesPer100g} kcal/100g',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1F86E1),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Serving size
          if (_selected != null) ...[
            const Text('Serving Size',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _servingCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Grams',
                      suffixText: 'g',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE0E8F0))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1F86E1), width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Quick gram buttons
                Row(
                  children: [50, 100, 150, 200].map((g) {
                    final active = _serving == g.toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () {
                          _servingCtrl.text = g.toString();
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF1F86E1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF1F86E1)),
                          ),
                          child: Text('${g}g',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF1F86E1))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Scaled nutrition preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition for ${_serving.toStringAsFixed(0)}g',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutrientPill(
                          label: 'Calories',
                          value:
                              '${_selected!.forServing(_serving)['calories']} kcal',
                          color: const Color(0xFF1F86E1)),
                      _NutrientPill(
                          label: 'Protein',
                          value:
                              '${_selected!.forServing(_serving)['protein']}g',
                          color: Colors.green),
                      _NutrientPill(
                          label: 'Carbs',
                          value:
                              '${_selected!.forServing(_serving)['carbs']}g',
                          color: Colors.orange),
                      _NutrientPill(
                          label: 'Fat',
                          value:
                              '${_selected!.forServing(_serving)['fat']}g',
                          color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],

          // Meal dropdown
          _MealDropdown(
            value: _selectedMeal,
            meals: _meals,
            onChanged: (v) => setState(() => _selectedMeal = v!),
          ),

          const SizedBox(height: 20),

          // Log button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected != null ? _log : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F86E1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Text('Log Meal',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── No meal found ───────────────────────────
  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show thumbnail
            if (_capturedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_capturedImage!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.no_food_outlined,
                  size: 48, color: Colors.orange.shade400),
            ),
            const SizedBox(height: 16),
            const Text('No meal found.',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    height: 1.6)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Take Another Photo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F86E1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Start Over'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ───────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F86E1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Manual Page — Open Food Facts API search

class _ManualPage extends StatefulWidget {
  final void Function(FoodEntry) onFoodLogged;
  const _ManualPage({required this.onFoodLogged});

  @override
  State<_ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<_ManualPage> {
  final _searchCtrl = TextEditingController();
  final _servingCtrl = TextEditingController(text: '100');
  String _selectedMeal = 'Breakfast';
  final List<String> _meals = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  List<FoodSearchResult> _results = [];
  FoodSearchResult? _selected;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  double get _serving => double.tryParse(_servingCtrl.text) ?? 100;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _selected = null;
        _error = null;
      });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
      _results = [];
    });
    try {
      final results = await FoodService.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        if (results.isEmpty) {
          _error = 'No results found for "$query". Try a different name.';
        }
      });
    } on FoodServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search failed. Please try again.';
      });
    }
  }

  void _selectFood(FoodSearchResult food) {
    setState(() {
      _selected = food;
      _results = [];
      _searchCtrl.text = food.name;
    });
  }

  void _log() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please search and select a food first.')));
      return;
    }
    if (_serving <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid serving size.')));
      return;
    }
    final nutrients = _selected!.forServing(_serving);
    widget.onFoodLogged(FoodEntry(
      name: '${_selected!.name} (${_serving.toStringAsFixed(0)}g)',
      calories: nutrients['calories']!,
      protein: nutrients['protein']!,
      carbs: nutrients['carbs']!,
      fat: nutrients['fat']!,
      meal: _selectedMeal,
    ));
    Navigator.pop(context);
  }

  InputDecoration _dec(String label,
          {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF1F86E1), width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search field 
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: _dec(
              'Search food',
              hint: 'e.g. ugali, banana, chicken…',
              suffix: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1F86E1))))
                  : (_searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _results = [];
                              _selected = null;
                              _error = null;
                            });
                          })
                      : null),
            ),
          ),

          // ── Error / empty state 
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline,
                  size: 14, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!,
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 12)),
              ),
            ]),
          ],

          // ── Search results dropdown 
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                children: _results.asMap().entries.map((e) {
                  final i = e.key;
                  final food = e.value;
                  return Column(children: [
                    if (i > 0)
                      const Divider(
                          height: 1, color: Color(0xFFE0E8F0)),
                    InkWell(
                      onTap: () => _selectFood(food),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(food.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w600)),
                                  if (food.brand != null &&
                                      food.brand!.isNotEmpty)
                                    Text(food.brand!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.grey[500])),
                                ]),
                          ),
                          Text('${food.caloriesPer100g} kcal/100g',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1F86E1),
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],

          // ── Selected food + serving 
          if (_selected != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF1F86E1), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selected!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F86E1),
                                fontSize: 14)),
                        if (_selected!.brand != null &&
                            _selected!.brand!.isNotEmpty)
                          Text(_selected!.brand!,
                              style: const TextStyle(
                                  color: Color(0xFF1F86E1),
                                  fontSize: 12)),
                      ]),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selected = null;
                    _searchCtrl.clear();
                  }),
                  child: const Text('Change',
                      style: TextStyle(
                          color: Color(0xFF1F86E1), fontSize: 12)),
                ),
              ]),
            ),

            const SizedBox(height: 14),

            // Serving size
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _servingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: _dec('Serving size (g)'),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [50, 100, 150, 200].map((g) {
                      final active = _serving == g.toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            _servingCtrl.text = g.toString();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1F86E1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF1F86E1)),
                            ),
                            child: Text('${g}g',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : const Color(0xFF1F86E1))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 14),

            // Scaled nutrition preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E8F0)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition for ${_serving.toStringAsFixed(0)}g',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutrientPill(
                            label: 'Calories',
                            value:
                                '${_selected!.forServing(_serving)['calories']} kcal',
                            color: const Color(0xFF1F86E1)),
                        _NutrientPill(
                            label: 'Protein',
                            value:
                                '${_selected!.forServing(_serving)['protein']}g',
                            color: Colors.green),
                        _NutrientPill(
                            label: 'Carbs',
                            value:
                                '${_selected!.forServing(_serving)['carbs']}g',
                            color: Colors.orange),
                        _NutrientPill(
                            label: 'Fat',
                            value:
                                '${_selected!.forServing(_serving)['fat']}g',
                            color: Colors.red),
                      ],
                    ),
                  ]),
            ),
          ],

          const SizedBox(height: 16),

          // Meal dropdown
          _MealDropdown(
            value: _selectedMeal,
            meals: _meals,
            onChanged: (v) => setState(() => _selectedMeal = v!),
          ),

          const SizedBox(height: 24),

          // Log button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected != null ? _log : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F86E1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Text('Log Meal',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// Shared widgets

class _HowItWorksStep extends StatelessWidget {
  final String number, text;
  const _HowItWorksStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
                color: Color(0xFF1F86E1), shape: BoxShape.circle),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _NutrientPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NutrientPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _MealDropdown extends StatelessWidget {
  final String value;
  final List<String> meals;
  final ValueChanged<String?> onChanged;
  const _MealDropdown(
      {required this.value, required this.meals, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF1F86E1)),
          items: meals
              .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(m,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}