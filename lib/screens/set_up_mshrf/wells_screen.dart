import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/my_app_bar.dart';

class WellsScreen extends StatefulWidget {
  const WellsScreen({super.key});

  @override
  State<WellsScreen> createState() => _WellsScreenState();
}

class _WellsScreenState extends State<WellsScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController wellController =
      TextEditingController();

  // ============================================================
  // اللون الموحد مع شريط العنوان
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // بيانات الموقع
  // ============================================================

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
  // الرسائل
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
  // إضافة البئر
  // ============================================================

  Future<void> addWell() async {
    if (loading) return;

    final String name =
        wellController.text.trim();

    // ----------------------------------------------------------
    // المحافظة
    // ----------------------------------------------------------

    if (provinceId == null ||
        provinceId!.isEmpty) {
      showMessage("اختر المحافظة");
      return;
    }

    // ----------------------------------------------------------
    // المديرية
    // ----------------------------------------------------------

    if (districtId == null ||
        districtId!.isEmpty) {
      showMessage("اختر المديرية");
      return;
    }

    // ----------------------------------------------------------
    // العزلة
    // ----------------------------------------------------------

    if (hamletId == null ||
        hamletId!.isEmpty) {
      showMessage("اختر العزلة");
      return;
    }

    // ----------------------------------------------------------
    // القرية
    // ----------------------------------------------------------

    if (villageId == null ||
        villageId!.isEmpty) {
      showMessage("اختر القرية");
      return;
    }

    // ----------------------------------------------------------
    // اسم البئر
    // ----------------------------------------------------------

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

        "createdAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      wellController.clear();

      showMessage(
        "تمت إضافة البئر بنجاح",
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "حدث خطأ أثناء إضافة البئر: $e",
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
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        // ========================================================
        // الخلفية
        // ========================================================

        backgroundColor:
            const Color(0xffF5F9FF),

        // ========================================================
        // شريط العنوان
        // ========================================================

        appBar: const MyAppBar(
          title: "تهيئة الآبار",
          showBackButton: true,
        ),

        // ========================================================
        // المحتوى
        // ========================================================

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // المحافظة
              // ==================================================

              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection("provinces")
                    .snapshots(),

                builder:
                    (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color: mainColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.red.withOpacity(.08),
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
                      padding:
                          const EdgeInsets.all(12),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.orange.withOpacity(.08),
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

                  final docs =
                      snapshot.data!.docs;

                  final validValue =
                      docs.any(
                    (doc) =>
                        doc.id == provinceId,
                  )
                          ? provinceId
                          : null;

                  return DropdownButtonFormField<
                      String>(
                    value: validValue,

                    isExpanded: true,

                    decoration:
                        const InputDecoration(
                      labelText:
                          "اختر المحافظة",

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

                    items: docs.map((doc) {
                      final data =
                          doc.data()
                              as Map<String,
                                  dynamic>;

                      return DropdownMenuItem<
                          String>(
                        value: doc.id,

                        child: Text(
                          data["name"]
                                  ?.toString() ??
                              "",
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      final doc =
                          docs.firstWhere(
                        (e) =>
                            e.id == value,
                      );

                      final data =
                          doc.data()
                              as Map<String,
                                  dynamic>;

                      setState(() {
                        provinceId =
                            value;

                        provinceName =
                            data["name"]
                                ?.toString();

                        districtId = null;
                        districtName = null;

                        hamletId = null;
                        hamletName = null;

                        villageId = null;
                        villageName = null;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // المديرية
              // ==================================================

              if (provinceId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("districts")
                      .where(
                        "provinceId",
                        isEqualTo:
                            provinceId,
                      )
                     
                      .snapshots(),

                  builder:
                      (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: mainColor,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.red
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
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
                        snapshot.data!.docs
                            .isEmpty) {
                      return Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.orange
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Text(
                          "لا توجد مديريات لهذه المحافظة",
                          style: TextStyle(
                            color:
                                Colors.orange,
                          ),
                        ),
                      );
                    }

                    final docs =
                        snapshot.data!.docs;

                    final validValue =
                        docs.any(
                      (doc) =>
                          doc.id ==
                          districtId,
                    )
                            ? districtId
                            : null;

                    return DropdownButtonFormField<
                        String>(
                      value: validValue,

                      isExpanded: true,

                      decoration:
                          const InputDecoration(
                        labelText:
                            "اختر المديرية",

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
                          Icons.map,
                          color: mainColor,
                        ),
                      ),

                      items:
                          docs.map((doc) {
                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        return DropdownMenuItem<
                            String>(
                          value: doc.id,

                          child: Text(
                            data["name"]
                                    ?.toString() ??
                                "",
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        final doc =
                            docs.firstWhere(
                          (e) =>
                              e.id == value,
                        );

                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        setState(() {
                          districtId =
                              value;

                          districtName =
                              data["name"]
                                  ?.toString();

                          hamletId = null;
                          hamletName = null;

                          villageId = null;
                          villageName = null;
                        });
                      },
                    );
                  },
                ),

              const SizedBox(height: 15),

              // ==================================================
              // العزلة
              // ==================================================

              if (districtId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("hamlets")
                      .where(
                        "districtId",
                        isEqualTo:
                            districtId,
                      )
                
                      .snapshots(),

                  builder:
                      (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: mainColor,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.red
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Text(
                          "حدث خطأ في تحميل العزل",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs
                            .isEmpty) {
                      return Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.orange
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Text(
                          "لا توجد عزل لهذه المديرية",
                          style: TextStyle(
                            color:
                                Colors.orange,
                          ),
                        ),
                      );
                    }

                    final docs =
                        snapshot.data!.docs;

                    final validValue =
                        docs.any(
                      (doc) =>
                          doc.id == hamletId,
                    )
                            ? hamletId
                            : null;

                    return DropdownButtonFormField<
                        String>(
                      value: validValue,

                      isExpanded: true,

                      decoration:
                          const InputDecoration(
                        labelText:
                            "اختر العزلة",

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

                      items:
                          docs.map((doc) {
                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        return DropdownMenuItem<
                            String>(
                          value: doc.id,

                          child: Text(
                            data["name"]
                                    ?.toString() ??
                                "",
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        final doc =
                            docs.firstWhere(
                          (e) =>
                              e.id == value,
                        );

                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        setState(() {
                          hamletId =
                              value;

                          hamletName =
                              data["name"]
                                  ?.toString();

                          villageId = null;
                          villageName = null;
                        });
                      },
                    );
                  },
                ),

              const SizedBox(height: 15),

              // ==================================================
              // القرية
              // ==================================================

              if (hamletId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("villages")
                      .where(
                        "hamletId",
                        isEqualTo:
                            hamletId,
                      )
                      
                      .snapshots(),

                  builder:
                      (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: mainColor,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.red
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Text(
                          "حدث خطأ في تحميل القرى",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs
                            .isEmpty) {
                      return Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.orange
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Text(
                          "لا توجد قرى لهذه العزلة",
                          style: TextStyle(
                            color:
                                Colors.orange,
                          ),
                        ),
                      );
                    }

                    final docs =
                        snapshot.data!.docs;

                    final validValue =
                        docs.any(
                      (doc) =>
                          doc.id ==
                          villageId,
                    )
                            ? villageId
                            : null;

                    return DropdownButtonFormField<
                        String>(
                      value: validValue,

                      isExpanded: true,

                      decoration:
                          const InputDecoration(
                        labelText:
                            "اختر القرية",

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
                          Icons.home,
                          color: mainColor,
                        ),
                      ),

                      items:
                          docs.map((doc) {
                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        return DropdownMenuItem<
                            String>(
                          value: doc.id,

                          child: Text(
                            data["name"]
                                    ?.toString() ??
                                "",
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        final doc =
                            docs.firstWhere(
                          (e) =>
                              e.id == value,
                        );

                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        setState(() {
                          villageId =
                              value;

                          villageName =
                              data["name"]
                                  ?.toString();
                        });
                      },
                    );
                  },
                ),

              const SizedBox(height: 15),

              // ==================================================
              // اسم / رقم البئر
              // ==================================================

              TextField(
                controller:
                    wellController,

                textInputAction:
                    TextInputAction.done,

                decoration:
                    const InputDecoration(
                  labelText:
                      "اسم / رقم البئر",

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
                    Icons.water_drop,
                    color: mainColor,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // زر إضافة البئر
              // نفس لون شريط العنوان
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height:
                    52,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : addWell,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        mainColor,

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        mainColor.withOpacity(
                      .55,
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
                            color:
                                Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save,
                          color:
                              Colors.white,
                        ),

                  label: Text(
                    loading
                        ? "جاري الحفظ..."
                        : "إضافة البئر",

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

              const SizedBox(height: 20),

              // ==================================================
              // عنوان قائمة الآبار
              // ==================================================

              const Align(
                alignment:
                    Alignment.centerRight,

                child: Text(
                  "الآبار المسجلة",

                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // قائمة الآبار
              // ==================================================

              Expanded(
                child:
                    StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("wells")
                      .orderBy("name")
                      .snapshots(),

                  builder:
                      (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: mainColor,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          "حدث خطأ في تحميل الآبار",
                          style:
                              TextStyle(
                            color:
                                Colors.red,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs
                            .isEmpty) {
                      return const Center(
                        child: Text(
                          "لا توجد آبار",
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      );
                    }

                    final docs =
                        snapshot.data!.docs;

                    return ListView.builder(
                      itemCount:
                          docs.length,

                      itemBuilder:
                          (context, index) {
                        final data =
                            docs[index]
                                .data()
                                as Map<String,
                                    dynamic>;

                        final String name =
                            data["name"]
                                    ?.toString() ??
                                "";

                        final String province =
                            data["provinceName"]
                                    ?.toString() ??
                                "";

                        final String district =
                            data["districtName"]
                                    ?.toString() ??
                                "";

                        final String hamlet =
                            data["hamletName"]
                                    ?.toString() ??
                                "";

                        final String village =
                            data["villageName"]
                                    ?.toString() ??
                                "";

                        return Card(
                          elevation: 3,

                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),

                          child:
                              ListTile(
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 15,
                              vertical: 6,
                            ),

                            leading:
                                CircleAvatar(
                              backgroundColor:
                                  mainColor
                                      .withOpacity(
                                .12,
                              ),

                              child:
                                  const Icon(
                                Icons.water_drop,
                                color:
                                    mainColor,
                              ),
                            ),

                            title: Text(
                              name,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),

                            subtitle:
                                Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 5,
                              ),

                              child: Text(
                                "$province\n"
                                "$district - "
                                "$hamlet - "
                                "$village",
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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
    wellController.dispose();
    super.dispose();
  }
}