import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WellsScreen extends StatefulWidget {
  const WellsScreen({super.key});

  @override
  State<WellsScreen> createState() => _WellsScreenState();
}

class _WellsScreenState extends State<WellsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController wellController = TextEditingController();

  String? provinceId;
  String? provinceName;

  String? districtId;
  String? districtName;

  String? hamletId;
  String? hamletName;

  String? villageId;
  String? villageName;

  bool loading = false;

  // ============================================================
  // إضافة البئر
  // ============================================================

  Future<void> addWell() async {
    final name = wellController.text.trim();

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

    if (villageId == null) {
      showMessage("اختر القرية");
      return;
    }

    if (name.isEmpty) {
      showMessage("اكتب اسم أو رقم البئر");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await firestore.collection("wells").add({
        "name": name,

        "provinceId": provinceId,
        "provinceName": provinceName,

        "districtId": districtId,
        "districtName": districtName,

        "hamletId": hamletId,
        "hamletName": hamletName,

        "villageId": villageId,
        "villageName": villageName,

        "createdAt": FieldValue.serverTimestamp(),
      });

      wellController.clear();

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage("تمت إضافة البئر بنجاح");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage("حدث خطأ أثناء إضافة البئر:\n$e");
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
  // Dropdown Error
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
  // المحافظة
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text(
            "لا توجد محافظات",
            style: TextStyle(color: Colors.red),
          );
        }

        return DropdownButtonFormField<String>(
          value: provinceId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "اختر المحافظة",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ?? "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final selectedDoc = docs.firstWhere(
              (doc) => doc.id == value,
            );

            final data =
                selectedDoc.data() as Map<String, dynamic>;

            setState(() {
              provinceId = value;
              provinceName = data["name"]?.toString();

              // تصفير المديريات التابعة
              districtId = null;
              districtName = null;

              // تصفير العزلات
              hamletId = null;
              hamletName = null;

              // تصفير القرى
              villageId = null;
              villageName = null;
            });

            debugPrint("================================");
            debugPrint("Province selected");
            debugPrint("provinceId = $provinceId");
            debugPrint("provinceName = $provinceName");
            debugPrint("================================");
          },
        );
      },
    );
  }

  // ============================================================
  // المديرية
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
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        debugPrint(
          "Districts loaded: ${docs.length}",
        );

        debugPrint(
          "Searching provinceId: $provinceId",
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
              "لا توجد مديريات مرتبطة بالمحافظة:\n$provinceName\n\n"
              "تأكد أن حقل provinceId داخل مجموعة districts "
              "يساوي ID المحافظة.",
              style: TextStyle(
                color: Colors.orange.shade900,
              ),
            ),
          );
        }

        // إذا كانت المديرية الحالية لم تعد موجودة
        final districtExists = docs.any(
          (doc) => doc.id == districtId,
        );

        if (!districtExists && districtId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                districtId = null;
                districtName = null;
                hamletId = null;
                hamletName = null;
                villageId = null;
                villageName = null;
              });
            }
          });
        }

        return DropdownButtonFormField<String>(
          value: districtExists ? districtId : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "اختر المديرية",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ?? "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final selectedDoc = docs.firstWhere(
              (doc) => doc.id == value,
            );

            final data =
                selectedDoc.data() as Map<String, dynamic>;

            setState(() {
              districtId = value;
              districtName = data["name"]?.toString();

              hamletId = null;
              hamletName = null;

              villageId = null;
              villageName = null;
            });

            debugPrint("District selected");
            debugPrint("districtId = $districtId");
            debugPrint("districtName = $districtName");
          },
        );
      },
    );
  }

  // ============================================================
  // العزلة
  // ============================================================

  Widget buildHamletDropdown() {
    if (districtId == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("hamlets")
          .where(
            "districtId",
            isEqualTo: districtId,
          )
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "لا توجد عزل مرتبطة بالمديرية:\n$districtName",
              style: TextStyle(
                color: Colors.orange.shade900,
              ),
            ),
          );
        }

        final hamletExists = docs.any(
          (doc) => doc.id == hamletId,
        );

        return DropdownButtonFormField<String>(
          value: hamletExists ? hamletId : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "اختر العزلة",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_tree),
          ),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ?? "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final selectedDoc = docs.firstWhere(
              (doc) => doc.id == value,
            );

            final data =
                selectedDoc.data() as Map<String, dynamic>;

            setState(() {
              hamletId = value;
              hamletName = data["name"]?.toString();

              villageId = null;
              villageName = null;
            });

            debugPrint("Hamlet selected");
            debugPrint("hamletId = $hamletId");
          },
        );
      },
    );
  }

  // ============================================================
  // القرية
  // ============================================================

  Widget buildVillageDropdown() {
    if (hamletId == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("villages")
          .where(
            "hamletId",
            isEqualTo: hamletId,
          )
          .orderBy("name")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "لا توجد قرى مرتبطة بالعزلة:\n$hamletName",
              style: TextStyle(
                color: Colors.orange.shade900,
              ),
            ),
          );
        }

        final villageExists = docs.any(
          (doc) => doc.id == villageId,
        );

        return DropdownButtonFormField<String>(
          value: villageExists ? villageId : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "اختر القرية",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_work),
          ),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                data["name"]?.toString() ?? "",
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final selectedDoc = docs.firstWhere(
              (doc) => doc.id == value,
            );

            final data =
                selectedDoc.data() as Map<String, dynamic>;

            setState(() {
              villageId = value;
              villageName = data["name"]?.toString();
            });

            debugPrint("Village selected");
            debugPrint("villageId = $villageId");
          },
        );
      },
    );
  }

  // ============================================================
  // حقل اسم البئر
  // ============================================================

  Widget buildWellField() {
    return TextField(
      controller: wellController,
      textDirection: TextDirection.rtl,
      decoration: const InputDecoration(
        labelText: "اسم / رقم البئر",
        hintText: "مثال: بئر رقم 1",
        border: OutlineInputBorder(),
        prefixIcon: Icon(
          Icons.water_drop,
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
        onPressed: loading ? null : addWell,
        icon: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          loading ? "جاري الحفظ..." : "إضافة البئر",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // عرض الآبار
  // ============================================================

  Widget buildWellsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("wells")
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
              "لا توجد آبار",
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
                docs[index].data() as Map<String, dynamic>;

            final name =
                data["name"]?.toString() ?? "";

            final province =
                data["provinceName"]?.toString() ?? "";

            final district =
                data["districtName"]?.toString() ?? "";

            final hamlet =
                data["hamletName"]?.toString() ?? "";

            final village =
                data["villageName"]?.toString() ?? "";

            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
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
                    Icons.water_drop,
                    color: Colors.blue,
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
                  padding: const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Text(
                    "$province\n"
                    "$district - $hamlet - $village",
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
    wellController.dispose();
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
            "تهيئة الآبار",
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ==================================================
                // المحافظة
                // ==================================================

                buildProvinceDropdown(),

                const SizedBox(height: 15),

                // ==================================================
                // المديرية
                // ==================================================

                buildDistrictDropdown(),

                if (provinceId != null)
                  const SizedBox(height: 15),

                // ==================================================
                // العزلة
                // ==================================================

                buildHamletDropdown(),

                if (districtId != null)
                  const SizedBox(height: 15),

                // ==================================================
                // القرية
                // ==================================================

                buildVillageDropdown(),

                if (hamletId != null)
                  const SizedBox(height: 15),

                // ==================================================
                // اسم البئر
                // ==================================================

                buildWellField(),

                const SizedBox(height: 15),

                // ==================================================
                // زر الإضافة
                // ==================================================

                buildAddButton(),

                const SizedBox(height: 20),

                // ==================================================
                // عنوان القائمة
                // ==================================================

                Row(
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "الآبار المسجلة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ==================================================
                // قائمة الآبار
                // ==================================================

                Expanded(
                  child: buildWellsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}