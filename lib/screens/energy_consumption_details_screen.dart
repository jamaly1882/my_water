import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/my_app_bar.dart';

class EnergyConsumptionDetailsScreen extends StatelessWidget {
  final String? wellId;
  final String? wellName;

  final List<Map<String, dynamic>> cycles;

  const EnergyConsumptionDetailsScreen({
    super.key,
    this.wellId,
    this.wellName,
    required this.cycles,
  });

  static const Color mainColor = Colors.blue;
  static const Color backgroundColor = Color(0xFFF5F9FF);

  // ============================================================
  // تحويل القيمة إلى Double
  // ============================================================

  double toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  // ============================================================
  // تحويل القيمة إلى DateTime
  // ============================================================

  DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // تحديد نوع الطاقة
  // ============================================================

  String getEnergyType(
    Map<String, dynamic> cycle,
  ) {
    final calculated =
        cycle['energyTypeCalculated']
            ?.toString()
            .trim();

    if (calculated != null &&
        calculated.isNotEmpty) {
      return calculated;
    }

    final values = [
      cycle['energyType'],
      cycle['energy_type'],
      cycle['meterType'],
      cycle['meter_type'],
      cycle['type'],
      cycle['powerType'],
      cycle['power_type'],
      cycle['source'],
      cycle['energy'],
    ];

    for (final value in values) {
      if (value == null) continue;

      final text = value
          .toString()
          .trim()
          .toLowerCase();

      if (text.contains('شمس') ||
          text.contains('solar') ||
          text.contains('sun')) {
        return 'طاقة شمسية';
      }

      if (text.contains('ديزل') ||
          text.contains('diesel') ||
          text.contains('مولد') ||
          text.contains('generator')) {
        return 'ديزل';
      }
    }

    return 'غير محدد';
  }

  // ============================================================
  // رقم الدورة
  // ============================================================

  String getCycleNumber(
    Map<String, dynamic> cycle,
  ) {
    final value =
        cycle['calculatedCycleNumber'] ??
            cycle['cycleNumber'] ??
            cycle['cycleNo'] ??
            cycle['number'] ??
            cycle['cycle_number'];

    if (value == null) {
      return '-';
    }

    return value.toString();
  }

  // ============================================================
  // اسم العميل
  // ============================================================

  String getCustomerName(
    Map<String, dynamic> cycle,
  ) {
    final value =
        cycle['calculatedCustomerName'] ??
            cycle['customerName'] ??
            cycle['customer'] ??
            cycle['customer_name'];

    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    return text.isEmpty ? '-' : text;
  }

  // ============================================================
  // القراءة السابقة
  // ============================================================

  String getPreviousReading(
    Map<String, dynamic> cycle,
  ) {
    final value =
        cycle['calculatedPreviousReading'] ??
            cycle['previousReading'] ??
            cycle['previous_reading'] ??
            cycle['startReading'] ??
            cycle['oldReading'];

    if (value == null) {
      return '-';
    }

    return value.toString();
  }

  // ============================================================
  // القراءة الحالية
  // ============================================================

  String getCurrentReading(
    Map<String, dynamic> cycle,
  ) {
    final value =
        cycle['calculatedCurrentReading'] ??
            cycle['currentReading'] ??
            cycle['current_reading'] ??
            cycle['endReading'] ??
            cycle['newReading'];

    if (value == null) {
      return '-';
    }

    return value.toString();
  }

  // ============================================================
  // الاستهلاك
  // ============================================================

  double getConsumption(
    Map<String, dynamic> cycle,
  ) {
    return toDouble(
      cycle['calculatedConsumption'] ??
          cycle['consumption'] ??
          cycle['energyConsumption'] ??
          cycle['energy_consumption'],
    );
  }

  // ============================================================
  // تاريخ البداية
  // ============================================================

  DateTime? getStartDate(
    Map<String, dynamic> cycle,
  ) {
    return toDateTime(
      cycle['calculatedStartDate'] ??
          cycle['startDate'] ??
          cycle['start_date'] ??
          cycle['openedAt'] ??
          cycle['createdAt'],
    );
  }

  // ============================================================
  // تاريخ النهاية
  // ============================================================

  DateTime? getEndDate(
    Map<String, dynamic> cycle,
  ) {
    return toDateTime(
      cycle['calculatedEndDate'] ??
          cycle['endDate'] ??
          cycle['end_date'] ??
          cycle['closedAt'] ??
          cycle['closed_at'],
    );
  }

  // ============================================================
  // مدة الدورة
  // ============================================================

