// ============================================================
// reading_list_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'previous_reading_screen.dart';
import '../widgets/my_app_bar.dart';

class ReadingListScreen extends StatefulWidget {
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

  const ReadingListScreen({
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
  State<ReadingListScreen> createState() =>
      _ReadingListScreenState();
}

// ============================================================
// State
// ============================================================

class _ReadingListScreenState
    extends State<ReadingListScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // اللون الموحد للصفحة
  // ============================================================

  static const Color appColor = Colors.blue;

  List<Map<String, dynamic>> cycles = [];

  bool loading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadOpenCycles();
  }

  // ============================================================
  // تحميل الأدوار المفتوحة
  // ============================================================

  Future<void> loadOpenCycles() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      debugPrint(
        "======================================",
      );

      debugPrint("تحميل الأدوار المفتوحة");

      debugPrint(
        "supervisorId = ${widget.supervisorId}",
      );

      debugPrint(
        "provinceId = ${widget.provinceId}",
      );

      debugPrint(
        "districtId = ${widget.districtId}",
      );

      debugPrint(
        "hamletId = ${widget.hamletId}",
      );

      debugPrint(
        "villageId = ${widget.villageId}",
      );

      debugPrint(
        "wellId = ${widget.wellId}",
      );

      debugPrint(
        "======================================",
      );

      Query<Map<String, dynamic>> query =
          firestore.collection("cycles");

      // ========================================================
      // البئر
      // ========================================================

      if (widget.wellId != null &&
          widget.wellId!.trim().isNotEmpty) {
        query = query.where(
          "wellId",
          isEqualTo: widget.wellId,
        );
      }

      // ========================================================
      // القرية
      // ========================================================

      if (widget.villageId != null &&
          widget.villageId!.trim().isNotEmpty) {
        query = query.where(
          "villageId",
          isEqualTo: widget.villageId,
        );
      }

      // ========================================================
      // العزلة
      // ========================================================

      if (widget.hamletId != null &&
          widget.hamletId!.trim().isNotEmpty) {
        query = query.where(
          "hamletId",
          isEqualTo: widget.hamletId,
        );
      }

      // ========================================================
      // المديرية
      // ========================================================

      if (widget.districtId != null &&
          widget.districtId!.trim().isNotEmpty) {
        query = query.where(
          "districtId",
          isEqualTo: widget.districtId,
        );
      }

      // ========================================================
      // المحافظة
      // ========================================================

      if (widget.provinceId != null &&
          widget.provinceId!.trim().isNotEmpty) {
        query = query.where(
          "provinceId",
          isEqualTo: widget.provinceId,
        );
      }

      // ========================================================
      // المشرف
      // ========================================================

      if (widget.supervisorId != null &&
          widget.supervisorId!.trim().isNotEmpty) {
        query = query.where(
          "supervisorId",
          isEqualTo: widget.supervisorId,
        );
      }

      // ========================================================
      // الحالة
      // ========================================================

      query = query.where(
        "status",
        isEqualTo: "مفتوح",
      );

      // ========================================================
      // تنفيذ الاستعلام
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> result =
          await query.get();

      debugPrint(
        "عدد النتائج: ${result.docs.length}",
      );

      final List<Map<String, dynamic>> temp = [];

      // ========================================================
      // قراءة البيانات
      // ========================================================

      for (final doc in result.docs) {
        final Map<String, dynamic> data =
            doc.data();

        // ======================================================
        // حماية إضافية للبئر
        // ======================================================

        if (widget.wellId != null &&
            widget.wellId!.trim().isNotEmpty &&
            data["wellId"] != widget.wellId) {
          continue;
        }

        // ======================================================
        // حماية إضافية للقرية
        // ======================================================

        if (widget.villageId != null &&
            widget.villageId!.trim().isNotEmpty &&
            data["villageId"] != widget.villageId) {
          continue;
        }

        temp.add({
          "cycleId": doc.id,

          "cycleNumber":
              data["cycleNumber"] ?? 0,

          "customerId":
              data["customerId"] ?? "",

          "customerName":
              data["customerName"] ?? "غير معروف",

          "customerPhone":
              data["customerPhone"] ?? "",

          "customerAddress":
              data["customerAddress"] ?? "",

          "previousReading":
              data["previousReading"] ?? 0,

          "previousReadingValue":
              data["previousReadingValue"] ?? 0,

          "currentReading":
              data["currentReading"] ?? 0,

          "currentReadingValue":
              data["currentReadingValue"] ?? 0,

          "consumption":
              data["consumption"] ?? 0,

          "amount":
              data["amount"] ?? 0,

          "wellId":
              data["wellId"] ?? "",

          "wellName":
              data["wellName"] ?? "",

          "villageId":
              data["villageId"] ?? "",

          "villageName":
              data["villageName"] ?? "",

          "waterUsageTypeName":
              data["waterUsageTypeName"] ?? "",

          "meterTypeName":
              data["meterTypeName"] ?? "",

          "unitPrice":
              data["unitPrice"] ?? 0,

          "status":
              data["status"] ?? "",
        });
      }

