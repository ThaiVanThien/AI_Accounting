import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';

class CustomerService {
  static const String _customersKey = 'customers';
  static const String _nextCustomerIdKey = 'next_customer_id';

  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  SharedPreferences? _prefs;
  List<Customer> _customers = [];
  int _nextId = 1;
  bool _isInitialized = false;

  // Initialize
  Future<bool> init() async {
    if (_isInitialized && _prefs != null) return true;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCustomers();
      _nextId = _prefs?.getInt(_nextCustomerIdKey) ?? 1;
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing CustomerService: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Load customers from storage
  Future<void> _loadCustomers() async {
    try {
      final String? customersJson = _prefs?.getString(_customersKey);
      if (customersJson == null || customersJson.isEmpty) {
        _customers = [];
        return;
      }
      final List<dynamic> customersList = jsonDecode(customersJson);
      _customers = customersList.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      print('Error loading customers: $e');
      _customers = [];
    }
  }

  // Save customers to storage
  Future<bool> _saveCustomers() async {
    if (!await init()) return false;
    
    try {
      final String customersJson = jsonEncode(_customers.map((c) => c.toJson()).toList());
      return await _prefs?.setString(_customersKey, customersJson) ?? false;
    } catch (e) {
      print('Error saving customers: $e');
      return false;
    }
  }

  // Get all customers
  Future<List<Customer>> getCustomers() async {
    if (!await init()) return [];
    return List.from(_customers);
  }

  // Get active customers only
  Future<List<Customer>> getActiveCustomers() async {
    final customers = await getCustomers();
    return customers.where((c) => c.isActive).toList();
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final customers = await getCustomers();
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) return await getCustomers();
    
    final customers = await getCustomers();
    final searchQuery = query.toLowerCase();
    
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(searchQuery) ||
             customer.phone.contains(searchQuery) ||
             customer.email.toLowerCase().contains(searchQuery) ||
             customer.address.toLowerCase().contains(searchQuery) ||
             customer.note.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Add customer
  Future<bool> addCustomer(Customer customer) async {
    if (!await init()) return false;
    
    try {
      // Kiểm tra validation
      if (!customer.isValid) {
        print('Customer validation failed: ${customer.name}, ${customer.phone}');
        return false;
      }

      // Kiểm tra trùng lặp số điện thoại (chỉ với khách hàng thật, không phải khách lẻ)
      if (!customer.isWalkIn && customer.phone.isNotEmpty) {
        final existingCustomer = _customers.where((c) => 
          !c.isWalkIn && c.phone == customer.phone && c.id != customer.id
        ).firstOrNull;
        if (existingCustomer != null) {
          print('Customer with phone ${customer.phone} already exists');
          return false;
        }
      }

      final newCustomer = customer.copyWith(
        id: customer.isWalkIn ? 'walk_in' : _nextId.toString(),
      );
      
      if (!customer.isWalkIn) {
        _customers.add(newCustomer);
        _nextId++;
      } else {
        // Không thêm khách lẻ vào danh sách, chỉ trả về true
        return true;
      }
      
      final success = await _saveCustomers();
      if (success) {
        if (!customer.isWalkIn) {
          await _prefs?.setInt(_nextCustomerIdKey, _nextId);
        }
        return true;
      } else {
        // Rollback
        if (!customer.isWalkIn) {
          _customers.removeLast();
          _nextId--;
        }
        return false;
      }
    } catch (e) {
      print('Error adding customer: $e');
      return false;
    }
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    if (!await init()) return false;
    
    try {
      // Không cho phép cập nhật khách lẻ
      if (customer.isWalkIn) {
        print('Cannot update walk-in customer');
        return false;
      }

      // Kiểm tra validation
      if (!customer.isValid) {
        print('Customer validation failed: ${customer.name}, ${customer.phone}');
        return false;
      }

      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index == -1) return false;
      
      // Kiểm tra trùng lặp số điện thoại
      if (customer.phone.isNotEmpty) {
        final existingCustomer = _customers.where((c) => 
          c.phone == customer.phone && c.id != customer.id
        ).firstOrNull;
        if (existingCustomer != null) {
          print('Customer with phone ${customer.phone} already exists');
          return false;
        }
      }
      
      final oldCustomer = _customers[index];
      final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());
      _customers[index] = updatedCustomer;
      
      final success = await _saveCustomers();
      if (!success) {
        // Rollback
        _customers[index] = oldCustomer;
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  // Delete customer (soft delete)
  Future<bool> deleteCustomer(String id) async {
    if (!await init()) return false;
    
    try {
      // Không cho phép xóa khách lẻ
      if (id == 'walk_in') {
        print('Cannot delete walk-in customer');
        return false;
      }

      final index = _customers.indexWhere((c) => c.id == id);
      if (index == -1) return false;
      
      // Soft delete - chỉ đánh dấu không hoạt động
      final customer = _customers[index];
      final updatedCustomer = customer.copyWith(isActive: false, updatedAt: DateTime.now());
      _customers[index] = updatedCustomer;
      
      final success = await _saveCustomers();
      if (!success) {
        // Rollback
        _customers[index] = customer;
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  // Hard delete customer
  Future<bool> hardDeleteCustomer(String id) async {
    if (!await init()) return false;
    
    try {
      // Không cho phép xóa khách lẻ
      if (id == 'walk_in') {
        print('Cannot hard delete walk-in customer');
        return false;
      }

      final index = _customers.indexWhere((c) => c.id == id);
      if (index == -1) return false;
      
      _customers.removeAt(index);
      
      final success = await _saveCustomers();
      if (!success) {
        // Rollback
        _customers.insert(index, _customers[index]);
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error hard deleting customer: $e');
      return false;
    }
  }

  // Restore customer
  Future<bool> restoreCustomer(String id) async {
    if (!await init()) return false;
    
    try {
      // Không cho phép restore khách lẻ
      if (id == 'walk_in') {
        print('Cannot restore walk-in customer');
        return false;
      }

      final index = _customers.indexWhere((c) => c.id == id);
      if (index == -1) return false;
      
      final customer = _customers[index];
      final updatedCustomer = customer.copyWith(isActive: true, updatedAt: DateTime.now());
      _customers[index] = updatedCustomer;
      
      final success = await _saveCustomers();
      if (!success) {
        // Rollback
        _customers[index] = customer;
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error restoring customer: $e');
      return false;
    }
  }

  // Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics() async {
    final customers = await getCustomers();
    final activeCustomers = customers.where((c) => c.isActive).length;
    final inactiveCustomers = customers.where((c) => !c.isActive).length;
    final walkInCustomers = customers.where((c) => c.isWalkIn).length;
    
    return {
      'totalCustomers': customers.length,
      'activeCustomers': activeCustomers,
      'inactiveCustomers': inactiveCustomers,
      'walkInCustomers': walkInCustomers,
      'regularCustomers': activeCustomers - walkInCustomers,
    };
  }

  // Clear all customers
  Future<bool> clearAllCustomers() async {
    if (!await init()) return false;
    
    try {
      _customers.clear();
      _nextId = 1;
      await _prefs?.remove(_customersKey);
      await _prefs?.remove(_nextCustomerIdKey);
      return true;
    } catch (e) {
      print('Error clearing customers: $e');
      return false;
    }
  }

  // Export customers to JSON
  Future<List<Map<String, dynamic>>> exportCustomers() async {
    final customers = await getCustomers();
    return customers.map((c) => c.toJson()).toList();
  }

  // Import customers from JSON
  Future<bool> importCustomers(List<Map<String, dynamic>> customersData) async {
    if (!await init()) return false;
    
    try {
      final customers = customersData.map((json) => Customer.fromJson(json)).toList();
      
      // Tìm ID lớn nhất để tránh trùng lặp
      int maxId = 0;
      for (final customer in customers) {
        if (customer.id != 'walk_in') {
          final id = int.tryParse(customer.id);
          if (id != null && id > maxId) {
            maxId = id;
          }
        }
      }
      
      _customers = customers;
      _nextId = maxId + 1;
      
      final success = await _saveCustomers();
      if (success) {
        await _prefs?.setInt(_nextCustomerIdKey, _nextId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing customers: $e');
      return false;
    }
  }

  // Validate customer before saving
  bool validateCustomer(Customer customer) {
    if (customer.name.trim().isEmpty) return false;
    if (customer.phone.trim().isEmpty) return false;
    
    // Kiểm tra định dạng số điện thoại (cơ bản)
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(customer.phone)) return false;
    
    return true;
  }

  // Get next customer ID
  Future<String> getNextCustomerId() async {
    if (!await init()) return '1';
    return _nextId.toString();
  }
}
