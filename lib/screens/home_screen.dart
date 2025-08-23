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
import '../utils/format_utils.dart';
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

  void _calculateStatistics(
    List<Order> orders,
    List<Product> products,
    List<Customer> customers,
  ) {
    // Filter orders by selected period
    final filteredOrders = _filterOrdersByPeriod(orders);

    // Calculate revenue and profit
    _totalRevenue = 0;
    _totalProfit = 0;
    for (final order in filteredOrders) {
      if (order.status == OrderStatus.paid ||
          order.status == OrderStatus.confirmed) {
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
    _lowStockProducts = products
        .where((p) => p.stockQuantity <= p.minStockLevel)
        .length;

    // Get recent orders (last 5)
    orders.sort(
      (a, b) =>
          (b.createdAt ?? b.orderDate).compareTo(a.createdAt ?? a.orderDate),
    );
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
          return orderDate.year == now.year && orderDate.month == now.month;
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
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
    final now = DateTime.now();
    String greeting;
    String timeEmoji;
    IconData greetingIcon;
    List<Color> gradientColors;

    if (hour < 12) {
      greeting = 'Chào buổi sáng';
      timeEmoji = '🌅';
      greetingIcon = Icons.wb_sunny_outlined;
      gradientColors = [
        const Color(0xFFFF9500),
        const Color(0xFFFFB84D),
        const Color(0xFFFFD93D),
      ];
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều';
      timeEmoji = '☀️';
      greetingIcon = Icons.wb_sunny;
      gradientColors = [
        const Color(0xFF4FC3F7),
        const Color(0xFF29B6F6),
        const Color(0xFF03A9F4),
      ];
    } else {
      greeting = 'Chào buổi tối';
      timeEmoji = '🌙';
      greetingIcon = Icons.nights_stay_outlined;
      gradientColors = [
        const Color(0xFF7E57C2),
        const Color(0xFF9575CD),
        const Color(0xFFB39DDB),
      ];
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: gradientColors[1].withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        child: Stack(
          children: [
            // Animated background patterns
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? AppStyles.spacingS : AppStyles.spacingXS),
              child: Row(
                children: [
                  // Icon container with improved design
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? AppStyles.spacingM : AppStyles.spacingL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      greetingIcon,
                      size: isSmallScreen ? 16 : 18,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(width: isSmallScreen ? AppStyles.spacingM : AppStyles.spacingL),
                  
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                greeting,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 20 : 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spacingS),
                            Text(
                              timeEmoji,
                              style: TextStyle(fontSize: isSmallScreen ? 20 : 24),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppStyles.spacingXS),
                        
                        Text(
                          DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: AppStyles.spacingXS),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacingS,
                            vertical: AppStyles.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppStyles.radiusS),
                          ),
                          child: Text(
                            'Chúc bạn một ngày kinh doanh thành công!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Row(
                //   children: [
                //     GestureDetector(
                //       onTap: _showQuickRevenueDialog,
                //       child: Container(
                //         padding: const EdgeInsets.all(AppStyles.spacingM),
                //         decoration: BoxDecoration(
                //           color: Colors.white.withOpacity(0.2),
                //           borderRadius: BorderRadius.circular(AppStyles.radiusL),
                //           border: Border.all(color: Colors.white.withOpacity(0.3)),
                //         ),
                //         child: const Icon(
                //           Icons.monetization_on_rounded,
                //           color: Colors.white,
                //           size: 24,
                //         ),
                //       ),
                //     ),
                //
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
      )
    );
  }
 
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),  
                ),
                child: Icon( 
                  Icons.analytics_rounded, 
                  size: 20,
                  color: AppColors.mainColor,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Text(
                'Thống kê theo thời gian',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppStyles.radiusL),
            ),
            child: Row(
              children: [
                Expanded(child: _buildPeriodChip('Ngày', 'day', Icons.today)),
                Expanded(
                  child: _buildPeriodChip(
                    'Tháng',
                    'month', 
                    Icons.calendar_view_month,
                  ),
                ),
                Expanded(
                  child: _buildPeriodChip('Năm', 'year', Icons.calendar_today),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppStyles.radiusL),
              border: Border.all(color: AppColors.mainColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang xem',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _getPeriodDisplayText(),
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    child: Icon(
                      Icons.edit_calendar_rounded,
                      size: 20,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period, IconData icon) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        _loadDashboardData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingS,
          vertical: AppStyles.spacingXS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppStyles.bodyLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitOverview() {
    final profitPercentage = _totalRevenue > 0
        ? (_totalProfit / _totalRevenue * 100)
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingXL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.successColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lợi nhuận',
                          style: AppStyles.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacingXS),
                        Text(
                          '${NumberFormat('#,###').format(_totalProfit)} VNĐ',
                          style: AppStyles.headingLarge.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (profitPercentage > 0) ...[
                          const SizedBox(height: AppStyles.spacingXS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppStyles.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                AppStyles.radiusS,
                              ),
                            ),
                            child: Text(
                              '${profitPercentage.toStringAsFixed(1)}%',
                              style: AppStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.radiusXL),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedMetricItem(
                      'Doanh thu',
                      '${NumberFormat('#,###').format(_totalRevenue)} VNĐ',
                      Icons.monetization_on_rounded,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingM),
                  Expanded(
                    child: _buildEnhancedMetricItem(
                      'Đơn hàng',
                      _totalOrders.toString(),
                      Icons.receipt_long_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingS),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppStyles.radiusS),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: AppStyles.spacingM),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              child: Icon(
                Icons.flash_on_rounded,
                size: 20,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Text(
              'Thao tác nhanh',
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppStyles.spacingM,
          mainAxisSpacing: AppStyles.spacingM,
          childAspectRatio: MediaQuery.of(context).size.width < 600 ? 1.0 : 1.1,
          children: [
            _buildActionCard(
              title: 'Danh sách đơn hàng',
              icon: Icons.receipt_long,
              color: AppColors.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListScreen(),
                ),
              ).then((_) => _loadDashboardData()),
            ),
            _buildActionCard(
              title: 'Tạo đơn hàng mới',
              icon: Icons.add_shopping_cart,
              color: AppColors.successColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderFormScreen(),
                ),
              ).then((_) => _loadDashboardData()),
            ),
            _buildActionCard(
              title: 'Quản lý sản phẩm',
              icon: Icons.inventory,
              color: AppColors.warningColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              ).then((_) => _loadDashboardData()),
            ),
            _buildActionCard(
              title: 'Danh sách KH',
              icon: Icons.people,
              color: AppColors.mainColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerListScreen(),
                ),
              ).then((_) => _loadDashboardData()),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.shadowLight.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
          child: Stack(
            children: [
              // Background gradient overlay
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppStyles.spacingM),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppStyles.radiusL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Container(
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.5), color],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: AppColors.infoColor,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Text(
              'Thống kê tổng quan',
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingL),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                'Sản phẩm',
                _totalProducts.toString(),
                Icons.inventory_2_rounded,
                AppColors.infoColor,
                _lowStockProducts > 0 ? 'Cảnh báo tồn kho' : 'Quản lý tốt',
              ),
            ),
            const SizedBox(width: AppStyles.spacingL),
            Expanded(
              child: _buildEnhancedStatCard(
                'Khách hàng',
                _totalCustomers.toString(),
                Icons.people_rounded,
                AppColors.successColor,
                _totalCustomers > 10 ? 'Khách hàng trung thành' : 'Mở rộng khách hàng',
              ),
            ),
          ],
        ),
        if (_lowStockProducts > 0) ...[
          const SizedBox(height: AppStyles.spacingL),
          _buildEnhancedWarningCard(),
        ],
      ],
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(AppStyles.radiusL),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppStyles.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusS),
            ),
            child: Text(
              subtitle,
              style: AppStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: MediaQuery.of(context).size.width * 0.03,
              ),
            ),
          ),
          const SizedBox(height: AppStyles.spacingS),
          Text(
            value,
            style: AppStyles.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            title,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWarningCard() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warningColor.withOpacity(0.1),
            AppColors.warningColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        border: Border.all(color: AppColors.warningColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: BoxDecoration(
              color: AppColors.warningColor,
              borderRadius: BorderRadius.circular(AppStyles.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warningColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppStyles.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh báo tồn kho',
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingXS),
                Text(
                  '$_lowStockProducts sản phẩm sắp hết hàng',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingM,
                vertical: AppStyles.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningColor,
                borderRadius: BorderRadius.circular(AppStyles.radiusL),
              ),
              child: Text(
                'Xem ngay',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    if (_recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppStyles.spacingXL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: AppColors.infoColor,
              ),
            ),
            const SizedBox(height: AppStyles.spacingM),
            Text(
              'Chưa có đơn hàng nào',
              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              'Tạo đơn hàng đầu tiên của bạn',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: AppColors.successColor,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Expanded(
              child: Text(
                'Đơn hàng gần đây',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingM,
                  vertical: AppStyles.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusL),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.successColor,
                        fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.width * 0.035
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingXS),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.successColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentOrders.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppStyles.spacingM),
          itemBuilder: (context, index) {
            final order = _recentOrders[index];
            return Container(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingM),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(order.status),
                          _getStatusColor(order.status).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.03,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacingXS),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppStyles.spacingXS),
                            Text(
                              order.customer.displayName,
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                  fontSize: MediaQuery.of(context).size.width * 0.03
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppStyles.radiusS,
                          ),
                        ),
                        child: Text(
                          '${NumberFormat('#,###').format(order.total)} VNĐ',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.successColor,
                            fontSize: MediaQuery.of(context).size.width * 0.03
                          ),
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Text(
                        DateFormat('dd/MM/yyyy').format(order.orderDate),
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                            fontSize: MediaQuery.of(context).size.width * 0.03
                        ),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.infoColor,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Expanded(
              child: Text(
                'Gợi ý kinh doanh',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width * 0.04
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingM),
        Column(
          children: _buildInsightItems(),
        ),
      ],
    );
  }

  List<Widget> _buildInsightItems() {
    List<Widget> insights = [];

    // Insight về sản phẩm sắp hết hàng
    if (_lowStockProducts > 0) {
      insights.add(
        _buildInsightItem(
          icon: Icons.inventory_2,
          text: 'Có $_lowStockProducts sản phẩm sắp hết hàng, cần nhập thêm!',
          color: AppColors.warningColor,
          action: 'Xem ngay',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductListScreen()),
          ),
        ),
      );
    }

    // Insight về doanh thu
    if (_totalRevenue > 0) {
      final profitMargin = (_totalProfit / _totalRevenue * 100);
      insights.add(
        _buildInsightItem(
          icon: Icons.trending_up,
          text:
              'Tỷ lệ lợi nhuận ${_selectedPeriod == 'day' ? 'hôm nay' : (_selectedPeriod == 'month' ? 'tháng này' : 'năm nay')}: ${profitMargin.toStringAsFixed(1)}%',
          color: profitMargin > 20
              ? AppColors.successColor
              : AppColors.warningColor,
        ),
      );
    }

    // Insight về khách hàng
    if (_totalCustomers > 0) {
      insights.add(
        _buildInsightItem(
          icon: Icons.people,
          text: 'Bạn có $_totalCustomers khách hàng đang theo dõi',
          color: AppColors.infoColor,
          action: 'Quản lý',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerListScreen()),
          ),
        ),
      );
    }

    // Default insight nếu không có gì
    if (insights.isEmpty) {
      insights.add(
        _buildInsightItem(
          icon: Icons.rocket_launch,
          text: 'Hãy bắt đầu tạo đơn hàng đầu tiên của bạn!',
          color: AppColors.successColor,
          action: 'Tạo ngay',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderFormScreen()),
          ).then((_) => _loadDashboardData()),
        ),
      );
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
      margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: Text(
                    text,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                        fontSize: MediaQuery.of(context).size.width * 0.03
                    ),
                  ),
                ),
                if (action != null && onTap != null) ...[
                  const SizedBox(width: AppStyles.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.spacingM,
                      vertical: AppStyles.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action,
                          style: AppStyles.bodyMedium.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                              fontSize: MediaQuery.of(context).size.width * 0.03
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacingXS),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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

  void _showQuickRevenueDialog() {
    final TextEditingController revenueController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusXL),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: Text(
                  'Tổng doanh thu ngày',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width * 0.04
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập tổng số tiền doanh thu của ngày hôm nay',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                    fontSize: MediaQuery.of(context).size.width * 0.035
                ),
              ),
              const SizedBox(height: AppStyles.spacingL),
              TextField(
                controller: revenueController,
                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Số tiền (VNĐ)',
                  prefixIcon: Icon(
                    Icons.monetization_on,
                    color: AppColors.successColor,
                  ),
                  hintText: 'Ví dụ: 500,000',
                  labelStyle: AppStyles.bodySmall.copyWith(
                    fontSize: (MediaQuery.of(context).size.width * 0.03), color: Colors.black87
                  ),
                  hintStyle: AppStyles.bodySmall.copyWith(
                    fontSize: (MediaQuery.of(context).size.width * 0.03),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppStyles.spacingM),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: AppStyles.bodyMedium.copyWith(fontSize: (MediaQuery.of(context).size.width * 0.03)), // chữ nhập
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Ghi chú (tùy chọn)',
                  labelStyle: AppStyles.bodySmall.copyWith(fontSize: (MediaQuery.of(context).size.width * 0.03),color: Colors.black87), // labelText
                  hintText: 'Ví dụ: Doanh thu bán hàng tại quầy',
                  hintStyle: AppStyles.bodySmall.copyWith(fontSize: (MediaQuery.of(context).size.width * 0.03), color: AppColors.textHint), // hintText
                  prefixIcon: Icon(
                    Icons.note_outlined,
                    color: AppColors.infoColor,
                  ),
                ),
              )

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary, fontSize: (MediaQuery.of(context).size.width * 0.03)
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _createQuickRevenueOrder(revenueController.text, noteController.text);
                Navigator.of(context).pop();
              },
              style: AppStyles.primaryButtonStyle,
              child: Text('Lưu',style: TextStyle(fontSize: (MediaQuery.of(context).size.width * 0.03)),),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createQuickRevenueOrder(String revenueText, String note) async {
    if (revenueText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập số tiền doanh thu'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    try {
      final revenue = FormatUtils.parseCurrency(revenueText.trim());
      
      if (revenue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số tiền phải lớn hơn 0'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      // Tạo hóa đơn tổng với sản phẩm đặc biệt
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderNumber: 'DT${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        customer: Customer.walkIn(),
        items: [
          OrderItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: '0', // ID đặc biệt cho tổng doanh thu
            productName: 'Tổng doanh thu ngày ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            productCode: 'DT-${DateFormat('yyyyMMdd').format(DateTime.now())}',
            unit: 'VNĐ',
            quantity: 1,
            unitPrice: revenue,
            costPrice: 0, // Không tính cost cho tổng doanh thu
            note: note.isNotEmpty ? note : '',
          ),
        ],
        status: OrderStatus.paid, // Đánh dấu là đã thanh toán
        orderDate: DateTime.now(),
        createdAt: DateTime.now(),
        note: note.isNotEmpty ? 'Tổng doanh thu ngày: $note' : 'Tổng doanh thu ngày ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      );

      await _orderService.addOrder(order);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppStyles.spacingS),
              Text('Đã lưu tổng doanh thu: ${NumberFormat('#,###').format(revenue)} VNĐ'),
            ],
          ),
          backgroundColor: AppColors.successColor,
        ),
      );

      // Reload dữ liệu
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số tiền không hợp lệ: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}