      // ========================================================
      // ترتيب الأدوار
      // ========================================================

      temp.sort(
        (a, b) {
          final int aNumber =
              int.tryParse(
                    a["cycleNumber"].toString(),
                  ) ??
                  0;

          final int bNumber =
              int.tryParse(
                    b["cycleNumber"].toString(),
                  ) ??
                  0;

          return aNumber.compareTo(bNumber);
        },
      );

      if (!mounted) return;

      setState(() {
        cycles = temp;
        loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        "ERROR LOAD CYCLES: $e",
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        "خطأ أثناء تحميل الأدوار:\n$e",
        color: Colors.red,
      );
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void showMessage(
    String message, {
    Color? color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // شريط معلومات الصفحة
  // ============================================================

  Widget buildTitleBar() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      decoration: BoxDecoration(
        color: appColor,

        borderRadius: BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            blurRadius: 7,
            offset: Offset(0, 3),
            color: Colors.black26,
          ),
        ],
      ),

      child: Row(
        children: [
          // ======================================================
          // الأيقونة
          // ======================================================

          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.speed,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // النص
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  "إدخال القراءة الحالية",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.wellName == null ||
                          widget.wellName!.trim().isEmpty
                      ? "جميع الأدوار المفتوحة"
                      : "البئر: ${widget.wellName}",

                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // العدد
          // ======================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              "${cycles.length}",

              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // معلومات الموقع
  // ============================================================

  Widget buildLocationCard() {
    return Card(
      elevation: 2,

      margin: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          children: [
            // ====================================================
            // البئر والقرية
            // ====================================================

            Row(
              children: [
                CircleAvatar(
                  radius: 26,

                  backgroundColor:
                      Colors.blue.shade100,

                  child: Icon(
                    Icons.water_drop,
                    color: appColor,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        "البئر: ${widget.wellName ?? "غير محدد"}",

                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "القرية: ${widget.villageName ?? "غير محددة"}",

                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // زر التحديث
                // =================================================

                IconButton(
                  tooltip: "تحديث",

                  onPressed:
                      loading ? null : loadOpenCycles,

                  icon: const Icon(
                    Icons.refresh,
                    color: appColor,
                  ),
                ),
              ],
            ),

            const Divider(height: 22),

            // ====================================================
            // الموقع
            // ====================================================

            Wrap(
              spacing: 8,
              runSpacing: 6,

              children: [
                if (widget.provinceName != null &&
                    widget.provinceName!
                        .trim()
                        .isNotEmpty)
                  _locationChip(
                    Icons.map,
                    widget.provinceName!,
                  ),

                if (widget.districtName != null &&
                    widget.districtName!
                        .trim()
                        .isNotEmpty)
                  _locationChip(
                    Icons.location_city,
                    widget.districtName!,
                  ),

                if (widget.hamletName != null &&
                    widget.hamletName!
                        .trim()
                        .isNotEmpty)
                  _locationChip(
                    Icons.home_work,
                    widget.hamletName!,
                  ),

                if (widget.villageName != null &&
                    widget.villageName!
                        .trim()
                        .isNotEmpty)
                  _locationChip(
                    Icons.home,
                    widget.villageName!,
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ====================================================
            // عدد الأدوار
            // ====================================================

            Row(
              children: [
                const Icon(
                  Icons.list_alt,
                  size: 20,
                  color: Colors.green,
                ),

                const SizedBox(width: 7),

                Text(
                  "الأدوار المفتوحة: ${cycles.length}",

                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
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
  // شريحة الموقع
  // ============================================================

  Widget _locationChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.blue.shade50,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 16,
            color: appColor,
          ),

          const SizedBox(width: 5),

          Text(
            text,

            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الدور
  // ============================================================

  Widget buildCycleCard(
    Map<String, dynamic> cycle,
  ) {
    final String cycleId =
        cycle["cycleId"].toString();

    final String customerName =
        cycle["customerName"].toString();

    final String customerPhone =
        cycle["customerPhone"].toString();

    final String previousReading =
        cycle["previousReading"].toString();

    final String currentReading =
        cycle["currentReading"].toString();

    final String waterUsage =
        cycle["waterUsageTypeName"].toString();

    return Card(
      elevation: 3,

      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () async {
          await openReadingScreen(cycleId);
        },

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            children: [
              // ==================================================
              // رأس البطاقة
              // ==================================================

              Row(
                children: [
                  CircleAvatar(
                    radius: 25,

                    backgroundColor:
                        Colors.blue.shade50,

                    child: Icon(
                      Icons.person,
                      color: appColor,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          customerName,

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          customerPhone.isEmpty
                              ? "لا يوجد هاتف"
                              : customerPhone,

                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),

                    child: Text(
                      "دور ${cycle["cycleNumber"]}",

                      style: TextStyle(
                        color: appColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // ==================================================
              // بيانات الدور
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: _readingBox(
                      "القراءة السابقة",
                      previousReading,
                      Icons.history,
                      Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _readingBox(
                      "القراءة الحالية",
                      currentReading == "0"
                          ? "لم تدخل"
                          : currentReading,
                      Icons.speed,
                      currentReading == "0"
                          ? Colors.grey
                          : Colors.green,
                    ),
                  ),
                ],
              ),

              if (waterUsage.isNotEmpty) ...[
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.water_drop,
                      size: 18,
                      color: appColor,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "الاستخدام: $waterUsage",

                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // ==================================================
              // زر القراءة - نفس لون شريط العنوان
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 45,

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    foregroundColor: Colors.white,

                    elevation: 2,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: () async {
                    await openReadingScreen(cycleId);
                  },

                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),

                  label: const Text(
                    "إدخال القراءة الحالية",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // صندوق القراءة
  // ============================================================

  Widget _readingBox(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),

          const SizedBox(height: 5),

          Text(
            title,
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // فتح شاشة القراءة
  // ============================================================

  Future<void> openReadingScreen(
    String cycleId,
  ) async {
    final dynamic result =
        await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            PreviousReadingScreen(
          cycleId: cycleId,
        ),
      ),
    );

    if (result == true) {
      await loadOpenCycles();
    }
  }

  // ============================================================
  // جدول الأدوار - للشاشات الكبيرة
  // ============================================================

  Widget buildCyclesTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      scrollDirection: Axis.horizontal,

      child: DataTable(
        border: TableBorder.all(
          color: Colors.grey.shade400,
        ),

        headingRowColor:
            WidgetStateProperty.all(
          Colors.blue.shade100,
        ),

        columnSpacing: 25,

        columns: const [
          DataColumn(
            label: Text(
              "الدور",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "الزبون",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "الهاتف",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "السابقة",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "الحالية",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          DataColumn(
            label: Text(
              "القراءة",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        rows: cycles.map(
          (cycle) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    "دور ${cycle["cycleNumber"]}",

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                DataCell(
                  Text(
                    cycle["customerName"].toString(),
                  ),
                ),

                DataCell(
                  Text(
                    cycle["customerPhone"].toString(),
                  ),
                ),

                DataCell(
                  Text(
                    cycle["previousReading"].toString(),
                  ),
                ),

                DataCell(
                  Text(
                    cycle["currentReading"].toString(),
                  ),
                ),

                DataCell(
                  IconButton(
                    tooltip:
                        "إدخال القراءة الحالية",

                    icon: const Icon(
                      Icons.edit,
                      color: appColor,
                    ),

                    onPressed: () async {
                      await openReadingScreen(
                        cycle["cycleId"].toString(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // قائمة الأدوار
  // ============================================================

  Widget buildCyclesList() {
    return RefreshIndicator(
      onRefresh: loadOpenCycles,

      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 20,
        ),

        itemCount: cycles.length,

        itemBuilder: (context, index) {
          return buildCycleCard(
            cycles[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // حالة عدم وجود أدوار
  // ============================================================

  Widget buildEmptyState() {
    return RefreshIndicator(
      onRefresh: loadOpenCycles,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.25,
          ),

          const Icon(
            Icons.speed_outlined,
            size: 80,
            color: Colors.grey,
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              "لا توجد أدوار مفتوحة لهذا البئر",

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              "اسحب للأسفل لتحديث البيانات",

              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        // ========================================================
        // شريط العنوان
        // ========================================================

        appBar: const MyAppBar(
          title: "القراءات الحالية",
        ),

        // ========================================================
        // Body
        // ========================================================

        body: Column(
          children: [
            // ====================================================
            // الشريط الأزرق
            // ====================================================

            buildTitleBar(),

            // ====================================================
            // معلومات البئر
            // ====================================================

            buildLocationCard(),

            // ====================================================
            // المحتوى
            // ====================================================

            Expanded(
              child: loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color: appColor,
                      ),
                    )
                  : cycles.isEmpty
                      ? buildEmptyState()
                      : buildCyclesList(),
            ),
          ],
        ),
      ),
    );
  }
}