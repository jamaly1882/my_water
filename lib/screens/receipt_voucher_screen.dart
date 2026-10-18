import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class ReceiptVoucherScreen extends StatefulWidget {
  final String? villageId;
  final String? villageName;

  final String? wellId;
  final String? wellName;

  const ReceiptVoucherScreen({
    super.key,
    this.villageId,
    this.villageName,
    this.wellId,
    this.wellName,
  });

  @override
  State<ReceiptVoucherScreen> createState() =>
      _ReceiptVoucherScreenState();
}

class _ReceiptVoucherScreenState
    extends State<ReceiptVoucherScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // اللون الموحد
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // المتغيرات
  // ============================================================

  String? selectedCustomerId;
  String? selectedAccountId;

  // حساب صندوق البئر
  String? selectedCashAccountId;

  String? selectedCycleId;

  String customerName = "";

  String cashAccountName =
      "جاري تحميل صندوق البئر...";

  List<QueryDocumentSnapshot> customers = [];
  List<QueryDocumentSnapshot> cycles = [];

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController statementController =
      TextEditingController();

  bool isLoading = false;
  bool isLoadingCycles = false;

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  // ============================================================
  // بداية الصفحة
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadCustomers();

    // تحميل صندوق نفس البئر
    loadCashAccount();
  }

  // ============================================================
  // التخلص من المتغيرات
  // ============================================================

  @override
  void dispose() {
    amountController.dispose();
    statementController.dispose();

    super.dispose();
  }

  // ============================================================
  // تحميل زبائن البئر
  // ============================================================

  Future<void> loadCustomers() async {
    try {
      if (widget.wellId == null ||
          widget.wellId!.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          customers = [];
        });

        return;
      }

      final result = await firestore
          .collection("well_customers")
          .where(
            "wellId",
            isEqualTo: widget.wellId!.trim(),
          )
          .get();

      if (!mounted) return;

      setState(() {
        customers = result.docs;
      });
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "خطأ أثناء تحميل الزبائن:\n$e",
        true,
      );
    }
  }

  // ============================================================
  // تحميل صندوق البئر
  //
  // مهم:
  // لا نأخذ أول حساب cash.
  //
  // نبحث عن:
  //
  // type  == cash
  // wellId == البئر الحالي
  //
  // ============================================================

  Future<void> loadCashAccount() async {
    try {
      // ========================================================
      // التأكد من وجود البئر
      // ========================================================

      if (widget.wellId == null ||
          widget.wellId!.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          selectedCashAccountId = null;

          cashAccountName =
              "لم يتم تحديد البئر";
        });

        return;
      }

      final String currentWellId =
          widget.wellId!.trim();

      debugPrint(
        "========================================",
      );

      debugPrint(
        "البحث عن صندوق البئر",
      );

      debugPrint(
        "wellId = $currentWellId",
      );

      debugPrint(
        "wellName = ${widget.wellName}",
      );

      // ========================================================
      // البحث عن صندوق نفس البئر
      // ========================================================

      final result = await firestore
          .collection("accounts")
          .where(
            "type",
            isEqualTo: "cash",
          )
          .where(
            "wellId",
            isEqualTo: currentWellId,
          )
          .limit(1)
          .get();

      if (!mounted) return;

      // ========================================================
      // وجدنا الصندوق
      // ========================================================

      if (result.docs.isNotEmpty) {
        final doc = result.docs.first;

        final data =
            doc.data();

        setState(() {
          selectedCashAccountId =
              doc.id;

          cashAccountName =
              data["name"]?.toString() ??
                  "صندوق البئر";
        });

        debugPrint(
          "تم العثور على صندوق البئر",
        );

        debugPrint(
          "cashAccountId = ${doc.id}",
        );

        debugPrint(
          "cashAccountName = ${data["name"]}",
        );

        debugPrint(
          "========================================",
        );
      }

      // ========================================================
      // لم نجد الصندوق
      // ========================================================

      else {
        setState(() {
          selectedCashAccountId = null;

          cashAccountName =
              "لم يتم العثور على صندوق لهذا البئر";
        });

        debugPrint(
          "لم يتم العثور على صندوق للبئر",
        );

        debugPrint(
          "wellId = $currentWellId",
        );

        debugPrint(
          "========================================",
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selectedCashAccountId = null;

        cashAccountName =
            "خطأ أثناء تحميل صندوق البئر";
      });

      debugPrint(
        "خطأ loadCashAccount: $e",
      );
    }
  }

  // ============================================================
  // تحميل دورات الزبون المفتوحة
  // ============================================================

  Future<void> loadCustomerCycles(
    String customerId,
  ) async {
    if (!mounted) return;

    setState(() {
      isLoadingCycles = true;

      cycles.clear();

      selectedCycleId = null;
    });

    try {
      final result = await firestore
          .collection("cycles")
          .where(
            "customerId",
            isEqualTo: customerId,
          )
          .where(
            "status",
            isEqualTo: "مفتوح",
          )
          .get();

      if (!mounted) return;

      setState(() {
        cycles = result.docs;
      });
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "خطأ تحميل الدورات:\n$e",
        true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoadingCycles = false;
      });
    }
  }

  // ============================================================
  // حفظ سند القبض
  // ============================================================

  Future<void> saveVoucher() async {
    // ==========================================================
    // التحقق من النموذج
    // ==========================================================

    if (!formKey.currentState!.validate()) {
      return;
    }

    // ==========================================================
    // التحقق من الزبون
    // ==========================================================

    if (selectedCustomerId == null) {
      showMessage(
        "الرجاء اختيار الزبون",
        true,
      );

      return;
    }

    // ==========================================================
    // التحقق من حساب الزبون
    // ==========================================================

    if (selectedAccountId == null ||
        selectedAccountId!.isEmpty) {
      showMessage(
        "الزبون لا يملك حساب",
        true,
      );

      return;
    }

    // ==========================================================
    // التحقق من صندوق البئر
    // ==========================================================

    if (selectedCashAccountId == null ||
        selectedCashAccountId!.isEmpty) {
      showMessage(
        "لم يتم العثور على صندوق لهذا البئر",
        true,
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // المبلغ
      // ========================================================

      final double amount =
          double.parse(
        amountController.text.trim(),
      );

      // ========================================================
      // التاريخ
      // ========================================================

      final Timestamp now =
          Timestamp.now();

      // ========================================================
      // Batch
      // ========================================================

      final WriteBatch batch =
          firestore.batch();

      // ========================================================
      // إنشاء سند القبض
      // ========================================================

      final voucherRef = firestore
          .collection("receipt_vouchers")
          .doc();

      batch.set(
        voucherRef,
        {
          "customerId":
              selectedCustomerId,

          "customerName":
              customerName,

          "accountId":
              selectedAccountId,

          "cashAccountId":
              selectedCashAccountId,

          "cashAccountName":
              cashAccountName,

          "cycleId":
              selectedCycleId,

          "amount":
              amount,

          "statement":
              statementController.text.trim(),

          "date":
              now,

          "villageId":
              widget.villageId,

          "villageName":
              widget.villageName,

          "wellId":
              widget.wellId,

          "wellName":
              widget.wellName,

          "createdAt":
              now,
        },
      );

      // ========================================================
      // الحركة المحاسبية
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
          "customerId":
              selectedCustomerId,

          "customerName":
              customerName,

          "cycleId":
              selectedCycleId,

          "amount":
              amount,

          // الصندوق مدين
          "debitAccountId":
              selectedCashAccountId,

          // حساب الزبون دائن
          "creditAccountId":
              selectedAccountId,

          "statement":
              statementController.text
                      .trim()
                      .isEmpty
                  ? "سند قبض"
                  : statementController.text
                      .trim(),

          "type":
              "receipt",

          "date":
              now,

          "createdAt":
              now,

          "wellId":
              widget.wellId,

          "wellName":
              widget.wellName,
        },
      );

      // ========================================================
      // تحديث حساب صندوق البئر
      //
      // الصندوق:
      // debit + amount
      // balance + amount
      // ========================================================

      batch.update(
        firestore
            .collection("accounts")
            .doc(
              selectedCashAccountId,
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
      // تحديث حساب الزبون
      //
      // credit + amount
      // balance - amount
      // ========================================================

      batch.update(
        firestore
            .collection("accounts")
            .doc(
              selectedAccountId,
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
      // تحديث الدورة
      // ========================================================

      if (selectedCycleId != null &&
          selectedCycleId!.isNotEmpty) {
        batch.update(
          firestore
              .collection("cycles")
              .doc(
                selectedCycleId,
              ),
          {
            "paidAmount":
                FieldValue.increment(
              amount,
            ),

            "remainingAmount":
                FieldValue.increment(
              -amount,
            ),
          },
        );
      }

      // ========================================================
      // تنفيذ العملية
      // ========================================================

      await batch.commit();

      if (!mounted) return;

      showMessage(
        "تم حفظ سند القبض بنجاح",
        false,
      );

      clearForm();
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "حدث خطأ أثناء الحفظ:\n$e",
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
      selectedCustomerId = null;

      selectedAccountId = null;

      selectedCycleId = null;

      customerName = "";

      cycles.clear();
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
        ),
        backgroundColor:
            isError
                ? Colors.red
                : Colors.black87,
      ),
    );
  }

  // ============================================================
  // اختيار الزبون
  // ============================================================

  void onCustomerChanged(
    String? value,
  ) {
    if (value == null) return;

    QueryDocumentSnapshot? selectedDoc;

    for (final doc in customers) {
      final data =
          doc.data()
              as Map<String, dynamic>;

      if (data["customerId"]?.toString() ==
          value) {
        selectedDoc = doc;

        break;
      }
    }

    if (selectedDoc == null) return;

    final data =
        selectedDoc.data()
            as Map<String, dynamic>;

    setState(() {
      selectedCustomerId =
          data["customerId"]
              ?.toString();

      customerName =
          data["customerName"]
                  ?.toString() ??
              "";

      selectedAccountId =
          data["accountId"]
              ?.toString();

      selectedCycleId = null;
    });

    loadCustomerCycles(value);
  }

  // ============================================================
  // بطاقة الموقع
  // ============================================================

  Widget buildLocationCard() {
    if ((widget.villageName == null ||
            widget.villageName!.trim().isEmpty) &&
        (widget.wellName == null ||
            widget.wellName!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.white,

      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            Row(
              children: const [
                Icon(
                  Icons.location_on,
                  color: mainColor,
                ),

                SizedBox(
                  width: 8,
                ),

                Text(
                  "معلومات الموقع",

                  style:
                      TextStyle(
                    fontSize: 17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(),

            // ==================================================
            // القرية
            // ==================================================

            if (widget.villageName != null &&
                widget.villageName!
                    .trim()
                    .isNotEmpty)
              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading:
                    const Icon(
                  Icons.location_city,
                  color: mainColor,
                ),

                title:
                    const Text(
                  "القرية",
                ),

                subtitle:
                    Text(
                  widget.villageName!,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

            // ==================================================
            // البئر
            // ==================================================

            if (widget.wellName != null &&
                widget.wellName!
                    .trim()
                    .isNotEmpty)
              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading:
                    const Icon(
                  Icons.water_drop,
                  color: mainColor,
                ),

                title:
                    const Text(
                  "البئر",
                ),

                subtitle:
                    Text(
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
  // بطاقة حساب صندوق البئر
  // ============================================================

  Widget buildCashAccountCard() {
    return Card(
      color: Colors.white,

      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,

          decoration:
              BoxDecoration(
            color: mainColor,

            borderRadius:
                BorderRadius.circular(12),
          ),

          child: const Icon(
            Icons.account_balance_wallet,

            color: Colors.white,
          ),
        ),

        title: const Text(
          "حساب الصندوق",

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

            color: mainColor,
          ),
        ),

        trailing:
            selectedCashAccountId != null
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                : const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
      ),
    );
  }

  // ============================================================
  // بطاقة حساب الزبون
  // ============================================================

  Widget buildCustomerAccountCard() {
    if (selectedCustomerId == null) {
      return const SizedBox.shrink();
    }

    if (selectedAccountId == null ||
        selectedAccountId!.isEmpty) {
      return Card(
        color: Colors.red.shade50,

        child: const ListTile(
          leading: Icon(
            Icons.error_outline,
            color: Colors.red,
          ),

          title: Text(
            "هذا الزبون لا يملك حساباً",

            style: TextStyle(
              color: Colors.red,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,

      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,

          decoration:
              const BoxDecoration(
            color: mainColor,

            shape:
                BoxShape.circle,
          ),

          child: const Icon(
            Icons.account_balance,

            color: Colors.white,
          ),
        ),

        title: const Text(
          "حساب الزبون",

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Text(
          customerName,

          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
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
            isLoading
                ? null
                : saveVoucher,

        icon: isLoading
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
              ? "جاري الحفظ..."
              : "حفظ سند القبض",

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
              mainColor,

          disabledForegroundColor:
              Colors.white,

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
  // الصفحة
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

        // ======================================================
        // شريط العنوان
        // ======================================================

        appBar:
            const MyAppBar(
          title:
              "سند قبض جديد",

          icon:
              Icons.receipt_long,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      mainColor,
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                child: Form(
                  key: formKey,

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      // ==================================================
                      // معلومات الموقع
                      // ==================================================

                      buildLocationCard(),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // صندوق البئر
                      // ==================================================

                      buildCashAccountCard(),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // اختيار الزبون
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        value:
                            selectedCustomerId,

                        decoration:
                            InputDecoration(
                          labelText:
                              "الزبون",

                          border:
                              const OutlineInputBorder(),

                          prefixIcon:
                              const Icon(
                            Icons.person,

                            color:
                                mainColor,
                          ),

                          filled:
                              true,

                          fillColor:
                              Colors.white,

                          focusedBorder:
                              const OutlineInputBorder(
                            borderSide:
                                BorderSide(
                              color:
                                  mainColor,

                              width:
                                  2,
                            ),
                          ),
                        ),

                        hint: Text(
                          customers.isEmpty
                              ? "لا يوجد زبائن"
                              : "اختر الزبون",
                        ),

                        items:
                            customers.map(
                          (doc) {
                            final data =
                                doc.data()
                                    as Map<
                                        String,
                                        dynamic>;

                            final customerId =
                                data[
                                        "customerId"]
                                    ?.toString();

                            final name =
                                data[
                                            "customerName"]
                                        ?.toString() ??
                                    "بدون اسم";

                            return DropdownMenuItem<
                                String>(
                              value:
                                  customerId,

                              child:
                                  Text(
                                name,
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            customers.isEmpty
                                ? null
                                : onCustomerChanged,

                        validator:
                            (value) {
                          if (value ==
                              null) {
                            return "اختر الزبون";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // حساب الزبون
                      // ==================================================

                      buildCustomerAccountCard(),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // الدورات
                      // ==================================================

                      if (isLoadingCycles)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            top: 8,

                            bottom: 8,
                          ),

                          child:
                              LinearProgressIndicator(
                            color:
                                mainColor,
                          ),
                        )
                      else
                        DropdownButtonFormField<
                            String>(
                          value:
                              selectedCycleId,

                          decoration:
                              InputDecoration(
                            labelText:
                                "الدورة",

                            border:
                                const OutlineInputBorder(),

                            prefixIcon:
                                const Icon(
                              Icons.cached,

                              color:
                                  mainColor,
                            ),

                            filled:
                                true,

                            fillColor:
                                Colors.white,

                            focusedBorder:
                                const OutlineInputBorder(
                              borderSide:
                                  BorderSide(
                                color:
                                    mainColor,

                                width:
                                    2,
                              ),
                            ),
                          ),

                          hint:
                              const Text(
                            "اختر الدورة (اختياري)",
                          ),

                          items:
                              cycles.map(
                            (doc) {
                              final data =
                                  doc.data()
                                      as Map<
                                          String,
                                          dynamic>;

                              final cycleNumber =
                                  data[
                                          "cycleNumber"]
                                      ?.toString() ??
                                  "";

                              final remaining =
                                  data[
                                          "remainingAmount"] ??
                                      0;

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    doc.id,

                                child:
                                    Text(
                                  "الدورة رقم $cycleNumber"
                                  " - المتبقي $remaining",
                                ),
                              );
                            },
                          ).toList(),

                          onChanged:
                              (value) {
                            setState(() {
                              selectedCycleId =
                                  value;
                            });
                          },
                        ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // المبلغ
                      // ==================================================

                      TextFormField(
                        controller:
                            amountController,

                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal:
                              true,
                        ),

                        decoration:
                            InputDecoration(
                          labelText:
                              "المبلغ",

                          border:
                              const OutlineInputBorder(),

                          prefixIcon:
                              const Icon(
                            Icons
                                .payments_outlined,

                            color:
                                mainColor,
                          ),

                          filled:
                              true,

                          fillColor:
                              Colors.white,

                          focusedBorder:
                              const OutlineInputBorder(
                            borderSide:
                                BorderSide(
                              color:
                                  mainColor,

                              width:
                                  2,
                            ),
                          ),
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return "أدخل المبلغ";
                          }

                          final amount =
                              double.tryParse(
                            value.trim(),
                          );

                          if (amount ==
                              null) {
                            return "المبلغ غير صحيح";
                          }

                          if (amount <=
                              0) {
                            return "يجب أن يكون المبلغ أكبر من صفر";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // البيان
                      // ==================================================

                      TextFormField(
                        controller:
                            statementController,

                        maxLines:
                            3,

                        decoration:
                            InputDecoration(
                          labelText:
                              "البيان",

                          border:
                              const OutlineInputBorder(),

                          prefixIcon:
                              const Icon(
                            Icons
                                .description_outlined,

                            color:
                                mainColor,
                          ),

                          alignLabelWithHint:
                              true,

                          filled:
                              true,

                          fillColor:
                              Colors.white,

                          focusedBorder:
                              const OutlineInputBorder(
                            borderSide:
                                BorderSide(
                              color:
                                  mainColor,

                              width:
                                  2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // زر حفظ سند القبض
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