import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  // ============================================================
  // اللون الموحد مع MyAppBar
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // خلفية الصفحة
  // ============================================================

  static const Color backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        // ======================================================
        // خلفية الصفحة
        // ======================================================

        backgroundColor: backgroundColor,

        // ======================================================
        // شريط العنوان الموحد
        // ======================================================

        appBar: const MyAppBar(
          title: 'الاستعلام',
          icon: Icons.search,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // شريط الاستعلام
              // نفس لون MyAppBar
              // ==================================================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),

                decoration: BoxDecoration(
                  color: mainColor,

                  borderRadius:
                      BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color:
                          mainColor.withOpacity(0.20),

                      blurRadius: 10,

                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    // ==================================================
                    // أيقونة البحث
                    // ==================================================

                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.18),

                        shape:
                            BoxShape.circle,

                        border: Border.all(
                          color:
                              Colors.white.withOpacity(0.20),
                        ),
                      ),

                      child: const Icon(
                        Icons.search,

                        color:
                            Colors.white,

                        size: 30,
                      ),
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    // ==================================================
                    // النص
                    // ==================================================

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            'الاستعلام',

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  22,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(
                            height: 5,
                          ),

                          Text(
                            'البحث والاستعلام عن بيانات الزبائن',

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // بطاقة الاستعلام
              // ==================================================

              Container(
                width: double.infinity,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),

                  border: Border.all(
                    color:
                        mainColor.withOpacity(
                      0.15,
                    ),

                    width: 1,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.06,
                      ),

                      blurRadius:
                          8,

                      offset:
                          const Offset(
                        0,
                        3,
                      ),
                    ),
                  ],
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  child: Row(
                    children: [
                      // ==================================================
                      // الأيقونة
                      // ==================================================

                      Container(
                        width: 55,
                        height: 55,

                        decoration:
                            BoxDecoration(
                          color:
                              mainColor.withOpacity(
                            0.10,
                          ),

                          shape:
                              BoxShape.circle,

                          border:
                              Border.all(
                            color:
                                mainColor.withOpacity(
                              0.15,
                            ),
                          ),
                        ),

                        child:
                            const Icon(
                          Icons.person_search,

                          color:
                              mainColor,

                          size: 30,
                        ),
                      ),

                      const SizedBox(
                        width: 15,
                      ),

                      // ==================================================
                      // النص
                      // ==================================================

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              'استعلام عن زبون',

                              style:
                                  TextStyle(
                                fontSize:
                                    18,

                                fontWeight:
                                    FontWeight.bold,

                                color:
                                    mainColor,
                              ),
                            ),

                            SizedBox(
                              height: 5,
                            ),

                            Text(
                              'البحث عن بيانات الزبون والحساب',

                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,

                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // أيقونة البحث
                      // ==================================================

                      Container(
                        width: 36,
                        height: 36,

                        decoration:
                            BoxDecoration(
                          color:
                              mainColor.withOpacity(
                            0.08,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),

                        child:
                            const Icon(
                          Icons.search,

                          color:
                              mainColor,

                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}