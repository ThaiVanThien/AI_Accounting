# Hướng dẫn debug vấn đề Order Items = 0

## Vấn đề đã được báo cáo

**Khi mới đầu add thì order không nhận sản phẩm sp = 0, nhưng khi tắt app bật lại thì nó mới hiển thị số tiền và sản phẩm**

## Nguyên nhân có thể xảy ra

### 1. **Lỗi trong việc tạo OrderItem**
- `OrderItem.fromProduct()` không hoạt động đúng
- Dữ liệu Product không được truyền đúng cách

### 2. **Lỗi trong việc lưu Order**
- Items không được lưu vào storage
- JSON serialization/deserialization bị lỗi

### 3. **Lỗi trong việc load Order**
- Items không được load từ storage
- Dữ liệu bị mất trong quá trình load

## Debug logs đã được thêm

### OrderFormScreen
```dart
// Trong _addProduct
print('DEBUG: Product selected: ${product.name} x$quantity');
print('DEBUG: New item created: ${newItem.productName} x${newItem.quantity} = ${newItem.lineTotal}');

// Trong _saveOrder
print('DEBUG: Creating order with ${_items.length} items');
print('DEBUG: Order object created with ${order.items.length} items');
```

### OrderService
```dart
// Trong addOrder
print('DEBUG: Adding order with ${order.items.length} items');
print('DEBUG: New order has ${newOrder.items.length} items');

// Trong _loadOrders
print('DEBUG: Loaded order ${order.orderNumber} with ${order.items.length} items');

// Trong _saveOrders
print('DEBUG: Saving ${_orders.length} orders to storage');
```

### OrderListScreen
```dart
// Trong _buildOrderCard
print('DEBUG: Building card for order ${order.orderNumber}');
print('DEBUG: Order has ${order.items.length} items');

// Trong _loadOrders
print('DEBUG: Loaded ${orders.length} orders from service');
```

## Cách kiểm tra

### 1. **Tạo đơn hàng mới**
1. Mở OrderFormScreen
2. Thêm sản phẩm vào đơn hàng
3. Kiểm tra console logs để xem:
   - Product được chọn
   - OrderItem được tạo
   - Order được tạo với items

### 2. **Lưu đơn hàng**
1. Nhấn "Tạo đơn hàng"
2. Kiểm tra console logs để xem:
   - Order được tạo với bao nhiêu items
   - Order được lưu vào storage
   - Dữ liệu JSON được tạo

### 3. **Xem danh sách đơn hàng**
1. Mở OrderListScreen
2. Kiểm tra console logs để xem:
   - Orders được load từ service
   - Mỗi order có bao nhiêu items
   - Dữ liệu items có đầy đủ không

## Kết quả mong đợi

### Khi tạo đơn hàng:
```
DEBUG: Product selected: Sản phẩm A x2
DEBUG: New item created: Sản phẩm A x2 = 200000.0
DEBUG: Creating order with 1 items
DEBUG: Order object created with 1 items
DEBUG: Adding order with 1 items
DEBUG: New order has 1 items
DEBUG: Order saved successfully. Total orders: 1
```

### Khi load danh sách:
```
DEBUG: Loaded 1 orders from service
DEBUG: Order 0: HD001 with 1 items, total: 200000.0
DEBUG:   Item 0: Sản phẩm A x2 = 200000.0
DEBUG: Building card for order HD001
DEBUG: Order has 1 items
```

## Nếu vẫn có vấn đề

### 1. **Kiểm tra Product data**
- Đảm bảo Product có đầy đủ thông tin
- Kiểm tra `product.sellingPrice`, `product.costPrice`

### 2. **Kiểm tra OrderItem.fromProduct**
- Đảm bảo method này hoạt động đúng
- Kiểm tra dữ liệu được copy từ Product

### 3. **Kiểm tra JSON storage**
- Đảm bảo items được serialize đúng cách
- Kiểm tra items được deserialize đúng cách

### 4. **Kiểm tra setState**
- Đảm bảo UI được cập nhật sau khi thêm items
- Kiểm tra `_items` list có được cập nhật không

## Lưu ý

- **Debug logs sẽ xuất hiện trong console** khi chạy ứng dụng
- **Kiểm tra từng bước** để xác định chính xác vấn đề ở đâu
- **So sánh dữ liệu** giữa khi tạo và khi load để tìm điểm mất dữ liệu

Bây giờ hãy chạy ứng dụng và kiểm tra console logs để xác định chính xác vấn đề! 🔍
