import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/my_app_bar.dart';

class ProvincesScreen extends StatefulWidget {
  const ProvincesScreen({super.key});

  @override
  State<ProvincesScreen> createState() =>
      _ProvincesScreenState();
}

class _ProvincesScreenState extends State<ProvincesScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController nameController =
      TextEditingController();

  bool loading = false;

  // ============================================================
  // اللون الموحد مع MyAppBar
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
  // إضافة المحافظة
  // ============================================================

  Future<void> addProvince() async {
    if (loading) return;

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage("أدخل اسم المحافظة");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await firestore.collection("provinces").add({
        "name": name,
        "createdAt": FieldValue.serverTimestamp(),
      });

      nameController.clear();

      if (mounted) {
        showMessage(
          "تمت إضافة المحافظة بنجاح",
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          "حدث خطأ أثناء إضافة المحافظة: $e",
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
  // قائمة المحافظات
  // ============================================================

  Widget provincesList() {
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
            child: CircularProgressIndicator(
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
              "حدث خطأ في تحميل المحافظات",
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
          return const Center(
            child: Text(
              "لا توجد محافظات",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,

          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final name =
                data["name"]?.toString() ?? "";

            return Card(
              elevation: 2,

              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: ListTile(
                // ==================================================
                // أيقونة المحافظة
                // ==================================================

                leading: CircleAvatar(
                  backgroundColor:
                      mainColor.withOpacity(.12),

                  child: const Icon(
                    Icons.map,
                    color: mainColor,
                  ),
                ),

                // ==================================================
                // اسم المحافظة
                // ==================================================

                title: Text(
                  name,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
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
        // شريط العنوان الموحد
        // ========================================================

        appBar: const MyAppBar(
          title: "تهيئة المحافظات",
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
              // اسم المحافظة
              // ==================================================

              TextField(
                controller:
                    nameController,

                textInputAction:
                    TextInputAction.done,

                decoration:
                    InputDecoration(
                  labelText:
                      "اسم المحافظة",

                  prefixIcon:
                      const Icon(
                    Icons.location_city,
                    color: mainColor,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
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
                      color: mainColor,
                      width: 2,
                    ),
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
                          : addProvince,

                  style:
                      ElevatedButton.styleFrom(
                    // ==========================================
                    // الأزرق نفس لون شريط العنوان
                    // ==========================================

                    backgroundColor:
                        mainColor,

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        mainColor.withOpacity(
                      0.5,
                    ),

                    disabledForegroundColor:
                        Colors.white70,

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
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
                        ? "جاري الحفظ..."
                        : "إضافة المحافظة",

                    style:
                        const TextStyle(
                      color: Colors.white,
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
                  "المحافظات المسجلة",

                  style:
                      TextStyle(
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
              // قائمة المحافظات
              // ==================================================

              Expanded(
                child:
                    provincesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // dispose
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }
}