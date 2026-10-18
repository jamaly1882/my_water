
import 'package:flutter/material.dart';

import 'screens/setup_screen.dart';
import 'screens/search_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/cycle_screen.dart';
import 'screens/receipt_voucher_screen.dart';
import 'screens/payment_voucher_screen.dart';
import 'screens/set_up_mshrf/setup_mshrf_screen.dart';

import 'features/ai_agent/ai_agent_page.dart';
import 'widgets/my_app_bar.dart';

class HomeScreen extends StatelessWidget {
  final bool isAdmin;

  final String? supervisorId;

  final String? provinceId;
  final String? provinceName;

  final String? districtId;
  final String? districtName;

  final String? hamletId;
  final String? hamletName;

  final String? villageId;
  final String? villageName;

  final String? wellId;
  final String? wellName;

  const HomeScreen({
    super.key,
    this.isAdmin = false,
    this.supervisorId,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.hamletId,
    this.hamletName,
    this.villageId,
    this.villageName,
    this.wellId,
    this.wellName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F9FF),
        appBar: const MyAppBar(
          title: 'نظام إدارة المياه',
          showBackButton: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            children: [
              // ==============================================
              // التهيئة
              // ==============================================
              _menuCard(
                context,
                title: 'التهيئة',
                icon: Icons.settings,
                color: Colors.blue,
                page: SetupScreen(
                  supervisorId: supervisorId,
                  provinceId: provinceId,
                  provinceName: provinceName,
                  districtId: districtId,
                  districtName: districtName,
                  hamletId: hamletId,
                  hamletName: hamletName,
                  villageId: villageId,
                  villageName: villageName,
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==============================================
              // الدور لإدخال القراءات
              // ==============================================
              _menuCard(
                context,
                title: 'الدور لإدخال القراءات',
                icon: Icons.speed,
                color: Colors.deepPurple,
                page: CycleScreen(
                  supervisorId: supervisorId,
                  provinceId: provinceId,
                  provinceName: provinceName,
                  districtId: districtId,
                  districtName: districtName,
                  hamletId: hamletId,
                  hamletName: hamletName,
                  villageId: villageId,
                  villageName: villageName,
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==============================================
              // الاستعلام
              // ==============================================
              _menuCard(
                context,
                title: 'الاستعلام',
                icon: Icons.search,
                color: Colors.orange,
                page: SearchScreen(),
              ),

              // ==============================================
              // التقارير
              // ==============================================
              _menuCard(
                context,
                title: 'التقارير',
                icon: Icons.bar_chart,
                color: Colors.green,
                page: ReportsScreen(
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==============================================
              // سند قبض
              // ==============================================
              _menuCard(
                context,
                title: 'سند قبض',
                icon: Icons.receipt_long,
                color: Colors.teal,
                page: ReceiptVoucherScreen(
                  villageId: villageId,
                  villageName: villageName,
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==============================================
              // سند صرف
              // ==============================================
              _menuCard(
                context,
                title: 'سند صرف',
                icon: Icons.money_off,
                color: Colors.red,
                page: PaymentVoucherScreen(
                  villageId: villageId,
                  villageName: villageName,
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==============================================
              // وكيل الذكاء الاصطناعي
              // ==============================================
              _menuCard(
                context,
                title: 'وكيل الذكاء الاصطناعي',
                icon: Icons.psychology,
                color: Colors.indigo,
                page: const AiAgentPage(),
              ),

              // ==============================================
              // تهيئة بيانات المشرفين - للمدير فقط
              // ==============================================
              if (isAdmin)
                _menuCard(
                  context,
                  title: 'تهيئة بيانات المشرفين',
                  icon: Icons.supervisor_account,
                  color: Colors.indigo,
                  page: const SetupMshrfScreen(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================
  // بطاقة القائمة
  // ================================================
  Widget _menuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => page,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  icon,
                  size: 35,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
