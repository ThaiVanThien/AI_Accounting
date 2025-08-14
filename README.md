# AI Accounting - Ứng dụng Quản lý Kế toán AI

## Tính năng chính

### 1. Quản lý Khách hàng (Customer Management)
- **CRUD đầy đủ**: Tạo, đọc, cập nhật, xóa khách hàng
- **Khách lẻ (Walk-in)**: Tự động tạo khách lẻ cho đơn hàng vãng lai
- **Quản lý thông tin**: Tên, số điện thoại, email, địa chỉ, ghi chú
- **Tìm kiếm và lọc**: Tìm kiếm khách hàng theo nhiều tiêu chí
- **Soft Delete**: Khách hàng bị xóa có thể khôi phục lại
- **Validation**: Kiểm tra thông tin trước khi lưu

### 2. Quản lý Đơn hàng (Order Management)
- **Tạo đơn hàng**: Chọn khách hàng từ danh sách hoặc khách lẻ
- **Quản lý sản phẩm**: Thêm, sửa, xóa sản phẩm trong đơn
- **Tính toán tự động**: Tổng tiền, giảm giá, thuế, lợi nhuận
- **Trạng thái đơn hàng**: Draft → Confirmed → Paid → Cancelled
- **Cập nhật tồn kho tự động**: Khi thay đổi trạng thái đơn hàng

### 3. Quản lý Sản phẩm (Product Management)
- **Thông tin sản phẩm**: Mã, tên, giá bán, giá vốn, đơn vị
- **Quản lý tồn kho**: Tự động cập nhật khi có đơn hàng
- **Phân loại**: Danh mục sản phẩm
- **Import/Export**: Nhập/xuất dữ liệu sản phẩm

### 4. Báo cáo và Thống kê
- **Thống kê đơn hàng**: Theo trạng thái, ngày tháng
- **Thống kê doanh thu**: Theo thời gian, sản phẩm
- **Sản phẩm bán chạy**: Top sản phẩm theo số lượng
- **Thống kê khách hàng**: Số lượng, trạng thái

## Cách sử dụng

### Quản lý Khách hàng
1. **Thêm khách hàng mới**:
   - Vào tab "Khách hàng"
   - Nhấn nút "+" để thêm mới
   - Điền thông tin bắt buộc: Tên và Số điện thoại
   - Nhấn "Lưu"

2. **Chỉnh sửa khách hàng**:
   - Nhấn vào khách hàng cần sửa
   - Thay đổi thông tin
   - Nhấn "Lưu"

3. **Xóa khách hàng**:
   - Nhấn nút xóa (thùng rác) bên cạnh khách hàng
   - Xác nhận xóa (sẽ đánh dấu không hoạt động)
   - Có thể khôi phục từ menu "Khôi phục"

### Tạo Đơn hàng
1. **Chọn khách hàng**:
   - Chọn từ dropdown danh sách khách hàng
   - Hoặc chọn "Khách lẻ" cho khách vãng lai
   - Nhấn "Thêm khách hàng mới" nếu cần

2. **Thêm sản phẩm**:
   - Nhấn nút "Thêm" trong phần sản phẩm
   - Chọn sản phẩm từ danh sách
   - Nhập số lượng
   - Nhấn "Thêm"

3. **Điều chỉnh giá**:
   - Nhập giảm giá (nếu có)
   - Nhập thuế (nếu có)

4. **Lưu đơn hàng**:
   - Chọn trạng thái: Draft (nháp) hoặc Confirmed (xác nhận)
   - Nhấn "Tạo đơn hàng" hoặc "Lưu thay đổi"

### Quản lý Tồn kho
- **Tự động cập nhật**: Khi đơn hàng chuyển từ Draft sang Confirmed/Paid
- **Kiểm tra tồn kho**: Trước khi cho phép tạo đơn hàng
- **Hoàn trả tồn kho**: Khi hủy đơn hàng hoặc chuyển về Draft

## Lưu ý kỹ thuật

### Trạng thái Đơn hàng
- **Draft**: Đơn hàng nháp, không ảnh hưởng tồn kho
- **Confirmed**: Đơn hàng đã xác nhận, đã trừ tồn kho
- **Paid**: Đơn hàng đã thanh toán, tồn kho đã trừ
- **Cancelled**: Đơn hàng đã hủy, tồn kho đã hoàn trả

### Cập nhật Tồn kho
- **Khi tạo đơn**: Nếu trạng thái không phải Draft
- **Khi thay đổi trạng thái**: Theo logic nghiệp vụ
- **Khi hủy đơn**: Hoàn trả tồn kho

### Khách lẻ (Walk-in)
- **ID cố định**: 'walk_in'
- **Không lưu vào database**: Chỉ sử dụng trong đơn hàng
- **Không thể chỉnh sửa/xóa**: Bảo vệ dữ liệu hệ thống

## Cài đặt và Chạy

1. **Cài đặt Flutter**: Phiên bản 3.0 trở lên
2. **Clone project**: `git clone [repository-url]`
3. **Cài đặt dependencies**: `flutter pub get`
4. **Chạy ứng dụng**: `flutter run`

## Cấu trúc Project

```
lib/
├── constants/          # Hằng số, màu sắc, styles
├── models/            # Data models
├── screens/           # UI screens
├── services/          # Business logic
└── utils/             # Utility functions
```

## Hỗ trợ

Nếu gặp vấn đề hoặc cần hỗ trợ, vui lòng:
1. Kiểm tra console log để xem lỗi
2. Đảm bảo đã cài đặt đúng dependencies
3. Kiểm tra quyền truy cập storage trên thiết bị
