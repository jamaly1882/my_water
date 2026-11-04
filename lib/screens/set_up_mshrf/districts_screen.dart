import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/my_app_bar.dart';

class DistrictsScreen extends StatefulWidget {
  const DistrictsScreen({super.key});

  @override
  State<DistrictsScreen> createState() =>
      _DistrictsScreenState();
}

class _DistrictsScreenState extends State<DistrictsScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController nameController =
      TextEditingController();

  String? selectedProvinceId;
  String? selectedProvinceName;

  bool loading = false;

  // ============================================================
  // لون الزر - نفس لون شريط العنوان
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  // ============================================================
  // إضافة المديرية
  // ============================================================

  Future<void> addDistrict() async {
    if (loading) return;

    final name =
        nameController.text.trim();

    if (selectedProvinceId == null ||
        selectedProvinceId!.trim().isEmpty) {
      showMessage("Choose governorate");
      return;
    }

    if (name.isEmpty) {
      showMessage("Enter the district name");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await firestore
          .collection("districts")
          .add({
        "name": name,
        "provinceId":
            selectedProvinceId,
        "provinceName":
            selectedProvinceName,
        "createdAt":
            FieldValue.serverTimestamp(),
      });

      nameController.clear();

      if (mounted) {
        showMessage(
          "District added",
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          "Could not add the district: $e",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // جلب المحافظات
  // ============================================================

  Widget provinceDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("provinces")
          .orderBy("name")
          .snapshots(),

      builder: (context, snapshot) {
        // ======================================================
        // تحميل
        // ======================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child:
                  CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        // ======================================================
        // خطأ
        // ======================================================

        if (snapshot.hasError) {
          return Container(
            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color:
                  Colors.red.withValues(alpha: .08),

              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: const Text(
              "Could not load governorates",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          );
        }

        // ======================================================
        // لا توجد محافظات
        // ======================================================

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return Container(
            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color:
                  Colors.orange.withValues(alpha: .08),

              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: const Text(
              "No governorates yet",
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          );
        }

        final docs =
            snapshot.data!.docs;

        // ======================================================
        // التأكد أن القيمة الحالية ما زالت موجودة
        // ======================================================

        final validValue = docs.any(
          (doc) =>
              doc.id ==
              selectedProvinceId,
        )
            ? selectedProvinceId
            : null;

        return DropdownButtonFormField<
            String>(
          value: validValue,

          isExpanded: true,

          decoration:
              const InputDecoration(
            labelText:
                "Choose governorate",

            border:
                OutlineInputBorder(),

            focusedBorder:
                OutlineInputBorder(
              borderSide:
                  BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),

            prefixIcon:
                Icon(
              Icons.location_on,
              color: mainColor,
            ),
          ),

          items: docs.map((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,

              child: Text(
                data["name"]
                        ?.toString() ??
                    "",
              ),
            );
          }).toList(),

          onChanged: (value) {
            if (value == null) return;

            final doc =
                docs.firstWhere(
              (element) =>
                  element.id ==
                  value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              selectedProvinceId =
                  value;

              selectedProvinceName =
                  data["name"]
                      ?.toString();
            });
          },
        );
      },
    );
  }

  // ============================================================
  // قائمة المديريات
  // ============================================================

  Widget districtsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("districts")
          .orderBy("name")
          .snapshots(),

      builder: (context, snapshot) {
        // ======================================================
        // تحميل
        // ======================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: mainColor,
            ),
          );
        }

        // ======================================================
        // خطأ
        // ======================================================

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Could not load districts",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          );
        }

        // ======================================================
        // لا توجد مديريات
        // ======================================================

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No districts yet",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          );
        }

        final docs =
            snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,

          itemBuilder:
              (context, index) {
            final data =
                docs[index].data()
                    as Map<String, dynamic>;

            final districtName =
                data["name"]
                        ?.toString() ??
                    "";

            final provinceName =
                data["provinceName"]
                        ?.toString() ??
                    "";

            return Card(
              elevation: 2,

              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: ListTile(
                // ==================================================
                // أيقونة المديرية
                // ==================================================

                leading: CircleAvatar(
                  backgroundColor:
                      mainColor.withValues(alpha: .12),

                  child: const Icon(
                    Icons.location_city,
                    color: mainColor,
                  ),
                ),

                // ==================================================
                // اسم المديرية
                // ==================================================

                title: Text(
                  districtName,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                // ==================================================
                // المحافظة
                // ==================================================

                subtitle: Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Expanded(
                      child: Text(
                        provinceName
                                .isEmpty
                            ? "No governorate selected"
                            : provinceName,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl,

      child: Scaffold(
        // ========================================================
        // خلفية الصفحة
        // ========================================================

        backgroundColor:
            const Color(0xffF5F9FF),

        // ========================================================
        // شريط العنوان
        // ========================================================

        appBar: const MyAppBar(
          title: "District setup",
          showBackButton: true,
        ),

        // ========================================================
        // المحتوى
        // ========================================================

        body: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // اختيار المحافظة
              // ==================================================

              provinceDropdown(),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // اسم المديرية
              // ==================================================

              TextField(
                controller:
                    nameController,

                textInputAction:
                    TextInputAction.done,

                decoration:
                    const InputDecoration(
                  labelText:
                      "District name",

                  border:
                      OutlineInputBorder(),

                  focusedBorder:
                      OutlineInputBorder(
                    borderSide:
                        BorderSide(
                      color: mainColor,
                      width: 2,
                    ),
                  ),

                  prefixIcon:
                      Icon(
                    Icons.location_city,
                    color: mainColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // زر الإضافة
              // نفس لون شريط العنوان
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : addDistrict,

                  style:
                      ElevatedButton
                          .styleFrom(
                    // ==========================================
                    // أزرق نفس لون شريط العنوان
                    // ==========================================

                    backgroundColor:
                        mainColor,

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        mainColor
                            .withValues(alpha: .5),

                    disabledForegroundColor:
                        Colors.white70,

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),

                  icon: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .add_location_alt,
                          color:
                              Colors.white,
                        ),

                  label: Text(
                    loading
                        ? "Saving…"
                        : "Add district",

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize: 16,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // عنوان القائمة
              // ==================================================

              const Align(
                alignment:
                    Alignment.centerRight,

                child: Text(
                  "Registered districts",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // القائمة
              // ==================================================

              Expanded(
                child:
                    districtsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // تنظيف
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }
}