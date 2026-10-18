import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/my_app_bar.dart';

class VillagesScreen extends StatefulWidget {
  const VillagesScreen({super.key});

  @override
  State<VillagesScreen> createState() => _VillagesScreenState();
}

class _VillagesScreenState extends State<VillagesScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController villageController =
      TextEditingController();

  String? provinceId;
  String? provinceName;

  String? districtId;
  String? districtName;

  String? hamletId;
  String? hamletName;

  bool loading = false;

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // إضافة القرية
  // ============================================================

  Future<void> addVillage() async {
    final name = villageController.text.trim();

    if (provinceId == null) {
      showMessage("اختر المحافظة");
      return;
    }

    if (districtId == null) {
      showMessage("اختر المديرية");
      return;
    }

    if (hamletId == null) {
      showMessage("اختر العزلة");
      return;
    }

    if (name.isEmpty) {
      showMessage("أدخل اسم القرية");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ========================================================
      // التأكد من عدم تكرار القرية
      // ========================================================

      final existing = await firestore
          .collection("villages")
          .where(
            "hamletId",
            isEqualTo: hamletId,
          )
          .where(
            "name",
            isEqualTo: name,
          )
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        showMessage(
          "هذه القرية موجودة مسبقاً في نفس العزلة",
        );

        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        return;
      }

      // ========================================================
      // حفظ القرية
      // ========================================================

      await firestore.collection("villages").add({
        "name": name,

        "provinceId": provinceId,
        "provinceName": provinceName,

        "districtId": districtId,
        "districtName": districtName,

        "hamletId": hamletId,
        "hamletName": hamletName,

        "createdAt": FieldValue.serverTimestamp(),
      });

      villageController.clear();

      showMessage("تمت إضافة القرية بنجاح");
    } catch (e) {
      showMessage(
        "حدث خطأ أثناء إضافة القرية: $e",
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // ============================================================
  // اختيار المحافظة
  // ============================================================

  Widget provincesDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("provinces")
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل المحافظات",
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          value: provinceId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "اختر المحافظة",
            prefixIcon: const Icon(
              Icons.location_city,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

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
                doc.data() as Map<String, dynamic>;

            setState(() {
              provinceId = value;
              provinceName =
                  data["name"]?.toString();

              districtId = null;
              districtName = null;

              hamletId = null;
              hamletName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // اختيار المديرية
  // ============================================================

  Widget districtsDropdown() {
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
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل المديريات",
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          value: districtId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "اختر المديرية",
            prefixIcon: const Icon(
              Icons.map,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

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
                doc.data() as Map<String, dynamic>;

            setState(() {
              districtId = value;
              districtName =
                  data["name"]?.toString();

              hamletId = null;
              hamletName = null;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // اختيار العزلة
  // ============================================================

  Widget hamletsDropdown() {
    if (districtId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("hamlets")
          .where(
            "districtId",
            isEqualTo: districtId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            "حدث خطأ في تحميل العُزل",
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          value: hamletId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "اختر العزلة",
            prefixIcon: const Icon(
              Icons.home_work,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

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
                doc.data() as Map<String, dynamic>;

            setState(() {
              hamletId = value;
              hamletName =
                  data["name"]?.toString();
            });
          },
        );
      },
    );
  }

  // ============================================================
  // زر إضافة القرية
  // ============================================================

  Widget addButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : addVillage,
        icon: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.save,
              ),
        label: Text(
          loading
              ? "جاري الحفظ..."
              : "إضافة القرية",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // عرض القرى
  // ============================================================

  Widget villagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("villages")
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "حدث خطأ في تحميل القرى",
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "لا توجد قرى حتى الآن",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            final name =
                data["name"]?.toString() ?? "";

            final province =
                data["provinceName"]?.toString() ?? "";

            final district =
                data["districtName"]?.toString() ?? "";

            final hamlet =
                data["hamletName"]?.toString() ?? "";

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.purple.withOpacity(.12),
                  child: const Icon(
                    Icons.home,
                    color: Colors.purple,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding:
                      const EdgeInsets.only(top: 5),
                  child: Text(
                    "$province\n"
                    "$district - $hamlet",
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        // ======================================================
        // شريط العنوان الموحد
        // ======================================================

        appBar: const MyAppBar(
          title: "تهيئة القرى",
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ==================================================
              // المحافظة
              // ==================================================

              provincesDropdown(),

              const SizedBox(height: 12),

              // ==================================================
              // المديرية
              // ==================================================

              districtsDropdown(),

              if (districtId != null)
                const SizedBox(height: 12),

              // ==================================================
              // العزلة
              // ==================================================

              hamletsDropdown(),

              if (hamletId != null)
                const SizedBox(height: 12),

              // ==================================================
              // اسم القرية
              // ==================================================

              TextField(
                controller: villageController,
                textInputAction:
                    TextInputAction.done,
                decoration: InputDecoration(
                  labelText: "اسم القرية",
                  hintText: "أدخل اسم القرية",
                  prefixIcon: const Icon(
                    Icons.home,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // زر الحفظ
              // ==================================================

              addButton(),

              const SizedBox(height: 20),

              // ==================================================
              // عنوان القائمة
              // ==================================================

              Align(
                alignment:
                    Alignment.centerRight,
                child: Row(
                  children: [
                    const Icon(
                      Icons.list,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "القرى المسجلة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // قائمة القرى
              // ==================================================

              Expanded(
                child: villagesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // إغلاق الكنترولر
  // ============================================================

  @override
  void dispose() {
    villageController.dispose();
    super.dispose();
  }
}