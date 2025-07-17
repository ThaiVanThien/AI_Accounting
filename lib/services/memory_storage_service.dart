import '../models/finance_record.dart';
import '../models/chat_message.dart';

class MemoryStorageService {
  // Singleton pattern
  static final MemoryStorageService _instance = MemoryStorageService._internal();
  factory MemoryStorageService() => _instance;
  MemoryStorageService._internal();

  // In-memory storage
  List<FinanceRecord> _records = [];
  List<ChatMessage> _messages = [];
  int _nextId = 1;

  // Finance Records Methods
  Future<List<FinanceRecord>> getFinanceRecords() async {
    return List.from(_records);
  }

  Future<bool> saveFinanceRecords(List<FinanceRecord> records) async {
    _records = List.from(records);
    return true;
  }

  Future<bool> addFinanceRecord(FinanceRecord record) async {
    _records.add(record);
    return true;
  }

  Future<bool> deleteFinanceRecord(int id) async {
    _records.removeWhere((record) => record.id == id);
    return true;
  }

  // Chat History Methods
  Future<List<ChatMessage>> getChatHistory() async {
    return List.from(_messages);
  }

  Future<bool> saveChatHistory(List<ChatMessage> messages) async {
    _messages = List.from(messages);
    return true;
  }

  Future<bool> addChatMessage(ChatMessage message) async {
    _messages.add(message);
    return true;
  }

  Future<bool> clearChatHistory() async {
    _messages.clear();
    return true;
  }

  // Next ID Methods
  Future<int> getNextId() async {
    return _nextId;
  }

  Future<bool> setNextId(int id) async {
    _nextId = id;
    return true;
  }

  Future<int> getAndIncrementNextId() async {
    final currentId = _nextId;
    _nextId++;
    return currentId;
  }

  // Statistics Methods
  Future<Map<String, dynamic>> getStatistics() async {
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
  }

  // Clear all data
  Future<bool> clearAllData() async {
    _records.clear();
    _messages.clear();
    _nextId = 1;
    return true;
  }

  // Export data to JSON
  Future<Map<String, dynamic>> exportData() async {
    final records = await getFinanceRecords();
    final chatHistory = await getChatHistory();
    final nextId = await getNextId();
    
    return {
      'finance_records': records.map((r) => r.toJson()).toList(),
      'chat_history': chatHistory.map((m) => m.toJson()).toList(),
      'next_id': nextId,
      'export_date': DateTime.now().toIso8601String(),
      'storage_type': 'memory',
    };
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
      print('Error importing data to memory storage: $e');
      return false;
    }
  }

  // Check if storage is available
  Future<bool> isStorageAvailable() async {
    return true; // Memory storage is always available
  }
} 