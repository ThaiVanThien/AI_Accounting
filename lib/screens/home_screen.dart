import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/customer_service.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/customer.dart';
import 'order_list_screen.dart';
import 'product_list_screen.dart';
import 'customer_list_screen.dart';
import 'order_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();

  bool _isLoading = true;
  String _selectedPeriod = 'day'; // day, month, year
  DateTime _selectedDate = DateTime.now();

  // Statistics data
  double _totalRevenue = 0;
  double _totalProfit = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  int _lowStockProducts = 0;
  List<Order> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all data in parallel
      final futures = await Future.wait([
        _orderService.getOrders(),
        _productService.getProducts(),
        _customerService.getCustomers(),
      ]);

      final orders = futures[0] as List<Order>;
      final products = futures[1] as List<Product>;
      final customers = futures[2] as List<Customer>;

      // Calculate statistics based on selected period
      _calculateStatistics(orders, products, customers);
      
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _calculateStatistics(List<Order> orders, List<Product> products, List<Customer> customers) {
    // Filter orders by selected period
    final filteredOrders = _filterOrdersByPeriod(orders);
    
    // Calculate revenue and profit
    _totalRevenue = 0; 
    _totalProfit = 0;
    for (final order in filteredOrders) {
      if (order.status == OrderStatus.paid || order.status == OrderStatus.confirmed) {
        _totalRevenue += order.total; 
        // Calculate profit as revenue - cost
        double orderCost = 0;
        for (final item in order.items) {
          orderCost += item.lineCostTotal;
        }
        _totalProfit += (order.total - orderCost);
      }
    }
    
    _totalOrders = filteredOrders.length;
    _totalProducts = products.length;
    _totalCustomers = customers.where((c) => !c.isWalkIn).length;
    
    // Count low stock products
    _lowStockProducts = products.where((p) => p.stockQuantity <= p.minStockLevel).length;
    
    // Get recent orders (last 5)
    orders.sort((a, b) => (b.createdAt ?? b.orderDate).compareTo(a.createdAt ?? a.orderDate));
    _recentOrders = orders.take(5).toList();
  }

  List<Order> _filterOrdersByPeriod(List<Order> orders) {
    final now = _selectedDate;
    
    return orders.where((order) {
      final orderDate = order.createdAt ?? order.orderDate;
      
      switch (_selectedPeriod) {
        case 'day':
          return orderDate.year == now.year && 
                 orderDate.month == now.month && 
                 orderDate.day == now.day;
        case 'month':
          return orderDate.year == now.year && 
                 orderDate.month == now.month;
        case 'year':
          return orderDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  String _getPeriodDisplayText() {
    switch (_selectedPeriod) {
      case 'day':
        return DateFormat('dd/MM/yyyy').format(_selectedDate);
      case 'month':
        return DateFormat('MM/yyyy').format(_selectedDate);
      case 'year':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading ? _buildLoadingWidget() : _buildDashboard(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
          ),
          SizedBox(height: AppStyles.spacingL),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppStyles.spacingL),
            _buildWelcomeHeader(),
            const SizedBox(height: AppStyles.spacingL),
            _buildPeriodSelector(),
            const SizedBox(height: AppStyles.spacingL),
            _buildProfitOverview(),
            const SizedBox(height: AppStyles.spacingL),
            _buildQuickActions(),
            const SizedBox(height: AppStyles.spacingL),
            _buildStatisticsCards(),
            const SizedBox(height: AppStyles.spacingL),
            _buildRecentOrders(),
            const SizedBox(height: AppStyles.spacingL),
            _buildQuickInsights(),
            const SizedBox(height: AppStyles.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Chào buổi sáng!';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều!';
      greetingIcon = Icons.wb_cloudy;
    } else {
      greeting = 'Chào buổi tối!';
      greetingIcon = Icons.nights_stay;
    }
    
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: AppStyles.elevatedCardDecoration.copyWith(
        gradient: AppColors.mainGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppStyles.radiusL),
            ),
            child: Icon(
              greetingIcon,
              size: 32,
              color: AppColors.textOnMain,
            ),
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppStyles.headingMedium.copyWith(
                    color: AppColors.textOnMain,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingXS),
                Text(
                  'Hôm nay là ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textOnMain.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadDashboardData,
            child: Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              child: const Icon(
                Icons.refresh,
                color: AppColors.textOnMain,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xem thống kê theo:',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: AppStyles.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildPeriodButton('Ngày', 'day'),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: _buildPeriodButton('Tháng', 'month'),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: _buildPeriodButton('Năm', 'year'),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingM),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: AppColors.mainColor,
              ),
              const SizedBox(width: AppStyles.spacingS),
              Text(
                'Đang xem: ${_getPeriodDisplayText()}',
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showDatePicker,
                icon: const Icon(Icons.edit_calendar),
                color: AppColors.mainColor,
                tooltip: 'Chọn ngày khác',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        _loadDashboardData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingM,
          vertical: AppStyles.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyles.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.textOnMain : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProfitOverview() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: AppStyles.elevatedCardDecoration.copyWith(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.successColor, Color(0xFF66BB6A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lợi nhuận',
                      style: AppStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      NumberFormat('#,###').format(_totalProfit) + ' VNĐ',
                      style: AppStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                'Doanh thu',
                NumberFormat('#,###').format(_totalRevenue) + ' VNĐ',
                Icons.attach_money,
              ),
              _buildMetricItem(
                'Đơn hàng',
                _totalOrders.toString(),
                Icons.receipt_long,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: AppStyles.headingSmall,
        ),
        const SizedBox(height: AppStyles.spacingM),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppStyles.spacingM,
          mainAxisSpacing: AppStyles.spacingM,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              title: 'Danh sách\nĐơn hàng',
              icon: Icons.receipt_long,
              color: AppColors.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderListScreen()),
              ),
            ),
            _buildActionCard(
              title: 'Tạo đơn\nhàng mới',
              icon: Icons.add_shopping_cart,
              color: AppColors.successColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderFormScreen()),
              ),
            ),
            _buildActionCard(
              title: 'Quản lý\nSản phẩm',
              icon: Icons.inventory,
              color: AppColors.warningColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductListScreen()),
              ),
            ),
            _buildActionCard(
              title: 'Danh sách\nKhách hàng',
              icon: Icons.people,
              color: AppColors.mainColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerListScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        decoration: AppStyles.cardDecoration.copyWith(
          color: color.withOpacity(0.1),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppStyles.radiusL),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: AppStyles.spacingM),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê tổng quan',
          style: AppStyles.headingSmall,
        ),
        const SizedBox(height: AppStyles.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sản phẩm',
                _totalProducts.toString(),
                Icons.inventory,
                AppColors.infoColor,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Expanded(
              child: _buildStatCard(
                'Khách hàng',
                _totalCustomers.toString(),
                Icons.people,
                AppColors.successColor,
              ),
            ),
          ],
        ),
        if (_lowStockProducts > 0) ...[
          const SizedBox(height: AppStyles.spacingM),
          _buildWarningCard(),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: AppStyles.cardDecoration,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: AppStyles.spacingS),
          Text(
            value,
            style: AppStyles.headingMedium.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            title,
            style: AppStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: AppStyles.cardDecoration.copyWith(
        color: AppColors.warningColor.withOpacity(0.1),
        border: Border.all(
          color: AppColors.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppColors.warningColor,
            size: 24,
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo tồn kho',
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_lowStockProducts sản phẩm sắp hết hàng',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.warningColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductListScreen()),
            ),
            child: Text(
              'Xem',
              style: TextStyle(color: AppColors.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    if (_recentOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đơn hàng gần đây',
              style: AppStyles.headingSmall,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderListScreen()),
              ),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingM),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentOrders.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppStyles.spacingS),
          itemBuilder: (context, index) {
            final order = _recentOrders[index];
            return Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: AppStyles.cardDecoration,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    child: Icon(
                      Icons.receipt,
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          order.customer.displayName,
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat('#,###').format(order.total) + ' VNĐ',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.successColor,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM').format(order.orderDate),
                        style: AppStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return AppColors.textHint;
      case OrderStatus.confirmed:
        return AppColors.infoColor;
      case OrderStatus.paid:
        return AppColors.successColor;
      case OrderStatus.cancelled:
        return AppColors.errorColor;
    }
  }

  Widget _buildQuickInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin nhanh',
          style: AppStyles.headingSmall,
        ),
        const SizedBox(height: AppStyles.spacingM),
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingL),
          decoration: AppStyles.cardDecoration.copyWith(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.infoColor.withOpacity(0.1),
                AppColors.mainColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.infoColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Text(
                    'Gợi ý kinh doanh',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.infoColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),
              ..._buildInsightItems(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInsightItems() {
    List<Widget> insights = [];
    
    // Insight về sản phẩm sắp hết hàng
    if (_lowStockProducts > 0) {
      insights.add(_buildInsightItem(
        icon: Icons.inventory_2,
        text: 'Có $_lowStockProducts sản phẩm sắp hết hàng, cần nhập thêm!',
        color: AppColors.warningColor,
        action: 'Xem ngay',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductListScreen()),
        ),
      ));
    }
    
    // Insight về doanh thu
    if (_totalRevenue > 0) {
      final profitMargin = (_totalProfit / _totalRevenue * 100);
      insights.add(_buildInsightItem(
        icon: Icons.trending_up,
        text: 'Tỷ lệ lợi nhuận ${_selectedPeriod == 'day' ? 'hôm nay' : (_selectedPeriod == 'month' ? 'tháng này' : 'năm nay')}: ${profitMargin.toStringAsFixed(1)}%',
        color: profitMargin > 20 ? AppColors.successColor : AppColors.warningColor,
      ));
    }
    
    // Insight về khách hàng
    if (_totalCustomers > 0) {
      insights.add(_buildInsightItem(
        icon: Icons.people,
        text: 'Bạn có $_totalCustomers khách hàng đang theo dõi',
        color: AppColors.infoColor,
        action: 'Quản lý',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerListScreen()),
        ),
      ));
    }
    
    // Default insight nếu không có gì
    if (insights.isEmpty) {
      insights.add(_buildInsightItem(
        icon: Icons.rocket_launch,
        text: 'Hãy bắt đầu tạo đơn hàng đầu tiên của bạn!',
        color: AppColors.successColor,
        action: 'Tạo ngay',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderFormScreen()),
        ),
      ));
    }
    
    return insights;
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String text,
    required Color color,
    String? action,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingS),
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium.copyWith(
                color: color,
              ),
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(width: AppStyles.spacingS),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingS,
                  vertical: AppStyles.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                ),
                child: Text(
                  action,
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDashboardData();
    }
  }
}
