import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class CreateSalesAccountScreen extends StatefulWidget {
  final String? supervisorId;

  final String? wellId;
  final String? wellName;

  const CreateSalesAccountScreen({
    super.key,
    this.supervisorId,
    this.wellId,
    this.wellName,
  });

  @override
  State<CreateSalesAccountScreen> createState() =>
      _CreateSalesAccountScreenState();
}

class _CreateSalesAccountScreenState
    extends State<CreateSalesAccountScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // اللون الموحد
  // ============================================================

  static const Color appColor = Colors.blue;

  // ============================================================
  // الحالة
  // ============================================================

  bool loading = false;
  bool loadingWell = true;

  String? wellName;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    wellName = widget.wellName;

    loadWellName();
  }

  // ============================================================
  // جلب اسم البئر
  // ============================================================

  Future<void> loadWellName() async {
    // ----------------------------------------------------------
    // إذا كان الاسم مرسلاً من الصفحة السابقة
    // ----------------------------------------------------------

    if (widget.wellName != null &&
        widget.wellName!.trim().isNotEmpty) {
      if (mounted) {
        setState(() {
          wellName = widget.wellName!.trim();
          loadingWell = false;
        });
      }

      return;
    }

    // ----------------------------------------------------------
    // لا يوجد ID للبئر
    // ----------------------------------------------------------

    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      if (mounted) {
        setState(() {
          loadingWell = false;
        });
      }

      return;
    }

    // ----------------------------------------------------------
    // جلب البئر من Firestore
    // ----------------------------------------------------------

    try {
      final doc = await firestore
          .collection('wells')
          .doc(widget.wellId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();

        final name =
            data?['name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          setState(() {
            wellName = name;
            loadingWell = false;
          });

          return;
        }
      }

      setState(() {
        loadingWell = false;
      });
    } catch (e) {
      debugPrint(
        'خطأ في جلب اسم البئر: $e',
      );

      if (mounted) {
        setState(() {
          loadingWell = false;
        });
      }
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // إنشاء الحسابات
  //
  // 1 - مبيعات البئر
  // 2 - صندوق البئر
  // 3 - مصروفات البئر
  // 4 - عامل البئر
  // ============================================================

  Future<void> createAccounts() async {
    if (loading) return;

    // ----------------------------------------------------------
    // التحقق من البئر
    // ----------------------------------------------------------

    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      showMessage(
        'رقم البئر غير موجود',
      );

      return;
    }

    // ----------------------------------------------------------
    // التحقق من اسم البئر
    // ----------------------------------------------------------

    final currentWellName =
        wellName?.trim();

    if (currentWellName == null ||
        currentWellName.isEmpty) {
      showMessage(
        'اسم البئر غير موجود',
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ========================================================
      // الحسابات الأربعة
      // ========================================================

      final List<Map<String, String>> accounts = [
        {
          'name': 'مبيعات $currentWellName',
          'type': 'sales',
        },
        {
          'name': 'صندوق $currentWellName',
          'type': 'cash',
        },
        {
          'name': 'مصروفات $currentWellName',
          'type': 'expenses',
        },
        {
          'name': 'عامل $currentWellName',
          'type': 'worker',
        },
      ];

      int createdCount = 0;
      int existingCount = 0;

      // ========================================================
      // إنشاء الحسابات
      // ========================================================

      for (final account in accounts) {
        final String type =
            account['type']!;

        final String name =
            account['name']!;

        // ------------------------------------------------------
        // البحث عن الحساب حسب البئر والنوع
        // ------------------------------------------------------

        final check = await firestore
            .collection('accounts')
            .where(
              'wellId',
              isEqualTo: widget.wellId,
            )
            .where(
              'type',
              isEqualTo: type,
            )
            .limit(1)
            .get();

        // ------------------------------------------------------
        // الحساب موجود
        // ------------------------------------------------------

        if (check.docs.isNotEmpty) {
          existingCount++;
          continue;
        }

        // ------------------------------------------------------
        // إنشاء الحساب
        // ------------------------------------------------------

        final accountRef = firestore
            .collection('accounts')
            .doc();

        await accountRef.set({
          'accountId':
              accountRef.id,

          'accountNumber':
              DateTime.now()
                  .millisecondsSinceEpoch
                  .toString(),

          'name':
              name,

          'type':
              type,

          'wellId':
              widget.wellId,

          'wellName':
              currentWellName,

          'supervisorId':
              widget.supervisorId,

          'debit':
              0,

          'credit':
              0,

          'balance':
              0,

          'createdAt':
              FieldValue.serverTimestamp(),
        });

        createdCount++;
      }

      // ========================================================
      // الرسالة
      // ========================================================

      if (!mounted) return;

      if (createdCount == 4) {
        showMessage(
          'تم إنشاء حسابات البئر الأربعة بنجاح',
        );
      } else if (createdCount > 0) {
        showMessage(
          'تم إنشاء $createdCount حساب، '
          'والحسابات الموجودة لم يتم تكرارها',
        );
      } else {
        showMessage(
          'حسابات البئر الأربعة موجودة مسبقاً',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'حدث خطأ أثناء إنشاء الحسابات:\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // شريط حالة الحسابات
  // ============================================================

  Widget accountStatusBar() {
    if (widget.wellId == null ||
        widget.wellId!.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color:
              Colors.orange.shade50,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                Colors.orange.shade200,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'لم يتم تحديد البئر',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('accounts')
          .where(
            'wellId',
            isEqualTo: widget.wellId,
          )
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        int sales = 0;
        int cash = 0;
        int expenses = 0;
        int worker = 0;

        if (snapshot.hasData) {
          for (final doc
              in snapshot.data!.docs) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            final type =
                data['type']?.toString();

            if (type == 'sales') {
              sales++;
            }

            if (type == 'cash') {
              cash++;
            }

            if (type == 'expenses') {
              expenses++;
            }

            if (type == 'worker') {
              worker++;
            }
          }
        }

        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: appColor,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _statusItem(
                  icon:
                      Icons.point_of_sale,
                  title: 'المبيعات',
                  active: sales > 0,
                ),
              ),

              Container(
                width: 1,
                height: 45,
                color: Colors.white30,
              ),

              Expanded(
                child: _statusItem(
                  icon:
                      Icons.account_balance_wallet,
                  title: 'الصندوق',
                  active: cash > 0,
                ),
              ),

              Container(
                width: 1,
                height: 45,
                color: Colors.white30,
              ),

              Expanded(
                child: _statusItem(
                  icon:
                      Icons.money_off,
                  title: 'المصروفات',
                  active: expenses > 0,
                ),
              ),

              Container(
                width: 1,
                height: 45,
                color: Colors.white30,
              ),

              Expanded(
                child: _statusItem(
                  icon:
                      Icons.engineering,
                  title: 'العامل',
                  active: worker > 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // عنصر حالة الحساب
  // ============================================================

  Widget _statusItem({
    required IconData icon,
    required String title,
    required bool active,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          active
              ? 'موجود'
              : 'غير موجود',
          style: TextStyle(
            color: active
                ? Colors.greenAccent
                : Colors.orangeAccent,
            fontSize: 10,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // بطاقة البئر
  // ============================================================

  Widget wellCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          children: [
            // --------------------------------------------------
            // أيقونة البئر
            // --------------------------------------------------

            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    appColor.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop,
                color: appColor,
                size: 35,
              ),
            ),

            const SizedBox(width: 15),

            // --------------------------------------------------
            // بيانات البئر
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'البئر',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 5),

                  if (loadingWell)
                    const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            color: appColor,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'جاري تحميل اسم البئر...',
                        ),
                      ],
                    )
                  else
                    Text(
                      wellName == null ||
                              wellName!
                                  .trim()
                                  .isEmpty
                          ? 'غير محدد'
                          : wellName!,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 5),

                  Text(
                    'رقم البئر: '
                    '${widget.wellId ?? 'غير محدد'}',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
  // بطاقة الحسابات
  // ============================================================

  Widget accountTypesCard() {
    final String name =
        wellName?.trim().isEmpty ?? true
            ? 'البئر'
            : wellName!;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // العنوان
            // --------------------------------------------------

            const Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: appColor,
                ),
                SizedBox(width: 8),
                Text(
                  'حسابات البئر',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // مبيعات البئر
            // --------------------------------------------------

            _accountRow(
              icon:
                  Icons.point_of_sale,
              title:
                  'مبيعات البئر',
              subtitle:
                  'مبيعات $name',
              color:
                  Colors.green,
            ),

            const Divider(),

            // --------------------------------------------------
            // صندوق البئر
            // --------------------------------------------------

            _accountRow(
              icon:
                  Icons.account_balance_wallet,
              title:
                  'صندوق البئر',
              subtitle:
                  'صندوق $name',
              color:
                  appColor,
            ),

            const Divider(),

            // --------------------------------------------------
            // مصروفات البئر
            // --------------------------------------------------

            _accountRow(
              icon:
                  Icons.money_off,
              title:
                  'مصروفات البئر',
              subtitle:
                  'مصروفات $name',
              color:
                  Colors.red,
            ),

            const Divider(),

            // --------------------------------------------------
            // عامل البئر
            // --------------------------------------------------

            _accountRow(
              icon:
                  Icons.engineering,
              title:
                  'عامل البئر',
              subtitle:
                  'عامل $name',
              color:
                  Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // صف الحساب
  // ============================================================

  Widget _accountRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,

      leading: CircleAvatar(
        backgroundColor:
            color.withOpacity(.12),
        child: Icon(
          icon,
          color: color,
        ),
      ),

      title: Text(
        title,
        style:
            const TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),

      subtitle:
          Text(subtitle),

      trailing: Icon(
        Icons.check_circle_outline,
        color: color,
      ),
    );
  }

  // ============================================================
  // زر الإضافة
  // ============================================================

  Widget createButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child:
          ElevatedButton.icon(
        onPressed:
            loading ||
                    loadingWell
                ? null
                : createAccounts,

        icon: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  color:
                      Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.add,
                color:
                    Colors.white,
              ),

        label: Text(
          loading
              ? 'جاري الإضافة...'
              : 'إضافة حسابات البئر الأربعة',
          style:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
            color:
                Colors.white,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              appColor,

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              appColor.withOpacity(
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
  // الملاحظة
  // ============================================================

  Widget infoCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
              Colors.blue.shade100,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20,
          ),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              'سيتم إضافة أربعة حسابات للبئر: '
              'مبيعات البئر وصندوق البئر '
              'ومصروفات البئر وعامل البئر. '
              'إذا كان أي حساب موجوداً مسبقاً '
              'فلن يتم تكراره.',
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
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
              'حسابات البئر',
          icon:
              Icons.account_balance,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child: Column(
            children: [
              // ==================================================
              // حالة الحسابات
              // ==================================================

              accountStatusBar(),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // معلومات البئر
              // ==================================================

              wellCard(),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // أنواع الحسابات
              // ==================================================

              accountTypesCard(),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // زر الإضافة
              // ==================================================

              createButton(),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // الملاحظة
              // ==================================================

              infoCard(),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}