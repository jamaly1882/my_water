import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class MonthlyAccountReportScreen extends StatefulWidget {
  final String accountId;
  final String accountName;

  final String? wellId;
  final String? wellName;

  const MonthlyAccountReportScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    this.wellId,
    this.wellName,
  });

  @override
  State<MonthlyAccountReportScreen> createState() =>
      _MonthlyAccountReportScreenState();
}

class _MonthlyAccountReportScreenState
    extends State<MonthlyAccountReportScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DateTime selectedMonth = DateTime.now();

  static const Color mainColor = Colors.blue;
  static const Color backgroundColor = Color(0xffF5F9FF);

  // ============================================================
  // بداية الشهر
  // ============================================================

  DateTime get startMonth {
    return DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
  }

  // ============================================================
  // نهاية الشهر
  // ============================================================

  DateTime get endMonth {
    return DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      1,
    );
  }

  // ============================================================
  // اختيار الشهر
  // ============================================================

  Future<void> chooseMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: "اختر الشهر",
      cancelText: "إلغاء",
      confirmText: "اختيار",
    );

    if (date != null && mounted) {
      setState(() {
        selectedMonth = date;
      });
    }
  }

  // ============================================================
  // الحصول على التاريخ
  // ============================================================

  DateTime? getDate(Map<String, dynamic> data) {
    if (data["date"] is Timestamp) {
      return (data["date"] as Timestamp).toDate();
    }

    if (data["createdAt"] is Timestamp) {
      return (data["createdAt"] as Timestamp).toDate();
    }

    return null;
  }

  // ============================================================
  // تحويل الرقم
  // ============================================================

  double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }

  // ============================================================
  // هل الحركة تخص الحساب؟
  // ============================================================

  bool isAccountTransaction(
    Map<String, dynamic> data,
  ) {
    return data["accountId"] == widget.accountId ||
        data["debitAccountId"] == widget.accountId ||
        data["creditAccountId"] == widget.accountId;
  }

  // ============================================================
  // المدين (علية)
  // ============================================================

  double getDebit(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // إذا كان الحساب هو الحساب المدين
    // ----------------------------------------------------------

    if (data["debitAccountId"] == widget.accountId) {
      if (data["debit"] != null) {
        return toDouble(data["debit"]);
      }

      if (data["amount"] != null) {
        return toDouble(data["amount"]);
      }
    }

    // ----------------------------------------------------------
    // الحركات القديمة التي تحتوي accountId
    // ----------------------------------------------------------

    if (data["accountId"] == widget.accountId &&
        data["debit"] != null) {
      return toDouble(data["debit"]);
    }

    return 0;
  }

  // ============================================================
  // الدائن (لة)
  // ============================================================

  double getCredit(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // إذا كان الحساب هو الحساب الدائن
    // ----------------------------------------------------------

    if (data["creditAccountId"] == widget.accountId) {
      if (data["credit"] != null) {
        return toDouble(data["credit"]);
      }

      if (data["amount"] != null) {
        return toDouble(data["amount"]);
      }
    }

    // ----------------------------------------------------------
    // الحركات القديمة التي تحتوي accountId
    // ----------------------------------------------------------

    if (data["accountId"] == widget.accountId &&
        data["credit"] != null) {
      return toDouble(data["credit"]);
    }

    return 0;
  }

  // ============================================================
  // وصف الحركة
  // ============================================================

  String getDescription(
    Map<String, dynamic> data,
  ) {
    final statement =
        data["statement"]?.toString().trim();

    if (statement != null && statement.isNotEmpty) {
      return statement;
    }

    final description =
        data["description"]?.toString().trim();

    if (description != null && description.isNotEmpty) {
      return description;
    }

    final type =
        data["type"]?.toString();

    switch (type) {
      case "payment":
        return "سند صرف";

      case "receipt":
        return "سند قبض";

      default:
        return type ?? "قيد محاسبي";
    }
  }

  // ============================================================
  // نوع الحركة
  // ============================================================

  String getTransactionType(
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

  // ============================================================
  // تاريخ الحركة
  // ============================================================

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return "";
    }

    final day =
        date.day.toString().padLeft(2, "0");

    final month =
        date.month.toString().padLeft(2, "0");

    final hour =
        date.hour.toString().padLeft(2, "0");

    final minute =
        date.minute.toString().padLeft(2, "0");

    return "${date.year}/$month/$day "
        "$hour:$minute";
  }

  // ============================================================
  // جلب كل حركات الحساب
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getAllAccountTransactions() async {
    final Map<String, Map<String, dynamic>>
        unique = {};

    // ==========================================================
    // 1 - accountId
    // ==========================================================

    try {
      final query = await firestore
          .collection("account_transactions")
          .where(
            "accountId",
            isEqualTo: widget.accountId,
          )
          .get();

      for (final doc in query.docs) {
        unique[doc.id] = {
          ...doc.data(),
          "docId": doc.id,
        };
      }
    } catch (_) {}

    // ==========================================================
    // 2 - debitAccountId
    // ==========================================================

    try {
      final query = await firestore
          .collection("account_transactions")
          .where(
            "debitAccountId",
            isEqualTo: widget.accountId,
          )
          .get();

      for (final doc in query.docs) {
        unique[doc.id] = {
          ...doc.data(),
          "docId": doc.id,
        };
      }
    } catch (_) {}

    // ==========================================================
    // 3 - creditAccountId
    // ==========================================================

    try {
      final query = await firestore
          .collection("account_transactions")
          .where(
            "creditAccountId",
            isEqualTo: widget.accountId,
          )
          .get();

      for (final doc in query.docs) {
        unique[doc.id] = {
          ...doc.data(),
          "docId": doc.id,
        };
      }
    } catch (_) {}

    final result = unique.values.toList();

    // ============================================================
    // التأكد أن الحركة تخص الحساب فعلاً
    // ============================================================

    result.removeWhere(
      (data) => !isAccountTransaction(data),
    );

    // ============================================================
    // ترتيب من الأقدم إلى الأحدث
    // ============================================================

    result.sort((a, b) {
      final dateA = getDate(a);
      final dateB = getDate(b);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateA.compareTo(dateB);
    });

    return result;
  }

  // ============================================================
  // الرصيد السابق لبداية الشهر
  //
  // الرصيد = المدين (علية) - الدائن (لة)
  // ============================================================

  double getOpeningBalance(
    List<Map<String, dynamic>> all,
  ) {
    double balance = 0;

    for (final data in all) {
      final date = getDate(data);

      if (date == null) {
        continue;
      }

      if (date.isBefore(startMonth)) {
        final debit = getDebit(data);
        final credit = getCredit(data);

        balance += debit;
        balance -= credit;
      }
    }

    return balance;
  }

  // ============================================================
  // حركات الشهر
  // ============================================================

  List<Map<String, dynamic>> getMonthTransactions(
    List<Map<String, dynamic>> all,
  ) {
    final result = all.where((data) {
      final date = getDate(data);

      if (date == null) {
        return false;
      }

      return !date.isBefore(startMonth) &&
          date.isBefore(endMonth);
    }).toList();

    result.sort((a, b) {
      final dateA = getDate(a);
      final dateB = getDate(b);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateA.compareTo(dateB);
    });

    return result;
  }

  // ============================================================
  // حساب الرصيد الجاري
  //
  // الرصيد = الرصيد السابق
  //         + مدين (علية)
  //         - دائن (لة)
  // ============================================================

  List<Map<String, dynamic>> calculateRunningBalance(
    List<Map<String, dynamic>> transactions,
    double openingBalance,
  ) {
    double balance = openingBalance;

    final List<Map<String, dynamic>> result = [];

    for (final data in transactions) {
      final debit = getDebit(data);
      final credit = getCredit(data);

      balance += debit;
      balance -= credit;

      result.add({
        ...data,
        "calculatedBalance": balance,
      });
    }

    return result;
  }

  // ============================================================
  // الشهر
  // ============================================================

  String get monthTitle {
    return "${selectedMonth.year}/"
        "${selectedMonth.month.toString().padLeft(2, "0")}";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: const MyAppBar(
          title: "التقرير الشهري للحساب",
          icon: Icons.account_balance_wallet,
        ),

        body: Column(
          children: [
            // ==================================================
            // رأس التقرير
            // ==================================================

            _buildReportHeader(),

            // ==================================================
            // المحتوى
            // ==================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FutureBuilder<
                    List<Map<String, dynamic>>>(
                  future: getAllAccountTransactions(),

                  builder: (
                    context,
                    snapshot,
                  ) {
                    // ==========================================
                    // تحميل
                    // ==========================================

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: mainColor,
                        ),
                      );
                    }

                    // ==========================================
                    // خطأ
                    // ==========================================

                    if (snapshot.hasError) {
                      return _buildError(
                        snapshot.error.toString(),
                      );
                    }

                    final allTransactions =
                        snapshot.data ?? [];

                    // ==========================================
                    // الرصيد السابق
                    // ==========================================

                    final openingBalance =
                        getOpeningBalance(
                      allTransactions,
                    );

                    // ==========================================
                    // حركات الشهر
                    // ==========================================

                    final monthTransactions =
                        getMonthTransactions(
                      allTransactions,
                    );

                    // ==========================================
                    // الرصيد الجاري
                    // ==========================================

                    final transactions =
                        calculateRunningBalance(
                      monthTransactions,
                      openingBalance,
                    );

                    // ==========================================
                    // الإجماليات
                    // ==========================================

                    double totalDebit = 0;
                    double totalCredit = 0;

                    for (final data
                        in transactions) {
                      totalDebit +=
                          getDebit(data);

                      totalCredit +=
                          getCredit(data);
                    }

                    final finalBalance =
                        openingBalance +
                            totalDebit -
                            totalCredit;

                    return Column(
                      children: [
                        // ======================================
                        // معلومات الحساب
                        // ======================================

                        _buildAccountCard(),

                        const SizedBox(
                          height: 10,
                        ),

                        // ======================================
                        // اختيار الشهر
                        // ======================================

                        _buildMonthButton(),

                        const SizedBox(
                          height: 10,
                        ),

                        // ======================================
                        // أرصدة الحساب
                        // ======================================

                        _buildBalanceSummary(
                          openingBalance,
                          totalDebit,
                          totalCredit,
                          finalBalance,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ======================================
                        // الجدول
                        // ======================================

                        Expanded(
                          child:
                              transactions.isEmpty
                                  ? _buildEmpty(
                                      openingBalance,
                                    )
                                  : _buildTable(
                                      transactions,
                                    ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // رأس التقرير
  // ============================================================

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: mainColor,
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(.20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 25,
              ),

              const SizedBox(width: 8),

              const Text(
                "التقرير الشهري للحساب",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            widget.accountName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "الشهر: $monthTitle",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          if (widget.wellName != null &&
              widget.wellName!.trim().isNotEmpty)
            Text(
              "البئر: ${widget.wellName}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الحساب
  // ============================================================

  Widget _buildAccountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      mainColor.withOpacity(.10),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: mainColor,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "الحساب",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      Text(
                        widget.accountName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "رقم الحساب: ${widget.accountId}",
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.wellName != null &&
                widget.wellName!.trim().isNotEmpty) ...[
              const Divider(height: 22),

              Row(
                children: [
                  const Icon(
                    Icons.water_drop,
                    color: mainColor,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      "البئر: ${widget.wellName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // زر الشهر
  // ============================================================

  Widget _buildMonthButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: chooseMonth,

        icon: const Icon(
          Icons.calendar_month,
        ),

        label: Text(
          "الشهر: $monthTitle",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          foregroundColor: Colors.white,
          elevation: 2,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ملخص الرصيد
  // ============================================================

  Widget _buildBalanceSummary(
    double opening,
    double debit,
    double credit,
    double finalBalance,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                "الرصيد السابق",
                opening,
                Colors.blue,
                Icons.history,
              ),
            ),

            Expanded(
              child: _summaryCard(
                "إجمالي المدين (علية)",
                debit,
                Colors.red,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                "إجمالي الدائن (لة)",
                credit,
                Colors.green,
                Icons.arrow_upward,
              ),
            ),

            Expanded(
              child: _summaryCard(
                "الرصيد النهائي",
                finalBalance,
                mainColor,
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // كرت ملخص
  // ============================================================

  Widget _summaryCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,

      margin: const EdgeInsets.all(3),

      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 9,
          horizontal: 5,
        ),

        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 21,
            ),

            const SizedBox(height: 3),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              value.toStringAsFixed(2),

              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const Text(
              "ريال",

              style: TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // الجدول
  // ============================================================

  Widget _buildTable(
    List<Map<String, dynamic>> transactions,
  ) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              mainColor.withOpacity(.12),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.05),
            blurRadius: 6,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,

        child: SingleChildScrollView(
          scrollDirection:
              Axis.vertical,

          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(
              mainColor.withOpacity(.10),
            ),

            border: TableBorder.all(
              color:
                  Colors.grey.shade300,
            ),

            columns: const [
              // ================================================
              // التاريخ
              // ================================================

              DataColumn(
                label: Text(
                  "التاريخ",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // ================================================
              // نوع الحركة
              // ================================================

              DataColumn(
                label: Text(
                  "نوع الحركة",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // ================================================
              // البيان
              // ================================================

              DataColumn(
                label: Text(
                  "البيان",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // ================================================
              // مدين (علية)
              // ================================================

              DataColumn(
                label: Text(
                  "مدين (علية)",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),

              // ================================================
              // دائن (لة)
              // ================================================

              DataColumn(
                label: Text(
                  "دائن (لة)",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              // ================================================
              // الرصيد
              // ================================================

              DataColumn(
                label: Text(
                  "الرصيد",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],

            rows: transactions.map(
              (data) {
                final debit =
                    getDebit(data);

                final credit =
                    getCredit(data);

                final balance =
                    toDouble(
                  data["calculatedBalance"],
                );

                final type =
                    getTransactionType(data);

                final bool isPayment =
                    data["type"] ==
                        "payment";

                final bool isReceipt =
                    data["type"] ==
                        "receipt";

                return DataRow(
                  cells: [
                    // =========================================
                    // التاريخ
                    // =========================================

                    DataCell(
                      Text(
                        formatDate(
                          getDate(data),
                        ),
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // =========================================
                    // نوع الحركة
                    // =========================================

                    DataCell(
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          color: isPayment
                              ? Colors.red
                                  .withOpacity(.10)
                              : isReceipt
                                  ? Colors.green
                                      .withOpacity(.10)
                                  : Colors.blue
                                      .withOpacity(.10),

                          borderRadius:
                              BorderRadius
                                  .circular(8),
                        ),

                        child: Text(
                          type,

                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,

                            color: isPayment
                                ? Colors.red
                                : isReceipt
                                    ? Colors.green
                                    : mainColor,
                          ),
                        ),
                      ),
                    ),

                    // =========================================
                    // البيان
                    // =========================================

                    DataCell(
                      SizedBox(
                        width: 230,

                        child: Text(
                          getDescription(data),

                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // =========================================
                    // مدين (علية)
                    // =========================================

                    DataCell(
                      Text(
                        debit.toStringAsFixed(2),

                        style:
                            const TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    // =========================================
                    // دائن (لة)
                    // =========================================

                    DataCell(
                      Text(
                        credit.toStringAsFixed(2),

                        style:
                            const TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    // =========================================
                    // الرصيد
                    // =========================================

                    DataCell(
                      Text(
                        balance.toStringAsFixed(2),

                        style:
                            const TextStyle(
                          color: mainColor,
                          fontWeight:
                              FontWeight.bold,
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

  // ============================================================
  // لا توجد حركة
  // ============================================================

  Widget _buildEmpty(
    double openingBalance,
  ) {
    return Card(
      elevation: 1,

      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                Icons.receipt_long,
                size: 65,
                color:
                    Colors.grey.shade400,
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                "لا توجد حركة في هذا الشهر",

                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "الرصيد السابق: "
                "${openingBalance.toStringAsFixed(2)} ريال",

                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // خطأ
  // ============================================================

  Widget _buildError(
    String error,
  ) {
    return Center(
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: Text(
            "حدث خطأ أثناء تحميل التقرير:\n\n$error",

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}