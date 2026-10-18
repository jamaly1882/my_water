
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class YearlyCycleReportScreen extends StatefulWidget {
  final String? wellId;
  final String? wellName;

  const YearlyCycleReportScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  @override
  State<YearlyCycleReportScreen> createState() =>
      _YearlyCycleReportScreenState();
}

class _YearlyCycleReportScreenState
    extends State<YearlyCycleReportScreen> {
  late Stream<QuerySnapshot> _cyclesStream;
  late int _currentYear;

  // =========================================================
  // اللون الرئيسي
  // نفس لون شريط العنوان
  // =========================================================

  static const Color primaryColor = Colors.blue;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _initReportStream();
  }

  // =========================================================
  // إنشاء استعلام التقرير السنوي
  // =========================================================

  void _initReportStream() {
    final now = DateTime.now();

    _currentYear = now.year;

    final start = DateTime(
      _currentYear,
      1,
      1,
    );

    final end = DateTime(
      _currentYear + 1,
      1,
      1,
    );

    _cyclesStream = FirebaseFirestore.instance
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bool hasWell =
        widget.wellName != null &&
        widget.wellName!.trim().isNotEmpty;

    // =========================================================
    // التأكد من وجود البئر
    // =========================================================

    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,

        child: Scaffold(
          backgroundColor:
              const Color(0xffF5F9FF),

          appBar: MyAppBar(
            title: "التقرير السنوي للدور",

            subtitle:
                "تقرير السنة $_currentYear",

            icon: Icons.assessment,
          ),

          body: const Center(
            child: Text(
              "لم يتم تحديد رقم البئر",

              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        // =====================================================
        // شريط عنوان واحد فقط
        // =====================================================

        appBar: MyAppBar(
          title: "التقرير السنوي للدور",

          subtitle: hasWell
              ? "البئر: ${widget.wellName} - السنة $_currentYear"
              : "تقرير السنة $_currentYear",

          icon: Icons.assessment,
        ),

        // =====================================================
        // التقرير
        // =====================================================

        body: StreamBuilder<QuerySnapshot>(
          stream: _cyclesStream,

          builder: (
            context,
            snapshot,
          ) {
            // =================================================
            // خطأ
            // =================================================

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
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }

            // =================================================
            // تحميل
            // =================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            // =================================================
            // لا توجد بيانات
            // =================================================

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
                            "لا توجد أدوار مسجلة لهذا البئر خلال هذه السنة",

                            textAlign:
                                TextAlign.center,

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

            // =================================================
            // نسخ البيانات
            // =================================================

            final docs =
                snapshot.data!.docs.toList();

            // =================================================
            // ترتيب الأدوار
            // =================================================

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

            // =================================================
            // حساب الإجماليات
            // =================================================

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

            final int cyclesCount =
                docs.length;

            // =================================================
            // عرض التقرير
            // =================================================

            return Column(
              children: [
                // =================================================
                // رأس التقرير
                // نفس لون شريط العنوان
                // =================================================

                _buildReportHeader(),

                // =================================================
                // الإحصائيات
                // =================================================

                Container(
                  margin:
                      const EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
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
                          3,
                        ),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _buildStatItem(
                          "إجمالي الأدوار",
                          "$cyclesCount",
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
                          "إجمالي المبالغ",
                          totalAmount
                              .toStringAsFixed(
                            0,
                          ),
                          Icons.payments,
                        ),
                      ),

                      _divider(),

                      Expanded(
                        child:
                            _buildStatItem(
                          "السنة",
                          "$_currentYear",
                          Icons.calendar_month,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // =================================================
                // الجدول
                // =================================================

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

                          // =================================================
                          // رأس الجدول بلون فاتح من نفس لون العنوان
                          // =================================================

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
                                  Text("التاريخ"),
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
                                  Text("نوع العداد"),
                            ),

                            DataColumn(
                              label:
                                  Text("السابقة"),
                            ),

                            DataColumn(
                              label:
                                  Text("الحالية"),
                            ),

                            DataColumn(
                              label:
                                  Text("الاستهلاك"),
                            ),

                            DataColumn(
                              label:
                                  Text("سعر الوحدة"),
                            ),

                            DataColumn(
                              label:
                                  Text("الإجمالي"),
                            ),

                            DataColumn(
                              label:
                                  Text("الحالة"),
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

                              // =========================================
                              // التاريخ
                              // =========================================

                              String dateText =
                                  "-";

                              final timestamp =
                                  data[
                                      "createdAt"];

                              if (timestamp
                                  is Timestamp) {
                                final date =
                                    timestamp
                                        .toDate();

                                dateText =
                                    "${date.day.toString().padLeft(2, '0')}-"
                                    "${date.month.toString().padLeft(2, '0')}-"
                                    "${date.year}";
                              }

                              // =========================================
                              // الحالة
                              // =========================================

                              final status =
                                  data["status"]
                                      ?.toString() ??
                                  "";

                              return DataRow(
                                cells: [
                                  // الدور
                                  DataCell(
                                    Text(
                                      "${data["cycleNumber"] ?? 0}",
                                    ),
                                  ),

                                  // التاريخ
                                  DataCell(
                                    Text(
                                      dateText,
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
                                      status,

                                      style:
                                          TextStyle(
                                        color:
                                            status ==
                                                    "مغلق"
                                                ? Colors
                                                    .green
                                                : Colors
                                                    .orange,

                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
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
        ),
      ),
    );
  }

  // =========================================================
  // رأس التقرير
  // نفس لون شريط العنوان
  // =========================================================

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
          // =====================================================
          // العنوان
          // =====================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.assessment,
                color: Colors.white,
                size: 22,
              ),

              const SizedBox(
                width: 8,
              ),

              const Text(
                "التقرير السنوي للدور",

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

          // =====================================================
          // السنة
          // =====================================================

          Text(
            "السنة: $_currentYear",

            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          // =====================================================
          // البئر
          // =====================================================

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
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

          // =====================================================
          // رقم البئر
          // =====================================================

          if (widget.wellId != null &&
              widget.wellId!
                  .trim()
                  .isNotEmpty)
            Text(
              "رقم البئر: ${widget.wellId}",

              style:
                  const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // عنصر الإحصائية
  // =========================================================

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
          size: 21,
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
            fontSize: 10,
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

  // =========================================================
  // فاصل الإحصائيات
  // =========================================================

  Widget _divider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white30,
    );
  }

  // =========================================================
  // تحويل الرقم إلى double بأمان
  // =========================================================

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

