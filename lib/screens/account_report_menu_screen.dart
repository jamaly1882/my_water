import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';
import 'account_report_type_screen.dart';

class AccountReportMenuScreen extends StatefulWidget {
  final String? wellId;
  final String? wellName;

  const AccountReportMenuScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  @override
  State<AccountReportMenuScreen> createState() =>
      _AccountReportMenuScreenState();
}

class _AccountReportMenuScreenState
    extends State<AccountReportMenuScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  // ============================================================
  // الألوان
  // ============================================================

  static const Color mainColor = Colors.blue;

  static const Color backgroundColor =
      Color(0xffF5F9FF);

  // ============================================================
  // جلب اسم الحساب
  // ============================================================

  Future<String> getAccountName(
    String accountId,
    Map<String, dynamic> account,
  ) async {
    try {
      // ========================================================
      // أولاً: اسم الحساب الموجود داخل accounts
      // وهذا مهم لحساب العامل والمبيعات وغيرها
      // ========================================================

      final accountName =
          account['name']?.toString().trim();

      if (accountName != null &&
          accountName.isNotEmpty) {
        return accountName;
      }

      final accountName2 =
          account['accountName']?.toString().trim();

      if (accountName2 != null &&
          accountName2.isNotEmpty) {
        return accountName2;
      }

      // ========================================================
      // إذا لم يوجد اسم الحساب، نبحث عن الزبون
      // ========================================================

      final customer = await firestore
          .collection('well_customers')
          .where(
            'accountId',
            isEqualTo: accountId,
          )
          .limit(1)
          .get();

      if (customer.docs.isNotEmpty) {
        final data =
            customer.docs.first.data();

        final customerName =
            data['customerName']
                ?.toString()
                .trim();

        if (customerName != null &&
            customerName.isNotEmpty) {
          return customerName;
        }
      }

      return 'حساب عام';
    } catch (e) {
      debugPrint(
        'خطأ في جلب اسم الحساب: $e',
      );

      return account['name']?.toString() ??
          account['accountName']?.toString() ??
          'حساب عام';
    }
  }

  // ============================================================
  // فتح صفحة نوع التقرير
  // ============================================================

  void openReportType(
    String accountId,
    Map<String, dynamic> accountData,
    String accountName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AccountReportTypeScreen(
          accountId: accountId,

          accountData: accountData,

          accountName: accountName,

          wellId:
              accountData['wellId']
                  ?.toString() ??
                  widget.wellId,

          wellName:
              accountData['wellName']
                  ?.toString() ??
                  widget.wellName,
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة البئر
  // ============================================================

  Widget buildWellCard() {
    if (widget.wellName == null ||
        widget.wellName!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: mainColor,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color:
                mainColor.withOpacity(0.18),

            blurRadius: 8,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ====================================================
          // أيقونة البئر
          // ====================================================

          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.16),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.water_drop,

              color: Colors.white,

              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // ====================================================
          // بيانات البئر
          // ====================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'البئر',

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  widget.wellName!,

                  style:
                      const TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'رقم البئر: ${widget.wellId ?? ''}',

                  style:
                      const TextStyle(
                    color: Colors.white70,

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // مربع البحث
  // ============================================================

  Widget searchBox() {
    return TextField(
      controller: searchController,

      textDirection:
          TextDirection.rtl,

      decoration:
          InputDecoration(
        labelText:
            'البحث باسم الحساب',

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
                    ),
                    onPressed: () {
                      searchController
                          .clear();

                      setState(() {
                        searchText = '';
                      });
                    },
                  )
                : null,

        filled: true,

        fillColor:
            Colors.white,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              BorderSide(
            color:
                Colors.grey.shade300,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              const BorderSide(
            color: mainColor,

            width: 2,
          ),
        ),
      ),

      onChanged: (value) {
        setState(() {
          searchText =
              value.trim();
        });
      },
    );
  }

  // ============================================================
  // لون نوع الحساب
  // ============================================================

  Color getAccountTypeColor(
    String type,
  ) {
    switch (type) {
      case 'worker':
        return Colors.orange;

      case 'sales':
        return Colors.green;

      case 'customer':
        return Colors.blue;

      default:
        return mainColor;
    }
  }

  // ============================================================
  // اسم نوع الحساب
  // ============================================================

  String getAccountTypeName(
    String type,
  ) {
    switch (type) {
      case 'worker':
        return 'عامل البئر';

      case 'sales':
        return 'مبيعات البئر';

      case 'customer':
        return 'زبون';

      default:
        return 'حساب';
    }
  }

  // ============================================================
  // بطاقة الحساب
  // ============================================================

  Widget accountCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final account =
        doc.data()
            as Map<String, dynamic>;

    return FutureBuilder<String>(
      future: getAccountName(
        doc.id,
        account,
      ),

      builder: (
        context,
        nameSnapshot,
      ) {
        // ======================================================
        // تحميل الاسم
        // ======================================================

        if (nameSnapshot
                .connectionState ==
            ConnectionState.waiting) {
          return Container(
            height: 90,

            margin:
                const EdgeInsets.only(
              bottom: 9,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                16,
              ),

              border:
                  Border.all(
                color:
                    mainColor
                        .withOpacity(
                  0.12,
                ),
              ),
            ),

            child:
                const Center(
              child:
                  SizedBox(
                width: 20,
                height: 20,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,

                  color:
                      mainColor,
                ),
              ),
            ),
          );
        }

        // ======================================================
        // الخطأ
        // ======================================================

        if (nameSnapshot.hasError) {
          return const SizedBox.shrink();
        }

        final accountName =
            nameSnapshot.data ??
                'حساب عام';

        // ======================================================
        // البحث
        // ======================================================

        if (searchText.isNotEmpty &&
            !accountName
                .toLowerCase()
                .contains(
                  searchText
                      .toLowerCase(),
                )) {
          return const SizedBox.shrink();
        }

        // ======================================================
        // بيانات الحساب
        // ======================================================

        final type =
            account['type']
                ?.toString() ??
                '';

        final typeName =
            getAccountTypeName(
          type,
        );

        final typeColor =
            getAccountTypeColor(
          type,
        );

        final balance =
            account['balance'] ?? 0;

        final accountNumber =
            account['accountNumber']
                ?.toString() ??
                '';

        final wellName =
            account['wellName']
                ?.toString() ??
                widget.wellName ??
                '';

        // ======================================================
        // بطاقة الحساب
        // ======================================================

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            border:
                Border.all(
              color:
                  mainColor
                      .withOpacity(
                0.14,
              ),

              width: 1,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.05,
                ),

                blurRadius: 7,

                offset:
                    const Offset(0, 3),
              ),
            ],
          ),

          child: ListTile(
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 7,
            ),

            // ==================================================
            // الأيقونة
            // ==================================================

            leading:
                Container(
              width: 50,
              height: 50,

              decoration:
                  BoxDecoration(
                color:
                    typeColor
                        .withOpacity(
                  0.10,
                ),

                shape:
                    BoxShape.circle,

                border:
                    Border.all(
                  color:
                      typeColor
                          .withOpacity(
                    0.18,
                  ),
                ),
              ),

              child:
                  Icon(
                type == 'worker'
                    ? Icons
                        .engineering
                    : type == 'sales'
                        ? Icons
                            .point_of_sale
                        : Icons
                            .account_balance_wallet,

                color:
                    typeColor,

                size: 25,
              ),
            ),

            // ==================================================
            // اسم الحساب
            // ==================================================

            title:
                Text(
              accountName,

              style:
                  const TextStyle(
                color:
                    mainColor,

                fontWeight:
                    FontWeight.bold,

                fontSize: 16,
              ),
            ),

            // ==================================================
            // تفاصيل الحساب
            // ==================================================

            subtitle:
                Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  // نوع الحساب
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              typeColor
                                  .withOpacity(
                            0.10,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),

                        child:
                            Text(
                          typeName,

                          style:
                              TextStyle(
                            color:
                                typeColor,

                            fontSize:
                                11,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  // الرصيد
                  Text(
                    'الرصيد: $balance',

                    style:
                        const TextStyle(
                      color:
                          Colors.black54,

                      fontSize: 12,
                    ),
                  ),

                  // رقم الحساب
                  if (accountNumber
                      .isNotEmpty)
                    Text(
                      'رقم الحساب: $accountNumber',

                      style:
                          const TextStyle(
                        color:
                            Colors.black45,

                        fontSize: 11,
                      ),
                    ),

                  // اسم البئر
                  if (wellName
                      .trim()
                      .isNotEmpty)
                    Text(
                      'البئر: $wellName',

                      style:
                          const TextStyle(
                        color:
                            Colors.black45,

                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // ==================================================
            // السهم
            // ==================================================

            trailing:
                Container(
              width: 34,
              height: 34,

              decoration:
                  BoxDecoration(
                color:
                    mainColor
                        .withOpacity(
                  0.08,
                ),

                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
              ),

              child:
                  const Icon(
                Icons
                    .arrow_back_ios_new,

                color:
                    mainColor,

                size: 15,
              ),
            ),

            // ==================================================
            // فتح التقارير
            // ==================================================

            onTap: () {
              openReportType(
                doc.id,

                account,

                accountName,
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // dispose
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool hasWell =
        widget.wellId != null &&
        widget.wellId!
            .trim()
            .isNotEmpty;

    return Directionality(
      textDirection:
          TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            backgroundColor,

        // ======================================================
        // شريط العنوان
        // ======================================================

        appBar:
            MyAppBar(
          title:
              'تقارير الحساب',

          subtitle:
              hasWell
                  ? 'حسابات البئر: ${widget.wellName ?? ''}'
                  : 'اختيار الحساب لعرض التقرير',

          icon:
              Icons
                  .account_balance_wallet,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body:
            Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child:
              Column(
            children: [
              // ==================================================
              // بطاقة البئر
              // ==================================================

              buildWellCard(),

              if (hasWell)
                const SizedBox(
                  height: 12,
                ),

              // ==================================================
              // البحث
              // ==================================================

              searchBox(),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // عنوان الحسابات
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      mainColor,

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                    Row(
                  children: [
                    const Icon(
                      Icons
                          .account_balance_wallet,

                      color:
                          Colors.white,

                      size: 22,
                    ),

                    const SizedBox(
                      width: 9,
                    ),

                    Expanded(
                      child:
                          Text(
                        hasWell
                            ? 'حسابات ${widget.wellName ?? ''}'
                            : 'جميع الحسابات',

                        style:
                            const TextStyle(
                          color:
                              Colors.white,

                          fontSize:
                              16,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // الحسابات
              // ==================================================

              Expanded(
                child:
                    StreamBuilder<
                        QuerySnapshot>(
                  // =================================================
                  // هنا أهم تعديل:
                  // إذا كان لدينا wellId نجلب حسابات نفس البئر فقط
                  // =================================================

                  stream:
                      hasWell
                          ? firestore
                              .collection(
                                'accounts',
                              )
                              .where(
                                'wellId',
                                isEqualTo:
                                    widget.wellId,
                              )
                              .snapshots()
                          : firestore
                              .collection(
                                'accounts',
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
                              const EdgeInsets.all(
                            20,
                          ),

                          child:
                              Text(
                            'حدث خطأ:\n${snapshot.error}',

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
                            CircularProgressIndicator(
                          color:
                              mainColor,
                        ),
                      );
                    }

                    // =============================================
                    // لا توجد حسابات
                    // =============================================

                    if (!snapshot
                            .hasData ||
                        snapshot.data!
                            .docs
                            .isEmpty) {
                      return Center(
                        child:
                            Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons
                                  .account_balance_wallet_outlined,

                              size:
                                  60,

                              color:
                                  Colors.grey
                                      .shade400,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              hasWell
                                  ? 'لا توجد حسابات لهذا البئر'
                                  : 'لا توجد حسابات',

                              style:
                                  TextStyle(
                                fontSize:
                                    17,

                                fontWeight:
                                    FontWeight
                                        .bold,

                                color:
                                    Colors.grey
                                        .shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // =============================================
                    // المستندات
                    // =============================================

                    final docs =
                        snapshot.data!
                            .docs;

                    // =============================================
                    // القائمة
                    // =============================================

                    return ListView.builder(
                      itemCount:
                          docs.length,

                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        return accountCard(
                          context,
                          docs[index],
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
}