import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../utils/format_utils.dart';
import 'storage_manager.dart';
import 'product_service.dart';
import 'customer_service.dart';
import 'order_service.dart';

class AIService {
  // API Keys từ Python.py
  final List<String> _apiKeys = [
    "AIzaSyBEfaLoEVOYc2Tft0m63Ae8HuxwaF8pCdA",
    "AIzaSyDmoMtVlGQqKQ8D1fHOxuP5ZBdEQvAgyO4",
    "AIzaSyBCSfatIlev3xZN9MrQlIhSu_dYrxoaExY"
  ];
  int _currentApiKeyIndex = 0;
  
  final StorageManager _storageManager = StorageManager();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final OrderService _orderService = OrderService();

  // Khởi tạo các service
  Future<void> init() async {
    await _productService.init();
    await _customerService.init();
    await _orderService.init();
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
    
    Input: 'Bán 2 chai nước suối, 1 bánh mì'
    Output: {"type_input": "order"}
    
    Input: 'Tạo đơn hàng 3 bút bi, 5 gói mì tôm'
    Output: {"type_input": "order"}
    
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _getWritePromptText(String userInput) {
    final now = DateTime.now();
    return '''Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
    Thời gian hiện tại: ${now.toString().split(' ')[0]}
    Context: Người dùng sẽ nói về doanh thu và chi phí trong ngày. Nếu tiền nợ sẽ tính vào tiền chi phí
    Task: Trích xuất chính xác số tiền và chuyển đổi thành JSON.
    Examples: Input: 'Hôm nay bán được 500k, mua hàng hết 300k' 
    Output: {"doanh_thu": 500000, "chi_phi": 300000,"ghi_chu": "", "ngay_tao": "2024-01-15"} //Ghi chú: ""
    Input: "Thu về 2 triệu 5, chi tiêu 1 triệu 2"
    Output: {"doanh_thu": 2500000, "chi_phi": 1200000,"ghi_chu": "", "ngay_tao": "2024-01-15"} Response (JSON only) không có Json data:  //Ghi chú: ""
    Nếu dữ liệu không liên quan thì trả về 'Error'
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _getOrderPromptText(String userInput, List<Product> availableProducts) {
    final now = DateTime.now();
    final productList = availableProducts.map((p) => 
      '{"name": "${p.name}", "code": "${p.code}", "unit": "${p.unit}", "price": ${p.sellingPrice}}'
    ).join(', ');
    
    return '''Bạn là AI chuyên xử lý đơn hàng bán hàng Việt Nam.
    Thời gian hiện tại: ${now.toString().split(' ')[0]}
    Danh sách sản phẩm có sẵn: [$productList]
    
    Context: Người dùng mô tả đơn hàng bán hàng. Hãy phân tích và trích xuất thông tin sản phẩm.
    Task: Trích xuất thông tin sản phẩm và số lượng, khớp với sản phẩm có sẵn.
    
    Examples:
    Input: 'Bán 2 chai nước suối Lavie, 1 bánh mì sandwich'
    Output: {
      "success": true,
      "items": [
        {"product_name": "Nước suối Lavie 500ml", "quantity": 2, "unit": "Chai", "matched": true},
        {"product_name": "Bánh mì sandwich", "quantity": 1, "unit": "Cái", "matched": true}
      ],
      "customer_name": "",
      "note": ""
    }
    
    Input: 'Khách hàng Anh Minh mua 5 bút bi, 3 gói mì tôm, ghi chú: khách hang quen thuoc'
    Output: {
      "success": true,
      "items": [
        {"product_name": "Bút bi", "quantity": 5, "unit": "Cái", "matched": false},
        {"product_name": "Mì tôm", "quantity": 3, "unit": "Gói", "matched": false}
      ],
      "customer_name": "Anh Minh",
      "note": "khách VIP"
    }
    
    Nếu không khớp sản phẩm thì matched = false, nếu khớp thì matched = true và dùng tên chính xác từ danh sách.
    Nếu dữ liệu không liên quan đến bán hàng thì trả về {"success": false, "reason": "not_order_related"}
    
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _cleanJsonText(String text) {
    String cleanJson = text.trim().replaceAll('`', '').replaceAll('\n', '');
    if (cleanJson.startsWith("json")) {
      cleanJson = cleanJson.substring(4);
    }
    return cleanJson;
  }

  Future<String> callGeminiAPI(String prompt) async {
    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
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

  Future<Map<String, dynamic>> analyzeUserInput(String userInput) async {
    final typeResponse = await callGeminiAPI(_getPromptTypeInput(userInput));
    final cleanTypeJson = _cleanJsonText(typeResponse);
    return jsonDecode(cleanTypeJson);
  }

  Future<FinanceRecord?> extractFinanceData(String userInput) async {
    final entryResponse = await callGeminiAPI(_getWritePromptText(userInput));
    final cleanEntryJson = _cleanJsonText(entryResponse);
    
    if (cleanEntryJson == "Error") {
      return null;
    }
    
    final data = jsonDecode(cleanEntryJson);
    return FinanceRecord(
      id: 0,
      doanhThu: (data["doanh_thu"] ?? 0).toDouble(),
      chiPhi: (data["chi_phi"] ?? 0).toDouble(),
      ghiChu: data["ghi_chu"] ?? "",
      ngayTao: DateTime.parse(data["ngay_tao"]),
    );
  }

  Future<Map<String, dynamic>?> extractOrderData(String userInput) async {
    final products = await _productService.getActiveProducts();
    final orderResponse = await callGeminiAPI(_getOrderPromptText(userInput, products));
    final cleanOrderJson = _cleanJsonText(orderResponse);
    
    try {
      final data = jsonDecode(cleanOrderJson);
      if (data["success"] != true) {
        return null;
      }
      
      // Match products with available products
      final List<Map<String, dynamic>> processedItems = [];
      for (final item in data["items"]) {
        final productName = item["product_name"];
        final quantity = item["quantity"];
        final unit = item["unit"] ?? "Cái";
        final matched = item["matched"] ?? false;
        
        Product? matchedProduct;
        // Luôn thực hiện tìm kiếm, bỏ qua flag "matched" từ AI vì có thể không chính xác
          matchedProduct = _findBestProductMatch(productName, products);
        
        processedItems.add({
          "product": matchedProduct,
          "quantity": quantity,
          "original_name": productName,
          "matched": matchedProduct != null && matchedProduct.id.isNotEmpty,
        });
      }
      
      return {
        "success": true,
        "items": processedItems,
        "customer_name": data["customer_name"] ?? "",
        "note": data["note"] ?? "",
      };
    } catch (e) {
      print('Error parsing order data: $e');
      return null;
    }
  }

  Product? _findBestProductMatch(String searchName, List<Product> products) {
    if (searchName.trim().isEmpty) return null;
    
    final searchLower = searchName.toLowerCase().trim();
    print('🔍 Tìm kiếm sản phẩm: "$searchName" -> "$searchLower"');
    
    // 1. Exact match (khớp chính xác)
    for (final product in products) {
      if (product.name.toLowerCase() == searchLower) {
        print('✅ EXACT MATCH: "${product.name}"');
        return product;
      }
    }
    
    // 2. Exact word match (khớp từ chính xác)
    final searchWords = searchLower.split(' ').where((w) => w.length > 2).toList();
    for (final product in products) {
      final productWords = product.name.toLowerCase().split(' ');
      for (final searchWord in searchWords) {
        for (final productWord in productWords) {
          if (searchWord == productWord && searchWord.length >= 3) {
            print('✅ WORD MATCH: "${product.name}" (từ: "$searchWord")');
            return product;
          }
        }
      }
    }
    
    // 3. Product name contains full search (chỉ 1 chiều)
    for (final product in products) {
      if (product.name.toLowerCase().contains(searchLower) && searchLower.length >= 3) {
        print('✅ CONTAINS MATCH: "${product.name}" chứa "$searchLower"');
        return product;
      }
    }
    
    // 4. Strict keyword match (tất cả từ quan trọng phải match)
    if (searchWords.length >= 2) {
    for (final product in products) {
      final productWords = product.name.toLowerCase().split(' ');
        int exactMatches = 0;
        
        for (final searchWord in searchWords) {
          for (final productWord in productWords) {
            if (searchWord == productWord || 
                (searchWord.length >= 4 && productWord.contains(searchWord)) ||
                (productWord.length >= 4 && searchWord.contains(productWord))) {
              exactMatches++;
              break;
            }
          }
        }
        
        // Phải match ít nhất 80% và tối thiểu 2 từ
        if (exactMatches >= 2 && exactMatches >= (searchWords.length * 0.8).ceil()) {
          print('✅ KEYWORD MATCH: "${product.name}" ($exactMatches/${searchWords.length} từ)');
          return product;
        }
      }
    }
    
    print('❌ Không tìm thấy sản phẩm phù hợp cho: "$searchName"');
    return null; // Không tìm thấy match hợp lệ
  }

  // Tìm khách hàng theo tên (fuzzy search)
  Future<Customer> _findCustomerByName(String customerName) async {
    if (customerName.trim().isEmpty) {
      return Customer.walkIn();
    }

    final customers = await _customerService.getActiveCustomers();
    final searchName = customerName.toLowerCase().trim();
    
    // Tìm khớp chính xác
    for (final customer in customers) {
      if (customer.name.toLowerCase() == searchName) {
        return customer;
      }
    }
    
    // Tìm khớp một phần
    for (final customer in customers) {
      if (customer.name.toLowerCase().contains(searchName) ||
          searchName.contains(customer.name.toLowerCase())) {
        return customer;
      }
    }
    
    // Tìm theo từ khóa
    final searchWords = searchName.split(' ');
    for (final customer in customers) {
      final customerWords = customer.name.toLowerCase().split(' ');
      int matchCount = 0;
      for (final word in searchWords) {
        if (customerWords.any((cw) => cw.contains(word) || word.contains(cw))) {
          matchCount++;
        }
      }
      if (matchCount >= searchWords.length ~/ 2) {
        return customer;
      }
    }
    
    // Không tìm thấy - trả về khách lẻ với tên gợi ý
    return Customer.walkIn().copyWith(name: customerName);
  }

  // Tạo đơn hàng thông minh từ dữ liệu AI
  Future<Map<String, dynamic>> createSmartOrder(Map<String, dynamic> orderData) async {
    try {
      final items = orderData["items"] as List<Map<String, dynamic>>? ?? [];
      final customerName = (orderData["customer_name"] as String? ?? "").trim();
      final note = orderData["note"] as String? ?? "";

      // Kiểm tra có sản phẩm khớp không
      final matchedItems = items.where((item) => item["matched"] == true).toList();
      
      if (matchedItems.isEmpty) {
        return {
          "success": false,
          "reason": "no_products_found",
          "message": "❌ Không tìm thấy sản phẩm phù hợp trong kho hàng. Vui lòng kiểm tra tên sản phẩm.",
          "suggested_products": items.map((item) => item["original_name"]).toList(),
        };
      }

      // Tìm khách hàng
      final customer = await _findCustomerByName(customerName);
      
      // Tạo đơn hàng
      final orderItems = <OrderItem>[]; 
      double totalAmount = 0;
      
      for (final item in matchedItems) {
        final product = item["product"] as Product?; 
        final quantity = item["quantity"] as int? ?? 0;
        
        if (product == null || quantity <= 0) {
          continue; // Bỏ qua item không hợp lệ
        }
        
        // Kiểm tra tồn kho
        if (product.stockQuantity < quantity) {
          return {
            "success": false,
            "reason": "insufficient_stock", 
            "message": "❌ Sản phẩm '${product.name}' không đủ tồn kho. Có sẵn: ${product.stockQuantity}, yêu cầu: $quantity",
            "product": product.name,
            "available": product.stockQuantity,
            "requested": quantity,
          };
        }
        
        final itemTotal = quantity * product.sellingPrice;
        totalAmount += itemTotal;
        
        orderItems.add(OrderItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${product.id}',
          productId: product.id,
          productName: product.name,
          productCode: product.code,
          quantity: quantity,
          unitPrice: product.sellingPrice,
          costPrice: product.costPrice,
          unit: product.unit,
        ));  
      }

      // Tạo Order object với đúng cấu trúc
      final now = DateTime.now();  
      final orderId = now.millisecondsSinceEpoch.toString();
      final orderNumber = Order.generateOrderNumber(now, 1); // Sequence sẽ được tính lại trong OrderService

      final order = Order(
        id: orderId,
        orderNumber: orderNumber,
        orderDate: now,
        status: OrderStatus.paid, // Đơn hàng AI tự động đã thanh toán
        items: orderItems,
        customer: customer,
        note: note,
        createdAt: now,
        updatedAt: now,
      );

      // Lưu đơn hàng
      await _orderService.addOrder(order);

      return {
        "success": true,
        "order": order,
        "message": "✅ Đã tạo đơn hàng thành công!",
        "customer_info": customer.isWalkIn ? "Khách lẻ" : customer.name,
        "total_amount": order.total,
        "item_count": orderItems.length,
      };

    } catch (e) {
      return {
        "success": false,
        "reason": "creation_error",
        "message": "❌ Lỗi khi tạo đơn hàng: $e",
        "error": e.toString(),
      };
    }
  }

  // Xem trước đơn hàng và chuẩn bị thông tin để hỏi người dùng
  Future<Map<String, dynamic>> _previewOrder(Map<String, dynamic> orderData) async {
    try {
      final items = orderData["items"] as List<Map<String, dynamic>>? ?? [];
      final customerName = (orderData["customer_name"] as String? ?? "").trim();
      final note = orderData["note"] as String? ?? "";

      // Kiểm tra có sản phẩm khớp không
      final matchedItems = items.where((item) => item["matched"] == true).toList();
      final unmatchedItems = items.where((item) => item["matched"] != true).toList();
      
      if (matchedItems.isEmpty) {
        return {
          "success": false,
          "reason": "no_products_found",
          "message": "❌ Không tìm thấy sản phẩm phù hợp trong kho hàng",
          "suggested_products": items.map((item) => item["original_name"]).toList(),
          "unmatched_items": unmatchedItems,
        };
      }

      // Tìm khách hàng
      final customer = await _findCustomerByName(customerName);
      
      // Chuẩn bị thông tin đơn hàng để hiển thị
      String itemsPreview = ""; 
      double totalAmount = 0;
      List<Map<String, dynamic>> orderItemsPreview = [];
      List<String> stockIssues = [];
       
      for (final item in matchedItems) {
        final product = item["product"] as Product?;
        final quantity = item["quantity"] as int? ?? 0;
        
        if (product == null || quantity <= 0) {
          continue; // Bỏ qua item không hợp lệ
        }
        
        // Kiểm tra tồn kho
        if (product.stockQuantity < quantity) {
          stockIssues.add("⚠️ ${product.name}: Yêu cầu $quantity, có sẵn ${product.stockQuantity}");
        }
        
        final itemTotal = quantity * product.sellingPrice;
        totalAmount += itemTotal;
        
        itemsPreview += "✅ ${product.name}: ${quantity} ${product.unit} × ${FormatUtils.formatCurrency(product.sellingPrice)} = ${FormatUtils.formatCurrency(itemTotal)} VNĐ\n";
        
        orderItemsPreview.add({
          "product": product,
          "quantity": quantity,
          "unit_price": product.sellingPrice,
          "line_total": itemTotal,
        });
      }

      // Thêm thông tin sản phẩm không khớp
      String unmatchedPreview = "";
      if (unmatchedItems.isNotEmpty) {
        unmatchedPreview = "\n❓ Sản phẩm không tìm thấy:\n";
        for (final item in unmatchedItems) {
          unmatchedPreview += "• ${item["original_name"]}: ${item["quantity"]}\n";
        }
      }

      return {
        "success": true,
        "customer": customer,
        "customer_info": customer.isWalkIn ? "Khách lẻ" : customer.name,
        "matched_items": matchedItems,
        "unmatched_items": unmatchedItems,
        "order_items_preview": orderItemsPreview,
        "total_amount": totalAmount,
        "items_preview": itemsPreview,
        "unmatched_preview": unmatchedPreview,
        "stock_issues": stockIssues,
        "note": note,
        "has_stock_issues": stockIssues.isNotEmpty,
        "has_unmatched": unmatchedItems.isNotEmpty,
      };

    } catch (e) {
      return {
        "success": false,
        "reason": "preview_error",
        "message": "❌ Lỗi khi chuẩn bị thông tin đơn hàng: $e",
        "error": e.toString(),
      };
    }
  }

  String generateReport(Map<String, dynamic> analysis, List<FinanceRecord> records) {
    final reportType = analysis["report_type"];
    final year = analysis["year"] ?? DateTime.now().year;
    
    List<FinanceRecord> filteredRecords = [];
    
    switch (reportType) {
      case "thang":
        final month = analysis["period"] ?? DateTime.now().month;
        filteredRecords = records.where((record) {
          return record.ngayTao.month == month && record.ngayTao.year == year;
        }).toList();
        break;
      case "quy":
        final quarter = analysis["period"] ?? ((DateTime.now().month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        filteredRecords = records.where((record) {
          return record.ngayTao.month >= startMonth &&
              record.ngayTao.month <= endMonth &&
              record.ngayTao.year == year;
        }).toList();
        break;
      case "nam":
        filteredRecords = records.where((record) {
          return record.ngayTao.year == year;
        }).toList();
        break;
      case "ngay":
        final date = DateTime.parse(analysis["date"]);
        filteredRecords = records.where((record) {
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
�� Tổng doanh thu: ${FormatUtils.formatCurrency(totalRevenue)} VNĐ
💸 Tổng chi phí: ${FormatUtils.formatCurrency(totalCost)} VNĐ
📊 Lợi nhuận: ${FormatUtils.formatCurrency(totalProfit)} VNĐ
📈 Số giao dịch: ${filteredRecords.length} 
${totalRevenue > 0 ? '📋 Tỷ lệ lợi nhuận: ${(totalProfit / totalRevenue * 100).toStringAsFixed(2)}%' : ''}''';
  }

  // Tạo metadata cho popup xác nhận đơn hàng  
  Map<String, dynamic> createOrderConfirmationDialog(Map<String, dynamic> previewData) {
    final customerInfo = previewData["customer_info"] as String? ?? "Khách lẻ";
    final totalAmount = previewData["total_amount"] as double? ?? 0.0;
    final itemsPreview = previewData["items_preview"] as String? ?? "";
    final unmatchedPreview = previewData["unmatched_preview"] as String? ?? "";
    final stockIssues = previewData["stock_issues"] as List<String>? ?? [];
    final hasStockIssues = previewData["has_stock_issues"] as bool? ?? false;
    final hasUnmatched = previewData["has_unmatched"] as bool? ?? false;
    final note = previewData["note"] as String? ?? "";
    
    String dialogContent = '''🛒 Xác nhận tạo đơn hàng:
👤 Khách hàng: $customerInfo
$itemsPreview${unmatchedPreview}
💰 Tổng tiền: ${FormatUtils.formatCurrency(totalAmount)} VNĐ${note.isNotEmpty ? '\n📝 Ghi chú: $note' : ''}''';

    // Thêm cảnh báo nếu có
    if (hasStockIssues) {
      dialogContent += "\n\n⚠️ Vấn đề tồn kho:\n";
      for (final issue in stockIssues) {
        dialogContent += "$issue\n";
      }
    }

    if (hasUnmatched) {
      dialogContent += "\n⚠️ Một số sản phẩm không tìm thấy trong kho.";
    }
    
    return {
      "show_dialog": true,
      "dialog_type": "order_confirmation",
      "title": "Xác nhận đơn hàng",
      "content": dialogContent,
      "preview_data": previewData,
      "has_issues": hasStockIssues || hasUnmatched,
      "positive_button": "Tạo đơn hàng",
      "negative_button": "Hủy",
    };
  }

  // Xử lý xác nhận tạo đơn hàng từ người dùng
  Future<Map<String, dynamic>> confirmOrderCreation(Map<String, dynamic> previewData) async {
    try {
      final items = previewData["matched_items"] as List<Map<String, dynamic>>? ?? [];
      final customer = previewData["customer"] as Customer? ?? Customer.walkIn();
      final note = previewData["note"] as String? ?? "";

      // Tạo đơn hàng
      final orderItems = <OrderItem>[];
      double totalAmount = 0;
      
      for (final item in items) {
        final product = item["product"] as Product?;
        final quantity = item["quantity"] as int? ?? 0;
        
        if (product == null || quantity <= 0) {
          continue; // Bỏ qua item không hợp lệ
        }
        
        // Kiểm tra lại tồn kho (có thể đã thay đổi)
        if (product.stockQuantity < quantity) {
          return {
            "success": false,
            "reason": "insufficient_stock_changed", 
            "message": "❌ Tồn kho sản phẩm '${product.name}' đã thay đổi. Có sẵn: ${product.stockQuantity}, yêu cầu: $quantity",
            "product": product.name,
            "available": product.stockQuantity,
            "requested": quantity,
          };
        }
        
        final itemTotal = quantity * product.sellingPrice;
        totalAmount += itemTotal;
        
        orderItems.add(OrderItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${product.id}',
          productId: product.id,
          productName: product.name,
          productCode: product.code,
          quantity: quantity,
          unitPrice: product.sellingPrice,
          costPrice: product.costPrice,
          unit: product.unit,
        ));
      }

      // Tạo Order object
      final now = DateTime.now();
      final orderId = now.millisecondsSinceEpoch.toString();
      final orderNumber = Order.generateOrderNumber(now, 1);
      
      final order = Order(
        id: orderId,
        orderNumber: orderNumber,
        orderDate: now,
        status: OrderStatus.paid,
        items: orderItems,
        customer: customer,
        note: note,
        createdAt: now,
        updatedAt: now,
      );

      // Lưu đơn hàng
      await _orderService.addOrder(order);

      return {
        "success": true,
        "order": order,
        "message": "✅ Đã tạo đơn hàng thành công!",
        "customer_info": customer.isWalkIn ? "Khách lẻ" : customer.name,
        "total_amount": order.total,
        "item_count": orderItems.length,
      };

    } catch (e) {
      return {
        "success": false,
        "reason": "creation_error",
        "message": "❌ Lỗi khi tạo đơn hàng: $e",
        "error": e.toString(),
      };
    }
  }

  // Xóa method xử lý xác nhận qua tin nhắn - giờ dùng popup

  // Xử lý tin nhắn và lưu lịch sử
  Future<ChatMessage> processMessage(String userMessage, List<FinanceRecord> records) async {
    // Lưu tin nhắn của user
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      type: 'user_input',
    );
    await _storageManager.addChatMessage(userChatMessage);

    try {
            // Bỏ logic xử lý xác nhận qua tin nhắn - giờ dùng popup

      // Xử lý bình thường nếu không phải xác nhận đơn hàng
      final analysis = await analyzeUserInput(userMessage);
      String aiResponse = "";
      String messageType = "general";
      Map<String, dynamic>? metadata;

      if (analysis["type_input"] == "entry") {
        // Xử lý nhập liệu
        final record = await extractFinanceData(userMessage);
        messageType = "entry";
        
        if (record == null) {
          aiResponse = "Dữ liệu không liên quan đến tài chính. Vui lòng nhập thông tin về doanh thu và chi phí.";
          metadata = {"success": false, "reason": "invalid_data"};
        } else {
          aiResponse = '''📝 Dữ liệu đã được xử lý:
💰 Doanh thu: ${FormatUtils.formatCurrency(record.doanhThu)} VNĐ
💸 Chi phí: ${FormatUtils.formatCurrency(record.chiPhi)} VNĐ
📊 Lợi nhuận: ${FormatUtils.formatCurrency(record.loiNhuan)} VNĐ
📅 Ngày: ${FormatUtils.formatSimpleDate(record.ngayTao)}
✏️ Ghi chú: ${record.ghiChu}
          ''';
          metadata = {
            "success": true,
            "record": record.toJson(),
            "revenue": record.doanhThu,
            "cost": record.chiPhi,
            "profit": record.loiNhuan,
          };
        }
      } else if (analysis["type_input"] == "order") {
        // Xử lý đơn hàng thông minh
        final orderData = await extractOrderData(userMessage);
        messageType = "order";
        
        if (orderData == null || orderData["success"] != true) {
          aiResponse = "❌ Không thể trích xuất thông tin đơn hàng. Vui lòng mô tả rõ sản phẩm và số lượng.";
          metadata = {"success": false, "reason": "invalid_order_data"};
        } else {
          // Chuẩn bị thông tin đơn hàng và hỏi ý kiến người dùng
          final previewResult = await _previewOrder(orderData);
          
                    if (previewResult["success"] == true) {
            // Tạo dialog xác nhận thay vì yêu cầu người dùng nhập tin nhắn
            final dialogData = createOrderConfirmationDialog(previewResult);
            
            aiResponse = "🔍 Đã phân tích đơn hàng thành công!\n📱 Vui lòng xem popup xác nhận để tiếp tục.";
            
            metadata = {
              "success": true,
              "order_preview": true,
              "preview_data": previewResult,
              "total_amount": previewResult["total_amount"],
              "customer_type": (previewResult["customer"] as Customer?)?.isWalkIn == true ? "walk_in" : "registered",
              "has_issues": previewResult["has_issues"] ?? false,
              "dialog_data": dialogData,
            };
            } else {
            // Không thể tạo preview đơn hàng
            aiResponse = previewResult["message"] as String? ?? "Lỗi xử lý đơn hàng";
            
            // Thêm thông tin chi tiết dựa vào lý do lỗi
            final reason = previewResult["reason"] as String? ?? "unknown_error";
            if (reason == "no_products_found") {
              final suggestedProducts = previewResult["suggested_products"] as List<dynamic>? ?? [];
              aiResponse += "\n\n🔍 Sản phẩm bạn đề cập:\n";
              for (final product in suggestedProducts) {
                aiResponse += "• $product\n";
              }
              aiResponse += "\n💡 Vui lòng kiểm tra danh sách sản phẩm có sẵn hoặc thêm sản phẩm mới vào kho.";
            }
          
          metadata = {
              "success": false,
              "reason": reason,
              "order_preview": false,
            };
          }
        }
      } else if (analysis["type_input"] == "report") {
        // Xử lý báo cáo
        messageType = "report";
        aiResponse = generateReport(analysis, records);
        metadata = {
          "report_type": analysis["report_type"],
          "period": analysis["period"],
          "year": analysis["year"],
          "date": analysis["date"],
        };
      } else {
        // Xử lý câu hỏi chung
        messageType = "search";
        final generalResponse = await callGeminiAPI("$userMessage Giải thích ngắn gọn về kế toán và tài chính");
        aiResponse = generalResponse;
        metadata = {"query": userMessage};
      }

      // Tạo và lưu tin nhắn phản hồi của AI
      final aiChatMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        type: messageType,
        metadata: metadata,
      );
      await _storageManager.addChatMessage(aiChatMessage);

      return aiChatMessage;
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Lỗi khi xử lý: $e",
        isUser: false,
        type: "error",
        metadata: {"error": e.toString()},
      );
              await _storageManager.addChatMessage(errorMessage);
      return errorMessage;
    }
  } 

  // Method public để UI gọi khi người dùng xác nhận từ popup
  Future<ChatMessage> handleOrderConfirmation(bool confirmed, Map<String, dynamic> previewData) async {
    String aiResponse = "";
    Map<String, dynamic>? metadata; 
     
    if (confirmed) {
      // Người dùng đồng ý tạo đơn hàng
      final confirmResult = await confirmOrderCreation(previewData);
      
      if (confirmResult["success"] == true) {
        final order = confirmResult["order"] as Order?;
        final customerInfo = confirmResult["customer_info"] as String? ?? "Khách lẻ";
        final totalAmount = confirmResult["total_amount"] as double? ?? 0.0;
        final itemCount = confirmResult["item_count"] as int? ?? 0;
        
        if (order == null) {
          throw Exception("Lỗi: Không thể tạo đơn hàng");
        }
        
        String itemsText = "";
        for (final item in order.items) {
          final lineTotal = item.quantity * item.unitPrice;
          itemsText += "✅ ${item.productName}: ${item.quantity} ${item.unit} × ${FormatUtils.formatCurrency(item.unitPrice)} = ${FormatUtils.formatCurrency(lineTotal)} VNĐ\n";
        }
        
        aiResponse = '''🎉 Đã tạo đơn hàng thành công!
🆔 Mã đơn: ${order.orderNumber}
👤 Khách hàng: $customerInfo
$itemsText
💰 Tổng tiền: ${FormatUtils.formatCurrency(totalAmount)} VNĐ
📦 Số sản phẩm: $itemCount
📅 Thời gian: ${FormatUtils.formatSimpleDate(order.createdAt)}
${order.note.isNotEmpty ? '📝 Ghi chú: ${order.note}\n' : ''}
✨ Đơn hàng đã được lưu vào hệ thống và tồn kho đã được cập nhật!''';
        
        metadata = {
          "success": true,
          "order_created": true,
          "order_id": order.id,
          "order_number": order.orderNumber,
          "total_amount": totalAmount,
          "item_count": itemCount,
        };
      } else {
        aiResponse = confirmResult["message"] as String? ?? "Lỗi không xác định";
        metadata = {
          "success": false,
          "reason": confirmResult["reason"] ?? "unknown_error",
          "order_created": false,
        };
      }
    } else {
      // Người dùng từ chối tạo đơn hàng
      aiResponse = "❌ Đã hủy tạo đơn hàng theo yêu cầu của bạn.\n💡 Bạn có thể mô tả lại đơn hàng khác nếu muốn.";
      metadata = {
        "success": false,
        "reason": "user_cancelled",
        "order_created": false,
      };
    }
    
    final aiChatMessage = ChatMessage(
      text: aiResponse,
      isUser: false,
      type: "order_confirmation",
      metadata: metadata,
    );
    await _storageManager.addChatMessage(aiChatMessage);
    return aiChatMessage;
  }

  // Lấy lịch sử chat
  Future<List<ChatMessage>> getChatHistory() async {
    return await _storageManager.getChatHistory();
  }

  // Xóa lịch sử chat
  Future<void> clearChatHistory() async {
    await _storageManager.clearChatHistory();
  }

  // Lấy thống kê chat
  Future<Map<String, dynamic>> getChatStatistics() async {
    final chatHistory = await getChatHistory();
    final userMessages = chatHistory.where((msg) => msg.isUser).length;
    final aiMessages = chatHistory.where((msg) => !msg.isUser).length;
    
    // Đếm theo loại tin nhắn
    final entryMessages = chatHistory.where((msg) => msg.type == 'entry').length;
    final reportMessages = chatHistory.where((msg) => msg.type == 'report').length;
    final searchMessages = chatHistory.where((msg) => msg.type == 'search').length;
    final errorMessages = chatHistory.where((msg) => msg.type == 'error').length;

    return {
      'totalMessages': chatHistory.length,
      'userMessages': userMessages,
      'aiMessages': aiMessages,
      'entryMessages': entryMessages,
      'reportMessages': reportMessages,
      'searchMessages': searchMessages,
      'errorMessages': errorMessages,
      'lastMessageTime': chatHistory.isNotEmpty ? chatHistory.last.timestamp.toIso8601String() : null,
    };
  }
} 