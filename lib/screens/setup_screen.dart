
import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

import 'customer_screen.dart';
import 'well_customers_screen.dart';
import 'meter_type_screen.dart';
import 'water_usage_screen.dart';
import 'create_sales_account_screen.dart';

class SetupScreen extends StatelessWidget {
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

  const SetupScreen({
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F9FF),

        // ==========================================================
        // شريط العنوان الموحد
        // ==========================================================

        appBar: const MyAppBar(
          title: 'التهيئة',
        ),

        // ==========================================================
        // القائمة
        // ==========================================================

        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ======================================================
            // إضافة زبون
            // ======================================================

            _item(
              context,
              'إضافة زبون',
              Icons.person_add_alt_1,
              Colors.blue,
              CustomerScreen(
                supervisorId: supervisorId ?? '',
                provinceId: provinceId,
                provinceName: provinceName,
                districtId: districtId,
                districtName: districtName,
                hamletId: hamletId,
                hamletName: hamletName,
                villageId: villageId,
                villageName: villageName,
              ),
            ),

            // ======================================================
            // إضافة زبون بئر
            // ======================================================

            _item(
              context,
              'إضافة زبون بئر',
              Icons.water_drop,
              Colors.cyan,
              WellCustomerScreen(
                supervisorId: supervisorId,
                provinceId: provinceId,
                districtId: districtId,
                hamletId: hamletId,
                villageId: villageId,
                wellId: wellId,
                wellName: wellName,
              ),
            ),

            // ======================================================
            // نوع استخدام المياه
            // ======================================================

            _item(
              context,
              'نوع استخدام المياه',
              Icons.category,
              Colors.green,
              const WaterUsageScreen(),
            ),

            // ======================================================
            // نوع العداد
            // ======================================================

            _item(
              context,
              'نوع المعدة',
              Icons.speed,
              Colors.orange,

              // إزالة const لأن MeterTypeScreen
              // لا يحتوي على constructor const
              EquipmentTypeScreen(
               supervisorId: supervisorId,
                provinceId: provinceId,
                districtId: districtId,
                hamletId: hamletId,
                villageId: villageId,
                wellId: wellId,
                wellName: wellName,),
            ),

            // ======================================================
            // الحسابات المالية
            // ======================================================

            _item(
              context,
              'إنشاء الحسابات المالية',
              Icons.point_of_sale,
              Colors.red,
              CreateSalesAccountScreen(
                supervisorId: supervisorId,
                wellId: wellId,
                wellName: wellName,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // عنصر القائمة
  // ==============================================================

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(.15),
          child: Icon(
            icon,
            size: 27,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
      ),
    );
  }
}

