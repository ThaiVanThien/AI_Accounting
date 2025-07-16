import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

void main() {
  runApp(const KeToAnApp());
}

class KeToAnApp extends StatelessWidget {
  const KeToAnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kế Toán AI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class FinanceRecord {
  final int id;
  final double doanhThu;
  final double chiPhi;
  final String ghiChu;
  final DateTime ngayTao;

  FinanceRecord({
    required this.id,
    required this.doanhThu,
    required this.chiPhi,
    required this.ghiChu,
    required this.ngayTao,
  });

  double get loiNhuan => doanhThu - chiPhi;
}

class Report {
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final String typeReport;

  Report({
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.typeReport,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<FinanceRecord> _records = [];
  int _nextId = 1;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      DataEntryScreen(
        onAddRecord: _addRecord,
      ),
      AIInputScreen(
        onAddRecord: _addRecord,
        records: _records,
      ),
      ReportScreen(records: _records),
      RecordListScreen(records: _records),
    ]);
  }

  void _addRecord(FinanceRecord record) {
    setState(() {
      _records.add(FinanceRecord(
        id: _nextId++,
        doanhThu: record.doanhThu,
        chiPhi: record.chiPhi,
        ghiChu: record.ghiChu,
        ngayTao: record.ngayTao,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Nhập liệu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Danh sách',
          ),
        ],
      ),
    );
  }
}

class DataEntryScreen extends StatefulWidget {
  final Function(FinanceRecord) onAddRecord;

  const DataEntryScreen({super.key, required this.onAddRecord});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doanhThuController = TextEditingController();
  final _chiPhiController = TextEditingController();
  final _ghiChuController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _doanhThuController.dispose();
    _chiPhiController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final record = FinanceRecord(
        id: 0,
        doanhThu: double.parse(_doanhThuController.text.replaceAll(',', '')),
        chiPhi: double.parse(_chiPhiController.text.replaceAll(',', '')),
        ghiChu: _ghiChuController.text,
        ngayTao: _selectedDate,
      );

      widget.onAddRecord(record);

