import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class CustomerScreen extends StatefulWidget {
  final String supervisorId;

  final String? provinceId;
  final String? provinceName;

  final String? districtId;
  final String? districtName;

  final String? hamletId;
  final String? hamletName;

  final String? villageId;
  final String? villageName;

  const CustomerScreen({
    super.key,
    required this.supervisorId,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.hamletId,
    this.hamletName,
    this.villageId,
    this.villageName,
  });

  @override
  State<CustomerScreen> createState() =>
      _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController customerNoController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  // ============================================================
  // State
  // ============================================================

  bool loading = false;

  String? selectedCustomerId;

  String? usageTypeId;
  String? usageTypeName;

  static const Color primaryColor = Colors.blue;

  // ============================================================
  // MESSAGE
  // ============================================================

  void message(
    String text, {
    Color? color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor:
              color ?? primaryColor,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // NEW RECORD
  // ============================================================

  void prepareNewCustomer() {
    customerNoController.clear();
    nameController.clear();
    phoneController.clear();
    addressController.clear();

    if (!mounted) return;

    setState(() {
      selectedCustomerId = null;
      usageTypeId = null;
      usageTypeName = null;
    });
  }

  // ============================================================
  // PHONE EXISTS
  // ============================================================

  Future<bool> phoneExists(
    String phone, {
    String? exceptId,
  }) async {
    final result = await firestore
        .collection('customers')
        .where(
          'phone',
          isEqualTo: phone,
        )
        .limit(20)
        .get();

    for (final doc in result.docs) {
      if (exceptId == null ||
          doc.id != exceptId) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // GENERATE CUSTOMER NUMBER
  // ============================================================

  Future<String> generateCustomerNumber(
    Transaction transaction,
  ) async {
    final counterRef = firestore
        .collection('counters')
        .doc('customers');

    final snapshot =
        await transaction.get(counterRef);

    int nextNumber = 1;

    if (snapshot.exists) {
      final data = snapshot.data();

      if (data is Map<String, dynamic>) {
        final lastNumber =
            data['lastNumber'];

        if (lastNumber is int) {
          nextNumber =
              lastNumber + 1;
        } else if (lastNumber is num) {
          nextNumber =
              lastNumber.toInt() + 1;
        }
      }
    }

    transaction.set(
      counterRef,
      {
        'lastNumber': nextNumber,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return nextNumber.toString();
  }

  // ============================================================
  // WATER USAGE TYPE
  // ============================================================

  Widget waterTypeDropdown() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('water_usage_types')
          .orderBy('number')
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(15),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      primaryColor,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _errorBox(
            'حدث خطأ في تحميل أنواع استخدام المياه\n'
            '${snapshot.error}',
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _warningBox(
            'لا توجد أنواع استخدام مياه مسجلة',
          );
        }

        String? currentValue;

        if (usageTypeId != null &&
            docs.any(
              (doc) =>
                  doc.id == usageTypeId,
            )) {
          currentValue =
              usageTypeId;
        }

        return DropdownButtonFormField<
            String>(
          value: currentValue,
          isExpanded: true,
          decoration:
              InputDecoration(
            labelText:
                'نوع استخدام المياه',
            prefixIcon:
                const Icon(
              Icons.water_drop,
              color:
                  primaryColor,
            ),
            filled: true,
            fillColor:
                Colors.white,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  BorderSide(
                color: Colors
                    .grey.shade300,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    primaryColor,
                width: 2,
              ),
            ),
          ),
          items: docs.map(
            (doc) {
              final data =
                  doc.data();

              final name =
                  data['name']
                          ?.toString() ??
                      '';

              return DropdownMenuItem<
                  String>(
                value: doc.id,
                child: Text(
                  name,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: loading
              ? null
              : (value) {
                  if (value ==
                      null) {
                    return;
                  }

                  final doc =
                      docs.firstWhere(
                    (e) =>
                        e.id ==
                        value,
                  );

                  final data =
                      doc.data();

                  setState(() {
                    usageTypeId =
                        value;

                    usageTypeName =
                        data['name']
                            ?.toString();
                  });
                },
        );
      },
    );
  }

  // ============================================================
  // ERROR BOX
  // ============================================================

  Widget _errorBox(
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        color:
            Colors.red.withOpacity(
          .08,
        ),
        border: Border.all(
          color:
              Colors.red.withOpacity(
            .3,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              text,
              textDirection:
                  TextDirection.rtl,
              style:
                  const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WARNING BOX
  // ============================================================

  Widget _warningBox(
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        color:
            Colors.orange.withOpacity(
          .08,
        ),
        border: Border.all(
          color:
              Colors.orange.withOpacity(
            .3,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              text,
              textDirection:
                  TextDirection.rtl,
              style:
                  const TextStyle(
                color:
                    Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPERVISOR VILLAGE
  // ============================================================

  Widget supervisorVillageCard() {
    final villageName =
        widget.villageName?.trim();

    if (widget.villageId ==
            null ||
        widget.villageId!
            .trim()
            .isEmpty) {
      return _errorBox(
        'لم يتم تحديد قرية المشرف',
      );
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        color:
            primaryColor.withOpacity(
          .08,
        ),
        border: Border.all(
          color:
              primaryColor.withOpacity(
            .3,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color:
                primaryColor,
            size: 32,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'قرية المشرف',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  villageName ==
                              null ||
                          villageName
                              .isEmpty
                      ? 'غير محددة'
                      : villageName,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        primaryColor,
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
  // LOCATION INFO
  // ============================================================

  Widget locationInfo() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_on,
                color:
                    primaryColor,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                'معلومات الموقع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          _locationRow(
            'المحافظة',
            widget.provinceName,
          ),
          _locationRow(
            'المديرية',
            widget.districtName,
          ),
          _locationRow(
            'العزلة',
            widget.hamletName,
          ),
          _locationRow(
            'القرية',
            widget.villageName,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION ROW
  // ============================================================

  Widget _locationRow(
    String title,
    String? value,
  ) {
    final text =
        value == null ||
                value.trim().isEmpty
            ? 'غير محدد'
            : value;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 5,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
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
  // INPUT FIELD
  // ============================================================

  Widget inputField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextInputAction?
        textInputAction,
  }) {
    return TextField(
      controller:
          controller,
      readOnly:
          readOnly,
      keyboardType:
          keyboardType,
      maxLines:
          maxLines,
      textInputAction:
          textInputAction,
      textDirection:
          TextDirection.rtl,
      decoration:
          InputDecoration(
        labelText:
            label,
        prefixIcon:
            Icon(
          icon,
          color:
              primaryColor,
        ),
        filled: true,
        fillColor:
            readOnly
                ? Colors
                    .grey
                    .shade100
                : Colors.white,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
          borderSide:
              BorderSide(
            color: Colors
                .grey
                .shade300,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
          borderSide:
              const BorderSide(
            color:
                primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD CUSTOMER
  // ============================================================

  Future<void> addCustomer() async {
    if (loading) return;

    final name =
        nameController.text.trim();

    final phone =
        phoneController.text.trim();

    final address =
        addressController.text.trim();

    // ==========================================================
    // التحقق قبل تشغيل التحميل
    // ==========================================================

    if (widget.supervisorId
        .trim()
        .isEmpty) {
      message(
        'لم يتم تحديد المشرف',
        color: Colors.orange,
      );
      return;
    }

    if (widget.villageId ==
            null ||
        widget.villageId!
            .trim()
            .isEmpty) {
      message(
        'لم يتم تحديد قرية المشرف',
        color: Colors.orange,
      );
      return;
    }

    if (name.isEmpty) {
      message(
        'أدخل اسم الزبون',
        color: Colors.orange,
      );
      return;
    }

    if (phone.isEmpty) {
      message(
        'أدخل رقم الهاتف',
        color: Colors.orange,
      );
      return;
    }

    if (usageTypeId ==
            null ||
        usageTypeId!
            .trim()
            .isEmpty) {
      message(
        'اختر نوع استخدام المياه',
        color: Colors.orange,
      );
      return;
    }

    // ==========================================================
    // تشغيل التحميل
    //
    // الصفحة تبقى ظاهرة
    // ==========================================================

    setState(() {
      loading = true;
    });

    try {
      // ========================================================
      // منع تكرار الهاتف
      // ========================================================

      final exists =
          await phoneExists(
        phone,
      );

      if (exists) {
        message(
          'رقم الهاتف موجود مسبقاً',
          color: Colors.orange,
        );
        return;
      }

      // ========================================================
      // مرجع الزبون
      // ========================================================

      final customerRef =
          firestore
              .collection(
                'customers',
              )
              .doc();

      // ========================================================
      // Transaction
      // ========================================================

      await firestore
          .runTransaction(
        (transaction) async {
          final customerNo =
              await generateCustomerNumber(
            transaction,
          );

          transaction.set(
            customerRef,
            {
              // ------------------------------------------------
              // بيانات الزبون
              // ------------------------------------------------

              'customerNo':
                  customerNo,

              'name':
                  name,

              'phone':
                  phone,

              'address':
                  address,

              // ------------------------------------------------
              // المشرف
              // ------------------------------------------------

              'supervisorId':
                  widget
                      .supervisorId,

              // ------------------------------------------------
              // المحافظة
              // ------------------------------------------------

              'provinceId':
                  widget
                      .provinceId,

              'provinceName':
                  widget
                      .provinceName,

              // ------------------------------------------------
              // المديرية
              // ------------------------------------------------

              'districtId':
                  widget
                      .districtId,

              'districtName':
                  widget
                      .districtName,

              // ------------------------------------------------
              // العزلة
              // ------------------------------------------------

              'hamletId':
                  widget
                      .hamletId,

              'hamletName':
                  widget
                      .hamletName,

              // ------------------------------------------------
              // القرية
              // ------------------------------------------------

              'villageId':
                  widget
                      .villageId,

              'villageName':
                  widget
                      .villageName,

              // ------------------------------------------------
              // استخدام المياه
              // ------------------------------------------------

              'waterUsageTypeId':
                  usageTypeId,

              'waterUsageTypeName':
                  usageTypeName,

              // ------------------------------------------------
              // القراءات الابتدائية
              // ------------------------------------------------

              'previousReading':
                  0,

              'currentReading':
                  0,

              // ------------------------------------------------
              // الحساب
              // ------------------------------------------------

              'accountId':
                  null,

              // ------------------------------------------------
              // التاريخ
              // ------------------------------------------------

              'createdAt':
                  FieldValue
                      .serverTimestamp(),

              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );
        },
      );

      // ========================================================
      // نجاح
      // ========================================================

      message(
        'تم إضافة الزبون بنجاح',
        color: Colors.green,
      );

      // ========================================================
      // تنظيف النموذج
      // ========================================================

      prepareNewCustomer();

    } catch (e) {
      message(
        'حدث خطأ أثناء الإضافة:\n$e',
        color: Colors.red,
      );
    } finally {
      // ========================================================
      // إيقاف التحميل
      // ========================================================

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // UPDATE CUSTOMER
  // ============================================================

  Future<void> updateCustomer() async {
    if (loading) return;

    if (selectedCustomerId ==
        null) {
      message(
        'اختر زبوناً من القائمة أولاً',
        color: Colors.orange,
      );
      return;
    }

    final name =
        nameController.text.trim();

    final phone =
        phoneController.text.trim();

    final address =
        addressController.text.trim();

    if (name.isEmpty) {
      message(
        'أدخل اسم الزبون',
        color: Colors.orange,
      );
      return;
    }

    if (phone.isEmpty) {
      message(
        'أدخل رقم الهاتف',
        color: Colors.orange,
      );
      return;
    }

    if (usageTypeId ==
            null ||
        usageTypeId!
            .trim()
            .isEmpty) {
      message(
        'اختر نوع استخدام المياه',
        color: Colors.orange,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final exists =
          await phoneExists(
        phone,
        exceptId:
            selectedCustomerId,
      );

      if (exists) {
        message(
          'رقم الهاتف مستخدم لزبون آخر',
          color: Colors.orange,
        );
        return;
      }

      await firestore
          .collection(
            'customers',
          )
          .doc(
            selectedCustomerId,
          )
          .update({
        'name': name,
        'phone': phone,
        'address': address,
        'waterUsageTypeId':
            usageTypeId,
        'waterUsageTypeName':
            usageTypeName,
        'updatedAt':
            FieldValue
                .serverTimestamp(),
      });

      message(
        'تم تعديل بيانات الزبون بنجاح',
        color: Colors.green,
      );

      prepareNewCustomer();

    } catch (e) {
      message(
        'حدث خطأ أثناء التعديل:\n$e',
        color: Colors.red,
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
  // DELETE CUSTOMER
  // ============================================================

  Future<void> deleteCustomer() async {
    if (loading) return;

    if (selectedCustomerId ==
        null) {
      message(
        'اختر زبوناً من القائمة أولاً',
        color: Colors.orange,
      );
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child:
              AlertDialog(
            title:
                const Row(
              children: [
                Icon(
                  Icons
                      .warning_amber,
                  color:
                      Colors.red,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'تأكيد الحذف',
                ),
              ],
            ),
            content:
                const Text(
              'هل تريد حذف الزبون المحدد؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child:
                    const Text(
                  'إلغاء',
                  style:
                      TextStyle(
                    color:
                        primaryColor,
                  ),
                ),
              ),
              ElevatedButton
                  .icon(
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.red,
                  foregroundColor:
                      Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                icon:
                    const Icon(
                  Icons.delete,
                ),
                label:
                    const Text(
                  'حذف',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm !=
        true) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await firestore
          .collection(
            'customers',
          )
          .doc(
            selectedCustomerId,
          )
          .delete();

      message(
        'تم حذف الزبون بنجاح',
        color: Colors.green,
      );

      prepareNewCustomer();

    } catch (e) {
      message(
        'حدث خطأ أثناء الحذف:\n$e',
        color: Colors.red,
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
  // SELECT CUSTOMER
  // ============================================================

  void selectCustomer(
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data();

    setState(() {
      selectedCustomerId =
          doc.id;

      customerNoController
          .text =
          data['customerNo']
                  ?.toString() ??
              '';

      nameController.text =
          data['name']
                  ?.toString() ??
              '';

      phoneController.text =
          data['phone']
                  ?.toString() ??
              '';

      addressController.text =
          data['address']
                  ?.toString() ??
              '';

      usageTypeId =
          data[
                  'waterUsageTypeId']
              ?.toString();

      usageTypeName =
          data[
                  'waterUsageTypeName']
              ?.toString();
    });
  }

  // ============================================================
  // CUSTOMERS LIST
  // ============================================================

  Widget customersList() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: firestore
          .collection(
            'customers',
          )
          .where(
            'supervisorId',
            isEqualTo:
                widget.supervisorId,
          )
          .where(
            'villageId',
            isEqualTo:
                widget.villageId,
          )
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot
                .connectionState ==
            ConnectionState
                .waiting) {
          return const SizedBox(
            height: 180,
            child:
                Center(
              child:
                  CircularProgressIndicator(
                color:
                    primaryColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _errorBox(
            'حدث خطأ في تحميل الزبائن:\n'
            '${snapshot.error}',
          );
        }

        final docs =
            snapshot.data?.docs
                    .toList() ??
                [];

        if (docs.isEmpty) {
          return Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .all(
              25,
            ),
            child:
                const Column(
              children: [
                Icon(
                  Icons
                      .people_outline,
                  size: 55,
                  color:
                      Colors.grey,
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  'لا توجد زبائن مسجلين',
                  style:
                      TextStyle(
                    color:
                        Colors.grey,
                    fontSize:
                        16,
                  ),
                ),
              ],
            ),
          );
        }

        // ========================================================
        // ترتيب حسب رقم الزبون
        // ========================================================

        docs.sort(
          (a, b) {
            final aData =
                a.data();

            final bData =
                b.data();

            final aNo =
                int.tryParse(
                      aData[
                                  'customerNo']
                              ?.toString() ??
                          '',
                    ) ??
                    0;

            final bNo =
                int.tryParse(
                      bData[
                                  'customerNo']
                              ?.toString() ??
                          '',
                    ) ??
                    0;

            return aNo.compareTo(
              bNo,
            );
          },
        );

        return Column(
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    14,
                vertical:
                    12,
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
                border:
                    Border.all(
                  color: Colors
                      .grey
                      .shade300,
                ),
              ),
              child:
                  const Row(
                children: [
                  Icon(
                    Icons.people,
                    color:
                        primaryColor,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    'الزبائن المسجلون',
                    style:
                        TextStyle(
                      color:
                          primaryColor,
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ====================================================
            // LIST
            // ====================================================

            ListView.builder(
              shrinkWrap:
                  true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  docs.length,
              itemBuilder:
                  (
                context,
                index,
              ) {
                final doc =
                    docs[index];

                final data =
                    doc.data();

                final customerNo =
                    data[
                                'customerNo']
                            ?.toString() ??
                        '';

                final name =
                    data['name']
                            ?.toString() ??
                        '';

                final phone =
                    data['phone']
                            ?.toString() ??
                        '';

                final usage =
                    data[
                                'waterUsageTypeName']
                            ?.toString() ??
                        '';

                final selected =
                    selectedCustomerId ==
                        doc.id;

                return Card(
                  elevation:
                      selected
                          ? 5
                          : 2,
                  color:
                      selected
                          ? primaryColor
                              .withOpacity(
                              .10,
                            )
                          : Colors.white,
                  margin:
                      const EdgeInsets
                          .only(
                    bottom:
                        8,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                    side:
                        selected
                            ? const BorderSide(
                                color:
                                    primaryColor,
                                width:
                                    1.5,
                              )
                            : BorderSide
                                .none,
                  ),
                  child:
                      ListTile(
                    enabled:
                        !loading,
                    onTap:
                        loading
                            ? null
                            : () {
                                selectCustomer(
                                  doc,
                                );
                              },
                    leading:
                        CircleAvatar(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      child:
                          Text(
                        customerNo
                                .isEmpty
                            ? '?'
                            : customerNo,
                      ),
                    ),
                    title:
                        Text(
                      name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize:
                            16,
                      ),
                    ),
                    subtitle:
                        Text(
                      'الهاتف: $phone'
                      '${usage.isEmpty ? '' : '\nالاستخدام: $usage'}',
                    ),
                    isThreeLine:
                        usage.isNotEmpty,
                    trailing:
                        selected
                            ? const Icon(
                                Icons
                                    .check_circle,
                                color:
                                    primaryColor,
                              )
                            : const Icon(
                                Icons
                                    .arrow_forward_ios,
                                size:
                                    16,
                                color:
                                    Colors.grey,
                              ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget actionButtons() {
    return Row(
      children: [
        // ========================================================
        // ADD
        // ========================================================

        Expanded(
          child:
              ElevatedButton.icon(
            onPressed:
                loading
                    ? null
                    : addCustomer,
            icon:
                loading
                    ? const SizedBox(
                        width:
                            20,
                        height:
                            20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.add,
                      ),
            label:
                Text(
              loading
                  ? 'جاري الإضافة...'
                  : 'إضافة',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight
                        .bold,
              ),
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  primaryColor,
              foregroundColor:
                  Colors.white,
              disabledBackgroundColor:
                  primaryColor
                      .withOpacity(
                .55,
              ),
              disabledForegroundColor:
                  Colors.white,
              minimumSize:
                  const Size(
                0,
                50,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ========================================================
        // UPDATE
        // ========================================================

        Expanded(
          child:
              ElevatedButton.icon(
            onPressed:
                loading
                    ? null
                    : updateCustomer,
            icon:
                const Icon(
              Icons.edit,
            ),
            label:
                const Text(
              'تعديل',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight
                        .bold,
              ),
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  primaryColor,
              foregroundColor:
                  Colors.white,
              disabledBackgroundColor:
                  Colors.blue
                      .withOpacity(
                .35,
              ),
              disabledForegroundColor:
                  Colors.white,
              minimumSize:
                  const Size(
                0,
                50,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ========================================================
        // DELETE
        // ========================================================

        Expanded(
          child:
              ElevatedButton.icon(
            onPressed:
                loading
                    ? null
                    : deleteCustomer,
            icon:
                const Icon(
              Icons.delete,
            ),
            label:
                const Text(
              'حذف',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight
                        .bold,
              ),
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  Colors.red,
              foregroundColor:
                  Colors.white,
              disabledBackgroundColor:
                  Colors.red
                      .withOpacity(
                .35,
              ),
              disabledForegroundColor:
                  Colors.white,
              minimumSize:
                  const Size(
                0,
                50,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),
            ),
          ),
        ),
      ],
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
      child:
          Scaffold(
        backgroundColor:
            const Color(
          0xffF5F9FF,
        ),

        // ======================================================
        // APP BAR
        // ======================================================

        appBar:
            const MyAppBar(
          title:
              'إدارة الزبائن',
          icon:
              Icons.people,
        ),

        // ======================================================
        // BODY
        // ======================================================

        body:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .all(
            15,
          ),
          child:
              Column(
            children: [
              // ==================================================
              // VILLAGE
              // ==================================================

              supervisorVillageCard(),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // LOCATION
              // ==================================================

              locationInfo(),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // CUSTOMER NUMBER
              // ==================================================

              inputField(
                controller:
                    customerNoController,
                label:
                    'رقم الزبون',
                icon:
                    Icons.tag,
                readOnly:
                    true,
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // WATER TYPE
              // ==================================================

              waterTypeDropdown(),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // NAME
              // ==================================================

              inputField(
                controller:
                    nameController,
                label:
                    'اسم الزبون',
                icon:
                    Icons.person,
                textInputAction:
                    TextInputAction
                        .next,
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // PHONE
              // ==================================================

              inputField(
                controller:
                    phoneController,
                label:
                    'رقم الهاتف',
                icon:
                    Icons.phone,
                keyboardType:
                    TextInputType
                        .phone,
                textInputAction:
                    TextInputAction
                        .next,
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // ADDRESS
              // ==================================================

              inputField(
                controller:
                    addressController,
                label:
                    'العنوان',
                icon:
                    Icons.home,
                maxLines:
                    2,
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // BUTTONS
              // ==================================================

              actionButtons(),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // CUSTOMERS
              // ==================================================

              customersList(),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    customerNoController
        .dispose();

    nameController
        .dispose();

    phoneController
        .dispose();

    addressController
        .dispose();

    super.dispose();
  }
}