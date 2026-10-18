import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class DailyAccountReportScreen extends StatefulWidget {
  final String accountId;
  final String accountName;

  final String? wellId;
  final String? wellName;

  const DailyAccountReportScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    this.wellId,
    this.wellName,
  });

  @override
  State<DailyAccountReportScreen> createState() =>
      _DailyAccountReportScreenState();
}

class _DailyAccountReportScreenState
    extends State<DailyAccountReportScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // اللون
  // ============================================================

  static const Color primaryColor = Colors.blue;

  // ============================================================
  // التاريخ
  // ============================================================

  DateTime selectedDate = DateTime.now();

  // ============================================================
  // رصيد الحساب الحالي
  // ============================================================

  double currentBalance = 0;

  bool isLoadingBalance = true;

  // ============================================================
  // بداية اليوم
  // ============================================================

  DateTime get startDay {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
  }

  // ============================================================
  // نهاية اليوم
  // ============================================================

  DateTime get endDay {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + 1,
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadAccountBalance();
  }

  // ============================================================
  // تحميل رصيد الحساب
  // ============================================================

  Future<void> loadAccountBalance() async {
    try {
      final doc = await firestore
          .collection("accounts")
          .doc(widget.accountId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};

        setState(() {
          currentBalance = toDouble(data["balance"]);
          isLoadingBalance = false;
        });
      } else {
        setState(() {
          currentBalance = 0;
          isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBalance = false;
      });

      showMessage(
        "تعذر تحميل رصيد الحساب:\n$e",
        true,
      );
    }
  }

  // ============================================================
  // تغيير التاريخ
  // ============================================================

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: "اختر تاريخ التقرير",
      cancelText: "إلغاء",
      confirmText: "اختيار",
      fieldLabelText: "التاريخ",
      fieldHintText: "يوم/شهر/سنة",
    );

    if (date != null && mounted) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  // ============================================================
  // التاريخ كنص
  // ============================================================

  String get formattedSelectedDate {
    return "${selectedDate.year}/"
        "${selectedDate.month.toString().padLeft(2, '0')}/"
        "${selectedDate.day.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(
    String message,
    bool isError,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // تحويل رقم
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
  // الحصول على التاريخ
  // ============================================================

  DateTime? _getDate(
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

  // ============================================================
  // هل الحركة في التاريخ المحدد؟
  // ============================================================

  bool isInSelectedDay(
    Map<String, dynamic> data,
  ) {
    final date = _getDate(data);

    if (date == null) {
      return false;
    }

    return !date.isBefore(startDay) &&
        date.isBefore(endDay);
  }

  // ============================================================
  // جلب القيود اليومية
  // ============================================================

  Stream<List<Map<String, dynamic>>>
      getDailyTransactions() async* {
    final Map<String, Map<String, dynamic>>
        unique = {};

    try {
      // ==========================================================
      // 1 - القيود القديمة التي تحتوي accountId
      // ==========================================================

      final normalQuery = await firestore
          .collection("account_transactions")
          .where(
            "accountId",
            isEqualTo: widget.accountId,
          )
          .get();

      for (final doc in normalQuery.docs) {
        final data = doc.data();

        if (!isInSelectedDay(data)) {
          continue;
        }

        unique[doc.id] = {
          ...data,
          "docId": doc.id,
        };
      }

      // ==========================================================
      // 2 - الحساب مدين
      // ==========================================================

      final debitQuery = await firestore
          .collection("account_transactions")
          .where(
            "debitAccountId",
            isEqualTo: widget.accountId,
          )
          .get();

      for (final doc in debitQuery.docs) {
        final data = doc.data();

        if (!isInSelectedDay(data)) {
          continue;
        }

        unique[doc.id] = {
          ...data,
          "docId": doc.id,
        };
      }

      // ==========================================================
      // 3 - الحساب دائن
      // ==========================================================

      final creditQuery = await firestore
          .collection("account_transactions")
          .where(
            "creditAccountId",
            isEqualTo: widget.accountId,
          )
          .get();

      for (final doc in creditQuery.docs) {
        final data = doc.data();

        if (!isInSelectedDay(data)) {
          continue;
        }

        unique[doc.id] = {
          ...data,
          "docId": doc.id,
        };
      }

      // ==========================================================
      // تحويل إلى قائمة
      // ==========================================================

      final result = unique.values.toList();

      // ==========================================================
      // ترتيب حسب التاريخ
      // ==========================================================

      result.sort((a, b) {
        final dateA = _getDate(a);
        final dateB = _getDate(b);

        if (dateA == null && dateB == null) {
          return 0;
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        return dateB.compareTo(dateA);
      });

      yield result;
    } catch (e) {
      throw Exception(
        "خطأ أثناء تحميل القيود: $e",
      );
    }
  }

  // ============================================================
  // المدين - عليه
  // ============================================================

  double getDebit(
    Map<String, dynamic> data,
  ) {
    // القيد الجديد
    if (data["debitAccountId"] ==
        widget.accountId) {
      return toDouble(data["amount"]);
    }

    // القيود القديمة
    if (data["accountId"] ==
        widget.accountId) {
      if (data["debit"] != null) {
        return toDouble(data["debit"]);
      }

      if (data["type"] == "receipt") {
        return toDouble(data["amount"]);
      }
    }

    return 0;
  }

  // ============================================================
  // الدائن - له
  // ============================================================

  double getCredit(
    Map<String, dynamic> data,
  ) {
    // القيد الجديد
    if (data["creditAccountId"] ==
        widget.accountId) {
      return toDouble(data["amount"]);
    }

    // القيود القديمة
    if (data["accountId"] ==
        widget.accountId) {
      if (data["credit"] != null) {
        return toDouble(data["credit"]);
      }

      if (data["type"] == "payment") {
        return toDouble(data["amount"]);
      }
    }

    return 0;
  }

  // ============================================================
  // نوع الحركة
  // ============================================================

  String getTransactionType(
    Map<String, dynamic> data,
  ) {
    final type =
        data["type"]?.toString() ?? "";

    if (type == "payment") {
      return "سند صرف";
    }

    if (type == "receipt") {
      return "سند قبض";
    }

    return "قيد محاسبي";
  }

  // ============================================================
  // لون نوع الحركة
  // ============================================================

  Color getTransactionColor(
    Map<String, dynamic> data,
  ) {
    final type =
        data["type"]?.toString() ?? "";

    if (type == "payment") {
      return Colors.red;
    }

    if (type == "receipt") {
      return Colors.green;
    }

    return Colors.blue;
  }

  // ============================================================
  // البيان
  // ============================================================

  String getStatement(
    Map<String, dynamic> data,
  ) {
    final statement =
        data["statement"]?.toString();

    if (statement != null &&
        statement.trim().isNotEmpty) {
      return statement;
    }

    final type =
        data["type"]?.toString() ?? "";

    if (type == "payment") {
      return "سند صرف";
    }

    if (type == "receipt") {
      return "سند قبض";
    }

    return data["description"]?.toString() ??
        "قيد محاسبي";
  }

  // ============================================================
  // التاريخ والوقت
  // ============================================================

  String getTransactionDate(
    Map<String, dynamic> data,
  ) {
    final date = _getDate(data);

    if (date == null) {
      return "";
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

  // ============================================================
  // الحساب المقابل
  // ============================================================

  String getOtherAccountName(
    Map<String, dynamic> data,
  ) {
    if (data["debitAccountId"] ==
        widget.accountId) {
      return data["creditAccountName"]
              ?.toString() ??
          "غير محدد";
    }

    if (data["creditAccountId"] ==
        widget.accountId) {
      return data["debitAccountName"]
              ?.toString() ??
          "غير محدد";
    }

    return "غير محدد";
  }

  // ============================================================
  // معلومات الحساب
  // ============================================================

  Widget buildAccountCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        primaryColor.withOpacity(.10),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons.account_balance,
                    color:
                        primaryColor,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                        height: 3,
                      ),

                      Text(
                        widget.accountName,
                        style:
                            const TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        "رقم الحساب: ${widget.accountId}",
                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize:
                              11,
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

            // ==================================================
            // الرصيد الحالي
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    Colors.blue.shade50,
                borderRadius:
                    BorderRadius.circular(12),
                border:
                    Border.all(
                  color:
                      Colors.blue.shade100,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color:
                        primaryColor,
                    size: 30,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "الرصيد الحالي",
                          style:
                              TextStyle(
                            fontSize:
                                13,
                            color:
                                Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        isLoadingBalance
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : Text(
                                "${currentBalance.toStringAsFixed(2)} ريال",
                                style:
                                    TextStyle(
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      currentBalance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // البئر
            // ==================================================

            if (widget.wellName != null &&
                widget.wellName!
                    .trim()
                    .isNotEmpty) ...[
              const Divider(
                height: 25,
              ),

              Row(
                children: [
                  const Icon(
                    Icons.water_drop,
                    color:
                        primaryColor,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      "البئر: ${widget.wellName}",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
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
  // رأس التقرير
  // ============================================================

  Widget buildReportHeader() {
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
        color:
            primaryColor,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                primaryColor.withOpacity(.25),
            blurRadius:
                5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                color:
                    Colors.white,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                "الحركة اليومية للحساب",
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            formattedSelectedDate,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          if (widget.wellName != null &&
              widget.wellName!
                  .trim()
                  .isNotEmpty)
            Text(
              "البئر: ${widget.wellName}",
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize:
                    12,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // زر التاريخ
  // ============================================================

  Widget buildDateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child:
          ElevatedButton.icon(
        onPressed:
            chooseDate,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              primaryColor,
          foregroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ),
        icon:
            const Icon(
          Icons.calendar_month,
        ),
        label:
            Text(
          "تاريخ التقرير: "
          "$formattedSelectedDate",
          style:
              const TextStyle(
            fontSize:
                15,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // كرت الإجمالي
  // ============================================================

  Widget buildTotalCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation:
          3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        child:
            Column(
          children: [
            Icon(
              icon,
              color:
                  color,
              size:
                  25,
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize:
                    12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              "${value.toStringAsFixed(2)} ريال",
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    15,
                fontWeight:
                    FontWeight.bold,
                color:
                    color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة صافي حركة اليوم
  // ============================================================

  Widget buildDailyBalanceCard(
    double totalDebit,
    double totalCredit,
  ) {
    final net =
        totalCredit - totalDebit;

    return Card(
      elevation:
          3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(14),
        child:
            Row(
          children: [
            Container(
              width:
                  45,
              height:
                  45,
              decoration:
                  BoxDecoration(
                color:
                    Colors.indigo.shade50,
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons.calculate,
                color:
                    Colors.indigo,
              ),
            ),

            const SizedBox(
              width:
                  10,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "صافي حركة اليوم",
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height:
                        3,
                  ),

                  Text(
                    net >= 0
                        ? "زيادة: ${net.toStringAsFixed(2)} ريال"
                        : "نقص: ${net.abs().toStringAsFixed(2)} ريال",
                    style:
                        TextStyle(
                      color:
                          net >= 0
                              ? Colors.green
                              : Colors.red,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // نوع الحركة داخل الجدول
  // ============================================================

  Widget buildTypeCell(
    Map<String, dynamic> data,
  ) {
    final color =
        getTransactionColor(data);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.10),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child:
          Text(
        getTransactionType(data),
        style:
            TextStyle(
          color:
              color,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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

      child:
          Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        appBar:
            MyAppBar(
          title:
              "الحركة اليومية للحساب",
          subtitle:
              hasWell
                  ? "البئر: ${widget.wellName}"
                  : widget.accountName,
          icon:
              Icons.account_balance_wallet,
        ),

        body:
            Column(
          children: [
            // ==================================================
            // رأس التقرير
            // ==================================================

            buildReportHeader(),

            // ==================================================
            // المحتوى
            // ==================================================

            Expanded(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(12),

                child:
                    Column(
                  children: [
                    // ==========================================
                    // معلومات الحساب
                    // ==========================================

                    buildAccountCard(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================================
                    // التاريخ
                    // ==========================================

                    buildDateButton(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================================
                    // الحركات
                    // ==========================================

                    Expanded(
                      child:
                          StreamBuilder<
                              List<
                                  Map<String,
                                      dynamic>>>(
                        stream:
                            getDailyTransactions(),

                        builder:
                            (
                          context,
                          snapshot,
                        ) {
                          if (snapshot.hasError) {
                            return Center(
                              child:
                                  Card(
                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets.all(20),
                                  child:
                                      Text(
                                    "حدث خطأ أثناء تحميل التقرير:\n\n"
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
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(
                                color:
                                    primaryColor,
                              ),
                            );
                          }

                          final list =
                              snapshot.data ?? [];

                          // ==================================
                          // لا توجد حركات
                          // ==================================

                          if (list.isEmpty) {
                            return Column(
                              children: [
                                buildDailyBalanceCard(
                                  0,
                                  0,
                                ),

                                const Expanded(
                                  child:
                                      Center(
                                    child:
                                        Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size:
                                              70,
                                          color:
                                              Colors.grey,
                                        ),

                                        SizedBox(
                                          height:
                                              15,
                                        ),

                                        Text(
                                          "لا توجد حركة في هذا اليوم",
                                          style:
                                              TextStyle(
                                            fontSize:
                                                17,
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

                          // ==================================
                          // الإجماليات
                          // ==================================

                          double totalDebit =
                              0;

                          double totalCredit =
                              0;

                          for (final data in list) {
                            totalDebit +=
                                getDebit(data);

                            totalCredit +=
                                getCredit(data);
                          }

                          // ==================================
                          // التقرير
                          // ==================================

                          return Column(
                            children: [
                              // =================================
                              // إجمالي المدين والدائن
                              // =================================

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        buildTotalCard(
                                      "إجمالي المدين (عليه)",
                                      totalDebit,
                                      Colors.red,
                                      Icons.arrow_downward,
                                    ),
                                  ),

                                  Expanded(
                                    child:
                                        buildTotalCard(
                                      "إجمالي الدائن (له)",
                                      totalCredit,
                                      Colors.green,
                                      Icons.arrow_upward,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // =================================
                              // صافي اليوم
                              // =================================

                              buildDailyBalanceCard(
                                totalDebit,
                                totalCredit,
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // =================================
                              // عدد الحركات
                              // =================================

                              Card(
                                elevation:
                                    2,
                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets.all(12),
                                  child:
                                      Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            color:
                                                primaryColor,
                                          ),

                                          SizedBox(
                                            width:
                                                8,
                                          ),

                                          Text(
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
                                        "${list.length}",
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // =================================
                              // الجدول
                              // =================================

                              Expanded(
                                child:
                                    Container(
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),

                                  child:
                                      SingleChildScrollView(
                                    scrollDirection:
                                        Axis.horizontal,

                                    child:
                                        SingleChildScrollView(
                                      scrollDirection:
                                          Axis.vertical,

                                      child:
                                          DataTable(
                                        border:
                                            TableBorder.all(
                                          color:
                                              Colors.grey.shade300,
                                        ),

                                        headingRowColor:
                                            WidgetStateProperty.all(
                                          primaryColor
                                              .withOpacity(.10),
                                        ),

                                        columns:
                                            const [
                                          DataColumn(
                                            label:
                                                Text(
                                              "التاريخ",
                                            ),
                                          ),

                                          DataColumn(
                                            label:
                                                Text(
                                              "نوع الحركة",
                                            ),
                                          ),

                                          DataColumn(
                                            label:
                                                Text(
                                              "البيان",
                                            ),
                                          ),

                                          DataColumn(
                                            label:
                                                Text(
                                              "الحساب المقابل",
                                            ),
                                          ),

                                          // ======================
                                          // المدين - عليه
                                          // ======================

                                          DataColumn(
                                            label:
                                                Text(
                                              "مدين (عليه)",
                                              style:
                                                  TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                          ),

                                          // ======================
                                          // الدائن - له
                                          // ======================

                                          DataColumn(
                                            label:
                                                Text(
                                              "دائن (له)",
                                              style:
                                                  TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],

                                        rows:
                                            list.map(
                                          (
                                            data,
                                          ) {
                                            final debit =
                                                getDebit(data);

                                            final credit =
                                                getCredit(data);

                                            return DataRow(
                                              cells: [
                                                // ==================
                                                // التاريخ
                                                // ==================

                                                DataCell(
                                                  Text(
                                                    getTransactionDate(
                                                      data,
                                                    ),
                                                  ),
                                                ),

                                                // ==================
                                                // النوع
                                                // ==================

                                                DataCell(
                                                  buildTypeCell(
                                                    data,
                                                  ),
                                                ),

                                                // ==================
                                                // البيان
                                                // ==================

                                                DataCell(
                                                  SizedBox(
                                                    width:
                                                        220,
                                                    child:
                                                        Text(
                                                      getStatement(
                                                        data,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // ==================
                                                // الحساب المقابل
                                                // ==================

                                                DataCell(
                                                  SizedBox(
                                                    width:
                                                        180,
                                                    child:
                                                        Text(
                                                      getOtherAccountName(
                                                        data,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // ==================
                                                // المدين - عليه
                                                // ==================

                                                DataCell(
                                                  Text(
                                                    debit.toStringAsFixed(
                                                      2,
                                                    ),
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                                // ==================
                                                // الدائن - له
                                                // ==================

                                                DataCell(
                                                  Text(
                                                    credit.toStringAsFixed(
                                                      2,
                                                    ),
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Colors.green,
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
          ],
        ),
      ),
    );
  }
}