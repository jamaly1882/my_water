import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

import 'daily_account_report_screen.dart';
import 'monthly_account_report_screen.dart';
import 'yearly_account_report_screen.dart';

class AccountReportTypeScreen extends StatelessWidget {
  final String accountId;
  final Map<String, dynamic> accountData;
  final String accountName;

  final String? wellId;
  final String? wellName;

  // ============================================================
  // اللون الموحد
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // خلفية الصفحة
  // ============================================================

  static const Color backgroundColor = Colors.white;

  const AccountReportTypeScreen({
    super.key,
    required this.accountId,
    required this.accountData,
    required this.accountName,
    this.wellId,
    this.wellName,
  });

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
          title: "تقارير الحساب",

          subtitle: accountName.isNotEmpty
              ? accountName
              : "اختر نوع التقرير",

          icon:
              Icons.account_balance_wallet,
        ),

        // ========================================================
        // المحتوى
        // ========================================================

        body: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // معلومات الحساب
              // ==================================================

              Container(
                width: double.infinity,

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  border: Border.all(
                    color:
                        mainColor.withOpacity(
                      0.14,
                    ),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.05,
                      ),

                      blurRadius: 7,

                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          // ========================================
                          // أيقونة الحساب
                          // ========================================

                          Container(
                            width: 52,
                            height: 52,

                            decoration:
                                BoxDecoration(
                              color:
                                  mainColor.withOpacity(
                                0.10,
                              ),

                              shape:
                                  BoxShape.circle,

                              border:
                                  Border.all(
                                color:
                                    mainColor.withOpacity(
                                  0.15,
                                ),
                              ),
                            ),

                            child: const Icon(
                              Icons.person,

                              color:
                                  mainColor,

                              size: 28,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          // ========================================
                          // اسم الحساب
                          // ========================================

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  "الحساب",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.black54,

                                    fontSize:
                                        13,
                                  ),
                                ),

                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  accountName,

                                  style:
                                      const TextStyle(
                                    color:
                                        mainColor,

                                    fontSize:
                                        18,

                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(
                        height: 25,
                      ),

                      // ==========================================
                      // البئر
                      // ==========================================

                      if (wellName != null &&
                          wellName!
                              .trim()
                              .isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,

                              color:
                                  mainColor,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                "البئر: $wellName",

                                style:
                                    const TextStyle(
                                  color:
                                      mainColor,

                                  fontSize:
                                      16,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // ==========================================
                      // رقم البئر
                      // ==========================================

                      if (wellId != null &&
                          wellId!
                              .trim()
                              .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 8,
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.tag,

                                size: 20,

                                color:
                                    Colors.grey,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Text(
                                "رقم البئر: $wellId",

                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // عنوان اختيار التقرير
              // بنفس لون شريط العنوان
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),

                decoration:
                    BoxDecoration(
                  color: mainColor,

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          mainColor.withOpacity(
                        0.18,
                      ),

                      blurRadius: 7,

                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),

                child: const Row(
                  children: [
                    // ==========================================
                    // الأيقونة
                    // ==========================================

                    Icon(
                      Icons.assessment,

                      color:
                          Colors.white,
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    // ==========================================
                    // العنوان
                    // ==========================================

                    Text(
                      "اختر نوع التقرير",

                      style:
                          TextStyle(
                        color:
                            Colors.white,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // التقارير
              // ==================================================

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,

                  crossAxisSpacing: 15,

                  mainAxisSpacing: 15,

                  childAspectRatio: 1.0,

                  children: [
                    // ============================================
                    // التقرير اليومي
                    // ============================================

                    _reportCard(
                      context,

                      "التقرير اليومي",

                      Icons.today,

                      mainColor,

                      DailyAccountReportScreen(
                        accountId:
                            accountId,

                        accountName:
                            accountName,

                        wellId:
                            wellId,

                        wellName:
                            wellName,
                      ),
                    ),

                    // ============================================
                    // التقرير الشهري
                    // ============================================

                    _reportCard(
                      context,

                      "التقرير الشهري",

                      Icons.calendar_month,

                      mainColor,

                      MonthlyAccountReportScreen(
                        accountId:
                            accountId,

                        accountName:
                            accountName,

                        wellId:
                            wellId,

                        wellName:
                            wellName,
                      ),
                    ),

                    // ============================================
                    // التقرير السنوي
                    // ============================================

                    _reportCard(
                      context,

                      "التقرير السنوي",

                      Icons.date_range,

                      mainColor,

                      YearlyAccountReportScreen(
                        accountId:
                            accountId,

                        accountName:
                            accountName,

                        wellId:
                            wellId,

                        wellName:
                            wellName,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // كرت التقرير
  // ================================================================

  Widget _reportCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        onTap: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) =>
                  page,
            ),
          );
        },

        child: Ink(
          decoration:
              BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border: Border.all(
              color:
                  color.withOpacity(
                0.14,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.06,
                ),

                blurRadius: 8,

                offset:
                    const Offset(0, 3),
              ),
            ],
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                // ================================================
                // الأيقونة
                // ================================================

                Container(
                  width: 72,
                  height: 72,

                  decoration:
                      BoxDecoration(
                    color:
                        color.withOpacity(
                      0.10,
                    ),

                    shape:
                        BoxShape.circle,

                    border:
                        Border.all(
                      color:
                          color.withOpacity(
                        0.16,
                      ),
                    ),
                  ),

                  child: Icon(
                    icon,

                    size: 42,

                    color: color,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // ================================================
                // العنوان
                // ================================================

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

                // ================================================
                // الوصف
                // ================================================

                Text(
                  "عرض التقرير",

                  style:
                      TextStyle(
                    fontSize: 12,

                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // ================================================
                // السهم
                // ================================================

                Container(
                  width: 32,
                  height: 32,

                  decoration:
                      BoxDecoration(
                    color:
                        color.withOpacity(
                      0.08,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      9,
                    ),
                  ),

                  child: Icon(
                    Icons
                        .arrow_back_ios_new,

                    color: color,

                    size: 15,
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