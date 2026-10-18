import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';
import 'payment_voucher_screen.dart';

class PaymentVoucherListScreen extends StatefulWidget {
  final String? villageId;
  final String? villageName;

  final String? wellId;
  final String? wellName;

  const PaymentVoucherListScreen({
    super.key,
    this.villageId,
    this.villageName,
    this.wellId,
    this.wellName,
  });

  @override
  State<PaymentVoucherListScreen> createState() =>
      _PaymentVoucherListScreenState();
}

class _PaymentVoucherListScreenState
    extends State<PaymentVoucherListScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static const Color mainColor = Colors.blue;

  // ============================================================
  // حذف سند
  // ============================================================

  Future<void> deleteVoucher(
    DocumentSnapshot doc,
  ) async {
    final data =
        doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final amount =
        (data['amount'] ?? 0).toDouble();

    final debitAccountId =
        data['debitAccountId']?.toString();

    final creditAccountId =
        data['creditAccountId']?.toString();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حذف سند الصرف',
            textDirection: TextDirection.rtl,
          ),
          content: Text(
            'هل تريد حذف سند الصرف بمبلغ '
            '$amount ريال؟\n\n'
            'سيتم عكس القيد المحاسبي أيضاً.',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              child: const Text(
                'حذف',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final batch =
          firestore.batch();

      // --------------------------------------------------------
      // حذف سند الصرف
      // --------------------------------------------------------

      batch.delete(
        firestore
            .collection(
              'payment_vouchers',
            )
            .doc(doc.id),
      );

      // --------------------------------------------------------
      // البحث عن القيد المرتبط
      // --------------------------------------------------------

      final transactions =
          await firestore
              .collection(
                'account_transactions',
              )
              .where(
                'type',
                isEqualTo: 'payment',
              )
              .where(
                'wellId',
                isEqualTo: widget.wellId,
              )
              .where(
                'debitAccountId',
                isEqualTo:
                    debitAccountId,
              )
              .where(
                'creditAccountId',
                isEqualTo:
                    creditAccountId,
              )
              .where(
                'amount',
                isEqualTo: amount,
              )
              .limit(1)
              .get();

      for (final transaction
          in transactions.docs) {
        batch.delete(
          transaction.reference,
        );
      }

      // --------------------------------------------------------
      // عكس الحساب المدين
      // --------------------------------------------------------

      if (debitAccountId != null &&
          debitAccountId.isNotEmpty) {
        batch.update(
          firestore
              .collection('accounts')
              .doc(debitAccountId),
          {
            'debit':
                FieldValue.increment(
              -amount,
            ),
            'balance':
                FieldValue.increment(
              -amount,
            ),
            'lastUpdate':
                Timestamp.now(),
          },
        );
      }

      // --------------------------------------------------------
      // عكس الصندوق
      // --------------------------------------------------------

      if (creditAccountId != null &&
          creditAccountId.isNotEmpty) {
        batch.update(
          firestore
              .collection('accounts')
              .doc(creditAccountId),
          {
            'credit':
                FieldValue.increment(
              -amount,
            ),
            'balance':
                FieldValue.increment(
              amount,
            ),
            'lastUpdate':
                Timestamp.now(),
          },
        );
      }

      await batch.commit();

      if (!mounted) return;

      showMessage(
        'تم حذف سند الصرف وعكس القيد بنجاح',
        false,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'حدث خطأ أثناء حذف السند:\n$e',
        true,
      );
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(
    String message,
    bool error,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection:
              TextDirection.rtl,
        ),
        backgroundColor:
            error
                ? Colors.red
                : Colors.black87,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // فتح سند جديد
  // ============================================================

  void openNewVoucher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentVoucherScreen(
          villageId:
              widget.villageId,
          villageName:
              widget.villageName,
          wellId:
              widget.wellId,
          wellName:
              widget.wellName,
        ),
      ),
    );
  }

  // ============================================================
  // تنسيق التاريخ
  // ============================================================

  String formatDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      final date =
          value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return '-';
  }

  // ============================================================
  // بطاقة الإجمالي
  // ============================================================

  Widget buildSummary(
    AsyncSnapshot<QuerySnapshot>
        snapshot,
  ) {
    double total = 0;

    if (snapshot.hasData) {
      for (final doc
          in snapshot.data!.docs) {
        final data =
            doc.data()
                as Map<String, dynamic>;

        total +=
            double.tryParse(
                  data['amount']
                          ?.toString() ??
                      '0',
                ) ??
                0;
      }
    }

    return Card(
      color: mainColor,
      elevation: 3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                color:
                    Colors.white24,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons.payments,
                color:
                    Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إجمالي المصروف',
                    style: TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} ريال',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 21,
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
  // بطاقة البئر
  // ============================================================

  Widget buildWellCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              mainColor.withOpacity(.12),
          child: const Icon(
            Icons.water_drop,
            color: mainColor,
          ),
        ),
        title: const Text(
          'البئر',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          widget.wellName ??
              'غير محدد',
          style:
              const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // جدول السندات
  // ============================================================

  Widget buildTable(
    AsyncSnapshot<QuerySnapshot>
        snapshot,
  ) {
    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: mainColor,
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'حدث خطأ:\n${snapshot.error}',
          textAlign:
              TextAlign.center,
        ),
      );
    }

    if (!snapshot.hasData ||
        snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'لا توجد سندات صرف لهذا البئر',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final docs =
        snapshot.data!.docs;

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder:
          (context, index) {
        final doc = docs[index];

        final data =
            doc.data()
                as Map<String, dynamic>;

        final debitName =
            data['debitAccountName']
                    ?.toString() ??
                'غير محدد';

        final creditName =
            data['creditAccountName']
                    ?.toString() ??
                'صندوق البئر';

        final amount =
            double.tryParse(
                  data['amount']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        final statement =
            data['statement']
                    ?.toString() ??
                'سند صرف';

        final date =
            formatDate(
          data['date'],
        );

        return Card(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),
          elevation: 2,
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Colors.red.shade50,
                      child: const Icon(
                        Icons.money_off,
                        color:
                            Colors.red,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سند صرف ${index + 1}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            date,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '${amount.toStringAsFixed(2)} ريال',
                      style:
                          const TextStyle(
                        color: Colors.red,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    PopupMenuButton<
                        String>(
                      onSelected:
                          (value) {
                        if (value ==
                            'delete') {
                          deleteVoucher(
                            doc,
                          );
                        }
                      },
                      itemBuilder:
                          (_) => const [
                        PopupMenuItem(
                          value:
                              'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color:
                                    Colors.red,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'حذف',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(),

                _row(
                  'المدين',
                  debitName,
                  Colors.red,
                ),

                _row(
                  'الدائن',
                  creditName,
                  mainColor,
                ),

                _row(
                  'البيان',
                  statement,
                  Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // صف داخل السند
  // ============================================================

  Widget _row(
    String title,
    String value,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
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
    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      return Directionality(
        textDirection:
            TextDirection.rtl,
        child: Scaffold(
          appBar:
              const MyAppBar(
            title:
                'سندات الصرف',
            icon:
                Icons.money_off,
          ),
          body: const Center(
            child: Text(
              'لم يتم تحديد البئر',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final stream = firestore
        .collection(
          'payment_vouchers',
        )
        .where(
          'wellId',
          isEqualTo: widget.wellId,
        )
        .orderBy(
          'date',
          descending: true,
        )
        .snapshots();

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
              'سندات الصرف',
          icon:
              Icons.money_off,
        ),

        floatingActionButton:
            FloatingActionButton(
          backgroundColor:
              mainColor,
          onPressed:
              openNewVoucher,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),

        body:
            StreamBuilder<
                QuerySnapshot>(
          stream: stream,
          builder:
              (context, snapshot) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Column(
                children: [
                  buildWellCard(),

                  const SizedBox(
                    height: 16,
                  ),

                  buildSummary(
                    snapshot,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  buildTable(
                    snapshot,
                  ),

                  const SizedBox(
                    height: 80,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}