import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ProductService {
  static const String _productsKey = 'products';
  static const String _nextProductIdKey = 'next_product_id';

  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  SharedPreferences? _prefs;
  List<Product> _products = [];
  int _nextId = 1;
  bool _isInitialized = false;

  // Initialize
  Future<bool> init() async {
    if (_isInitialized && _prefs != null) return true;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadProducts();
      _nextId = _prefs?.getInt(_nextProductIdKey) ?? 1;
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing ProductService: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Load products from storage
  Future<void> _loadProducts() async {
    try {
      final String? productsJson = _prefs?.getString(_productsKey);
      if (productsJson == null || productsJson.isEmpty) {
        _products = [];
        // Chỉ tạo dữ liệu mẫu khi thực sự cần
        return;
      }

      final List<dynamic> productsList = jsonDecode(productsJson);
      _products = productsList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading products: $e');
      _products = [];
    }
  }

  // Save products to storage
  Future<bool> _saveProducts() async {
    if (!await init()) return false;
    
    try {
      final String productsJson = jsonEncode(_products.map((p) => p.toJson()).toList());
      return await _prefs?.setString(_productsKey, productsJson) ?? false;
    } catch (e) {
      print('Error saving products: $e');
      return false;
    }
  }

  // Get all products
  Future<List<Product>> getProducts() async {
    if (!await init()) return [];
    
    // Tạo dữ liệu mẫu nếu danh sách trống
    if (_products.isEmpty) {
      await _createSampleProducts();
    }
    
    return List.from(_products);
  }

  // Get active products only
  Future<List<Product>> getActiveProducts() async {
    final products = await getProducts();
    return products.where((p) => p.isActive).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get product by code
  Future<Product?> getProductByCode(String code) async {
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.code.toLowerCase() == code.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return await getProducts();
    
    final products = await getProducts();
    final searchQuery = query.toLowerCase();
    
    return products.where((product) {
      return product.name.toLowerCase().contains(searchQuery) ||
             product.code.toLowerCase().contains(searchQuery) ||
             product.category.toLowerCase().contains(searchQuery) ||
             product.description.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products.where((p) => p.category == category).toList();
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final products = await getProducts();
    return products.where((p) => p.isLowStock && p.isActive).toList();
  }

  // Add product
  Future<bool> addProduct(Product product) async {
    if (!await init()) return false;
    
    try {
      // Tạo ID mới
      final newProduct = product.copyWith(
        id: _nextId.toString(),
        code: product.code.isEmpty 
            ? Product.generateProductCode('SP', _nextId)
            : product.code,
      );
      
      _products.add(newProduct);
      _nextId++;
      
      final success = await _saveProducts();
      if (success) {
        await _prefs?.setInt(_nextProductIdKey, _nextId);
        return true;
      } else {
        // Rollback
        _products.removeLast();
        _nextId--;
        return false;
      }
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    if (!await init()) return false;
    
    try {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index == -1) return false;
      
      final oldProduct = _products[index];
      _products[index] = product.copyWith(updatedAt: DateTime.now());
      
      final success = await _saveProducts();
      if (!success) {
        // Rollback
        _products[index] = oldProduct;
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    if (!await init()) return false;
    
    try {
      final index = _products.indexWhere((p) => p.id == id);
      if (index == -1) return false;
      
      final deletedProduct = _products[index];
      _products.removeAt(index);
      
      final success = await _saveProducts();
      if (!success) {
        // Rollback
        _products.insert(index, deletedProduct);
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock(String productId, int newQuantity) async {
    final product = await getProductById(productId);
    if (product == null) return false;
    
    final updatedProduct = product.copyWith(stockQuantity: newQuantity);
    return await updateProduct(updatedProduct);
  }

  // Reduce stock (when selling)
  Future<bool> reduceStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return false;
    
    final newQuantity = (product.stockQuantity - quantity).clamp(0, double.infinity).toInt();
    return await updateStock(productId, newQuantity);
  }

  // Increase stock (when restocking)
  Future<bool> increaseStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return false;
    
    final newQuantity = product.stockQuantity + quantity;
    return await updateStock(productId, newQuantity);
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final products = await getProducts();
    final activeProducts = products.where((p) => p.isActive).toList();
    final lowStockProducts = products.where((p) => p.isLowStock && p.isActive).toList();
    
    double totalStockValue = 0;
    for (final product in activeProducts) {
      totalStockValue += product.stockValue;
    }
    
    return {
      'totalProducts': products.length,
      'activeProducts': activeProducts.length,
      'inactiveProducts': products.length - activeProducts.length,
      'lowStockProducts': lowStockProducts.length,
      'totalStockValue': totalStockValue,
      'categories': _getCategories(products),
    };
  }

  // Get categories with count
  Map<String, int> _getCategories(List<Product> products) {
    final Map<String, int> categories = {};
    for (final product in products) {
      if (product.category.isNotEmpty) {
        categories[product.category] = (categories[product.category] ?? 0) + 1;
      }
    }
    return categories;
  }

  // Clear all products
  Future<bool> clearAllProducts() async {
    if (!await init()) return false;
    
    try {
      _products.clear();
      _nextId = 1;
      await _prefs?.remove(_productsKey);
      await _prefs?.remove(_nextProductIdKey);
      return true;
    } catch (e) {
      print('Error clearing products: $e');
      return false;
    }
  }

  // Import products from JSON
  Future<bool> importProducts(List<Map<String, dynamic>> productsData) async {
    if (!await init()) return false;
    
    try {
      final importedProducts = productsData.map((data) => Product.fromJson(data)).toList();
      
      for (final product in importedProducts) {
        // Check if product already exists
        final existingProduct = await getProductByCode(product.code);
        if (existingProduct == null) {
          await addProduct(product);
        }
      }
      
      return true;
    } catch (e) {
      print('Error importing products: $e');
      return false;
    }
  }

  // Export products to JSON
  Future<List<Map<String, dynamic>>> exportProducts() async {
    final products = await getProducts();
    return products.map((p) => p.toJson()).toList();
  }

  // Create sample products - minimal data
  Future<void> _createSampleProducts() async {
    try {
      // Chỉ tạo 1 sản phẩm mẫu để tiết kiệm memory
      _products = [
        Product(
          id: '1',
          code: 'SP000001',
          name: 'Sản phẩm mẫu',
          sellingPrice: 10000,
          costPrice: 8000,
          unit: 'Cái',
          category: 'Demo',
          description: 'Sản phẩm demo',
          stockQuantity: 10,
          minStockLevel: 5,
        ),
      ];

      _nextId = 2;
      await _saveProducts();
      await _prefs?.setInt(_nextProductIdKey, _nextId);
    } catch (e) {
      print('Error creating sample products: $e');
      _products = [];
      _nextId = 1;
    }
  }

  // Get next product code
  Future<String> getNextProductCode() async {
    if (!await init()) return 'SP000001';
    return Product.generateProductCode('SP', _nextId);
  }

  // Check if product code exists
  Future<bool> isProductCodeExists(String code) async {
    final product = await getProductByCode(code);
    return product != null;
  }
}
