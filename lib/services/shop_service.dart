import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_info.dart';

class ShopService {
  static const String _shopInfoKey = 'shop_info';
  static const String _isSetupCompleteKey = 'is_setup_complete';
  static const String _currentUserKey = 'current_user';

  // Singleton pattern
  static final ShopService _instance = ShopService._internal();
  factory ShopService() => _instance;
  ShopService._internal();

  SharedPreferences? _prefs;
  ShopInfo? _shopInfo;
  bool _isInitialized = false;

  // Initialize
  Future<bool> init() async {
    if (_isInitialized && _prefs != null) return true;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadShopInfo();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing ShopService: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Load shop info from storage
  Future<void> _loadShopInfo() async {
    try {
      final String? shopInfoJson = _prefs?.getString(_shopInfoKey);
      if (shopInfoJson != null) {
        _shopInfo = ShopInfo.fromJson(jsonDecode(shopInfoJson));
      }
    } catch (e) {
      print('Error loading shop info: $e');
      _shopInfo = null;
    }
  }

  // Save shop info to storage
  Future<bool> _saveShopInfo() async {
    if (!await init() || _shopInfo == null) return false;
    
    try {
      final String shopInfoJson = jsonEncode(_shopInfo!.toJson());
      final success = await _prefs?.setString(_shopInfoKey, shopInfoJson) ?? false;
      if (success) {
        await _prefs?.setBool(_isSetupCompleteKey, true);
      }
      return success;
    } catch (e) {
      print('Error saving shop info: $e');
      return false;
    }
  }

  // Get shop info
  Future<ShopInfo?> getShopInfo() async {
    if (!await init()) return null;
    return _shopInfo;
  }

  // Set shop info
  Future<bool> setShopInfo(ShopInfo shopInfo) async {
    if (!await init()) return false;
    
    try {
      _shopInfo = shopInfo.copyWith(
        id: _shopInfo?.id ?? '1',
        updatedAt: DateTime.now(),
      );
      return await _saveShopInfo();
    } catch (e) {
      print('Error setting shop info: $e');
      return false;
    }
  }

  // Update shop info
  Future<bool> updateShopInfo(ShopInfo shopInfo) async {
    if (!await init()) return false;
    
    try {
      _shopInfo = shopInfo.copyWith(updatedAt: DateTime.now());
      return await _saveShopInfo();
    } catch (e) {
      print('Error updating shop info: $e');
      return false;
    }
  }

  // Check if setup is complete
  Future<bool> isSetupComplete() async {
    if (!await init()) return false;
    return _prefs?.getBool(_isSetupCompleteKey) ?? false;
  }

  // Mark setup as complete
  Future<bool> markSetupComplete() async {
    if (!await init()) return false;
    return await _prefs?.setBool(_isSetupCompleteKey, true) ?? false;
  }

  // Reset setup
  Future<bool> resetSetup() async {
    if (!await init()) return false;
    
    try {
      await _prefs?.remove(_shopInfoKey);
      await _prefs?.remove(_isSetupCompleteKey);
      await _prefs?.remove(_currentUserKey);
      _shopInfo = null;
      return true;
    } catch (e) {
      print('Error resetting setup: $e');
      return false;
    }
  }

  // Simple login check (for demo purposes)
  Future<bool> login(String username, String password) async {
    if (!await init()) return false;
    
    // Demo credentials
    if (username == 'huetechcoop' && password == 'dev') {
      await _prefs?.setString(_currentUserKey, username);
      return true;
    }
    
    return false;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    if (!await init()) return false;
    final currentUser = _prefs?.getString(_currentUserKey);
    return currentUser != null && currentUser.isNotEmpty;
  }

  // Get current user
  Future<String?> getCurrentUser() async {
    if (!await init()) return null;
    return _prefs?.getString(_currentUserKey);
  }

  // Logout
  Future<bool> logout() async {
    if (!await init()) return false;
    
    try {
      await _prefs?.remove(_currentUserKey);
      return true;
    } catch (e) {
      print('Error logging out: $e');
      return false;
    }
  }

  // Check if app needs initial setup
  Future<bool> needsInitialSetup() async {
    final loggedIn = await isLoggedIn();
    final setupComplete = await isSetupComplete();
    return !loggedIn || !setupComplete;
  }

  // Get app status
  Future<Map<String, dynamic>> getAppStatus() async {
    final loggedIn = await isLoggedIn();
    final setupComplete = await isSetupComplete();
    final currentUser = await getCurrentUser();
    final shopInfo = await getShopInfo();
    
    return {
      'isLoggedIn': loggedIn,
      'isSetupComplete': setupComplete,
      'needsInitialSetup': !loggedIn || !setupComplete,
      'currentUser': currentUser,
      'hasShopInfo': shopInfo != null,
      'shopName': shopInfo?.name ?? '',
    };
  }

  // Export shop data
  Future<Map<String, dynamic>> exportShopData() async {
    final shopInfo = await getShopInfo();
    final status = await getAppStatus();
    
    return {
      'shopInfo': shopInfo?.toJson(),
      'appStatus': status,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import shop data
  Future<bool> importShopData(Map<String, dynamic> data) async {
    try {
      if (data['shopInfo'] != null) {
        final shopInfo = ShopInfo.fromJson(data['shopInfo']);
        await setShopInfo(shopInfo);
      }
      return true;
    } catch (e) {
      print('Error importing shop data: $e');
      return false;
    }
  }
}
