import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class MonthlyCycleReportScreen extends StatefulWidget {
  final String? wellId;
  final String? wellName;

  const MonthlyCycleReportScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  @override
  State<MonthlyCycleReportScreen> createState() =>
      _MonthlyCycleReportScreenState();
}

class _MonthlyCycleReportScreenState
    extends State<MonthlyCycleReportScreen> {
  late Stream<QuerySnapshot> _monthlyStream;

  late int _currentYear;
  late int _currentMonth;

  // ============================================================
  // اللون الموحد مع MyAppBar
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // خلفية الصفحة
  // ============================================================

  static const Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();

    _initReportStream();
  }

  // ============================================================
  // إنشاء استعلام التقرير الشهري
  // ============================================================

  void _initReportStream() {
    final now = DateTime.now();

    _currentYear = now.year;
    _currentMonth = now.month;

    final start = DateTime(
      _currentYear,
      _currentMonth,
      1,
    );

    final end = DateTime(
      _currentYear,
      _currentMonth + 1,
      1,
    );

    _monthlyStream = FirebaseFirestore.instance
        .collection("cycles")
        .where(
          "wellId",
          isEqualTo: widget.wellId,
        )
        .where(
          "createdAt",
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(start),
        )
        .where(
          "createdAt",
          isLessThan:
              Timestamp.fromDate(end),
        )
        .snapshots();
  }

  // ============================================================
  // تحويل الرقم
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }

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
          title: "التقرير الشهري للدور",

          subtitle:
              "${widget.wellName ?? ''} - $_currentMonth / $_currentYear",

          icon: Icons.assessment,
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: Column(
          children: [
            // ====================================================
            // معلومات البئر
            // بنفس لون شريط العنوان
            // ====================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),

              decoration: BoxDecoration(
                color: mainColor,

                boxShadow: [
                  BoxShadow(
                    color:
                        mainColor.withOpacity(
                      0.18,
                    ),

                    blurRadius: 6,

                    offset:
                        const Offset(0, 2),
                  ),
                ],
              ),

              child: Row(
                children: [
                  // ==================================================
                  // أيقونة البئر
                  // ==================================================

                  Container(
                    width: 46,
                    height: 46,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white.withOpacity(
                        0.16,
                      ),

                      shape:
                          BoxShape.circle,

                      border: Border.all(
                        color:
                            Colors.white.withOpacity(
                          0.25,
                        ),
                      ),
                    ),

                    child: const Icon(
                      Icons.water_drop,

                      color:
                          Colors.white,

                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ==================================================
                  // معلومات البئر
                  // ==================================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          "البئر: ${widget.wellName ?? ''}",

                          style:
                              const TextStyle(
                            fontSize: 17,

                            fontWeight:
                                FontWeight.bold,

                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          "رقم البئر: ${widget.wellId ?? ''}",

                          style:
                              const TextStyle(
                            fontSize: 12,

                            color:
                                Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // التقرير
            // ====================================================

            Expanded(
              child:
                  StreamBuilder<QuerySnapshot>(
                stream: _monthlyStream,

                builder:
                    (context, snapshot) {
                  // ===============================================
                  // خطأ
                  // ===============================================

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child: Text(
                          "حدث خطأ أثناء تحميل البيانات:\n\n"
                          "${snapshot.error}",

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            color:
                                Colors.red,
                          ),
                        ),
                      ),
                    );
                  }

                  // ===============================================
                  // تحميل
                  // ===============================================

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color: mainColor,
                      ),
                    );
                  }

                  // ===============================================
                  // لا توجد بيانات
                  // ===============================================

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "لا توجد أدوار لهذا الشهر لهذا البئر",

                        style:
                            TextStyle(
                          fontSize: 16,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  // ===============================================
                  // جميع الأدوار
                  // ===============================================

                  final docs =
                      snapshot.data!.docs.toList();

                  // ===============================================
                  // ترتيب الأدوار
                  // ===============================================

                  docs.sort((a, b) {
                    final dataA =
                        a.data()
                            as Map<String, dynamic>;

                    final dataB =
                        b.data()
                            as Map<String, dynamic>;

                    final cycleA =
                        _toDouble(
                      dataA["cycleNumber"],
                    );

                    final cycleB =
                        _toDouble(
                      dataB["cycleNumber"],
                    );

                    return cycleA.compareTo(
                      cycleB,
                    );
                  });

                  // ===============================================
                  // حساب الإجماليات
                  // ===============================================

                  double totalConsumption = 0;

                  double totalAmount = 0;

                  for (final doc in docs) {
                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    totalConsumption +=
                        _toDouble(
                      data["consumption"],
                    );

                    totalAmount +=
                        _toDouble(
                      data["amount"],
                    );
                  }

                  final totalCycles =
                      docs.length;

                  // ===============================================
                  // عرض التقرير
                  // ===============================================

                  return Column(
                    children: [
                      // =============================================
                      // كروت الملخص
                      // =============================================

                      Padding(
                        padding:
                            const EdgeInsets.all(
                          8,
                        ),

                        child: Row(
                          children: [
                            Expanded(
                              child:
                                  _buildStatCard(
                                "عدد الأدوار",

                                "$totalCycles",
                              ),
                            ),

                            Expanded(
                              child:
                                  _buildStatCard(
                                "إجمالي الاستهلاك",

                                totalConsumption
                                    .toStringAsFixed(
                                  0,
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                                  _buildStatCard(
                                "إجمالي المبالغ",

                                totalAmount
                                    .toStringAsFixed(
                                  0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                      ),

                      // =============================================
                      // جدول التقرير
                      // =============================================

                      Expanded(
                        child:
                            SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,

                          child:
                              SingleChildScrollView(
                            scrollDirection:
                                Axis.vertical,

                            child: DataTable(
                              border:
                                  TableBorder.all(
                                color:
                                    Colors.grey.shade300,
                              ),

                              // =====================================
                              // عنوان الجدول
                              // =====================================

                              headingRowColor:
                                  WidgetStateProperty
                                      .all(
                                mainColor
                                    .withOpacity(
                                  0.10,
                                ),
                              ),

                              columns:
                                  const [
                                DataColumn(
                                  label:
                                      Text(
                                    "الدور",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "الزبون",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "الاستخدام",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "نوع العداد",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "السابقة",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "الحالية",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "الاستهلاك",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "سعر الوحدة",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "الإجمالي",
                                  ),
                                ),

                                DataColumn(
                                  label:
                                      Text(
                                    "الحالة",
                                  ),
                                ),
                              ],

                              rows:
                                  docs.map(
                                (doc) {
                                  final data =
                                      doc.data()
                                          as Map<String,
                                              dynamic>;

                                  return DataRow(
                                    cells: [
                                      // الدور
                                      DataCell(
                                        Text(
                                          "${data["cycleNumber"] ?? 0}",
                                        ),
                                      ),

                                      // الزبون
                                      DataCell(
                                        Text(
                                          "${data["customerName"] ?? ""}",
                                        ),
                                      ),

                                      // الاستخدام
                                      DataCell(
                                        Text(
                                          "${data["waterUsageTypeName"] ?? ""}",
                                        ),
                                      ),

                                      // نوع العداد
                                      DataCell(
                                        Text(
                                          "${data["meterTypeName"] ?? ""}",
                                        ),
                                      ),

                                      // السابقة
                                      DataCell(
                                        Text(
                                          "${data["previousReading"] ?? 0}",
                                        ),
                                      ),

                                      // الحالية
                                      DataCell(
                                        Text(
                                          "${data["currentReading"] ?? 0}",
                                        ),
                                      ),

                                      // الاستهلاك
                                      DataCell(
                                        Text(
                                          "${data["consumption"] ?? 0}",
                                        ),
                                      ),

                                      // سعر الوحدة
                                      DataCell(
                                        Text(
                                          "${data["unitPrice"] ?? 0}",
                                        ),
                                      ),

                                      // الإجمالي
                                      DataCell(
                                        Text(
                                          "${data["amount"] ?? 0}",
                                        ),
                                      ),

                                      // الحالة
                                      DataCell(
                                        Text(
                                          "${data["status"] ?? ""}",
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // كرت الإحصائيات
  // بنفس اللون الأزرق
  // ============================================================

  Widget _buildStatCard(
    String title,
    String value,
  ) {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 4,
      ),

      decoration: BoxDecoration(
        color: mainColor,

        borderRadius:
            BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color:
                mainColor.withOpacity(
              0.18,
            ),

            blurRadius: 6,

            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 4,
        ),

        child: Column(
          children: [
            Text(
              title,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 11,

                color:
                    Colors.white70,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              value,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 15,

                fontWeight:
                    FontWeight.bold,

                color:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}