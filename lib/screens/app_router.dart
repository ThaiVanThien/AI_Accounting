import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'business_setup_screen.dart';
import 'main_screen.dart';
import '../constants/app_colors.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _isLoading = true;
  bool _setupCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    try {
      final isCompleted = await StorageService.isSetupCompleted();
      setState(() {
        _setupCompleted = isCompleted;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking setup status: $e');
      setState(() {
        _setupCompleted = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_setupCompleted) {
      return const MainScreen();
    } else {
      return const BusinessSetupScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Kế Toán AI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo ứng dụng...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 