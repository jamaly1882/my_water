import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'open_cycle_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState
    extends State<CustomerSearchScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController searchController =
      TextEditingController();

  String searchText = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // شريط العنوان
  // ============================================================

  Widget buildTitleBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.75),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_search,
            color: Colors.white,
            size: 25,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              "الاستعلام عن الزبون",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "الدور",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // البحث
  // ============================================================

  Widget buildSearchField() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: "اكتب اسم الزبون",
        hintText: "ابحث عن الزبون",
        prefixIcon: const Icon(
          Icons.search,
        ),
        suffixIcon: searchText.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                ),
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchText = "";
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) {
        setState(() {
          searchText = value.trim();
        });
      },
    );
  }

  // ============================================================
  // بطاقة معلومات
  // ============================================================

  Widget buildInfoBar(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: Colors.blue.shade700,
          ),

          const SizedBox(width: 8),

          Text(
            "عدد الزبائن: $count",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),

          const Spacer(),

          if (searchText.isNotEmpty)
            Text(
              "نتيجة البحث",
              style: TextStyle(
                color: Colors.grey.shade700,
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
        appBar: AppBar(
          title: const Text(
            "البحث عن زبون",
          ),
          centerTitle: true,
        ),

        body: Column(
          children: [
            // ====================================================
            // شريط العنوان
            // ====================================================

            buildTitleBar(),

            // ====================================================
            // محتوى الصفحة
            // ====================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [
                    // ==================================================
                    // مربع البحث
                    // ==================================================

                    buildSearchField(),

                    const SizedBox(height: 12),

                    // ==================================================
                    // قائمة الزبائن
                    // ==================================================

                    Expanded(
                      child: StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: firestore
                            .collection("customers")
                            .snapshots(),

                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "حدث خطأ:\n${snapshot.error}",
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: Text(
                                "لا توجد بيانات",
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs
                              .where((doc) {
                            final data = doc.data();

                            final name =
                                data["name"]
                                        ?.toString() ??
                                    "";

                            final phone =
                                data["phone"]
                                        ?.toString() ??
                                    "";

                            final customerNumber =
                                data["customerNumber"]
                                        ?.toString() ??
                                    "";

                            final search =
                                searchText.toLowerCase();

                            return name
                                    .toLowerCase()
                                    .contains(search) ||
                                phone
                                    .toLowerCase()
                                    .contains(search) ||
                                customerNumber
                                    .toLowerCase()
                                    .contains(search);
                          }).toList();

                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 70,
                                    color:
                                        Colors.grey.shade400,
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  Text(
                                    searchText.isEmpty
                                        ? "لا يوجد زبائن مسجلون"
                                        : "لا توجد نتائج للبحث",
                                    style:
                                        TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              buildInfoBar(
                                docs.length,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Expanded(
                                child:
                                    SingleChildScrollView(
                                  scrollDirection:
                                      Axis.horizontal,

                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      border:
                                          TableBorder.all(
                                        color:
                                            Colors.grey.shade300,
                                      ),

                                      headingRowColor:
                                          WidgetStateProperty
                                              .all(
                                        Colors.blue.shade100,
                                      ),

                                      columnSpacing: 25,

                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            "الرقم",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        DataColumn(
                                          label: Text(
                                            "الاسم",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        DataColumn(
                                          label: Text(
                                            "الهاتف",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        DataColumn(
                                          label: Text(
                                            "العنوان",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        DataColumn(
                                          label: Text(
                                            "الاستخدام",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        DataColumn(
                                          label: Text(
                                            "فتح الدور",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),
                                      ],

                                      rows: docs
                                          .map(
                                            (doc) {
                                              final data =
                                                  doc.data();

                                              return DataRow(
                                                cells: [
                                                  // =================================
                                                  // رقم الزبون
                                                  // =================================

                                                  DataCell(
                                                    Text(
                                                      data["customerNumber"]
                                                              ?.toString() ??
                                                          data["number"]
                                                              ?.toString() ??
                                                          "",
                                                    ),
                                                  ),

                                                  // =================================
                                                  // الاسم
                                                  // =================================

                                                  DataCell(
                                                    Text(
                                                      data["name"]
                                                              ?.toString() ??
                                                          "",
                                                    ),
                                                  ),

                                                  // =================================
                                                  // الهاتف
                                                  // =================================

                                                  DataCell(
                                                    Text(
                                                      data["phone"]
                                                              ?.toString() ??
                                                          "",
                                                    ),
                                                  ),

                                                  // =================================
                                                  // العنوان
                                                  // =================================

                                                  DataCell(
                                                    Text(
                                                      data["address"]
                                                              ?.toString() ??
                                                          "",
                                                    ),
                                                  ),

                                                  // =================================
                                                  // نوع الاستخدام
                                                  // =================================

                                                  DataCell(
                                                    Text(
                                                      data["waterUsageTypeName"]
                                                              ?.toString() ??
                                                          "",
                                                    ),
                                                  ),

                                                  // =================================
                                                  // فتح الدور
                                                  // =================================

                                                  DataCell(
                                                    IconButton(
                                                      tooltip:
                                                          "فتح دور جديد",

                                                      icon:
                                                          const Icon(
                                                        Icons
                                                            .add_circle,
                                                        color:
                                                            Colors.green,
                                                      ),

                                                      onPressed:
                                                          () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    OpenCycleScreen(
                                                              customerId:
                                                                  doc.id,

                                                              customerData:
                                                                  data,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],

                                                // =================================
                                                // الضغط على الصف
                                                // =================================

                                                onSelectChanged:
                                                    (value) {
                                                  if (value !=
                                                      true) {
                                                    return;
                                                  }

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              OpenCycleScreen(
                                                        customerId:
                                                            doc.id,

                                                        customerData:
                                                            data,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}