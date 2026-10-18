
// ============================================================
// customer_search_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';
import 'open_cycle_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
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

  const CustomerSearchScreen({
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

  // ============================================================
  // اللون الموحد
  // نفس لون MyAppBar
  // ============================================================

  static const Color mainColor = Colors.blue;

  static const Color backgroundColor =
      Color(0xffF5F9FF);

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // شريط معلومات البئر
  // نفس لون شريط العنوان
  // ============================================================

  Widget buildWellHeader() {
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
        color: mainColor,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ======================================================
          // أيقونة البئر
          // ======================================================

          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.16),

              shape: BoxShape.circle,

              border: Border.all(
                color:
                    Colors.white.withOpacity(0.20),
              ),
            ),

            child: const Icon(
              Icons.water_drop,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // ======================================================
          // معلومات البئر
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  widget.wellName == null ||
                          widget.wellName!
                              .trim()
                              .isEmpty
                      ? "البئر"
                      : widget.wellName!,

                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                if (widget.wellId != null &&
                    widget.wellId!
                        .trim()
                        .isNotEmpty)
                  Text(
                    "رقم البئر: ${widget.wellId}",

                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                if (widget.villageName != null &&
                    widget.villageName!
                        .trim()
                        .isNotEmpty)
                  Text(
                    "القرية: ${widget.villageName}",

                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // ======================================================
          // أيقونة اختيار الزبون
          // ======================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(
                0.15,
              ),

              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // شريط البحث
  // ============================================================

  Widget buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        15,
      ),

      child: TextField(
        controller:
            searchController,

        textInputAction:
            TextInputAction.search,

        decoration:
            InputDecoration(
          labelText:
              "البحث باسم الزبون",

          hintText:
              "اكتب اسم الزبون للبحث",

          prefixIcon:
              const Icon(
            Icons.search,
            color: mainColor,
          ),

          suffixIcon:
              searchText.isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(
                        Icons.clear,
                        color:
                            mainColor,
                      ),

                      onPressed: () {
                        searchController
                            .clear();

                        setState(() {
                          searchText =
                              "";
                        });
                      },
                    )
                  : null,

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
                  mainColor.withOpacity(
                0.35,
              ),
            ),
          ),

          focusedBorder:
              const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(
              Radius.circular(12),
            ),

            borderSide:
                BorderSide(
              color: mainColor,
              width: 2,
            ),
          ),

          filled:
              true,

          fillColor:
              Colors.white,
        ),

        onChanged:
            (value) {
          setState(() {
            searchText =
                value.trim();
          });
        },
      ),
    );
  }

  // ============================================================
  // حالة عدم وجود زبائن
  // ============================================================

  Widget buildEmptyCustomers() {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.people_outline,
            size: 60,
            color: Colors.grey,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            "لا يوجد زبائن لهذا البئر",

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // حالة عدم وجود نتائج
  // ============================================================

  Widget buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            "لا توجد نتائج",

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          if (searchText.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),

              child: Text(
                "بحث عن: $searchText",

                style:
                    TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الزبون
  // ============================================================

  Widget buildCustomerCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final Map<String, dynamic>
        data = doc.data();

    final String customerName =
        data["customerName"]
                ?.toString() ??
            "";

    final String phone =
        data["customerPhone"]
                ?.toString() ??
            "";

    final String address =
        data["customerAddress"]
                ?.toString() ??
            "";

    final String usage =
        data["waterUsageTypeName"]
                ?.toString() ??
            "";

    final String customerNo =
        data["customerNo"]
                ?.toString() ??
            "";

    final String customerId =
        data["customerId"]
                ?.toString() ??
            doc.id;

    return Card(
      elevation: 3,

      margin:
          const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 10,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          15,
        ),

        // ========================================================
        // فتح شاشة الدور
        // ========================================================

        onTap: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder:
                  (context) =>
                      OpenCycleScreen(
                customerId:
                    customerId,

                customerData: {
                  "name":
                      customerName,

                  "phone":
                      phone,

                  "address":
                      address,

                  "accountId":
                      data[
                          "accountId"],

                  "waterUsageTypeId":
                      data[
                          "waterUsageTypeId"],

                  "waterUsageTypeName":
                      data[
                          "waterUsageTypeName"],

                  "customerNo":
                      data[
                          "customerNo"],

                  "wellId":
                      data[
                          "wellId"],

                  "wellName":
                      data[
                          "wellName"],
                },

                supervisorId:
                    widget
                        .supervisorId,

                provinceId:
                    widget
                        .provinceId,

                provinceName:
                    widget
                        .provinceName,

                districtId:
                    widget
                        .districtId,

                districtName:
                    widget
                        .districtName,

                hamletId:
                    widget
                        .hamletId,

                hamletName:
                    widget
                        .hamletName,

                villageId:
                    widget
                        .villageId,

                villageName:
                    widget
                        .villageName,

                wellId:
                    widget
                        .wellId,

                wellName:
                    widget
                        .wellName,
              ),
            ),
          );
        },

        child:
            Padding(
          padding:
              const EdgeInsets.all(
            12,
          ),

          child:
              Row(
            children: [
              // ==================================================
              // أيقونة الزبون
              // ==================================================

              CircleAvatar(
                radius: 27,

                backgroundColor:
                    mainColor
                        .withOpacity(
                  0.12,
                ),

                child:
                    const Icon(
                  Icons.person,
                  color:
                      mainColor,
                  size: 30,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // ==================================================
              // بيانات الزبون
              // ==================================================

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      customerName
                              .isEmpty
                          ? "بدون اسم"
                          : customerName,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,

                        fontSize:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    if (customerNo
                        .isNotEmpty)
                      Text(
                        "رقم الزبون: $customerNo",

                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade700,

                          fontSize:
                              13,
                        ),
                      ),

                    if (phone
                        .isNotEmpty)
                      Text(
                        "الهاتف: $phone",

                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade700,

                          fontSize:
                              13,
                        ),
                      ),

                    if (address
                        .isNotEmpty)
                      Text(
                        "العنوان: $address",

                        maxLines:
                            1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade700,

                          fontSize:
                              13,
                        ),
                      ),

                    if (usage
                        .isNotEmpty)
                      Text(
                        "الاستخدام: $usage",

                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade700,

                          fontSize:
                              13,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ==================================================
              // سهم الانتقال
              // ==================================================

              Container(
                width: 38,
                height: 38,

                decoration:
                    BoxDecoration(
                  color:
                      mainColor
                          .withOpacity(
                    0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    const Icon(
                  Icons
                      .arrow_back_ios_new,

                  size: 17,

                  color:
                      mainColor,
                ),
              ),
            ],
          ),
        ),
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

      child:
          Scaffold(
        backgroundColor:
            backgroundColor,

        // ========================================================
        // شريط التطبيق الموحد
        // ========================================================

        appBar:
            const MyAppBar(
          title:
              "اختيار زبون البئر",

          icon:
              Icons.people,
        ),

        // ========================================================
        // BODY
        // ========================================================

        body:
            Column(
          children: [
            // ====================================================
            // شريط معلومات البئر
            // ====================================================

            buildWellHeader(),

            // ====================================================
            // شريط البحث
            // ====================================================

            buildSearchBox(),

            // ====================================================
            // قائمة الزبائن
            // ====================================================

            Expanded(
              child:
                  StreamBuilder<
                      QuerySnapshot<
                          Map<String,
                              dynamic>>>(
                stream:
                    firestore
                        .collection(
                          "well_customers",
                        )
                        .where(
                          "wellId",
                          isEqualTo:
                              widget
                                  .wellId,
                        )
                        .snapshots(),

                builder:
                    (
                  context,
                  snapshot,
                ) {
                  // =============================================
                  // خطأ
                  // =============================================

                  if (snapshot
                      .hasError) {
                    return Center(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          20,
                        ),

                        child:
                            Text(
                          "حدث خطأ أثناء تحميل الزبائن:\n\n"
                          "${snapshot.error}",

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            color:
                                Colors.red,
                          ),
                        ),
                      ),
                    );
                  }

                  // =============================================
                  // تحميل
                  // =============================================

                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  // =============================================
                  // لا توجد بيانات
                  // =============================================

                  if (!snapshot
                          .hasData ||
                      snapshot
                          .data!
                          .docs
                          .isEmpty) {
                    return buildEmptyCustomers();
                  }

                  // =============================================
                  // فلترة الزبائن
                  // =============================================

                  final List<
                      QueryDocumentSnapshot<
                          Map<String,
                              dynamic>>>
                      customers =
                      snapshot
                          .data!
                          .docs
                          .where(
                    (
                      doc,
                    ) {
                      final Map<
                              String,
                              dynamic>
                          data =
                          doc.data();

                      final String
                          name =
                          data[
                                      "customerName"]
                                  ?.toString()
                                  .toLowerCase() ??
                              "";

                      final String
                          phone =
                          data[
                                      "customerPhone"]
                                  ?.toString()
                                  .toLowerCase() ??
                              "";

                      final String
                          customerNo =
                          data[
                                      "customerNo"]
                                  ?.toString()
                                  .toLowerCase() ??
                              "";

                      final String
                          search =
                          searchText
                              .toLowerCase();

                      return name
                              .contains(
                            search,
                          ) ||
                          phone.contains(
                            search,
                          ) ||
                          customerNo
                              .contains(
                            search,
                          );
                    },
                  ).toList();

                  // =============================================
                  // لا توجد نتائج
                  // =============================================

                  if (customers
                      .isEmpty) {
                    return buildNoResults();
                  }

                  // =============================================
                  // عرض الزبائن
                  // =============================================

                  return RefreshIndicator(
                    onRefresh:
                        () async {
                      setState(
                        () {},
                      );
                    },

                    child:
                        ListView.builder(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 0,
                        bottom: 20,
                      ),

                      itemCount:
                          customers.length,

                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        return buildCustomerCard(
                          customers[
                              index],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

