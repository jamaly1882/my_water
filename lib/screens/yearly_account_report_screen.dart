import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class YearlyAccountReportScreen extends StatefulWidget {
  final String accountId;
  final String accountName;

  final String? wellId;
  final String? wellName;

  const YearlyAccountReportScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    this.wellId,
    this.wellName,
  });

  @override
  State<YearlyAccountReportScreen> createState() =>
      _YearlyAccountReportScreenState();
}

class _YearlyAccountReportScreenState
    extends State<YearlyAccountReportScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  int selectedYear = DateTime.now().year;

  // =========================================================
  // الألوان
  // =========================================================

  static const Color primaryColor = Colors.indigo;
  static const Color secondaryColor = Colors.blue;

  // =========================================================
  // بداية السنة
  // =========================================================

  DateTime get startYear {
    return DateTime(
      selectedYear,
      1,
      1,
    );
  }

  // =========================================================
  // نهاية السنة
  // =========================================================

  DateTime get endYear {
    return DateTime(
      selectedYear + 1,
      1,
      1,
    );
  }

  // =========================================================
  // اختيار السنة
  // =========================================================

  Future<void> chooseYear() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: "اختر سنة التقرير",
      cancelText: "إلغاء",
      confirmText: "اختيار",
      fieldLabelText: "التاريخ",
      fieldHintText: "يوم/شهر/سنة",
    );

    if (date != null && mounted) {
      setState(() {
        selectedYear = date.year;
      });
    }
  }

  // =========================================================
  // تحويل أي قيمة إلى رقم
  // =========================================================

  num toNumber(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value;
    }

    return num.tryParse(
          value.toString().replaceAll(',', ''),
        ) ??
        0;
  }

  // =========================================================
  // تنسيق الرقم
  // =========================================================

  String formatNumber(dynamic value) {
    return toNumber(value).toStringAsFixed(2);
  }

  // =========================================================
  // الحصول على تاريخ الحركة
  // =========================================================

  DateTime? getTransactionDate(
    Map<String, dynamic> data,
  ) {
    if (data["date"] is Timestamp) {
      return (data["date"] as Timestamp).toDate();
    }

    if (data["createdAt"] is Timestamp) {
      return (data["createdAt"] as Timestamp).toDate();
    }

    return null;
  }

  // =========================================================
  // تنسيق التاريخ
  // =========================================================

  String formatDate(DateTime? date) {
    if (date == null) {
      return "بدون تاريخ";
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return "${date.year}/$month/$day "
        "$hour:$minute";
  }

  // =========================================================
  // الحصول على البيان
  // =========================================================

  String getDescription(
    Map<String, dynamic> data,
  ) {
    final statement =
        data["statement"]?.toString().trim();

    if (statement != null &&
        statement.isNotEmpty) {
      return statement;
    }

    final description =
        data["description"]?.toString().trim();

    if (description != null &&
        description.isNotEmpty) {
      return description;
    }

    final type =
        data["type"]?.toString().trim();

    if (type == "payment") {
      return "سند صرف";
    }

    if (type == "receipt") {
      return "سند قبض";
    }

    return type ?? "";
  }

  // =========================================================
  // اسم نوع السند
  // =========================================================

  String getVoucherType(
    Map<String, dynamic> data,
  ) {
    final type =
        data["type"]?.toString();

    if (type == "payment") {
      return "سند صرف";
    }

    if (type == "receipt") {
      return "سند قبض";
    }

    return "قيد";
  }

  // =========================================================
  // حساب المدين (عليه)
  // =========================================================

  num getDebit(
    Map<String, dynamic> data,
  ) {
    // ---------------------------------------------------------
    // الحركات القديمة التي تحتوي accountId
    // ---------------------------------------------------------

    if (data["accountId"] ==
        widget.accountId) {
      return toNumber(
        data["debit"],
      );
    }

    // ---------------------------------------------------------
    // الحساب الحالي هو الحساب المدين
    // ---------------------------------------------------------

    if (data["debitAccountId"] ==
        widget.accountId) {
      return toNumber(
        data["amount"],
      );
    }

    return 0;
  }

  // =========================================================
  // حساب الدائن (له)
  // =========================================================

  num getCredit(
    Map<String, dynamic> data,
  ) {
    // ---------------------------------------------------------
    // الحركات القديمة التي تحتوي accountId
    // ---------------------------------------------------------

    if (data["accountId"] ==
        widget.accountId) {
      return toNumber(
        data["credit"],
      );
    }

    // ---------------------------------------------------------
    // الحساب الحالي هو الحساب الدائن
    // ---------------------------------------------------------

    if (data["creditAccountId"] ==
        widget.accountId) {
      return toNumber(
        data["amount"],
      );
    }

    return 0;
  }

  // =========================================================
  // جلب جميع حركات الحساب
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getTransactions() async {
    final Map<String, Map<String, dynamic>>
        allTransactions = {};

    // =======================================================
    // 1 - accountId
    // =======================================================

    final accountQuery = await firestore
        .collection("account_transactions")
        .where(
          "accountId",
          isEqualTo: widget.accountId,
        )
        .get();

    for (final doc in accountQuery.docs) {
      allTransactions[doc.id] = {
        ...doc.data(),
        "_docId": doc.id,
      };
    }

    // =======================================================
    // 2 - debitAccountId
    // =======================================================

    final debitQuery = await firestore
        .collection("account_transactions")
        .where(
          "debitAccountId",
          isEqualTo: widget.accountId,
        )
        .get();

    for (final doc in debitQuery.docs) {
      allTransactions[doc.id] = {
        ...doc.data(),
        "_docId": doc.id,
      };
    }

    // =======================================================
    // 3 - creditAccountId
    // =======================================================

    final creditQuery = await firestore
        .collection("account_transactions")
        .where(
          "creditAccountId",
          isEqualTo: widget.accountId,
        )
        .get();

    for (final doc in creditQuery.docs) {
      allTransactions[doc.id] = {
        ...doc.data(),
        "_docId": doc.id,
      };
    }

    // =======================================================
    // تحويل إلى قائمة
    // =======================================================

    final List<Map<String, dynamic>> result =
        allTransactions.values.toList();

    // =======================================================
    // فلترة السنة
    // =======================================================

    result.removeWhere(
      (item) {
        final date =
            getTransactionDate(item);

        if (date == null) {
          return true;
        }

        return date.isBefore(startYear) ||
            !date.isBefore(endYear);
      },
    );

    // =======================================================
    // ترتيب من الأقدم إلى الأحدث
    // =======================================================

    result.sort(
      (a, b) {
        final dateA =
            getTransactionDate(a);

        final dateB =
            getTransactionDate(b);

        if (dateA == null &&
            dateB == null) {
          return 0;
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        return dateA.compareTo(dateB);
      },
    );

    return result;
  }

  // =========================================================
  // حساب الرصيد
  //
  // الرصيد = المدين (عليه) - الدائن (له)
  // =========================================================

  List<Map<String, dynamic>>
      calculateBalance(
    List<Map<String, dynamic>>
        transactions,
  ) {
    num balance = 0;

    final List<Map<String, dynamic>>
        result = [];

    for (final item in transactions) {
      final debit =
          getDebit(item);

      final credit =
          getCredit(item);

      balance += debit;
      balance -= credit;

      result.add({
        ...item,
        "_calculatedBalance": balance,
      });
    }

    return result;
  }

  // =========================================================
  // إجمالي المدين (عليه)
  // =========================================================

  num getTotalDebit(
    List<Map<String, dynamic>>
        transactions,
  ) {
    num total = 0;

    for (final item in transactions) {
      total += getDebit(item);
    }

    return total;
  }

  // =========================================================
  // إجمالي الدائن (له)
  // =========================================================

  num getTotalCredit(
    List<Map<String, dynamic>>
        transactions,
  ) {
    num total = 0;

    for (final item in transactions) {
      total += getCredit(item);
    }

    return total;
  }

  // =========================================================
  // الرصيد النهائي
  // =========================================================

  num getFinalBalance(
    List<Map<String, dynamic>>
        transactions,
  ) {
    if (transactions.isEmpty) {
      return 0;
    }

    final calculated =
        calculateBalance(
      transactions,
    );

    return toNumber(
      calculated.last[
          "_calculatedBalance"],
    );
  }

  // =========================================================
  // إحصائية
  // =========================================================

  Widget _buildReportStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 23,
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          title,
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            color:
                Colors.white70,
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          "$value ريال",
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // فاصل
  // =========================================================

  Widget _reportDivider() {
    return Container(
      width: 1,
      height: 52,
      color: Colors.white30,
    );
  }

  // =========================================================
  // ملخص التقرير
  // =========================================================

  Widget _buildReportSummary({
    required num totalDebit,
    required num totalCredit,
    required num finalBalance,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.centerRight,
          end:
              Alignment.centerLeft,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        boxShadow: [
          BoxShadow(
            color:
                primaryColor.withOpacity(
              0.18,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child:
                _buildReportStat(
              title:
                  "إجمالي المدين (عليه)",
              value:
                  formatNumber(
                totalDebit,
              ),
              icon:
                  Icons.arrow_downward,
            ),
          ),

          _reportDivider(),

          Expanded(
            child:
                _buildReportStat(
              title:
                  "إجمالي الدائن (له)",
              value:
                  formatNumber(
                totalCredit,
              ),
              icon:
                  Icons.arrow_upward,
            ),
          ),

          _reportDivider(),

          Expanded(
            child:
                _buildReportStat(
              title:
                  "الرصيد النهائي",
              value:
                  formatNumber(
                finalBalance,
              ),
              icon:
                  Icons.account_balance,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // عدد الحركات
  // =========================================================

  Widget _buildTransactionCount(
    int count,
  ) {
    return Container(
      width: double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color:
                      primaryColor,
                ),

                const SizedBox(
                  width: 8,
                ),

                const Text(
                  "عدد الحركات",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            Text(
              "$count",
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // لون نوع السند
  // =========================================================

  Color getVoucherColor(
    Map<String, dynamic> data,
  ) {
    final type =
        data["type"]?.toString();

    if (type == "payment") {
      return Colors.orange;
    }

    if (type == "receipt") {
      return Colors.green;
    }

    return primaryColor;
  }

  // =========================================================
  // أيقونة نوع السند
  // =========================================================

  IconData getVoucherIcon(
    Map<String, dynamic> data,
  ) {
    final type =
        data["type"]?.toString();

    if (type == "payment") {
      return Icons.arrow_downward;
    }

    if (type == "receipt") {
      return Icons.arrow_upward;
    }

    return Icons.swap_horiz;
  }

  // =========================================================
  // جدول التقرير
  // =========================================================

  Widget buildTable(
    List<Map<String, dynamic>>
        transactions,
  ) {
    return Container(
      width: double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
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
              color:
                  Colors.grey.shade300,
            ),

            headingRowColor:
                WidgetStateProperty.all(
              primaryColor
                  .withOpacity(
                0.10,
              ),
            ),

            columns: const [
              // =================================================
              // التاريخ
              // =================================================

              DataColumn(
                label: Text(
                  "التاريخ",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // =================================================
              // نوع السند
              // =================================================

              DataColumn(
                label: Text(
                  "نوع السند",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // =================================================
              // البيان
              // =================================================

              DataColumn(
                label: Text(
                  "البيان",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // =================================================
              // مدين (عليه)
              // =================================================

              DataColumn(
                label: Text(
                  "مدين (عليه)",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // =================================================
              // دائن (له)
              // =================================================

              DataColumn(
                label: Text(
                  "دائن (له)",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // =================================================
              // الرصيد
              // =================================================

              DataColumn(
                label: Text(
                  "الرصيد",
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],

            rows:
                transactions.map(
              (data) {
                final date =
                    getTransactionDate(
                  data,
                );

                final debit =
                    getDebit(data);

                final credit =
                    getCredit(data);

                final balance =
                    data[
                        "_calculatedBalance"] ??
                    0;

                final voucherColor =
                    getVoucherColor(
                  data,
                );

                return DataRow(
                  cells: [
                    // =====================================
                    // التاريخ
                    // =====================================

                    DataCell(
                      Text(
                        formatDate(
                          date,
                        ),
                      ),
                    ),

                    // =====================================
                    // نوع السند
                    // =====================================

                    DataCell(
                      Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration:
                                BoxDecoration(
                              color:
                                  voucherColor
                                      .withOpacity(
                                0.10,
                              ),
                              shape:
                                  BoxShape
                                      .circle,
                            ),
                            child:
                                Icon(
                              getVoucherIcon(
                                data,
                              ),
                              color:
                                  voucherColor,
                              size:
                                  17,
                            ),
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          Text(
                            getVoucherType(
                              data,
                            ),
                            style:
                                TextStyle(
                              color:
                                  voucherColor,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =====================================
                    // البيان
                    // =====================================

                    DataCell(
                      SizedBox(
                        width: 280,
                        child:
                            Text(
                          getDescription(
                            data,
                          ),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ),

                    // =====================================
                    // المدين (عليه)
                    // =====================================

                    DataCell(
                      Text(
                        formatNumber(
                          debit,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.red,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    // =====================================
                    // الدائن (له)
                    // =====================================

                    DataCell(
                      Text(
                        formatNumber(
                          credit,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    // =====================================
                    // الرصيد
                    // =====================================

                    DataCell(
                      Text(
                        formatNumber(
                          balance,
                        ),
                        style:
                            const TextStyle(
                          color:
                              primaryColor,
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
    );
  }

  // =========================================================
  // الصفحة
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool hasWell =
        widget.wellName != null &&
        widget.wellName!
            .trim()
            .isNotEmpty;

    return Directionality(
      textDirection:
          TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        // =====================================================
        // شريط التطبيق
        // =====================================================

        appBar:
            MyAppBar(
          title:
              "التقرير السنوي - ${widget.accountName}",

          subtitle:
              hasWell
                  ? "البئر: ${widget.wellName}"
                  : "السنة: $selectedYear",

          icon:
              Icons.account_balance_wallet,
        ),

        // =====================================================
        // BODY
        // =====================================================

        body:
            Padding(
          padding:
              const EdgeInsets.all(
            12,
          ),

          child:
              Column(
            children: [
              // =================================================
              // معلومات الحساب
              // =================================================

              Container(
                width:
                    double.infinity,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withOpacity(
                        0.05,
                      ),
                      blurRadius:
                          6,
                      offset:
                          const Offset(
                        0,
                        2,
                      ),
                    ),
                  ],
                ),

                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),

                  child:
                      Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width:
                                52,
                            height:
                                52,

                            decoration:
                                const BoxDecoration(
                              gradient:
                                  LinearGradient(
                                colors: [
                                  primaryColor,
                                  secondaryColor,
                                ],
                              ),
                              shape:
                                  BoxShape.circle,
                            ),

                            child:
                                const Icon(
                              Icons
                                  .account_balance_wallet,
                              color:
                                  Colors.white,
                              size:
                                  27,
                            ),
                          ),

                          const SizedBox(
                            width:
                                12,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  "الحساب",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                    fontSize:
                                        12,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      3,
                                ),

                                Text(
                                  widget.accountName,

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      3,
                                ),

                                Text(
                                  "رقم الحساب: ${widget.accountId}",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // =========================================
                      // البئر
                      // =========================================

                      if (hasWell) ...[
                        const Divider(
                          height:
                              25,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color:
                                  Colors.blue,
                            ),

                            const SizedBox(
                              width:
                                  8,
                            ),

                            Expanded(
                              child:
                                  Text(
                                "البئر: ${widget.wellName}",

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (widget.wellId !=
                              null &&
                          widget.wellId!
                              .trim()
                              .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top:
                                5,
                          ),

                          child:
                              Align(
                            alignment:
                                Alignment
                                    .centerRight,

                            child:
                                Text(
                              "رقم البئر: ${widget.wellId}",

                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              // =================================================
              // اختيار السنة
              // =================================================

              SizedBox(
                width:
                    double.infinity,

                height:
                    50,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      chooseYear,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        primaryColor,

                    foregroundColor:
                        Colors.white,

                    elevation:
                        2,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),

                  icon:
                      const Icon(
                    Icons.date_range,
                  ),

                  label:
                      Text(
                    "السنة: $selectedYear",

                    style:
                        const TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              // =================================================
              // التقرير
              // =================================================

              Expanded(
                child:
                    FutureBuilder<
                        List<
                            Map<String,
                                dynamic>>>(
                  future:
                      getTransactions(),

                  builder:
                      (
                    context,
                    snapshot,
                  ) {
                    // =========================================
                    // تحميل
                    // =========================================

                    if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    // =========================================
                    // خطأ
                    // =========================================

                    if (snapshot.hasError) {
                      return Center(
                        child:
                            Container(
                          margin:
                              const EdgeInsets
                                  .all(
                            20,
                          ),

                          padding:
                              const EdgeInsets
                                  .all(
                            20,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),

                          child:
                              Text(
                            "حدث خطأ أثناء تحميل التقرير:\n\n"
                            "${snapshot.error}",

                            textAlign:
                                TextAlign
                                    .center,

                            style:
                                const TextStyle(
                              color:
                                  Colors.red,
                            ),
                          ),
                        ),
                      );
                    }

                    // =========================================
                    // البيانات
                    // =========================================

                    final list =
                        snapshot.data ??
                            [];

                    // =========================================
                    // لا توجد بيانات
                    // =========================================

                    if (list.isEmpty) {
                      return Center(
                        child:
                            Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons
                                  .receipt_long,
                              size:
                                  70,
                              color:
                                  Colors.grey
                                      .shade400,
                            ),

                            const SizedBox(
                              height:
                                  15,
                            ),

                            Text(
                              "لا توجد حركة في سنة $selectedYear",

                              style:
                                  const TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // =========================================
                    // الإجماليات
                    // =========================================

                    final totalDebit =
                        getTotalDebit(
                      list,
                    );

                    final totalCredit =
                        getTotalCredit(
                      list,
                    );

                    final finalBalance =
                        getFinalBalance(
                      list,
                    );

                    // =========================================
                    // الرصيد بعد كل حركة
                    // =========================================

                    final transactions =
                        calculateBalance(
                      list,
                    );

                    // =========================================
                    // التقرير
                    // =========================================

                    return Column(
                      children: [
                        // =======================================
                        // ملخص
                        // =======================================

                        _buildReportSummary(
                          totalDebit:
                              totalDebit,

                          totalCredit:
                              totalCredit,

                          finalBalance:
                              finalBalance,
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        // =======================================
                        // عدد الحركات
                        // =======================================

                        _buildTransactionCount(
                          list.length,
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        // =======================================
                        // الجدول
                        // =======================================

                        Expanded(
                          child:
                              buildTable(
                            transactions,
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
      ),
    );
  }
}