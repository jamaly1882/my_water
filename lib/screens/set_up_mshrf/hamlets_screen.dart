import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/my_app_bar.dart';

class HamletsScreen extends StatefulWidget {
  const HamletsScreen({super.key});

  @override
  State<HamletsScreen> createState() =>
      _HamletsScreenState();
}

class _HamletsScreenState extends State<HamletsScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController hamletController =
      TextEditingController();

  String? provinceId;
  String? provinceName;

  String? districtId;
  String? districtName;

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
  // إضافة العزلة
  // ============================================================

  Future<void> addHamlet() async {
    if (loading) return;

    final name = hamletController.text.trim();

    if (provinceId == null ||
        provinceId!.trim().isEmpty) {
      showMessage("اختر المحافظة");
      return;
    }

    if (districtId == null ||
        districtId!.trim().isEmpty) {
      showMessage("اختر المديرية");
      return;
    }

    if (name.isEmpty) {
      showMessage("اكتب اسم العزلة");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await firestore.collection("hamlets").add({
        "name": name,
        "provinceId": provinceId,
        "provinceName": provinceName,
        "districtId": districtId,
        "districtName": districtName,
        "createdAt": FieldValue.serverTimestamp(),
      });

      hamletController.clear();

      if (mounted) {
        showMessage(
          "تمت إضافة العزلة بنجاح",
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          "حدث خطأ أثناء إضافة العزلة: $e",
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
  // اختيار المحافظة
  // ============================================================

  Widget provinceDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("provinces")
         
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              "حدث خطأ في تحميل المحافظات",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              "لا توجد محافظات",
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == provinceId,
        )
            ? provinceId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,

          decoration: const InputDecoration(
            labelText: "المحافظة",
            border: OutlineInputBorder(),

            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),

            prefixIcon: Icon(
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
                data["name"]?.toString() ?? "",
              ),
            );
          }).toList(),

          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              provinceId = value;

              provinceName =
                  data["name"]?.toString();

              districtId = null;
              districtName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // اختيار المديرية
  // ============================================================

  Widget districtDropdown() {
    if (provinceId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("districts")
          .where(
            "provinceId",
            isEqualTo: provinceId,
          )
          
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                color: mainColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              "حدث خطأ في تحميل المديريات",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              "لا توجد مديريات لهذه المحافظة",
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final validValue = docs.any(
          (doc) => doc.id == districtId,
        )
            ? districtId
            : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,

          decoration: const InputDecoration(
            labelText: "المديرية",
            border: OutlineInputBorder(),

            focusedBorder:
                OutlineInputBorder(
              borderSide: BorderSide(
                color: mainColor,
                width: 2,
              ),
            ),

            prefixIcon: Icon(
              Icons.location_city,
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
                data["name"]?.toString() ?? "",
              ),
            );
          }).toList(),

          onChanged: (value) {
            if (value == null) return;

            final doc = docs.firstWhere(
              (e) => e.id == value,
            );

            final data =
                doc.data()
                    as Map<String, dynamic>;

            setState(() {
              districtId = value;

              districtName =
                  data["name"]?.toString();
            });
          },
        );
      },
    );
  }

  // ============================================================
  // قائمة العزل
  // ============================================================

  Widget hamletsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("hamlets")
          .orderBy("name")
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: mainColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "حدث خطأ في تحميل العزل",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "لا توجد عزل مسجلة",
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
            final data =
                docs[index].data()
                    as Map<String, dynamic>;

            final name =
                data["name"]?.toString() ?? "";

            final province =
                data["provinceName"]
                        ?.toString() ??
                    "";

            final district =
                data["districtName"]
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
                    BorderRadius.circular(12),
              ),

              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      mainColor.withOpacity(.12),

                  child: const Icon(
                    Icons.home_work,
                    color: mainColor,
                  ),
                ),

                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                subtitle: Text(
                  "$province - $district",
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
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        appBar: const MyAppBar(
          title: "تهيئة العزل",
          showBackButton: true,
        ),

        body: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // المحافظة
              // ==================================================

              provinceDropdown(),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // المديرية
              // ==================================================

              districtDropdown(),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // اسم العزلة
              // ==================================================

              TextField(
                controller:
                    hamletController,

                textInputAction:
                    TextInputAction.done,

                decoration:
                    const InputDecoration(
                  labelText:
                      "اسم العزلة",

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
                    Icons.home_work,
                    color: mainColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // زر إضافة العزلة
              // نفس لون شريط العنوان
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : addHamlet,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        mainColor,

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        mainColor.withOpacity(
                      .5,
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
                        : "إضافة العزلة",

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
                  "العزل المسجلة",

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
                    hamletsList(),
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
    hamletController.dispose();

    super.dispose();
  }
}