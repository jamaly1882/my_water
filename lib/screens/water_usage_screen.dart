import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';

class WaterUsageScreen extends StatefulWidget {
  const WaterUsageScreen({super.key});

  @override
  State<WaterUsageScreen> createState() =>
      _WaterUsageScreenState();
}

class _WaterUsageScreenState
    extends State<WaterUsageScreen> {
  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  final TextEditingController nameController =
      TextEditingController();

  String? selectedId;

  bool loading = false;

  // ============================================================
  // اللون الرئيسي
  // نفس لون MyAppBar
  // ============================================================

  static const Color primaryColor = Colors.blue;

  // ============================================================
  // تهيئة
  // ============================================================

  @override
  void initState() {
    super.initState();
    newRecord();
  }

  // ============================================================
  // سجل جديد
  // ============================================================

  void newRecord() {
    nameController.clear();
    selectedId = null;

    if (mounted) {
      setState(() {});
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
  // إضافة
  // ============================================================

  Future<void> save() async {
    if (loading) return;

    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'أدخل اسم نوع استخدام المياه',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await db
          .collection('water_usage_types')
          .add({
        'name': name,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      newRecord();

      showMessage(
        'تمت إضافة نوع استخدام المياه بنجاح',
      );
    } catch (e) {
      showMessage(
        'حدث خطأ أثناء الإضافة:\n$e',
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
  // تعديل
  // ============================================================

  Future<void> update() async {
    if (loading) return;

    if (selectedId == null) {
      showMessage(
        'اختر نوع استخدام المياه أولاً',
      );
      return;
    }

    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'أدخل اسم نوع استخدام المياه',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await db
          .collection('water_usage_types')
          .doc(selectedId)
          .update({
        'name': name,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      newRecord();

      showMessage(
        'تم تعديل نوع استخدام المياه بنجاح',
      );
    } catch (e) {
      showMessage(
        'حدث خطأ أثناء التعديل:\n$e',
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
    if (loading) return;

    if (selectedId == null) {
      showMessage(
        'اختر نوع استخدام المياه أولاً',
      );
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  'تأكيد الحذف',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'هل تريد حذف نوع استخدام المياه المحدد؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text(
                  'إلغاء',
                ),
              ),
              ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
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
                icon: const Icon(
                  Icons.delete,
                ),
                label: const Text(
                  'حذف',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await db
          .collection('water_usage_types')
          .doc(selectedId)
          .delete();

      newRecord();

      showMessage(
        'تم حذف نوع استخدام المياه بنجاح',
      );
    } catch (e) {
      showMessage(
        'حدث خطأ أثناء الحذف:\n$e',
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
  // حقل الاسم
  // ============================================================

  Widget nameField() {
    return TextField(
      controller: nameController,
      textDirection:
          TextDirection.rtl,
      textInputAction:
          TextInputAction.done,
      decoration:
          InputDecoration(
        labelText:
            'اسم نوع استخدام المياه',
        hintText:
            'مثال: منزلي، تجاري، حكومي',
        prefixIcon:
            const Icon(
          Icons.water_drop,
          color: primaryColor,
        ),
        filled: true,
        fillColor: Colors.white,
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
            color:
                Colors.grey.shade300,
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
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة النموذج
  // ============================================================

  Widget formCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [
            // ==================================================
            // العنوان
            // ==================================================

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        primaryColor
                            .withOpacity(
                      0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons.water_drop,
                    color:
                        primaryColor,
                    size: 27,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'بيانات نوع الاستخدام',
                        style:
                            TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        'إضافة أو تعديل نوع استخدام المياه',
                        style:
                            TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // الاسم
            // ==================================================

            nameField(),

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // إضافة + تعديل
            // ==================================================

            Row(
              children: [
                // ==================================================
                // إضافة
                // ==================================================

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : save,
                    icon:
                        loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.add,
                              ),
                    label:
                        const Text(
                      'إضافة',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    // نفس لون MyAppBar
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size(
                        0,
                        52,
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
                  width: 10,
                ),

                // ==================================================
                // تعديل
                // ==================================================

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : update,
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
                            FontWeight.bold,
                      ),
                    ),

                    // نفس لون MyAppBar
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size(
                        0,
                        52,
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
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // جديد + حذف
            // ==================================================

            Row(
              children: [
                // ==================================================
                // جديد
                // ==================================================

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : newRecord,
                    icon:
                        const Icon(
                      Icons.add_circle_outline,
                    ),
                    label:
                        const Text(
                      'جديد',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          primaryColor,
                      minimumSize:
                          const Size(
                        0,
                        52,
                      ),
                      side:
                          const BorderSide(
                        color:
                            primaryColor,
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
                  width: 10,
                ),

                // ==================================================
                // حذف
                // ==================================================

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : delete,
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
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.red,
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size(
                        0,
                        52,
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
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // عنوان القائمة
  // نفس لون MyAppBar
  // ============================================================

  Widget listHeader() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color: primaryColor,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.list_alt,
            color:
                Colors.white,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            'أنواع استخدام المياه المسجلة',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // القائمة
  // ============================================================

  Widget buildList() {
    return Expanded(
      child: StreamBuilder<
          QuerySnapshot>(
        stream: db
            .collection(
              'water_usage_types',
            )
            .snapshots(),
        builder:
            (context, snapshot) {
          // ==================================================
          // تحميل
          // ==================================================

          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          // ==================================================
          // خطأ
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ:\n${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          // ==================================================
          // لا توجد بيانات
          // ==================================================

          if (!snapshot.hasData ||
              snapshot.data!.docs
                  .isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Icon(
                    Icons
                        .water_drop_outlined,
                    size: 70,
                    color:
                        Colors.grey,
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    'لا توجد أنواع استخدام مياه مسجلة',
                    style:
                        TextStyle(
                      fontSize: 16,
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs =
              snapshot.data!.docs;

          // ==================================================
          // القائمة
          // ==================================================

          return ListView.builder(
            itemCount:
                docs.length,
            itemBuilder:
                (context, index) {
              final doc =
                  docs[index];

              final data =
                  doc.data()
                      as Map<
                          String,
                          dynamic>;

              final name =
                  data['name']
                          ?.toString() ??
                      '';

              final isSelected =
                  selectedId ==
                      doc.id;

              return Card(
                elevation:
                    isSelected
                        ? 5
                        : 2,
                color: isSelected
                    ? primaryColor
                        .withOpacity(
                        0.10,
                      )
                    : Colors.white,
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 8,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  side: isSelected
                      ? const BorderSide(
                          color:
                              primaryColor,
                          width: 1.5,
                        )
                      : BorderSide
                          .none,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),

                  // ==================================================
                  // الأيقونة
                  // ==================================================

                  leading:
                      CircleAvatar(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                    child:
                        const Icon(
                      Icons.water_drop,
                    ),
                  ),

                  // ==================================================
                  // الاسم
                  // ==================================================

                  title: Text(
                    name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  subtitle:
                      const Text(
                    'نوع استخدام المياه',
                  ),

                  // ==================================================
                  // الاختيار
                  // ==================================================

                  trailing:
                      isSelected
                          ? const Icon(
                              Icons
                                  .check_circle,
                              color:
                                  primaryColor,
                            )
                          : const Icon(
                              Icons
                                  .arrow_forward_ios,
                              size: 16,
                              color:
                                  Colors.grey,
                            ),

                  onTap: () {
                    setState(() {
                      selectedId =
                          doc.id;

                      nameController
                              .text =
                          name;
                    });
                  },
                ),
              );
            },
          );
        },
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
        // MyAppBar
        // اللون Colors.blue
        // ======================================================

        appBar:
            const MyAppBar(
          title:
              'تهيئة أنواع استخدام المياه',
          icon:
              Icons.water_drop,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body: Padding(
          padding:
              const EdgeInsets.all(
            15,
          ),
          child: Column(
            children: [
              // ==================================================
              // النموذج
              // ==================================================

              formCard(),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // عنوان القائمة
              // ==================================================

              listHeader(),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // القائمة
              // ==================================================

              buildList(),
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
    nameController.dispose();
    super.dispose();
  }
}