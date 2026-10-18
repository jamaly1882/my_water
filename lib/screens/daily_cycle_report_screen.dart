
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class DailyCycleReportScreen extends StatefulWidget {
  final String? wellId;
  final String? wellName;

  const DailyCycleReportScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  @override
  State<DailyCycleReportScreen> createState() =>
      _DailyCycleReportScreenState();
}

class _DailyCycleReportScreenState
    extends State<DailyCycleReportScreen> {
  late Stream<QuerySnapshot> _dailyStream;

  // ============================================================
  // اللون الرئيسي
  // نفس لون شريط MyAppBar
  // ============================================================

  static const Color primaryColor = Colors.blue;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initDailyStream();
  }

  // ============================================================
  // تهيئة تقرير اليوم
  // ============================================================

  void _initDailyStream() {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    _dailyStream = FirebaseFirestore.instance
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool hasWell =
        widget.wellName != null &&
        widget.wellName!.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        // ========================================================
        // شريط عنوان واحد فقط
        // ========================================================

        appBar: MyAppBar(
          title: "التقرير اليومي للدور",

          subtitle: hasWell
              ? "البئر: ${widget.wellName}"
              : "التقرير اليومي",

          icon: Icons.water_drop,
        ),

        // ========================================================
        // التقرير
        // ========================================================

        body: _buildReport(),
      ),
    );
  }

  // ============================================================
  // التقرير
  // ============================================================

  Widget _buildReport() {
    // ============================================================
    // التأكد من وجود البئر
    // ============================================================

    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      return const Center(
        child: Text(
          "لم يتم تحديد رقم البئر",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // ============================================================
    // Stream
    // ============================================================

    return StreamBuilder<QuerySnapshot>(
      stream: _dailyStream,

      builder: (
        context,
        snapshot,
      ) {
        // ========================================================
        // خطأ
        // ========================================================

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),

              child: Text(
                "حدث خطأ أثناء تحميل البيانات:\n\n"
                "${snapshot.error}",

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          );
        }

        // ========================================================
        // تحميل
        // ========================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        // ========================================================
        // لا توجد بيانات
        // ========================================================

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              _buildReportHeader(),

              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 65,
                        color: Colors.grey,
                      ),

                      SizedBox(
                        height: 15,
                      ),

                      Text(
                        "لا توجد أدوار اليوم لهذا البئر",

                        style:
                            TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // ========================================================
        // جميع الأدوار
        // ========================================================

        final docs =
            snapshot.data!.docs.toList();

        // ========================================================
        // ترتيب حسب رقم الدور
        // ========================================================

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

        // ========================================================
        // الإحصائيات
        // ========================================================

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

        final int totalCycles =
            docs.length;

        // ========================================================
        // عرض التقرير
        // ========================================================

        return Column(
          children: [
            // ====================================================
            // رأس التقرير
            // نفس لون شريط العنوان
            // ====================================================

            _buildReportHeader(),

            // ====================================================
            // شريط الإحصائيات
            // نفس لون شريط العنوان
            // ====================================================

            Container(
              margin:
                  const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                5,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),

              decoration:
                  BoxDecoration(
                color: primaryColor,

                borderRadius:
                    BorderRadius.circular(
                  15,
                ),

                boxShadow: [
                  BoxShadow(
                    color: primaryColor
                        .withOpacity(
                      0.20,
                    ),

                    blurRadius: 8,

                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              child: Row(
                children: [
                  Expanded(
                    child:
                        _buildStatItem(
                      "أدوار اليوم",
                      "$totalCycles",
                      Icons.water_drop,
                    ),
                  ),

                  _divider(),

                  Expanded(
                    child:
                        _buildStatItem(
                      "الاستهلاك",
                      totalConsumption
                          .toStringAsFixed(
                        0,
                      ),
                      Icons.opacity,
                    ),
                  ),

                  _divider(),

                  Expanded(
                    child:
                        _buildStatItem(
                      "المبالغ",
                      totalAmount
                          .toStringAsFixed(
                        0,
                      ),
                      Icons.payments,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            // ====================================================
            // الجدول
            // ====================================================

            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.fromLTRB(
                  8,
                  0,
                  8,
                  8,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.06,
                      ),

                      blurRadius: 5,

                      offset:
                          const Offset(
                        0,
                        2,
                      ),
                    ),
                  ],
                ),

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
                        color: Colors
                            .grey
                            .shade300,
                      ),

                      // ==================================================
                      // رأس الجدول بنفس اللون الرئيسي بشكل فاتح
                      // ==================================================

                      headingRowColor:
                          WidgetStateProperty
                              .all(
                        primaryColor
                            .withOpacity(
                          0.10,
                        ),
                      ),

                      columns: const [
                        DataColumn(
                          label:
                              Text("الدور"),
                        ),

                        DataColumn(
                          label:
                              Text("الزبون"),
                        ),

                        DataColumn(
                          label:
                              Text("الاستخدام"),
                        ),

                        DataColumn(
                          label:
                              Text("العداد"),
                        ),

                        DataColumn(
                          label:
                              Text("سابقة"),
                        ),

                        DataColumn(
                          label:
                              Text("حالية"),
                        ),

                        DataColumn(
                          label:
                              Text("الاستهلاك"),
                        ),

                        DataColumn(
                          label:
                              Text("الإجمالي"),
                        ),
                      ],

                      rows:
                          docs.map(
                        (doc) {
                          final data =
                              doc.data()
                                  as Map<
                                      String,
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

                              // الإجمالي
                              DataCell(
                                Text(
                                  "${data["amount"] ?? 0}",
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
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // رأس التقرير
  // نفس لون شريط MyAppBar
  // ============================================================

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.fromLTRB(
        8,
        8,
        8,
        0,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      decoration:
          BoxDecoration(
        color: primaryColor,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        boxShadow: [
          BoxShadow(
            color:
                primaryColor.withOpacity(
              0.25,
            ),

            blurRadius: 5,

            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),

      child: Column(
        children: [
          // ======================================================
          // عنوان التقرير
          // ======================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 22,
              ),

              const SizedBox(
                width: 8,
              ),

              const Text(
                "التقرير اليومي للدور",

                style:
                    TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          // ======================================================
          // التاريخ
          // ======================================================

          Text(
            "اليوم: ${_formatToday()}",

            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          // ======================================================
          // البئر
          // ======================================================

          if (widget.wellName != null &&
              widget.wellName!
                  .trim()
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 3,
              ),

              child: Text(
                "البئر: ${widget.wellName}",

                style:
                    const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),

          // ======================================================
          // رقم البئر
          // ======================================================

          if (widget.wellId != null &&
              widget.wellId!
                  .trim()
                  .isNotEmpty)
            Text(
              "رقم البئر: ${widget.wellId}",

              style:
                  const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // تاريخ اليوم
  // ============================================================

  String _formatToday() {
    final now = DateTime.now();

    final month =
        now.month.toString().padLeft(
              2,
              '0',
            );

    final day =
        now.day.toString().padLeft(
              2,
              '0',
            );

    return "${now.year}/$month/$day";
  }

  // ============================================================
  // عنصر الإحصائية
  // ============================================================

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          title,

          textAlign:
              TextAlign.center,

          style:
              const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          value,

          textAlign:
              TextAlign.center,

          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // فاصل الإحصائيات
  // ============================================================

  Widget _divider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white30,
    );
  }

  // ============================================================
  // تحويل إلى double
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
}