      // Reset form
      _doanhThuController.clear();
      _chiPhiController.clear();
      _ghiChuController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm dữ liệu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Dữ Liệu Tài Chính'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _doanhThuController,
                        decoration: const InputDecoration(
                          labelText: 'Doanh Thu (VNĐ)',
                          prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập doanh thu';
                          }
                          if (double.tryParse(value.replaceAll(',', '')) == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _chiPhiController,
                        decoration: const InputDecoration(
                          labelText: 'Chi Phí (VNĐ)',
                          prefixIcon: Icon(Icons.money_off, color: Colors.red),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập chi phí';
                          }
                          if (double.tryParse(value.replaceAll(',', '')) == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ghiChuController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi Chú',
                          prefixIcon: Icon(Icons.note, color: Colors.blue),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              }
                            },
                            child: const Text('Chọn ngày'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Thêm Dữ Liệu',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportScreen extends StatefulWidget {
  final List<FinanceRecord> records;

  const ReportScreen({super.key, required this.records});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedReportType = 'thang';
  int _selectedMonth = DateTime.now().month;
  int _selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int _selectedYear = DateTime.now().year;

  Report _generateReport() {
    List<FinanceRecord> filteredRecords = [];

    switch (_selectedReportType) {
      case 'thang':
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.month == _selectedMonth &&
              record.ngayTao.year == _selectedYear;
        }).toList();
        break;
      case 'quy':
        int startMonth = (_selectedQuarter - 1) * 3 + 1;
        int endMonth = _selectedQuarter * 3;
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.month >= startMonth &&
              record.ngayTao.month <= endMonth &&
              record.ngayTao.year == _selectedYear;
        }).toList();
        break;
      case 'nam':
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.year == _selectedYear;
        }).toList();
        break;
    }

    double totalRevenue = filteredRecords.fold(0, (sum, record) => sum + record.doanhThu);
    double totalCost = filteredRecords.fold(0, (sum, record) => sum + record.chiPhi);
    double totalProfit = totalRevenue - totalCost;

    return Report(
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      typeReport: _selectedReportType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _generateReport();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Tài Chính'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Loại báo cáo: '),
                        DropdownButton<String>(
                          value: _selectedReportType,
                          onChanged: (value) {
                            setState(() {
                              _selectedReportType = value!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'thang', child: Text('Tháng')),
                            DropdownMenuItem(value: 'quy', child: Text('Quý')),
                            DropdownMenuItem(value: 'nam', child: Text('Năm')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedReportType == 'thang')
                      Row(
                        children: [
                          const Text('Tháng: '),
                          DropdownButton<int>(
                            value: _selectedMonth,
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value!;
                              });
                            },
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1}'),
                              );
                            }),
                          ),
                          const SizedBox(width: 20),
                          const Text('Năm: '),
                          DropdownButton<int>(
                            value: _selectedYear,
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value!;
                              });
                            },
                            items: List.generate(5, (index) {
                              int year = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              );
                            }),
                          ),
                        ],
                      ),
                    if (_selectedReportType == 'quy')
                      Row(
                        children: [
                          const Text('Quý: '),
                          DropdownButton<int>(
                            value: _selectedQuarter,
                            onChanged: (value) {
                              setState(() {
                                _selectedQuarter = value!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Quý 1')),
                              DropdownMenuItem(value: 2, child: Text('Quý 2')),
                              DropdownMenuItem(value: 3, child: Text('Quý 3')),
                              DropdownMenuItem(value: 4, child: Text('Quý 4')),
                            ],
                          ),
                          const SizedBox(width: 20),
                          const Text('Năm: '),
                          DropdownButton<int>(
                            value: _selectedYear,
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value!;
                              });
                            },
                            items: List.generate(5, (index) {
                              int year = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              );
                            }),
                          ),
                        ],
                      ),
                    if (_selectedReportType == 'nam')
                      Row(
                        children: [
                          const Text('Năm: '),
                          DropdownButton<int>(
                            value: _selectedYear,
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value!;
                              });
                            },
                            items: List.generate(5, (index) {
                              int year = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              );
                            }),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Báo cáo ${_selectedReportType == 'thang' ? 'tháng $_selectedMonth' : _selectedReportType == 'quy' ? 'quý $_selectedQuarter' : 'năm'} $_selectedYear',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildReportItem(
                        'Tổng Doanh Thu',
                        report.totalRevenue,
                        Colors.green,
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 12),
                      _buildReportItem(
                        'Tổng Chi Phí',
                        report.totalCost,
                        Colors.red,
                        Icons.trending_down,
                      ),
                      const SizedBox(height: 12),
                      _buildReportItem(
                        'Lợi Nhuận',
                        report.totalProfit,
                        report.totalProfit >= 0 ? Colors.green : Colors.red,
                        report.totalProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      const SizedBox(height: 20),
                      if (report.totalRevenue > 0)
                        Text(
                          'Tỷ lệ lợi nhuận: ${(report.totalProfit / report.totalRevenue * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(value)} VNĐ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AIInputScreen extends StatefulWidget {
  final Function(FinanceRecord) onAddRecord;
  final List<FinanceRecord> records;

  const AIInputScreen({super.key, required this.onAddRecord, required this.records});

  @override
  State<AIInputScreen> createState() => _AIInputScreenState();
}

class _AIInputScreenState extends State<AIInputScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // API Keys từ Python.py
  final List<String> _apiKeys = [
    "AIzaSyBEfaLoEVOYc2Tft0m63Ae8HuxwaF8pCdA",
    "AIzaSyDmoMtVlGQqKQ8D1fHOxuP5ZBdEQvAgyO4",
    "AIzaSyBCSfatIlev3xZN9MrQlIhSu_dYrxoaExY"
  ];
  int _currentApiKeyIndex = 0;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _getPromptTypeInput(String userInput) {
    final now = DateTime.now();
    return '''Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
    DateTime: $now
    Context: Người dùng yêu cầu nhập hoặc báo cáo
    Task: Hãy xác định chính xác yêu cầu của người dùng và chuyển đổi thành JSON
    
    Examples:
    Input: 'Hôm nay bán được 500k, mua hàng hết 300k'
    Output: {"type_input": "entry"}
    
    Input: 'Báo cáo doanh thu quý 3'
    Output: {"type_input": "report", "report_type": "quy", "period": 3, "year": 2025}
    
    Input: 'Báo cáo tháng 7'
    Output: {"type_input": "report", "report_type": "thang", "period": 7, "year": 2025}
    
    Input: 'Báo cáo năm 2024'
    Output: {"type_input": "report", "report_type": "nam", "year": 2024}
    
    Input: 'Xem báo cáo hôm nay'
    Output: {"type_input": "report", "report_type": "ngay", "date": "${now.toString().split(' ')[0]}"}
    
    Input: 'Kế toán là gì'
    Output: {"type_input": "search"}
    
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _getWritePromptText(String userInput) {
    final now = DateTime.now();
    return '''Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
Thời gian hiện tại: ${now.toString().split(' ')[0]}
Context: Người dùng sẽ nói về doanh thu và chi phí trong ngày. Nếu tiền nợ sẽ tính vào tiền chi phí
Task: Trích xuất chính xác số tiền và chuyển đổi thành JSON.
Examples: Input: 'Hôm nay bán được 500k, mua hàng hết 300k' 
Output: {"doanh_thu": 500000, "chi_phi": 300000,"ghi_chu": "Lấy thông tin từ input có thể để trống", "ngay_tao": "2024-01-15"} 
Input: "Thu về 2 triệu 5, chi tiêu 1 triệu 2"
Output: {"doanh_thu": 2500000, "chi_phi": 1200000,"ghi_chu": "Lấy thông tin từ input có thể để trống", "ngay_tao": "2024-01-15"} Response (JSON only) không có Json data:
Nếu dữ liệu không liên quan thì trả về 'Error'
Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _cleanJsonText(String text) {
    String cleanJson = text.trim().replaceAll('`', '').replaceAll('\n', '');
    if (cleanJson.startsWith("json")) {
      cleanJson = cleanJson.substring(4);
    }
    return cleanJson;
  }

  Future<String> _callGeminiAPI(String prompt) async {
    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKeys[_currentApiKeyIndex],
        );

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        } else {
          throw Exception("Empty response from API");
        }
      } catch (e) {
        print('Lỗi API key ${_currentApiKeyIndex + 1}: $e');
        _currentApiKeyIndex = (_currentApiKeyIndex + 1) % _apiKeys.length;
        if (attempt == _apiKeys.length - 1) {
          throw Exception("Đã thử hết tất cả API keys nhưng vẫn lỗi: $e");
        }
      }
    }
    throw Exception("Không thể gọi API");
  }

  String _generateReport(Map<String, dynamic> analysis) {
    final reportType = analysis["report_type"];
    final year = analysis["year"] ?? DateTime.now().year;
    
    List<FinanceRecord> filteredRecords = [];
    
    switch (reportType) {
      case "thang":
        final month = analysis["period"] ?? DateTime.now().month;
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.month == month && record.ngayTao.year == year;
        }).toList();
        break;
      case "quy":
        final quarter = analysis["period"] ?? ((DateTime.now().month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.month >= startMonth &&
              record.ngayTao.month <= endMonth &&
              record.ngayTao.year == year;
        }).toList();
        break;
      case "nam":
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.year == year;
        }).toList();
        break;
      case "ngay":
        final date = DateTime.parse(analysis["date"]);
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.year == date.year &&
              record.ngayTao.month == date.month &&
              record.ngayTao.day == date.day;
        }).toList();
        break;
    }

    double totalRevenue = filteredRecords.fold(0, (sum, record) => sum + record.doanhThu);
    double totalCost = filteredRecords.fold(0, (sum, record) => sum + record.chiPhi);
    double totalProfit = totalRevenue - totalCost;

    String reportTitle = "";
    switch (reportType) {
      case "thang":
        reportTitle = "Báo cáo tháng ${analysis["period"]}/$year";
        break;
      case "quy":
        reportTitle = "Báo cáo quý ${analysis["period"]}/$year";
        break;
      case "nam":
        reportTitle = "Báo cáo năm $year";
        break;
      case "ngay":
        reportTitle = "Báo cáo ngày ${analysis["date"]}";
        break;
    }

    return '''$reportTitle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 Tổng doanh thu: ${NumberFormat('#,###').format(totalRevenue)} VNĐ
💸 Tổng chi phí: ${NumberFormat('#,###').format(totalCost)} VNĐ
📊 Lợi nhuận: ${NumberFormat('#,###').format(totalProfit)} VNĐ
📈 Số giao dịch: ${filteredRecords.length}
${totalRevenue > 0 ? '📋 Tỷ lệ lợi nhuận: ${(totalProfit / totalRevenue * 100).toStringAsFixed(2)}%' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });

    try {
      // Bước 1: Xác định loại input
      final typeResponse = await _callGeminiAPI(_getPromptTypeInput(userMessage));
      final cleanTypeJson = _cleanJsonText(typeResponse);
      final analysis = jsonDecode(cleanTypeJson);

      String aiResponse = "";

      if (analysis["type_input"] == "entry") {
        // Bước 2: Xử lý nhập liệu
        final entryResponse = await _callGeminiAPI(_getWritePromptText(userMessage));
        final cleanEntryJson = _cleanJsonText(entryResponse);
        
        if (cleanEntryJson == "Error") {
          aiResponse = "Dữ liệu không liên quan đến tài chính. Vui lòng nhập thông tin về doanh thu và chi phí.";
        } else {
          final data = jsonDecode(cleanEntryJson);
          final record = FinanceRecord(
            id: 0,
            doanhThu: (data["doanh_thu"] ?? 0).toDouble(),
            chiPhi: (data["chi_phi"] ?? 0).toDouble(),
            ghiChu: data["ghi_chu"] ?? "",
            ngayTao: DateTime.parse(data["ngay_tao"]),
          );

          // Hiển thị xác nhận
          aiResponse = '''📝 Dữ liệu đã được xử lý:
