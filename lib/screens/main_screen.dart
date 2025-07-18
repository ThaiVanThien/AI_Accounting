import 'package:flutter/material.dart';
import '../models/finance_record.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/storage_manager.dart';
import 'data_entry_screen.dart';
import 'ai_input_screen.dart';
import 'report_screen.dart';
import 'record_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<FinanceRecord> _records = [];
  int _nextId = 1;
  bool _isLoading = true;
  
  final StorageManager _storageManager = StorageManager();
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load dữ liệu từ storage
      final records = await _storageManager.getFinanceRecords();
      final nextId = await _storageManager.getNextId();
      final storageInfo = await _storageManager.getStorageInfo();
      
      setState(() {
        _records = records;
        _nextId = nextId;
        _isLoading = false;
      });
      
      // Hiển thị thông báo về loại storage
      if (mounted && !storageInfo['isPersistentStorageAvailable']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Chỉ sử dụng bộ nhớ tạm thời. Dữ liệu sẽ mất khi thoát app.'),
            backgroundColor: AppColors.warningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Khởi tạo screens sau khi load data
      _initializeScreens();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      _initializeScreens();
    }
  }

  void _initializeScreens() {
    _screens.clear();
    _screens.addAll([
      DataEntryScreen(
        onAddRecord: _addRecord,
      ),
      AIInputScreen(
        onAddRecord: _addRecord,
        records: _records,
      ),
      ReportScreen(records: _records),
      RecordListScreen(
        records: _records,
        onDeleteRecord: _deleteRecord,
        onUpdateRecord: _updateRecord,
      ),
    ]);
  }

  Future<void> _addRecord(FinanceRecord record) async {
    try {
      // Tạo record với ID mới
      final newRecord = record.copyWith(id: _nextId);
      
      // Thêm vào danh sách local
      setState(() {
        _records.add(newRecord);
        _nextId++;
      });
      
      // Lưu vào storage
      final success = await _storageManager.addFinanceRecord(newRecord);
      if (success) {
        await _storageManager.setNextId(_nextId);
      } else {
        // Rollback nếu không lưu được
        setState(() {
          _records.removeLast();
          _nextId--;
        });
        throw Exception('Không thể lưu dữ liệu');
      }
      
      // Cập nhật lại screens
      _initializeScreens();
      
    } catch (e) {
      print('Error adding record: $e');
      // Rollback nếu có lỗi
      setState(() {
        if (_records.isNotEmpty) _records.removeLast();
        _nextId--;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecord(int id) async {
    try {
      // Tìm record cần xóa
      final recordIndex = _records.indexWhere((record) => record.id == id);
      if (recordIndex == -1) return;
      
      final deletedRecord = _records[recordIndex];
      
      // Xóa khỏi danh sách local
      setState(() {
        _records.removeAt(recordIndex);
      });
      
      // Xóa khỏi storage
      final success = await _storageManager.deleteFinanceRecord(id);
      if (!success) {
        // Rollback nếu không xóa được
        setState(() {
          _records.insert(recordIndex, deletedRecord);
        });
        throw Exception('Không thể xóa dữ liệu');
      }
      
      // Cập nhật lại screens
      _initializeScreens();
      
      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa giao dịch thành công'),
            backgroundColor: AppColors.successColor,
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () => _addRecord(deletedRecord),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateRecord(FinanceRecord updatedRecord) async {
    try {
      // Tìm và cập nhật record
      final recordIndex = _records.indexWhere((record) => record.id == updatedRecord.id);
      if (recordIndex == -1) return;
      
      final oldRecord = _records[recordIndex];
      
      setState(() {
        _records[recordIndex] = updatedRecord;
      });
      
      // Lưu lại toàn bộ danh sách
      final success = await _storageManager.saveFinanceRecords(_records);
      if (!success) {
        // Rollback nếu không lưu được
        setState(() {
          _records[recordIndex] = oldRecord;
        });
        throw Exception('Không thể cập nhật dữ liệu');
      }
      
      // Cập nhật lại screens
      _initializeScreens();
      
    } catch (e) {
      print('Error updating record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                ),
                const SizedBox(height: AppStyles.spacingL),
                Text(
                  'Đang tải dữ liệu...',
                  style: AppStyles.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: _screens.isNotEmpty ? _screens[_currentIndex] : const SizedBox(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppStyles.radiusL),
            topRight: Radius.circular(AppStyles.radiusL),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppStyles.radiusL),
            topRight: Radius.circular(AppStyles.radiusL),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.textOnMain,
            unselectedItemColor: AppColors.textOnMain.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.add_circle_outline, size: 26),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.add_circle, size: 26),
                ),
                label: 'Nhập liệu (${_records.length})',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.smart_toy_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.smart_toy, size: 26),
                ),
                label: 'AI Chat',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.bar_chart_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.bar_chart, size: 26),
                ),
                label: 'Báo cáo',
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.list_alt_outlined, size: 26),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.list_alt, size: 26),
                ),
                label: 'DS (${_records.length})',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 