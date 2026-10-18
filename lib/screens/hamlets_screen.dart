import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HamletsScreen extends StatefulWidget {
  const HamletsScreen({super.key});

  @override
  State<HamletsScreen> createState() => _HamletsScreenState();
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
  // إضافة العزلة
  // ============================================================

  Future<void> addHamlet() async {
    final name = hamletController.text.trim();

    if (provinceId == null) {
      showMessage("اختر المحافظة");
      return;
    }

    if (districtId == null) {
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

      if (!mounted) return;

      hamletController.clear();

      setState(() {
        loading = false;
      });

      showMessage("تمت إضافة العزلة بنجاح");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        "حدث خطأ أثناء إضافة العزلة:\n$e",
      );
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // عرض خطأ Firestore
  // ============================================================

  Widget errorWidget(Object? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Text(
        "حدث خطأ في تحميل البيانات:\n$error",
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 13,
        ),
      ),
    );
  }

  // ============================================================
  // Loading
  // ============================================================

  Widget loadingWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // ============================================================
  // Dropdown المحافظة
  // ============================================================

  Widget buildProvinceDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("provinces")
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error);
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return loadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text(
            "لا توجد محافظات",
            style: TextStyle(
              color: Colors.red,
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: provinceId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "اختر المحافظة",
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.location_on,
              color: Colors.blue,
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

              // عند تغيير المحافظة
              // نحذف اختيار المديرية القديمة
              districtId = null;
              districtName = null;
            });

            debugPrint(
              "================================",
            );
            debugPrint(
              "تم اختيار المحافظة",
            );
            debugPrint(
              "provinceId = $provinceId",
            );
            debugPrint(
              "provinceName = $provinceName",
            );
            debugPrint(
              "================================",
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Dropdown المديريات
  // ============================================================

  Widget buildDistrictDropdown() {
    if (provinceId == null) {
      return const SizedBox();
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
        if (snapshot.hasError) {
          return errorWidget(snapshot.error);
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return loadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        debugPrint(
          "================================",
        );
        debugPrint(
          "تحميل المديريات",
        );
        debugPrint(
          "provinceId = $provinceId",
        );
        debugPrint(
          "عدد المديريات = ${docs.length}",
        );
        debugPrint(
          "================================",
        );

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: Text(
              "لا توجد مديريات لهذه المحافظة.\n\n"
              "المحافظة: $provinceName\n"
              "ID المحافظة: $provinceId\n\n"
              "تأكد أن مستندات districts تحتوي على:\n"
              "provinceId = $provinceId",
              style: TextStyle(
                color: Colors.orange.shade900,
              ),
            ),
          );
        }

        final districtExists = docs.any(
          (doc) => doc.id == districtId,
        );

        return DropdownButtonFormField<String>(
          value: districtExists
              ? districtId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "اختر المديرية",
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.location_city,
              color: Colors.blue,
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
            });

            debugPrint(
              "تم اختيار المديرية",
            );
            debugPrint(
              "districtId = $districtId",
            );
            debugPrint(
              "districtName = $districtName",
            );
          },
        );
      },
    );
  }

  // ============================================================
  // حقل اسم العزلة
  // ============================================================

  Widget buildHamletField() {
    return TextField(
      controller: hamletController,
      textDirection: TextDirection.rtl,
      decoration: const InputDecoration(
        labelText: "اسم العزلة",
        hintText: "مثال: عزلة بني فلان",
        border: OutlineInputBorder(),
        prefixIcon: Icon(
          Icons.home_work,
          color: Colors.blue,
        ),
      ),
    );
  }

  // ============================================================
  // زر الإضافة
  // ============================================================

  Widget buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            loading ? null : addHamlet,
        icon: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child:
                    CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          loading
              ? "جاري الحفظ..."
              : "إضافة العزلة",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // قائمة العزل
  // ============================================================

  Widget buildHamletsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("hamlets")
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error);
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "لا توجد عزل مسجلة",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

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
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_work,
                    color: Colors.blue,
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
                subtitle: Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Text(
                    "$province - $district",
                    style: const TextStyle(
                      height: 1.5,
                    ),
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
  // Dispose
  // ============================================================

  @override
  void dispose() {
    hamletController.dispose();
    super.dispose();
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "تهيئة العزل",
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                // ================================================
                // المحافظة
                // ================================================

                buildProvinceDropdown(),

                const SizedBox(height: 15),

                // ================================================
                // المديرية
                // ================================================

                buildDistrictDropdown(),

                const SizedBox(height: 15),

                // ================================================
                // اسم العزلة
                // ================================================

                buildHamletField(),

                const SizedBox(height: 15),

                // ================================================
                // زر الإضافة
                // ================================================

                buildAddButton(),

                const SizedBox(height: 20),

                // ================================================
                // عنوان القائمة
                // ================================================

                Row(
                  children: [
                    const Icon(
                      Icons.home_work,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "العزل المسجلة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================================================
                // القائمة
                // ================================================

                Expanded(
                  child:
                      buildHamletsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}