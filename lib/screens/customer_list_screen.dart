import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await _customerService.getCustomers();
      // Lọc bỏ khách lẻ khỏi danh sách hiển thị (chỉ hiển thị khách hàng thật)
      final realCustomers = customers.where((c) => !c.isWalkIn).toList();
      setState(() {
        _customers = realCustomers;
        _filteredCustomers = realCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách khách hàng: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.phone.contains(query) ||
              customer.email.toLowerCase().contains(query.toLowerCase()) ||
              customer.address.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _addCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
    );

    if (result == true) {
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm khách hàng thành công'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    // Không cho phép chỉnh sửa khách lẻ
    if (customer.isWalkIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chỉnh sửa khách lẻ'),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    );

    if (result == true) {
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật khách hàng thành công'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    // Không cho phép xóa khách lẻ
    if (customer.isWalkIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa khách lẻ'),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khách hàng "${customer.name}"?\n\nKhách hàng sẽ được đánh dấu là không hoạt động và có thể khôi phục sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: AppColors.textOnMain,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _customerService.deleteCustomer(customer.id);
        if (success) {
          _loadCustomers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa khách hàng "${customer.name}"'),
                backgroundColor: AppColors.successColor,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể xóa khách hàng'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa khách hàng: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreCustomer(Customer customer) async {
    try {
      final success = await _customerService.restoreCustomer(customer.id);
      if (success) {
        _loadCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã khôi phục khách hàng "${customer.name}"'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể khôi phục khách hàng'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi khôi phục khách hàng: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách khách hàng'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCustomers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khách hàng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterCustomers('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterCustomers,
            ),
          ),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không có khách hàng nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _filteredCustomers.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return Dismissible(
                        key: ValueKey(customer.id ?? index),
                        direction: customer.isActive
                            ? DismissDirection
                                  .endToStart // active: swipe left to delete
                            : DismissDirection
                                  .startToEnd, // inactive: swipe right to restore
                        confirmDismiss: (direction) async {
                          // bạn có thể showDialog xác nhận ở đây nếu muốn
                          return true;
                        },
                        onDismissed: (direction) {
                          if (customer.isActive) {
                            _deleteCustomer(customer);
                          } else {
                            _restoreCustomer(customer);
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: Colors.green,
                          child: const Row(
                            children: [
                              Icon(Icons.restore, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Khôi phục',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Xóa',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              // mở chi tiết hoặc edit khi tap toàn bộ hàng (tuỳ bạn)
                              if (customer.isActive) _editCustomer(customer);
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              leading: _buildAvatar(customer),
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      customer.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(customer),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (customer.phone.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'SĐT: ${customer.phone}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (customer.email.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.email, size: 16),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Email: ${customer.email}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (customer.address.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Địa chỉ: ${customer.address}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (customer.note.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.note, size: 16),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Ghi chú: ${customer.note}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editCustomer(customer);
                                      break;
                                    case 'delete':
                                      _deleteCustomer(customer);
                                      break;
                                    case 'restore':
                                      _restoreCustomer(customer);
                                      break;
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                itemBuilder: (context) => [
                                  if (customer.isActive)
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Sửa'),
                                        ],
                                      ),
                                    ),
                                  if (customer.isActive)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Xóa'),
                                        ],
                                      ),
                                    ),
                                  if (!customer.isActive)
                                    PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.restore, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Khôi phục'),
                                        ],
                                      ),
                                    ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.more_vert, color: Colors.black87, size: 20),
                                ),
                              ),

                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

Widget _buildAvatar(dynamic customer) {
  // Hiển thị gradient avatar + icon hoặc chữ tắt
  final initials = _getInitials(customer.displayName ?? '');
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      gradient: customer.isWalkIn
          ? const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFF7043)])
          : const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
            ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: initials.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
    ),
  );
}

Widget _buildStatusChip(dynamic customer) {
  return Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: customer.isActive ? Colors.green : Colors.red,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          customer.isActive ? 'Hoạt động' : 'Không hoạt động',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

String _getInitials(String name) {
  if (name.trim().isEmpty) return '';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts.last[0]).toUpperCase();
}
