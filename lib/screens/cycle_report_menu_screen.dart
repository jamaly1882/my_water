import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

import 'daily_cycle_report_screen.dart';
import 'monthly_cycle_report_screen.dart';
import 'yearly_cycle_report_screen.dart';

class CycleReportMenuScreen extends StatelessWidget {
  // ============================================================
  // بيانات البئر
  // ============================================================

  final String? wellId;
  final String? wellName;

  // ============================================================
  // اللون الموحد مع MyAppBar
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // خلفية الصفحة
  // ============================================================

  static const Color backgroundColor = Colors.white;

  const CycleReportMenuScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  // ============================================================
  // هل يوجد بئر؟
  // ============================================================

  bool get hasWell =>
      wellName != null &&
      wellName!.trim().isNotEmpty;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        // ========================================================
        // خلفية الصفحة بيضاء
        // ========================================================

        backgroundColor: backgroundColor,

        // ========================================================
        // شريط العنوان
        // ========================================================

        appBar: MyAppBar(
          title: "تقارير الأدوار",

          subtitle: hasWell
              ? "البئر: ${wellName!}"
              : "اختر نوع التقرير",

          icon: Icons.water_drop,
        ),

        // ========================================================
        // محتوى الصفحة
        // ========================================================

        body: Column(
          children: [
            // ======================================================
            // عنوان اختيار التقرير
            // نفس لون شريط العنوان
            // ======================================================

            Container(
              width: double.infinity,

              margin: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                5,
              ),

              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),

              decoration: BoxDecoration(
                // ==================================================
                // نفس لون MyAppBar
                // ==================================================

                color: mainColor,

                borderRadius:
                    BorderRadius.circular(15),

                boxShadow: [
                  BoxShadow(
                    color:
                        mainColor.withOpacity(0.18),

                    blurRadius: 8,

                    offset:
                        const Offset(0, 4),
                  ),
                ],
              ),

              child: const Row(
                children: [
                  // =================================================
                  // الأيقونة
                  // =================================================

                  Icon(
                    Icons.assessment,

                    color: Colors.white,

                    size: 25,
                  ),

                  SizedBox(
                    width: 10,
                  ),

                  // =================================================
                  // العنوان
                  // =================================================

                  Text(
                    "اختر نوع التقرير",

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // بطاقات التقارير
            // ======================================================

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),

                child: GridView.count(
                  crossAxisCount: 2,

                  crossAxisSpacing: 15,

                  mainAxisSpacing: 15,

                  childAspectRatio: 1.05,

                  children: [
                    // ==================================================
                    // التقرير اليومي
                    // ==================================================

                    _reportItem(
                      context,

                      title:
                          "التقرير اليومي",

                      subtitle:
                          "عرض تقرير اليوم",

                      icon:
                          Icons.today,

                      color:
                          mainColor,

                      page:
                          DailyCycleReportScreen(
                        wellId:
                            wellId,

                        wellName:
                            wellName,
                      ),
                    ),

                    // ==================================================
                    // التقرير الشهري
                    // ==================================================

                    _reportItem(
                      context,

                      title:
                          "التقرير الشهري",

                      subtitle:
                          "عرض تقرير الشهر",

                      icon:
                          Icons.calendar_month,

                      color:
                          mainColor,

                      page:
                          MonthlyCycleReportScreen(
                        wellId:
                            wellId,

                        wellName:
                            wellName,
                      ),
                    ),

                    // ==================================================
                    // التقرير السنوي
                    // ==================================================

                    _reportItem(
                      context,

                      title:
                          "التقرير السنوي",

                      subtitle:
                          "عرض تقرير السنة",

                      icon:
                          Icons.date_range,

                      color:
                          mainColor,

                      page:
                          YearlyCycleReportScreen(
                        wellId:
                            wellId,

                        wellName:
                            wellName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // بطاقة التقرير
  // ==============================================================

  Widget _reportItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),

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
            // ==================================================
            // خلفية البطاقة بيضاء
            // ==================================================

            color: Colors.white,

            borderRadius:
                BorderRadius.circular(20),

            // ==================================================
            // حدود زرقاء خفيفة
            // ==================================================

            border: Border.all(
              color:
                  color.withOpacity(0.14),

              width: 1,
            ),

            // ==================================================
            // ظل خفيف
            // ==================================================

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.06),

                blurRadius: 8,

                offset:
                    const Offset(0, 3),
              ),
            ],
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(12),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                // ==================================================
                // الأيقونة
                // ==================================================

                Container(
                  width: 75,
                  height: 75,

                  decoration:
                      BoxDecoration(
                    color:
                        color.withOpacity(0.10),

                    shape:
                        BoxShape.circle,

                    border:
                        Border.all(
                      color:
                          color.withOpacity(
                        0.18,
                      ),

                      width: 1,
                    ),
                  ),

                  child: Icon(
                    icon,

                    size: 42,

                    color: color,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==================================================
                // اسم التقرير
                // ==================================================

                Text(
                  title,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    color: mainColor,

                    fontSize: 17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ==================================================
                // الوصف
                // ==================================================

                Text(
                  subtitle,

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    fontSize: 12,

                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // ==================================================
                // سهم الدخول
                // ==================================================

                Container(
                  width: 32,
                  height: 32,

                  decoration:
                      BoxDecoration(
                    color:
                        color.withOpacity(0.08),

                    borderRadius:
                        BorderRadius.circular(
                      9,
                    ),
                  ),

                  child: Icon(
                    Icons
                        .arrow_back_ios_new,

                    size: 15,

                    color: color,
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