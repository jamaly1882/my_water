import 'package:flutter/material.dart';

import '../../widgets/my_app_bar.dart';
import 'dart:math';

import 'provinces_screen.dart';
import 'districts_screen.dart';
import 'hamlets_screen.dart';
import 'villages_screen.dart';
import 'wells_screen.dart';
import 'supervisors_screen.dart';

class SetupMshrfScreen extends StatelessWidget {
  const SetupMshrfScreen({super.key});

  // ============================================================
  // اللون الموحد مع MyAppBar
  // ============================================================

  static const Color mainColor = Colors.blue;

  // ============================================================
  // خلفية الصفحة
  // ============================================================

  static const Color backgroundColor =
      Color(0xffF5F9FF);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor: backgroundColor,

        // ======================================================
        // شريط العنوان الموحد
        // ======================================================

        appBar: const MyAppBar(
          title: 'تهيئة البيانات',
          showBackButton: true,
        ),

        // ======================================================
        // المحتوى
        // ======================================================

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: GridView.count(
            crossAxisCount: 2,

            crossAxisSpacing: 16,
            mainAxisSpacing: 16,

            childAspectRatio: 1,

            children: [
              // ==================================================
              // المحافظات
              // ==================================================

              _menuCard(
                context,
                'تهيئة المحافظات',
                Icons.location_city,
                const ProvincesScreen(),
              ),

              // ==================================================
              // المديريات
              // ==================================================

              _menuCard(
                context,
                'تهيئة المديريات',
                Icons.map,
                const DistrictsScreen(),
              ),

              // ==================================================
              // العزل
              // ==================================================

              _menuCard(
                context,
                'تهيئة العُزل',
                Icons.home_work,
                const HamletsScreen(),
              ),

              // ==================================================
              // القرى
              // ==================================================

              _menuCard(
                context,
                'تهيئة القرى',
                Icons.home,
                const VillagesScreen(),
              ),

              // ==================================================
              // الآبار
              // ==================================================

              _menuCard(
                context,
                'تهيئة الآبار',
                Icons.water_drop,
                const WellsScreen(),
              ),

              // ==================================================
              // المشرفين
              // ==================================================

              _menuCard(
                context,
                'تهيئة المشرفين',
                Icons.supervisor_account,
                const SupervisorsScreen(),
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

  Widget _menuCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Card(
      // ========================================================
      // البطاقة بيضاء
      // ========================================================

      color: Colors.white,

      elevation: 3,

      shadowColor:
          mainColor.withOpacity(0.18),

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },

        child: Padding(
          padding:
              const EdgeInsets.all(12),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              // ==================================================
              // الأيقونة
              // ==================================================

              Container(
                width: 70,
                height: 70,

                decoration: BoxDecoration(
                  color: Colors.white,

                  shape: BoxShape.circle,

                  border: Border.all(
                    color:
                        mainColor.withOpacity(0.35),
                    width: 2,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          mainColor.withOpacity(0.10),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),

                child: Icon(
                  icon,
                  size: 38,
                  color: mainColor,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // اسم التهيئة
              // ==================================================

              Text(
                title,

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,

                  fontSize: 15,

                  color: Colors.black87,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // سهم الدخول
              // ==================================================

              Container(
                width: 32,
                height: 32,

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(9),

                  border: Border.all(
                    color:
                        mainColor.withOpacity(0.30),
                  ),
                ),

                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: mainColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}