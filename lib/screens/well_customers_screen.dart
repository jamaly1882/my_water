import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class WellCustomerScreen extends StatefulWidget {
  final String? supervisorId;

  final String? provinceId;
  final String? provinceName;

  final String? districtId;
  final String? districtName;

  final String? hamletId;
  final String? hamletName;

  final String? villageId;
  final String? villageName;

  final String? wellId;
  final String? wellName;

  const WellCustomerScreen({
    super.key,
    this.supervisorId,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.hamletId,
    this.hamletName,
    this.villageId,
    this.villageName,
    this.wellId,
    this.wellName,
  });

  @override
  State<WellCustomerScreen> createState() =>
      _WellCustomerScreenState();
}

class _WellCustomerScreenState
    extends State<WellCustomerScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // اللون الموحد
  // ============================================================

  static const Color primaryColor = Colors.blue;

  // ============================================================
  // بيانات الموقع
  // ============================================================

  String? supervisorId;

  String? provinceId;
  String? provinceName;

  String? districtId;
  String? districtName;

  String? hamletId;
  String? hamletName;

  String? villageId;
  String? villageName;

  String? wellId;
  String? wellName;

  // ============================================================
  // مهم جداً
  // loading = تحميل الصفحة والبيانات
  // saving = عملية إضافة الزبون
  // ============================================================

  bool loading = true;
  bool saving = false;

  // ============================================================
  // قائمة الزبائن
  // ============================================================

  List<QueryDocumentSnapshot> customers = [];

  // ============================================================
  // الزبون المختار
  // ============================================================

  String? selectedCustomerId;
  String? selectedCustomerName;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    supervisorId = widget.supervisorId;

    provinceId = widget.provinceId;
    provinceName = widget.provinceName;

    districtId = widget.districtId;
    districtName = widget.districtName;

    hamletId = widget.hamletId;
    hamletName = widget.hamletName;

    villageId = widget.villageId;
    villageName = widget.villageName;

    wellId = widget.wellId;
    wellName = widget.wellName;

    loadVillageName();
    loadCustomers();
  }

  // ============================================================
  // جلب اسم القرية
  // ============================================================

  Future<void> loadVillageName() async {
    if (villageId == null ||
        villageId!.trim().isEmpty) {
      return;
    }

    try {
      final doc = await firestore
          .collection('villages')
          .doc(villageId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();

        setState(() {
          villageName =
              data?['name']?.toString() ??
                  villageName;
        });
      }
    } catch (e) {
      debugPrint(
        'خطأ في جلب اسم القرية: $e',
      );
    }
  }

  // ============================================================
  // جلب زبائن القرية
  // ============================================================

  Future<void> loadCustomers() async {
    if (villageId == null ||
        villageId!.trim().isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      return;
    }

    try {
      final result = await firestore
          .collection('customers')
          .where(
            'villageId',
            isEqualTo: villageId,
          )
          .get();

      if (!mounted) return;

      setState(() {
        customers = result.docs;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'خطأ في تحميل الزبائن: $e',
      );

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void message(String text) {
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
  // حفظ الزبون بالبئر + إنشاء الحساب
  // ============================================================

  Future<void> saveWellCustomer() async {
    // منع الضغط المتكرر أثناء الإضافة
    if (saving) return;

    // ==========================================================
    // التحقق من الزبون
    // ==========================================================

    if (selectedCustomerId == null ||
        selectedCustomerId!.trim().isEmpty) {
      message('اختر الزبون أولاً');
      return;
    }

    // ==========================================================
    // التحقق من البئر
    // ==========================================================

    if (wellId == null ||
        wellId!.trim().isEmpty) {
      message('رقم البئر غير موجود');
      return;
    }

    // ==========================================================
    // تشغيل حالة الحفظ
    // لا نخفي الصفحة
    // ==========================================================

    setState(() {
      saving = true;
    });

    try {
      // ========================================================
      // جلب بيانات الزبون
      // ========================================================

      final customerDoc = await firestore
          .collection('customers')
          .doc(selectedCustomerId)
          .get();

      if (!customerDoc.exists) {
        throw Exception(
          'الزبون غير موجود',
        );
      }

      final customer =
          customerDoc.data()!;

      // ========================================================
      // البحث عن حساب سابق للزبون
      // ========================================================

      String accountId;

      final oldAccount = await firestore
          .collection('accounts')
          .where(
            'customerId',
            isEqualTo: selectedCustomerId,
          )
          .limit(1)
          .get();

      if (oldAccount.docs.isNotEmpty) {
        accountId =
            oldAccount.docs.first.id;
      } else {
        // ======================================================
        // إنشاء حساب جديد
        // ======================================================

        final accountRef =
            await firestore
                .collection('accounts')
                .add({
          'customerId':
              selectedCustomerId,

          'customerName':
              customer['name'],

          'balance': 0,

          'debit': 0,

          'credit': 0,

          'statement':
              'فتح حساب زبون البئر',

          'createdAt':
              FieldValue.serverTimestamp(),
        });

        accountId =
            accountRef.id;
      }

      // ========================================================
      // معرف ربط الزبون بالبئر
      // ========================================================

      final wellCustomerId =
          '${wellId}_$selectedCustomerId';

      // ========================================================
      // حفظ ربط الزبون بالبئر
      // ========================================================

      await firestore
          .collection('well_customers')
          .doc(wellCustomerId)
          .set({
        'customerId':
            selectedCustomerId,

        'customerName':
            customer['name'],

        'phone':
            customer['phone'] ?? '',

        'accountId':
            accountId,

        'villageId':
            villageId,

        'villageName':
            villageName,

        'wellId':
            wellId,

        'wellName':
            wellName,

        'provinceId':
            provinceId,

        'provinceName':
            provinceName,

        'districtId':
            districtId,

        'districtName':
            districtName,

        'hamletId':
            hamletId,

        'hamletName':
            hamletName,

        'waterUsageTypeId':
            customer['waterUsageTypeId'],

        'waterUsageTypeName':
            customer['waterUsageTypeName'],

        'supervisorId':
            supervisorId,

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      message(
        'تم إضافة الزبون وربطه بالبئر بنجاح',
      );

      // ========================================================
      // تنظيف الاختيار فقط
      // الصفحة لا تختفي
      // ========================================================

      setState(() {
        selectedCustomerId = null;
        selectedCustomerName = null;
      });
    } catch (e) {
      if (!mounted) return;

      message(
        'حدث خطأ أثناء الإضافة:\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ============================================================
  // حقل القرية
  // ============================================================

  Widget villageField() {
    return DropdownButtonFormField<String>(
      initialValue: villageId,

      decoration: InputDecoration(
        labelText: 'القرية',

        prefixIcon: const Icon(
          Icons.location_on,
          color: primaryColor,
        ),

        filled: true,

        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),

      items: [
        DropdownMenuItem<String>(
          value: villageId,
          child: Text(
            villageName ?? 'غير محدد',
          ),
        ),
      ],

      onChanged: null,
    );
  }

  // ============================================================
  // حقل اختيار الزبون
  // ============================================================

  Widget customerDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedCustomerId,

      decoration: InputDecoration(
        labelText: 'اختر الزبون',

        prefixIcon: const Icon(
          Icons.person,
          color: primaryColor,
        ),

        filled: true,

        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),

      items: customers.map(
        (customer) {
          final data =
              customer.data()
                  as Map<String, dynamic>;

          final name =
              data['name']?.toString() ??
                  '';

          final phone =
              data['phone']?.toString() ??
                  '';

          return DropdownMenuItem<String>(
            value: customer.id,
            child: Text(
              phone.isEmpty
                  ? name
                  : '$name - $phone',
              overflow:
                  TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),

      onChanged: saving
          ? null
          : (value) {
              if (value == null) return;

              final customer =
                  customers.firstWhere(
                (c) => c.id == value,
              );

              final data =
                  customer.data()
                      as Map<String, dynamic>;

              setState(() {
                selectedCustomerId =
                    customer.id;

                selectedCustomerName =
                    data['name']?.toString() ??
                        '';
              });
            },
    );
  }

  // ============================================================
  // بطاقة معلومات الزبون
  // ============================================================

  Widget customerCard() {
    if (selectedCustomerId == null) {
      return const SizedBox.shrink();
    }

    final customer =
        customers.firstWhere(
      (c) => c.id == selectedCustomerId,
    );

    final data =
        customer.data()
            as Map<String, dynamic>;

    final phone =
        data['phone']?.toString() ?? '';

    final address =
        data['address']?.toString() ?? '';

    final usage =
        data['waterUsageTypeName']
                ?.toString() ??
            '';

    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(14),

        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      primaryColor,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
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
                      Text(
                        selectedCustomerName ??
                            '',
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'البئر: ${wellName ?? ''}',
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            if (phone.isNotEmpty)
              _infoRow(
                Icons.phone,
                'الهاتف',
                phone,
              ),

            if (address.isNotEmpty)
              _infoRow(
                Icons.home,
                'العنوان',
                address,
              ),

            if (usage.isNotEmpty)
              _infoRow(
                Icons.water_drop,
                'نوع الاستخدام',
                usage,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // صف معلومات
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),

          const SizedBox(
            width: 8,
          ),

          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // معلومات البئر
  // ============================================================

  Widget wellInfoCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color:
            primaryColor.withOpacity(.08),

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              primaryColor.withOpacity(.25),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.water,
            color: primaryColor,
            size: 32,
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
                  'البئر المحدد',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  wellName == null ||
                          wellName!
                              .trim()
                              .isEmpty
                      ? 'غير محدد'
                      : wellName!,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.lock_outline,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // زر الإضافة
  // ============================================================

  Widget saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: ElevatedButton.icon(
        onPressed:
            saving
                ? null
                : saveWellCustomer,

        icon: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.add,
                color: Colors.white,
              ),

        label: Text(
          saving
              ? 'جاري الإضافة...'
              : 'إضافة وربط الزبون بالبئر',

          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              primaryColor,

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              primaryColor.withOpacity(.60),

          disabledForegroundColor:
              Colors.white70,

          elevation: 3,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
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
            const Color(0xffF5F9FF),

        appBar: MyAppBar(
          title:
              wellName == null ||
                      wellName!.trim().isEmpty
                  ? 'زبائن البئر'
                  : 'زبائن البئر $wellName',
          icon:
              Icons.people,
        ),

        // ======================================================
        // أثناء تحميل البيانات فقط نعرض التحميل
        // ======================================================

        body: loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: primaryColor,
                ),
              )

            // ==================================================
            // بعد تحميل البيانات تبقى الصفحة ظاهرة دائماً
            // حتى أثناء saving
            // ==================================================

            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(15),

                child: Column(
                  children: [
                    // ==========================================
                    // معلومات البئر
                    // ==========================================

                    wellInfoCard(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================================
                    // القرية
                    // ==========================================

                    villageField(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================================
                    // اختيار الزبون
                    // ==========================================

                    customerDropdown(),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==========================================
                    // معلومات الزبون
                    // ==========================================

                    customerCard(),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==========================================
                    // زر الإضافة
                    // ==========================================

                    saveButton(),

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