  Duration getDuration(
    Map<String, dynamic> cycle,
  ) {
    final calculated =
        cycle['calculatedDuration'];

    if (calculated is Duration) {
      return calculated;
    }

    final start = getStartDate(cycle);
    final end = getEndDate(cycle);

    if (start == null || end == null) {
      return Duration.zero;
    }

    final duration = end.difference(start);

    if (duration.isNegative) {
      return Duration.zero;
    }

    return duration;
  }

  // ============================================================
  // تنسيق الرقم
  // ============================================================

  String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // تنسيق المدة
  // ============================================================

  String formatDuration(
    Duration duration,
  ) {
    if (duration.isNegative) {
      return '0 دقيقة';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days يوم و $hours ساعة';
    }

    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }

    return '$minutes دقيقة';
  }

  // ============================================================
  // تنسيق التاريخ
  // ============================================================

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  // ============================================================
  // أيقونة الطاقة
  // ============================================================

  IconData getEnergyIcon(
    String energyType,
  ) {
    if (energyType == 'طاقة شمسية') {
      return Icons.wb_sunny;
    }

    if (energyType == 'ديزل') {
      return Icons.local_gas_station;
    }

    return Icons.bolt;
  }

  // ============================================================
  // صف بيانات
  // ============================================================

  Widget buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: mainColor,
            size: 21,
          ),

          const SizedBox(width: 10),

          Text(
            '$title:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الدورة
  // ============================================================

  Widget buildCycleCard(
    Map<String, dynamic> cycle,
  ) {
    final energyType =
        getEnergyType(cycle);

    final consumption =
        getConsumption(cycle);

    final startDate =
        getStartDate(cycle);

    final endDate =
        getEndDate(cycle);

    final duration =
        getDuration(cycle);

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====================================================
            // رأس الدورة
            // ====================================================

            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color: mainColor
                        .withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    getEnergyIcon(
                      energyType,
                    ),
                    color: mainColor,
                    size: 27,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'الدورة رقم ${getCycleNumber(cycle)}',
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        energyType,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          color: mainColor,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(
              height: 25,
            ),

            // ====================================================
            // بيانات الدورة
            // ====================================================

            buildInfoRow(
              icon:
                  Icons.person_outline,
              title: 'العميل',
              value:
                  getCustomerName(
                cycle,
              ),
            ),

            buildInfoRow(
              icon: Icons.speed,
              title: 'القراءة السابقة',
              value:
                  getPreviousReading(
                cycle,
              ),
            ),

            buildInfoRow(
              icon:
                  Icons.speed_outlined,
              title: 'القراءة الحالية',
              value:
                  getCurrentReading(
                cycle,
              ),
            ),

            buildInfoRow(
              icon:
                  Icons.water_drop_outlined,
              title: 'الاستهلاك',
              value:
                  formatNumber(
                consumption,
              ),
            ),

            buildInfoRow(
              icon: Icons.timelapse,
              title: 'مدة الدورة',
              value:
                  formatDuration(
                duration,
              ),
            ),

            buildInfoRow(
              icon:
                  Icons.play_arrow_outlined,
              title: 'بداية الدورة',
              value:
                  formatDate(
                startDate,
              ),
            ),

            buildInfoRow(
              icon:
                  Icons.stop_outlined,
              title: 'نهاية الدورة',
              value:
                  formatDate(
                endDate,
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // حالة الدورة
            // ====================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 12,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.green
                    .withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 19,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'الدورة مغلقة',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // بناء الصفحة
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            backgroundColor,

        appBar: MyAppBar(
          title: 'تفاصيل الدورات',
        ),

        body: cycles.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد دورات مغلقة',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              )
            : ListView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                children: [
                  // ==================================================
                  // اسم البئر
                  // ==================================================

                  if (wellName != null &&
                      wellName!
                          .trim()
                          .isNotEmpty)
                    Container(
                      width:
                          double.infinity,
                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.water,
                            color:
                                mainColor,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Text(
                              'البئر: $wellName',
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================================
                  // عدد الدورات
                  // ==================================================

                  Container(
                    width:
                        double.infinity,
                    margin:
                        const EdgeInsets.only(
                      bottom: 16,
                    ),
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.list_alt,
                          color:
                              mainColor,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Text(
                          'إجمالي الدورات: ${cycles.length}',
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // جميع الدورات
                  // ==================================================

                  ...cycles.map(
                    (cycle) =>
                        buildCycleCard(
                      cycle,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
      ),
    );
  }
}