💰 Doanh thu: ${NumberFormat('#,###').format(record.doanhThu)} VNĐ
💸 Chi phí: ${NumberFormat('#,###').format(record.chiPhi)} VNĐ
📊 Lợi nhuận: ${NumberFormat('#,###').format(record.loiNhuan)} VNĐ
📅 Ngày: ${DateFormat('dd/MM/yyyy').format(record.ngayTao)}
📝 Ghi chú: ${record.ghiChu}

✅ Dữ liệu đã được thêm vào hệ thống!''';

          // Thêm record vào danh sách
          widget.onAddRecord(record);
        }
      } else if (analysis["type_input"] == "report") {
        // Bước 3: Xử lý báo cáo
        aiResponse = _generateReport(analysis);
      } else {
        // Bước 4: Xử lý câu hỏi chung
        final generalResponse = await _callGeminiAPI("$userMessage Giải thích ngắn gọn về kế toán và tài chính");
        aiResponse = generalResponse;
      }

      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Lỗi khi xử lý: $e", isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat - Kế Toán'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Chào bạn! Tôi có thể giúp bạn:\n\n'
                      '💰 Nhập dữ liệu tài chính\n'
                      '📊 Tạo báo cáo\n'
                      '❓ Trả lời câu hỏi về kế toán\n\n'
                      'Hãy nhập tin nhắn để bắt đầu!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 12),
                  Text('AI đang xử lý...'),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor: Colors.green,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class RecordListScreen extends StatelessWidget {
  final List<FinanceRecord> records;

  const RecordListScreen({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Giao Dịch'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'Chưa có dữ liệu nào',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record.loiNhuan >= 0 ? Colors.green : Colors.red,
                      child: Icon(
                        record.loiNhuan >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      DateFormat('dd/MM/yyyy').format(record.ngayTao),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Doanh thu: ${NumberFormat('#,###').format(record.doanhThu)} VNĐ'),
                        Text('Chi phí: ${NumberFormat('#,###').format(record.chiPhi)} VNĐ'),
                        if (record.ghiChu.isNotEmpty) Text('Ghi chú: ${record.ghiChu}'),
                      ],
                    ),
                    trailing: Text(
                      '${NumberFormat('#,###').format(record.loiNhuan)} VNĐ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: record.loiNhuan >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
