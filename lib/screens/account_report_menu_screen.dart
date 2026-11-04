
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
      // أولاً اسم الحساب الموجود في accounts
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

      // إذا لم يوجد اسم الحساب نبحث عن الزبون
      final customerSnapshot = await firestore
          .collection('well_customers')
          .where(
            'accountId',
            isEqualTo: accountId,
          )
          .limit(1)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        final data =
            customerSnapshot.docs.first.data();

        final customerName =
            data['customerName']
                ?.toString()
                .trim();

        if (customerName != null &&
            customerName.isNotEmpty) {
          return customerName;
        }
      }

      return 'General account';
    } catch (e) {
      debugPrint(
        'Could not load account name: $e',
      );

      return account['name']?.toString() ??
          account['accountName']?.toString() ??
          'General account';
    }
  }

  // ============================================================
  // جلب الحسابات
  //
  // الترتيب:
  // 1. Accounts: الزبائن المرتبطة بالبئر
  // 2. Accounts: البئر المباشرة
  //
  // مع منع التكرار
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getWellAccounts() async {
    final wellId = widget.wellId?.trim();

    // ==========================================================
    // إذا لم يتم تحديد بئر
    // نعرض جميع الحسابات
    // ==========================================================

    if (wellId == null || wellId.isEmpty) {
      final allAccounts = await firestore
          .collection('accounts')
          .get();

      return allAccounts.docs;
    }

    // ==========================================================
    // أولاً:
    // جلب الزبائن المرتبطين بهذا البئر
    // من well_customers
    // ==========================================================

    final customersSnapshot = await firestore
        .collection('well_customers')
        .where(
          'wellId',
          isEqualTo: wellId,
        )
        .get();

    final Set<String> customerAccountIds =
        <String>{};

    for (final customerDoc
        in customersSnapshot.docs) {
      final data = customerDoc.data();

      final accountId =
          data['accountId']
              ?.toString()
              .trim();

      if (accountId != null &&
          accountId.isNotEmpty) {
        customerAccountIds.add(accountId);
      }
    }

    // ==========================================================
    // جلب Accounts: الزبائن من accounts
    //
    // Firestore whereIn يسمح بحد أقصى 30 قيمة
    // لذلك نقسم IDs إلى مجموعات
    // ==========================================================

    final Map<
            String,
            QueryDocumentSnapshot<Map<String, dynamic>>>
        customerAccounts = {};

    final customerIds =
        customerAccountIds.toList();

    for (
      int i = 0;
      i < customerIds.length;
      i += 30
    ) {
      final int end =
          (i + 30 < customerIds.length)
              ? i + 30
              : customerIds.length;

      final chunk =
          customerIds.sublist(i, end);

      if (chunk.isEmpty) {
        continue;
      }

      final accountsSnapshot =
          await firestore
              .collection('accounts')
              .where(
                FieldPath.documentId,
                whereIn: chunk,
              )
              .get();

      for (final doc
          in accountsSnapshot.docs) {
        customerAccounts[doc.id] = doc;
      }
    }

    // ==========================================================
    // ثانياً:
    // جلب الAccounts: المرتبطة مباشرة بالبئر
    // accounts.wellId
    // ==========================================================

    final wellAccountsSnapshot =
        await firestore
            .collection('accounts')
            .where(
              'wellId',
              isEqualTo: wellId,
            )
            .get();

    final Map<
            String,
            QueryDocumentSnapshot<Map<String, dynamic>>>
        wellAccounts = {};

    for (final doc
        in wellAccountsSnapshot.docs) {
      wellAccounts[doc.id] = doc;
    }

    // ==========================================================
    // بناء القائمة النهائية
    //
    // أولاً Accounts: الزبائن
    // ثم Accounts: البئر
    //
    // بدون تكرار
    // ==========================================================

    final List<
            QueryDocumentSnapshot<Map<String, dynamic>>>
        result = [];

    // أولاً: Accounts: الزبائن
    for (final doc
        in customerAccounts.values) {
      result.add(doc);
    }

    // ثانياً: Accounts: البئر
    for (final doc
        in wellAccounts.values) {
      if (!customerAccounts.containsKey(doc.id)) {
        result.add(doc);
      }
    }

    return result;
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withValues(
              alpha: 0.18,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.16,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_drop,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Well',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  widget.wellName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Well number: ${widget.wellId ?? ''}',
                  style: const TextStyle(
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
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: 'Search by account name',

        prefixIcon: const Icon(
          Icons.search,
          color: mainColor,
        ),

        suffixIcon:
            searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(
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
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: mainColor,
            width: 2,
          ),
        ),
      ),

      onChanged: (value) {
        setState(() {
          searchText = value.trim();
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
        return 'Well operator';

      case 'sales':
        return 'Well sales';

      case 'customer':
        return 'Subscriber';

      default:
        return 'Account';
    }
  }

  // ============================================================
  // أيقونة نوع الحساب
  // ============================================================

  IconData getAccountIcon(
    String type,
  ) {
    switch (type) {
      case 'worker':
        return Icons.engineering;

      case 'sales':
        return Icons.point_of_sale;

      case 'customer':
        return Icons.person;

      default:
        return Icons.account_balance_wallet;
    }
  }

  // ============================================================
  // بطاقة الحساب
  // ============================================================

  Widget accountCard(
    BuildContext context,
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
  ) {
    final account = doc.data();

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

        if (nameSnapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            height: 90,
            margin:
                const EdgeInsets.only(
              bottom: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: mainColor.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: mainColor,
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
            'General account';

        // ======================================================
        // البحث
        // ======================================================

        if (searchText.isNotEmpty &&
            !accountName
                .toLowerCase()
                .contains(
                  searchText.toLowerCase(),
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
            getAccountTypeName(type);

        final typeColor =
            getAccountTypeColor(type);

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: mainColor.withValues(
                alpha: 0.14,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 7,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),

          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),

            // ==================================================
            // الأيقونة
            // ==================================================

            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    typeColor.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      typeColor.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),

              child: Icon(
                getAccountIcon(type),
                color: typeColor,
                size: 25,
              ),
            ),

            // ==================================================
            // اسم الحساب
            // ==================================================

            title: Text(
              accountName,
              style: const TextStyle(
                color: mainColor,
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            // ==================================================
            // تفاصيل الحساب
            // ==================================================

            subtitle: Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

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
                                  .withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),

                        child: Text(
                          typeName,
                          style: TextStyle(
                            color:
                                typeColor,
                            fontSize: 11,
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
                    'Balance: $balance',
                    style:
                        const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),

                  // رقم الحساب
                  if (accountNumber
                      .isNotEmpty)
                    Text(
                      'Account number: $accountNumber',
                      style:
                          const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),

                  // اسم البئر
                  if (wellName
                      .trim()
                      .isNotEmpty)
                    Text(
                      'Well: $wellName',
                      style:
                          const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // ==================================================
            // السهم
            // ==================================================

            trailing: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    mainColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
              ),

              child: const Icon(
                Icons.arrow_back_ios_new,
                color: mainColor,
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
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            backgroundColor,

        // ======================================================
        // شريط العنوان
        // ======================================================

        appBar: MyAppBar(
          title: 'Account reports',

          subtitle:
              hasWell
                  ? 'Well accounts: ${widget.wellName ?? ''}'
                  : 'Select an account to view its report',

          icon:
              Icons.account_balance_wallet,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
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
                width: double.infinity,

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),

                decoration:
                    BoxDecoration(
                  color: mainColor,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .account_balance_wallet,
                      color: Colors.white,
                      size: 22,
                    ),

                    const SizedBox(
                      width: 9,
                    ),

                    Expanded(
                      child: Text(
                        hasWell
                            ? 'Accounts: ${widget.wellName ?? ''}'
                            : 'All accounts',

                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                child: FutureBuilder<
                    List<
                        QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>>(
                  future: getWellAccounts(),

                  builder: (
                    context,
                    snapshot,
                  ) {
                    // ============================================
                    // خطأ
                    // ============================================

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(20),

                          child: Text(
                            'حدث خطأ:\n${snapshot.error}',

                            textAlign:
                                TextAlign.center,

                            style:
                                const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    }

                    // ============================================
                    // تحميل
                    // ============================================

                    if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: mainColor,
                        ),
                      );
                    }

                    // ============================================
                    // لا توجد حسابات
                    // ============================================

                    if (!snapshot.hasData ||
                        snapshot.data!
                            .isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons
                                  .account_balance_wallet_outlined,
                              size: 60,
                              color: Colors
                                  .grey
                                  .shade400,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              hasWell
                                  ? 'No accounts on this well'
                                  : 'No accounts',

                              style:
                                  TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ============================================
                    // المستندات
                    // ============================================

                    final docs =
                        snapshot.data!;

                    // ============================================
                    // القائمة
                    // ============================================

                    return ListView.builder(
                      itemCount:
                          docs.length,

                      itemBuilder: (
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
