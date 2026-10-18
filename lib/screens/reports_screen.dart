import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

import 'cycle_report_menu_screen.dart';
import 'account_report_menu_screen.dart';
import 'energy_consumption_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  final String? wellId;
  final String? wellName;

  const ReportsScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  static const Color mainColor = Colors.blue;
  static const Color backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: MyAppBar(
          title: 'التقارير',
          subtitle:
              wellName == null ||
                      wellName!.trim().isEmpty
                  ? 'جميع التقارير'
                  : 'البئر: $wellName',
          icon: Icons.assessment,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
            children: [
              // ==================================================
              // تقرير الدور
              // ==================================================

              _reportCard(
                context: context,
                title: 'تقرير الدور',
                subtitle:
                    'تقارير القراءات والدورات',
                icon: Icons.water_drop,
                page: CycleReportMenuScreen(
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==================================================
              // تقرير الحساب
              // ==================================================

              _reportCard(
                context: context,
                title: 'تقرير الحساب',
                subtitle:
                    'تقارير الحسابات والحركات',
                icon:
                    Icons.account_balance_wallet,
                page: AccountReportMenuScreen(
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),

              // ==================================================
              // تقرير الطاقة
              // ==================================================

              _reportCard(
                context: context,
                title: 'تقرير استهلاك الطاقة',
                subtitle:
                    'الشمسي والديزل وعدد الساعات',
                icon: Icons.bolt,
                page:
                    EnergyConsumptionReportScreen(
                  wellId: wellId,
                  wellName: wellName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REPORT CARD
  // ============================================================

  Widget _reportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration:
                      const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: mainColor,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  subtitle,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: 34,
                  height: 34,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}