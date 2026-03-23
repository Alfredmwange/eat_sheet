import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// FoodSearchResult — lightweight result from API
// ─────────────────────────────────────────────

class FoodSearchResult {
  final String name;
  final String? brand;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? imageUrl;

  const FoodSearchResult({
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.imageUrl,
  });

  /// Scale nutrients to a given serving size in grams
  Map<String, int> forServing(double servingGrams) {
    final ratio = servingGrams / 100.0;
    return {
      'calories': (caloriesPer100g * ratio).round(),
      'protein':  (proteinPer100g  * ratio).round(),
      'carbs':    (carbsPer100g    * ratio).round(),
      'fat':      (fatPer100g      * ratio).round(),
    };
  }
}

// FoodServiceException

class FoodServiceException implements Exception {
  final String message;
  const FoodServiceException(this.message);
  @override
  String toString() => message;
}

// FoodService — Open Food Facts API

class FoodService {
  static const _baseUrl = 'https://world.openfoodfacts.org';
  static const _timeout = Duration(seconds: 10);

  
  /// Throws [FoodServiceException] on network/parse failure.
  static Future<List<FoodSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/cgi/search.pl'
      '?search_terms=${Uri.encodeComponent(query)}'
      '&search_simple=1'
      '&action=process'
      '&json=1'
      '&page_size=15'
      '&fields=product_name,brands,nutriments,image_front_small_url',
    );

    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {'User-Agent': 'EatSheet/1.0 (Flutter)'},
      ).timeout(_timeout);
    } catch (e) {
      throw FoodServiceException('No internet connection. Please check your network.');
    }

    if (response.statusCode != 200) {
      throw FoodServiceException('Server error (${response.statusCode}). Try again.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = (data['products'] as List?) ?? [];

    final results = <FoodSearchResult>[];
    for (final p in products) {
      final result = _parseProduct(p as Map<String, dynamic>);
      if (result != null) results.add(result);
    }

    return results; // empty list = no results (caller shows "No results found")
  }

  /// Lookup food by barcode — returns null if not found in database,
  /// throws [FoodServiceException] on network/server errors.
  static Future<FoodSearchResult?> lookupBarcode(String barcode) async {
    late http.Response response;
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/v0/product/$barcode.json'
        '?fields=product_name,brands,nutriments,image_front_small_url',
      );
      response = await http.get(
        uri,
        headers: {'User-Agent': 'EatSheet/1.0 (Flutter)'},
      ).timeout(_timeout);
    } catch (e) {
      throw FoodServiceException('No internet connection. Please check your network.');
    }

    if (response.statusCode != 200) {
      throw FoodServiceException('Server error (${response.statusCode}). Try again.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // status 0 = product not found in Open Food Facts database
    if (data['status'] == 0) return null;

    final product = data['product'] as Map<String, dynamic>? ?? {};
    return _parseProduct(product);
  }

  // ── Food image recognition (Logmeal API) 
  // Sign up free at https://api.logmeal.com to get your API token.
  static const _logmealToken = 'YOUR_LOGMEAL_API_TOKEN';
  static const _logmealUrl   = 'https://api.logmeal.com/v2/image/recognition/complete';

  /// Recognise food items in [imageFile], then fetch nutritional data
  /// for each recognised item from Open Food Facts.
  ///
  /// Returns a list of [FoodSearchResult] ordered by recognition confidence.
  /// Returns an empty list when no food is detected.
  /// Throws [FoodServiceException] on network or API errors.
  static Future<List<FoodSearchResult>> recognizeFood(File imageFile) async {
    // ── Step 1: Identify food names from photo via Logmeal ──
    final request = http.MultipartRequest('POST', Uri.parse(_logmealUrl))
      ..headers['Authorization'] = 'Bearer $_logmealToken'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw FoodServiceException('No internet connection. Please check your network.');
    }

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 401) {
      throw FoodServiceException(
          'Food recognition API key missing or invalid.\nAdd your Logmeal token to food_service.dart.');
    }
    if (streamed.statusCode != 200) {
      throw FoodServiceException(
          'Food recognition failed (${streamed.statusCode}). Try again.');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;

    // Logmeal response: { "recognition_results": [ { "name": "pizza", "prob": 0.95 }, ... ] }
    final recognitions = (data['recognition_results'] as List? ?? []);
    if (recognitions.isEmpty) return []; // caller shows "No meal found"

    // Take top 3 detected food names
    final foodNames = recognitions
        .take(3)
        .map((r) => (r['name'] as String? ?? '').trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (foodNames.isEmpty) return [];

    // ── Step 2: Fetch nutritional data for each detected food ──
    final results = <FoodSearchResult>[];
    for (final name in foodNames) {
      try {
        final found = await search(name);
        // Take the best match for each recognised food name
        if (found.isNotEmpty) results.add(found.first);
      } catch (_) {
        // If one name fails, continue with the rest
      }
    }

    return results;
  }

  static FoodSearchResult? _parseProduct(Map<String, dynamic> p) {
    final name = (p['product_name'] as String? ?? '').trim();
    if (name.isEmpty) return null;

    final n = p['nutriments'] as Map<String, dynamic>? ?? {};

    double _d(String key) =>
        (n[key] ?? n['${key}_100g'] ?? 0).toDouble();

    final calories = _d('energy-kcal').round();
    if (calories <= 0) return null; // skip items with no calorie data

    return FoodSearchResult(
      name:             name,
      brand:            p['brands'] as String?,
      caloriesPer100g:  calories,
      proteinPer100g:   _d('proteins'),
      carbsPer100g:     _d('carbohydrates'),
      fatPer100g:       _d('fat'),
      imageUrl:         p['image_front_small_url'] as String?,
    );
  }

}