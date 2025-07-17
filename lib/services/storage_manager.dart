import '../models/finance_record.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';
import 'memory_storage_service.dart';

class StorageManager {
  // Singleton pattern
  static final StorageManager _instance = StorageManager._internal();
  factory StorageManager() => _instance;
  StorageManager._internal();

  final StorageService _persistentStorage = StorageService();
  final MemoryStorageService _memoryStorage = MemoryStorageService();
  
  bool _isPersistentStorageAvailable = false;
  bool _isInitialized = false;

  // Initialize và kiểm tra storage availability
  Future<void> init() async {
    if (_isInitialized) return;
    
    _isPersistentStorageAvailable = await _persistentStorage.isStorageAvailable();
    _isInitialized = true;
    
    print('Storage Manager initialized. Persistent storage available: $_isPersistentStorageAvailable');
    
    if (!_isPersistentStorageAvailable) {
      print('Warning: Using memory storage only. Data will not persist between app restarts.');
    }
  }

  // Lấy storage service phù hợp
  dynamic get _currentStorage {
    return _isPersistentStorageAvailable ? _persistentStorage : _memoryStorage;
  }

  // Finance Records Methods
  Future<List<FinanceRecord>> getFinanceRecords() async {
    await init();
    return await _currentStorage.getFinanceRecords();
  }

  Future<bool> saveFinanceRecords(List<FinanceRecord> records) async {
    await init();
    return await _currentStorage.saveFinanceRecords(records);
  }

  Future<bool> addFinanceRecord(FinanceRecord record) async {
    await init();
    return await _currentStorage.addFinanceRecord(record);
  }

  Future<bool> deleteFinanceRecord(int id) async {
    await init();
    return await _currentStorage.deleteFinanceRecord(id);
  }

  // Chat History Methods
  Future<List<ChatMessage>> getChatHistory() async {
    await init();
    return await _currentStorage.getChatHistory();
  }

  Future<bool> saveChatHistory(List<ChatMessage> messages) async {
    await init();
    return await _currentStorage.saveChatHistory(messages);
  }

  Future<bool> addChatMessage(ChatMessage message) async {
    await init();
    return await _currentStorage.addChatMessage(message);
  }

  Future<bool> clearChatHistory() async {
    await init();
    return await _currentStorage.clearChatHistory();
  }

  // Next ID Methods
  Future<int> getNextId() async {
    await init();
    return await _currentStorage.getNextId();
  }

  Future<bool> setNextId(int id) async {
    await init();
    return await _currentStorage.setNextId(id);
  }

  Future<int> getAndIncrementNextId() async {
    await init();
    return await _currentStorage.getAndIncrementNextId();
  }

  // Statistics Methods
  Future<Map<String, dynamic>> getStatistics() async {
    await init();
    final stats = await _currentStorage.getStatistics();
    stats['storage_type'] = _isPersistentStorageAvailable ? 'persistent' : 'memory';
    return stats;
  }

  // Clear all data
  Future<bool> clearAllData() async {
    await init();
    return await _currentStorage.clearAllData();
  }

  // Export data to JSON
  Future<Map<String, dynamic>> exportData() async {
    await init();
    final data = await _currentStorage.exportData();
    data['storage_type'] = _isPersistentStorageAvailable ? 'persistent' : 'memory';
    return data;
  }

  // Import data from JSON
  Future<bool> importData(Map<String, dynamic> data) async {
    await init();
    return await _currentStorage.importData(data);
  }

  // Check if storage is available
  Future<bool> isStorageAvailable() async {
    await init();
    return await _currentStorage.isStorageAvailable();
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    await init();
    return {
      'isPersistentStorageAvailable': _isPersistentStorageAvailable,
      'currentStorageType': _isPersistentStorageAvailable ? 'persistent' : 'memory',
      'isInitialized': _isInitialized,
    };
  }

  // Force refresh storage availability
  Future<void> refreshStorageAvailability() async {
    _isPersistentStorageAvailable = await _persistentStorage.isStorageAvailable();
    print('Storage availability refreshed: $_isPersistentStorageAvailable');
  }
} 