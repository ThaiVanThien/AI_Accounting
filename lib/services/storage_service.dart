import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../models/models.dart';

class StorageService {
  static const String _financeRecordsKey = 'finance_records';
  static const String _chatHistoryKey = 'chat_history';
  static const String _nextIdKey = 'next_id';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Initialize SharedPreferences with error handling
  Future<bool> init() async {
    if (_isInitialized && _prefs != null) return true;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Finance Records Methods
  Future<List<FinanceRecord>> getFinanceRecords() async {
    if (!await init()) return [];
    
    try {
      final String? recordsJson = _prefs?.getString(_financeRecordsKey);
      if (recordsJson == null) return [];

      final List<dynamic> recordsList = jsonDecode(recordsJson);
      return recordsList.map((json) => FinanceRecord.fromJson(json)).toList();
    } catch (e) {
      print('Error loading finance records: $e');
      return [];
    }
  }

  Future<bool> saveFinanceRecords(List<FinanceRecord> records) async {
    if (!await init()) return false;
    
    try {
      final String recordsJson = jsonEncode(records.map((r) => r.toJson()).toList());
      return await _prefs?.setString(_financeRecordsKey, recordsJson) ?? false;
    } catch (e) {
      print('Error saving finance records: $e');
      return false;
    }
  }

  Future<bool> addFinanceRecord(FinanceRecord record) async {
    try {
      final records = await getFinanceRecords();
      records.add(record);
      return await saveFinanceRecords(records);
    } catch (e) {
      print('Error adding finance record: $e');
      return false;
    }
  }

  Future<bool> deleteFinanceRecord(int id) async {
    try {
      final records = await getFinanceRecords();
      records.removeWhere((record) => record.id == id);
      return await saveFinanceRecords(records);
    } catch (e) {
      print('Error deleting finance record: $e');
      return false;
    }
  }

  // Chat History Methods
  Future<List<ChatMessage>> getChatHistory() async {
    if (!await init()) return [];
    
    try {
      final String? chatJson = _prefs?.getString(_chatHistoryKey);
      if (chatJson == null) return [];

      final List<dynamic> chatList = jsonDecode(chatJson);
      return chatList.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  Future<bool> saveChatHistory(List<ChatMessage> messages) async {
    if (!await init()) return false;
    
    try {
      final String chatJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      return await _prefs?.setString(_chatHistoryKey, chatJson) ?? false;
    } catch (e) {
      print('Error saving chat history: $e');
      return false;
    }
  }

  Future<bool> addChatMessage(ChatMessage message) async {
    try {
      final messages = await getChatHistory();
      messages.add(message);
      return await saveChatHistory(messages);
    } catch (e) {
      print('Error adding chat message: $e');
      return false;
    }
  }

  Future<bool> clearChatHistory() async {
    if (!await init()) return false;
    
    try {
      return await _prefs?.remove(_chatHistoryKey) ?? false;
    } catch (e) {
      print('Error clearing chat history: $e');
      return false;
    }
  }

  // Next ID Methods
  Future<int> getNextId() async {
    if (!await init()) return 1;
    
    try {
      return _prefs?.getInt(_nextIdKey) ?? 1;
    } catch (e) {
      print('Error getting next ID: $e');
      return 1;
    }
  }

  Future<bool> setNextId(int id) async {
    if (!await init()) return false;
    
    try {
      return await _prefs?.setInt(_nextIdKey, id) ?? false;
    } catch (e) {
      print('Error setting next ID: $e');
      return false;
    }
  }

  Future<int> getAndIncrementNextId() async {
    final currentId = await getNextId();
    await setNextId(currentId + 1);
    return currentId;
  }

  // Statistics Methods
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final records = await getFinanceRecords();
      final chatHistory = await getChatHistory();
      
      if (records.isEmpty) {
        return {
          'totalRecords': 0,
          'totalRevenue': 0.0,
          'totalCost': 0.0,
          'totalProfit': 0.0,
          'chatMessages': chatHistory.length,
          'lastUpdate': null,
        };
      }

      final totalRevenue = records.fold(0.0, (sum, record) => sum + record.doanhThu);
      final totalCost = records.fold(0.0, (sum, record) => sum + record.chiPhi);
      final totalProfit = totalRevenue - totalCost;
      
      // Tìm record mới nhất
      final latestRecord = records.reduce((a, b) => 
        a.ngayTao.isAfter(b.ngayTao) ? a : b
      );

      return {
        'totalRecords': records.length,
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'chatMessages': chatHistory.length,
        'lastUpdate': latestRecord.ngayTao.toIso8601String(),
        'profitMargin': totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0.0,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalRecords': 0,
        'totalRevenue': 0.0,
        'totalCost': 0.0,
        'totalProfit': 0.0,
        'chatMessages': 0,
        'lastUpdate': null,
      };
    }
  }

  // Clear all data
  Future<bool> clearAllData() async {
    if (!await init()) return false;
    
    try {
      await _prefs?.remove(_financeRecordsKey);
      await _prefs?.remove(_chatHistoryKey);
      await _prefs?.remove(_nextIdKey);
      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  // Export data to JSON
  Future<Map<String, dynamic>> exportData() async {
    try {
      final records = await getFinanceRecords();
      final chatHistory = await getChatHistory();
      final nextId = await getNextId();
      
      return {
        'finance_records': records.map((r) => r.toJson()).toList(),
        'chat_history': chatHistory.map((m) => m.toJson()).toList(),
        'next_id': nextId,
        'export_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error exporting data: $e');
      return {
        'finance_records': [],
        'chat_history': [],
        'next_id': 1,
        'export_date': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Import data from JSON
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      if (data['finance_records'] != null) {
        final List<dynamic> recordsList = data['finance_records'];
        final records = recordsList.map((json) => FinanceRecord.fromJson(json)).toList();
        await saveFinanceRecords(records);
      }

      if (data['chat_history'] != null) {
        final List<dynamic> chatList = data['chat_history'];
        final messages = chatList.map((json) => ChatMessage.fromJson(json)).toList();
        await saveChatHistory(messages);
      }

      if (data['next_id'] != null) {
        await setNextId(data['next_id']);
      }
      
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }

  // Check if storage is available
  Future<bool> isStorageAvailable() async {
    return await init();
  }

  // Static methods for business user (delegate to BusinessUserService)
  static Future<void> saveBusinessUser(BusinessUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toMap());
    await prefs.setString('business_user', userJson);
    await prefs.setBool('setup_completed', true);
  }

  static Future<BusinessUser?> getBusinessUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('business_user');
    
    if (userJson == null) {
      return null;
    }

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return BusinessUser.fromMap(userMap);
    } catch (e) {
      print('Error loading business user: $e');
      return null;
    }
  }

  static Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setup_completed') ?? false;
  }
} 