// ============================================================
// cycle_screen.dart
// ============================================================

import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

import 'customer_search_screen.dart';
import 'reading_list_screen.dart';

class CycleScreen extends StatelessWidget {
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

  const CycleScreen({
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

  // ============================================================
  // اللون الرئيسي
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // لون خلفية الصفحة
  // ============================================================

  static const Color backgroundColor = Color(0xffF5F9FF);

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
        // شريط العنوان
        // ======================================================

        appBar: const MyAppBar(
          title: 'الدور لإدخال القراءات',
          icon: Icons.speed,
        ),

        // ======================================================
        // محتوى الصفحة
        // ======================================================

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // بطاقة معلومات الدور
              // ==================================================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: mainColor,

                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.20),

                      blurRadius: 10,

                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: const Row(
                  children: [
                    // ==========================================
                    // الأيقونة
                    // ==========================================

                    Icon(
                      Icons.speed,
                      color: Colors.white,
                      size: 38,
                    ),

                    SizedBox(width: 14),

                    // ==========================================
                    // النص
                    // ==========================================

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'الدور لإدخال القراءات',

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'إدخال قراءة بداية الدور وقراءة نهاية الدور',

                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // القوائم
              // ==================================================

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,

                  crossAxisSpacing: 14,

                  mainAxisSpacing: 14,

                  childAspectRatio: 0.95,

                  children: [
                    // ============================================
                    // قراءة بداية الدور
                    // ============================================

                    _menuCard(
                      context: context,

                      title: 'قراءة بداية الدور',

                      subtitle:
                          'إدخال قراءة بداية الدورة للزبون',

                      icon: Icons.add_circle,

                      page: CustomerSearchScreen(
                        supervisorId: supervisorId,

                        provinceId: provinceId,

                        provinceName: provinceName,

                        districtId: districtId,

                        districtName: districtName,

                        hamletId: hamletId,

                        hamletName: hamletName,

                        villageId: villageId,

                        villageName: villageName,

                        wellId: wellId,

                        wellName: wellName,
                      ),
                    ),

                    // ============================================
                    // قراءة نهاية الدور
                    // ============================================

                    _menuCard(
                      context: context,

                      title: 'قراءة نهاية الدور',

                      subtitle:
                          'إدخال قراءة نهاية الدورة للزبون',

                      icon: Icons.speed,

                      page: ReadingListScreen(
                        supervisorId: supervisorId,

                        provinceId: provinceId,

                        provinceName: provinceName,

                        districtId: districtId,

                        districtName: districtName,

                        hamletId: hamletId,

                        hamletName: hamletName,

                        villageId: villageId,

                        villageName: villageName,

                        wellId: wellId,

                        wellName: wellName,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة القائمة
  // ============================================================

  Widget _menuCard({
    required BuildContext context,

    required String title,

    required String subtitle,

    required IconData icon,

    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },

        child: Ink(
          decoration: BoxDecoration(
            // ==================================================
            // الخلفية بيضاء
            // ==================================================

            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            // ==================================================
            // حدود خفيفة
            // ==================================================

            border: Border.all(
              color: mainColor.withOpacity(0.15),

              width: 1,
            ),

            // ==================================================
            // ظل خفيف
            // ==================================================

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),

                blurRadius: 8,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(14),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // ==============================================
                // دائرة الأيقونة
                // ==============================================

                Container(
                  width: 68,

                  height: 68,

                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.10),

                    shape: BoxShape.circle,

                    border: Border.all(
                      color: mainColor.withOpacity(0.18),
                    ),
                  ),

                  child: Icon(
                    icon,

                    color: mainColor,

                    size: 38,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==============================================
                // عنوان البطاقة
                // ==============================================

                Text(
                  title,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: mainColor,

                    fontSize: 16,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                // ==============================================
                // وصف البطاقة
                // ==============================================

                Text(
                  subtitle,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.black54,

                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==============================================
                // زر السهم
                // ==============================================

                Container(
                  width: 34,

                  height: 34,

                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.08),

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: const Icon(
                    Icons.arrow_back_ios_new,

                    color: mainColor,

                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}