import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class PaymentVoucherScreen extends StatefulWidget {
  final String? villageId;
  final String? villageName;

  final String? wellId;
  final String? wellName;

  const PaymentVoucherScreen({
    super.key,
    this.villageId,
    this.villageName,
    this.wellId,
    this.wellName,
  });

  @override
  State<PaymentVoucherScreen> createState() =>
      _PaymentVoucherScreenState();
}

class _PaymentVoucherScreenState
    extends State<PaymentVoucherScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static const Color mainColor = Colors.blue;

  // ============================================================
  // الحساب المدين
  // ============================================================

  String? selectedDebitAccountId;
  String? selectedDebitAccountType;

  String debitAccountName = "اختر الحساب المدين";

  // ============================================================
  // الصندوق الدائن
  // ============================================================

  String? selectedCashAccountId;

  String cashAccountName =
      "جاري تحميل صندوق البئر...";

  // ============================================================
  // الحسابات
  // ============================================================

  QueryDocumentSnapshot? workerAccount;
  QueryDocumentSnapshot? expensesAccount;
  QueryDocumentSnapshot? cashAccount;

  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController statementController =
      TextEditingController();

  // ============================================================
  // الحالة
  // ============================================================

  bool isLoading = false;
  bool isLoadingAccounts = true;

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadAccounts();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    amountController.dispose();
    statementController.dispose();

    super.dispose();
  }

  // ============================================================
  // تحميل حسابات البئر
  // ============================================================

  Future<void> loadAccounts() async {
    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoadingAccounts = false;
        cashAccountName = "لم يتم تحديد البئر";
      });

      return;
    }

    try {
      final result = await firestore
          .collection("accounts")
          .where(
            "wellId",
            isEqualTo: widget.wellId,
          )
          .get();

      QueryDocumentSnapshot? worker;
      QueryDocumentSnapshot? expenses;
      QueryDocumentSnapshot? cash;

      for (final doc in result.docs) {
        final data =
            doc.data() as Map<String, dynamic>;

        final type =
            data["type"]?.toString().trim();

        if (type == "worker") {
          worker = doc;
        }

        if (type == "expenses") {
          expenses = doc;
        }

        if (type == "cash") {
          cash = doc;
        }
      }

      if (!mounted) return;

      setState(() {
        workerAccount = worker;
        expensesAccount = expenses;
        cashAccount = cash;

        selectedCashAccountId =
            cash?.id;

        cashAccountName =
            cash == null
                ? "لم يتم العثور على صندوق البئر"
                : ((cash.data()
                            as Map<String, dynamic>)["name"]
                        ?.toString() ??
                    "صندوق البئر");

        isLoadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAccounts = false;
        cashAccountName =
            "خطأ أثناء تحميل الحسابات";
      });

      showMessage(
        "خطأ أثناء تحميل حسابات البئر:\n$e",
        true,
      );
    }
  }

  // ============================================================
  // اختيار الحساب المدين
  // ============================================================

  void onDebitAccountChanged(
    String? value,
  ) {
    if (value == null) return;

    QueryDocumentSnapshot? account;

    if (workerAccount?.id == value) {
      account = workerAccount;
    } else if (expensesAccount?.id == value) {
      account = expensesAccount;
    }

    if (account == null) return;

    final data =
        account.data()
            as Map<String, dynamic>;

    setState(() {
      selectedDebitAccountId = account!.id;

      selectedDebitAccountType =
          data["type"]?.toString();

      debitAccountName =
          data["name"]?.toString() ??
              "الحساب المدين";
    });
  }

  // ============================================================
  // حفظ سند الصرف وترحيل القيد
  // ============================================================

  Future<void> saveVoucher() async {
    if (isLoading) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // البئر
    // ----------------------------------------------------------

    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      showMessage(
        "لم يتم تحديد البئر",
        true,
      );

      return;
    }

    // ----------------------------------------------------------
    // الحساب المدين
    // ----------------------------------------------------------

    if (selectedDebitAccountId == null ||
        selectedDebitAccountId!.isEmpty) {
      showMessage(
        "اختر الحساب المدين",
        true,
      );

      return;
    }

    // ----------------------------------------------------------
    // الصندوق
    // ----------------------------------------------------------

    if (selectedCashAccountId == null ||
        selectedCashAccountId!.isEmpty) {
      showMessage(
        "لم يتم العثور على صندوق البئر",
        true,
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final double amount =
          double.parse(
        amountController.text.trim(),
      );

      final Timestamp now =
          Timestamp.now();

      final String statement =
          statementController.text.trim();

      final String finalStatement =
          statement.isEmpty
              ? selectedDebitAccountType ==
                      "worker"
                  ? "صرف مستحقات عامل البئر"
                  : "مصروفات البئر"
              : statement;

      // ========================================================
      // Batch
      // ========================================================

      final WriteBatch batch =
          firestore.batch();

      // ========================================================
      // 1 - إنشاء سند الصرف
      // ========================================================

      final voucherRef = firestore
          .collection("payment_vouchers")
          .doc();

      batch.set(
        voucherRef,
        {
          "voucherId": voucherRef.id,

          // ------------------------------------------
          // الموقع
          // ------------------------------------------

          "wellId": widget.wellId,
          "wellName": widget.wellName,

          "villageId": widget.villageId,
          "villageName": widget.villageName,

          // ------------------------------------------
          // المدين
          // ------------------------------------------

          "debitAccountId":
              selectedDebitAccountId,

          "debitAccountType":
              selectedDebitAccountType,

          "debitAccountName":
              debitAccountName,

          // ------------------------------------------
          // الدائن
          // ------------------------------------------

          "creditAccountId":
              selectedCashAccountId,

          "creditAccountType":
              "cash",

          "creditAccountName":
              cashAccountName,

          // ------------------------------------------
          // البيانات
          // ------------------------------------------

          "amount": amount,

          "statement":
              finalStatement,

          "type": "payment",

          "date": now,

          "createdAt": now,
        },
      );

      // ========================================================
      // 2 - ترحيل القيد المحاسبي
      // ========================================================

      final transactionRef =
          firestore
              .collection(
                "account_transactions",
              )
              .doc();

      batch.set(
        transactionRef,
        {
          "transactionId":
              transactionRef.id,

          // ------------------------------------------
          // السند
          // ------------------------------------------

          "voucherId":
              voucherRef.id,

          "voucherType":
              "payment",

          // ------------------------------------------
          // الموقع
          // ------------------------------------------

          "wellId":
              widget.wellId,

          "wellName":
              widget.wellName,

          "villageId":
              widget.villageId,

          "villageName":
              widget.villageName,

          // ------------------------------------------
          // الحساب المدين
          // ------------------------------------------

          "debitAccountId":
              selectedDebitAccountId,

          "debitAccountType":
              selectedDebitAccountType,

          "debitAccountName":
              debitAccountName,

          // ------------------------------------------
          // الحساب الدائن
          // ------------------------------------------

          "creditAccountId":
              selectedCashAccountId,

          "creditAccountType":
              "cash",

          "creditAccountName":
              cashAccountName,

          // ------------------------------------------
          // المبلغ
          // ------------------------------------------

          "amount":
              amount,

          // ------------------------------------------
          // البيان
          // ------------------------------------------

          "statement":
              finalStatement,

          "type":
              "payment",

          "date":
              now,

          "createdAt":
              now,
        },
      );

      // ========================================================
      // 3 - تحديث الحساب المدين
      //
      // مدين + المبلغ
      // الرصيد يزيد
      // ========================================================

      batch.update(
        firestore
            .collection("accounts")
            .doc(
              selectedDebitAccountId,
            ),
        {
          "debit":
              FieldValue.increment(
            amount,
          ),

          "balance":
              FieldValue.increment(
            amount,
          ),

          "lastUpdate":
              now,
        },
      );

      // ========================================================
      // 4 - تحديث صندوق البئر
      //
      // دائن + المبلغ
      // الرصيد ينقص
      // ========================================================

      batch.update(
        firestore
            .collection("accounts")
            .doc(
              selectedCashAccountId,
            ),
        {
          "credit":
              FieldValue.increment(
            amount,
          ),

          "balance":
              FieldValue.increment(
            -amount,
          ),

          "lastUpdate":
              now,
        },
      );

      // ========================================================
      // 5 - تنفيذ السند والقيد والحسابات معًا
      // ========================================================

      await batch.commit();

      if (!mounted) return;

      showMessage(
        "تم حفظ سند الصرف وترحيل القيد بنجاح",
        false,
      );

      clearForm();
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "حدث خطأ أثناء حفظ سند الصرف:\n$e",
        true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // تنظيف النموذج
  // ============================================================

  void clearForm() {
    if (!mounted) return;

    setState(() {
      selectedDebitAccountId = null;
      selectedDebitAccountType = null;

      debitAccountName =
          "اختر الحساب المدين";
    });

    amountController.clear();
    statementController.clear();
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(
    String message,
    bool isError,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: "Cairo",
          ),
          textDirection:
              TextDirection.rtl,
        ),
        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // بطاقة الموقع
  // ============================================================

  Widget buildLocationCard() {
    if ((widget.villageName == null ||
            widget.villageName!.isEmpty) &&
        (widget.wellName == null ||
            widget.wellName!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: mainColor,
                ),
                SizedBox(width: 8),
                Text(
                  "معلومات الموقع",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(),

            if (widget.villageName != null &&
                widget.villageName!.isNotEmpty)
              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading: const Icon(
                  Icons.location_city,
                  color: mainColor,
                ),
                title:
                    const Text("القرية"),
                subtitle: Text(
                  widget.villageName!,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

            if (widget.wellName != null &&
                widget.wellName!.isNotEmpty)
              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading: const Icon(
                  Icons.water_drop,
                  color: mainColor,
                ),
                title:
                    const Text("البئر"),
                subtitle: Text(
                  widget.wellName!,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة الدائن
  // ============================================================

  Widget buildCashAccountCard() {
    return Card(
      color: Colors.red.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
          ),
        ),
        title: const Text(
          "الدائن - صندوق البئر",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          cashAccountName,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // الحساب المدين
  // ============================================================

  Widget buildDebitAccountDropdown() {
    final List<QueryDocumentSnapshot>
        availableAccounts = [];

    if (workerAccount != null) {
      availableAccounts.add(
        workerAccount!,
      );
    }

    if (expensesAccount != null) {
      availableAccounts.add(
        expensesAccount!,
      );
    }

    return DropdownButtonFormField<String>(
      value:
          selectedDebitAccountId,

      decoration:
          InputDecoration(
        labelText:
            "الحساب المدين",

        hintText:
            "اختر العامل أو المصروفات",

        border:
            const OutlineInputBorder(),

        prefixIcon:
            const Icon(
          Icons.account_balance,
          color: mainColor,
        ),

        filled: true,

        fillColor:
            Colors.white,

        focusedBorder:
            const OutlineInputBorder(
          borderSide:
              BorderSide(
            color: mainColor,
            width: 2,
          ),
        ),
      ),

      items:
          availableAccounts.map(
        (doc) {
          final data =
              doc.data()
                  as Map<String, dynamic>;

          final type =
              data["type"]?.toString();

          final name =
              data["name"]?.toString() ??
                  "بدون اسم";

          final bool isWorker =
              type == "worker";

          return DropdownMenuItem<String>(
            value: doc.id,

            child: Row(
              children: [
                Icon(
                  isWorker
                      ? Icons.engineering
                      : Icons.money_off,
                  color:
                      isWorker
                          ? Colors.orange
                          : Colors.red,
                ),

                const SizedBox(
                  width: 10,
                ),

                Text(name),
              ],
            ),
          );
        },
      ).toList(),

      onChanged:
          availableAccounts.isEmpty
              ? null
              : onDebitAccountChanged,

      validator:
          (value) {
        if (value == null ||
            value.isEmpty) {
          return "اختر الحساب المدين";
        }

        return null;
      },
    );
  }

  // ============================================================
  // المبلغ
  // ============================================================

  Widget buildAmountField() {
    return TextFormField(
      controller:
          amountController,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration:
          InputDecoration(
        labelText:
            "المبلغ",

        hintText:
            "أدخل مبلغ الصرف",

        border:
            const OutlineInputBorder(),

        prefixIcon:
            const Icon(
          Icons.payments_outlined,
          color: mainColor,
        ),

        suffixText:
            "ريال",

        filled: true,

        fillColor:
            Colors.white,

        focusedBorder:
            const OutlineInputBorder(
          borderSide:
              BorderSide(
            color: mainColor,
            width: 2,
          ),
        ),
      ),

      validator:
          (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return "أدخل المبلغ";
        }

        final amount =
            double.tryParse(
          value.trim(),
        );

        if (amount == null) {
          return "المبلغ غير صحيح";
        }

        if (amount <= 0) {
          return "يجب أن يكون المبلغ أكبر من صفر";
        }

        return null;
      },
    );
  }

  // ============================================================
  // البيان
  // ============================================================

  Widget buildStatementField() {
    return TextFormField(
      controller:
          statementController,

      maxLines: 3,

      decoration:
          InputDecoration(
        labelText:
            "البيان",

        hintText:
            "اكتب سبب الصرف",

        border:
            const OutlineInputBorder(),

        prefixIcon:
            const Icon(
          Icons.description_outlined,
          color: mainColor,
        ),

        alignLabelWithHint:
            true,

        filled: true,

        fillColor:
            Colors.white,

        focusedBorder:
            const OutlineInputBorder(
          borderSide:
              BorderSide(
            color: mainColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // القيد المحاسبي
  // ============================================================

  Widget buildAccountingInfo() {
    final debitName =
        selectedDebitAccountId == null
            ? "الحساب المدين"
            : debitAccountName;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color:
            Colors.blue.shade50,

        borderRadius:
            BorderRadius.circular(14),

        border:
            Border.all(
          color:
              Colors.blue.shade100,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance,
                color: mainColor,
              ),

              SizedBox(width: 8),

              Text(
                "القيد المحاسبي",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              const Icon(
                Icons.arrow_downward,
                color: Colors.green,
              ),

              const SizedBox(
                width: 6,
              ),

              Expanded(
                child: Text(
                  "مدين: $debitName",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Colors.red,
              ),

              const SizedBox(
                width: 6,
              ),

              Expanded(
                child: Text(
                  "دائن: $cashAccountName",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (amountController.text
              .trim()
              .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            Text(
              "المبلغ: ${amountController.text} ريال",
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // زر الحفظ
  // ============================================================

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child:
          ElevatedButton.icon(
        onPressed:
            isLoading ||
                    isLoadingAccounts
                ? null
                : saveVoucher,

        icon:
            isLoading
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.save,
                    color:
                        Colors.white,
                  ),

        label: Text(
          isLoading
              ? "جاري الترحيل..."
              : "حفظ وترحيل سند الصرف",

          style:
              const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color:
                Colors.white,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              mainColor,

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              mainColor.withOpacity(
            .55,
          ),

          disabledForegroundColor:
              Colors.white70,

          elevation: 3,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
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
    return Directionality(
      textDirection:
          TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            const Color(
          0xffF5F9FF,
        ),

        appBar:
            const MyAppBar(
          title:
              "سند صرف",
          icon:
              Icons.money_off,
        ),

        body:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child: Form(
            key: formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // الموقع
                // ==================================================

                buildLocationCard(),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // الصندوق
                // ==================================================

                buildCashAccountCard(),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // الحساب المدين
                // ==================================================

                if (isLoadingAccounts)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(
                        20,
                      ),
                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              mainColor,
                        ),
                      ),
                    ),
                  )
                else
                  buildDebitAccountDropdown(),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // المبلغ
                // ==================================================

                buildAmountField(),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // البيان
                // ==================================================

                buildStatementField(),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // القيد
                // ==================================================

                buildAccountingInfo(),

                const SizedBox(
                  height: 25,
                ),

                // ==================================================
                // حفظ
                // ==================================================

                buildSaveButton(),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}