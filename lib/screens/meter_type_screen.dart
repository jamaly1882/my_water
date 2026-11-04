import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

class EquipmentTypeScreen extends StatefulWidget {
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

  const EquipmentTypeScreen({
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
  State<EquipmentTypeScreen> createState() =>
      _EquipmentTypeScreenState();
}

class _EquipmentTypeScreenState
    extends State<EquipmentTypeScreen> {
  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  String? selectedId;

  String? selectedWellId;
  String? selectedWellName;

  bool loading = false;

  static const Color primaryColor = Colors.blue;

  bool get isEditing => selectedId != null;

  bool get hasFixedWell =>
      widget.wellId != null &&
      widget.wellId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    selectedWellId = widget.wellId;
    selectedWellName = widget.wellName;

    newRecord(
      keepWell: true,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();

    super.dispose();
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor:
              error ? Colors.red : Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // سجل جديد
  // ============================================================

  void newRecord({
    bool keepWell = false,
  }) {
    setState(() {
      selectedId = null;

      nameController.clear();
      priceController.clear();

      if (!keepWell) {
        selectedWellId = null;
        selectedWellName = null;
      } else {
        selectedWellId = widget.wellId;
        selectedWellName = widget.wellName;
      }
    });
  }

  // ============================================================
  // اختيار البئر
  // ============================================================

  Widget buildWellSelector() {
    // ------------------------------------------------------------
    // إذا كان البئر محددًا من الشاشة السابقة
    // ------------------------------------------------------------

    if (hasFixedWell) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.water,
                color: primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Well',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedWellName ??
                          widget.wellName ??
                          'Selected well',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

    // ------------------------------------------------------------
    // اختيار البئر يدويًا
    // ------------------------------------------------------------

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('wells')
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Could not load the wells',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: Colors.orange,
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No wells yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        String? currentValue;

        if (selectedWellId != null &&
            docs.any(
              (doc) =>
                  doc.id == selectedWellId,
            )) {
          currentValue = selectedWellId;
        }

        return Card(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: currentValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Well',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.water,
                  color: primaryColor,
                ),
              ),
              items: docs.map((doc) {
                final data = doc.data();

                final name =
                    data['name']?.toString() ??
                        data['wellName']?.toString() ??
                        'No name';

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    name,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: isEditing
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      final doc =
                          docs.firstWhere(
                        (item) =>
                            item.id == value,
                      );

                      final data =
                          doc.data();

                      final name =
                          data['name']
                                  ?.toString() ??
                              data['wellName']
                                  ?.toString() ??
                              'No name';

                      setState(() {
                        selectedWellId =
                            doc.id;
                        selectedWellName =
                            name;
                      });
                    },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // اسم نوع المعدة
  // ============================================================

  Widget nameField() {
    return TextField(
      controller: nameController,
      textInputAction:
          TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Meter type',
        hintText: 'e.g. Diesel',
        border: OutlineInputBorder(),
        prefixIcon: Icon(
          Icons.precision_manufacturing,
          color: primaryColor,
        ),
      ),
    );
  }

  // ============================================================
  // سعر الوحدة
  // ============================================================

  Widget priceField() {
    return TextField(
      controller: priceController,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textInputAction:
          TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Unit price',
        hintText: 'e.g. 130',
        border: OutlineInputBorder(),
        prefixIcon: Icon(
          Icons.payments,
          color: primaryColor,
        ),
        suffixText: 'YER',
      ),
    );
  }

  // ============================================================
  // حفظ سجل جديد
  // ============================================================

  Future<void> save() async {
    final name =
        nameController.text.trim();

    final priceText =
        priceController.text.trim();

    if (selectedWellId == null ||
        selectedWellId!.trim().isEmpty) {
      showMessage(
        'Choose the well',
        error: true,
      );
      return;
    }

    if (name.isEmpty) {
      showMessage(
        'Enter the meter type',
        error: true,
      );
      return;
    }

    if (priceText.isEmpty) {
      showMessage(
        'Enter the unit price',
        error: true,
      );
      return;
    }

    final price =
        double.tryParse(priceText);

    if (price == null ||
        price < 0) {
      showMessage(
        'Invalid unit price',
        error: true,
      );
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      // ==========================================================
      // إنشاء نوع المعدة
      //
      // مهم:
      // unitsCount موجود في قاعدة البيانات
      // لكنه لا يظهر للمستخدم ولا يتم طلب إدخاله.
      //
      // يبدأ من صفر، وبعد ذلك يتم تحديثه تلقائيًا
      // من شاشة القراءات.
      // ==========================================================

      await db.collection('meter_types').add({
        'name': name,
        'unitPrice': price,

        // --------------------------------------------------------
        // عدد الوحدات يبدأ من صفر
        // --------------------------------------------------------
        'unitsCount': 0,

        'wellId': selectedWellId,
        'wellName': selectedWellName,

        'supervisorId':
            widget.supervisorId,

        'provinceId':
            widget.provinceId,

        'provinceName':
            widget.provinceName,

        'districtId':
            widget.districtId,

        'districtName':
            widget.districtName,

        'hamletId':
            widget.hamletId,

        'hamletName':
            widget.hamletName,

        'villageId':
            widget.villageId,

        'villageName':
            widget.villageName,

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage(
        'Meter type added',
      );

      newRecord(
        keepWell: true,
      );
    } catch (e) {
      showMessage(
        'حدث خطأ أثناء الحفظ:\n$e',
        error: true,
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
  // تحديث
  // ============================================================

  Future<void> update() async {
    if (selectedId == null) {
      return;
    }

    final name =
        nameController.text.trim();

    final priceText =
        priceController.text.trim();

    if (selectedWellId == null ||
        selectedWellId!.trim().isEmpty) {
      showMessage(
        'Choose the well',
        error: true,
      );
      return;
    }

    if (name.isEmpty) {
      showMessage(
        'Enter the meter type',
        error: true,
      );
      return;
    }

    if (priceText.isEmpty) {
      showMessage(
        'Enter the unit price',
        error: true,
      );
      return;
    }

    final price =
        double.tryParse(priceText);

    if (price == null ||
        price < 0) {
      showMessage(
        'Invalid unit price',
        error: true,
      );
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      // ==========================================================
      // مهم جداً:
      //
      // لا نرسل unitsCount هنا.
      //
      // لأن unitsCount يتم حسابه وتحديثه تلقائيًا
      // من عمليات استهلاك المياه.
      // ==========================================================

      await db
          .collection('meter_types')
          .doc(selectedId)
          .update({
        'name': name,
        'unitPrice': price,

        // لا نغير unitsCount

        'wellId': selectedWellId,
        'wellName': selectedWellName,

        'supervisorId':
            widget.supervisorId,

        'provinceId':
            widget.provinceId,

        'provinceName':
            widget.provinceName,

        'districtId':
            widget.districtId,

        'districtName':
            widget.districtName,

        'hamletId':
            widget.hamletId,

        'hamletName':
            widget.hamletName,

        'villageId':
            widget.villageId,

        'villageName':
            widget.villageName,

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage(
        'Meter type updated',
      );

      newRecord(
        keepWell: true,
      );
    } catch (e) {
      showMessage(
        'حدث خطأ أثناء التعديل:\n$e',
        error: true,
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
  // حذف
  // ============================================================

  Future<void> delete() async {
    if (selectedId == null) {
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Confirm delete',
          ),
          content: const Text(
            'Delete the selected meter type?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      await db
          .collection('meter_types')
          .doc(selectedId)
          .delete();

      if (!mounted) return;

      showMessage(
        'Meter type deleted',
      );

      newRecord(
        keepWell: true,
      );
    } catch (e) {
      showMessage(
        'حدث خطأ أثناء الحذف:\n$e',
        error: true,
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
  // بطاقة النموذج
  // ============================================================

  Widget formCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isEditing
                      ? Icons.edit
                      : Icons.add_circle,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'Edit meter type'
                        : 'Add meter type',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Align(
              alignment:
                  Alignment.centerRight,
              child: Text(
                'Pick the well, the meter type and the price',
                style: TextStyle(
                  color:
                      Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // البئر
            buildWellSelector(),

            // نوع المعدة
            nameField(),

            const SizedBox(height: 12),

            // السعر
            priceField(),

            // ==================================================
            // لا يوجد هنا حقل unitsCount
            //
            // يتم تخزينه في Firestore تلقائيًا بقيمة 0
            // عند إنشاء النوع، ثم يتم تحديثه لاحقًا تلقائيًا.
            // ==================================================

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            if (isEditing) {
                              update();
                            } else {
                              save();
                            }
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : Icon(
                            isEditing
                                ? Icons.save
                                : Icons.add,
                          ),
                    label: Text(
                      isEditing
                          ? 'Save changes'
                          : 'Add',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                if (isEditing) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () {
                              newRecord(
                                keepWell: true,
                              );
                            },
                      icon: const Icon(
                        Icons.clear,
                      ),
                      label: const Text(
                        'Cancel',
                      ),
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            Colors.grey
                                .shade700,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (isEditing) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Delete meter type',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // قراءة السعر
  // ============================================================

  double readPrice(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // قراءة عدد الوحدات
  // ============================================================

  int readUnitsCount(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // تنسيق السعر
  // ============================================================

  String formatPrice(
    double value,
  ) {
    if (value == value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(
          RegExp(r'\.?0+$'),
          '',
        );
  }

  // ============================================================
  // قائمة أنواع المعدات
  // ============================================================

  Widget buildList() {
    Query<Map<String, dynamic>> query =
        db.collection('meter_types');

    if (hasFixedWell) {
      query = query.where(
        'wellId',
        isEqualTo: widget.wellId,
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child:
                  CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 45,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Could not load the meter types',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.precision_manufacturing_outlined,
                    color: Colors.orange,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No meter types yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasFixedWell
                        ? 'No meter types on this well'
                        : 'Add a new meter type',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 20,
          ),
          itemCount: docs.length,
          itemBuilder: (
            context,
            index,
          ) {
            final doc = docs[index];

            final data = doc.data();

            final name =
                data['name']?.toString() ??
                    'No name';

            final price =
                readPrice(
              data['unitPrice'],
            );

            // ----------------------------------------------------
            // unitsCount موجود في قاعدة البيانات
            // ويتم عرضه هنا للقراءة فقط.
            //
            // لا يوجد حقل لإدخاله أو تعديله في النموذج.
            // ----------------------------------------------------

            final unitsCount =
                readUnitsCount(
              data['unitsCount'],
            );

            final wellName =
                data['wellName']
                        ?.toString() ??
                    '';

            final isSelected =
                selectedId == doc.id;

            return Card(
              elevation:
                  isSelected ? 3 : 1,
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                onTap: () {
                  setState(() {
                    selectedId = doc.id;

                    nameController.text =
                        name;

                    priceController.text =
                        price.toString();

                    selectedWellId =
                        data['wellId']
                            ?.toString();

                    selectedWellName =
                        wellName.isNotEmpty
                            ? wellName
                            : null;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration:
                                BoxDecoration(
                              color: primaryColor
                                  .withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing,
                              color:
                                  primaryColor,
                            ),
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
                                Text(
                                  name,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                if (wellName
                                    .isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets
                                            .only(
                                      top: 4,
                                    ),
                                    child: Text(
                                      wellName,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                        fontSize:
                                            12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.edit_outlined,
                            color:
                                Colors.grey,
                          ),
                        ],
                      ),

                      const Divider(
                        height: 24,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _infoItem(
                              icon:
                                  Icons.payments,
                              title:
                                  'Unit price',
                              value:
                                  '${formatPrice(price)} YER',
                            ),
                          ),

                          Expanded(
                            child: _infoItem(
                              icon:
                                  Icons
                                      .calculate_outlined,
                              title:
                                  'Running balance',
                              value:
                                  unitsCount
                                      .toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // عنصر معلومات
  // ============================================================

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryColor,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const MyAppBar(
          title:
              'Meter types and prices setup',
          icon: Icons.precision_manufacturing,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              formCard(),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Align(
                  alignment:
                      Alignment.centerRight,
                  child: Text(
                    'Registered meter types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              buildList(),
            ],
          ),
        ),
      ),
    );
  }
}