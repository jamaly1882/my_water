
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/my_app_bar.dart';
import 'energy_consumption_details_screen.dart';

class EnergyConsumptionReportScreen extends StatefulWidget {
  final String? wellId;
  final String? wellName;

  const EnergyConsumptionReportScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  @override
  State<EnergyConsumptionReportScreen> createState() =>
      _EnergyConsumptionReportScreenState();
}

class _EnergyConsumptionReportScreenState
    extends State<EnergyConsumptionReportScreen> {
  static const Color mainColor = Colors.blue;
  static const Color backgroundColor = Color(0xFFF5F9FF);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> cycles = [];

  double solarConsumption = 0;
  double dieselConsumption = 0;

  Duration solarDuration = Duration.zero;
  Duration dieselDuration = Duration.zero;

  int solarCycles = 0;
  int dieselCycles = 0;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  String normalizeType(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '');
  }

  bool isSolar(String value) {
    final name = normalizeType(value);

    return name.contains('شمسي') ||
        name.contains('شمس') ||
        name.contains('طاقهشمسيه') ||
        name.contains('طاقهشمسي') ||
        name.contains('طاقةشمسية') ||
        name.contains('طاقةشمس') ||
        name.contains('solar');
  }

  bool isDiesel(String value) {
    final name = normalizeType(value);

    return name.contains('ديزل') ||
        name.contains('دیزل') ||
        name.contains('diesel');
  }

  String detectEnergyType(Map<String, dynamic> data) {
    final candidates = <String>[
      data['energyType']?.toString() ?? '',
      data['meterTypeName']?.toString() ?? '',
      data['meterType']?.toString() ?? '',
      data['meterType_name']?.toString() ?? '',
      data['meterName']?.toString() ?? '',
    ];

    for (final candidate in candidates) {
      if (candidate.trim().isEmpty) {
        continue;
      }

      if (isSolar(candidate)) {
        return 'الطاقة الشمسية';
      }

      if (isDiesel(candidate)) {
        return 'الديزل';
      }
    }

    for (final candidate in candidates) {
      if (candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return 'غير محدد';
  }

  String getRawMeterTypeName(Map<String, dynamic> data) {
    final fields = <String>[
      data['meterTypeName']?.toString() ?? '',
      data['meterType']?.toString() ?? '',
      data['meterType_name']?.toString() ?? '',
      data['meterName']?.toString() ?? '',
      data['energyType']?.toString() ?? '',
    ];

    for (final value in fields) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '0 دقيقة';
    }

    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0 && minutes == 0) {
      return '0 دقيقة';
    }

    if (hours == 0) {
      return '$minutes دقيقة';
    }

    if (minutes == 0) {
      return '$hours ساعة';
    }

    return '$hours ساعة و$minutes دقيقة';
  }

  Future<void> loadReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      Query<Map<String, dynamic>> query =
          firestore.collection('cycles');

      if (widget.wellId != null &&
          widget.wellId!.trim().isNotEmpty) {
        query = query.where(
          'wellId',
          isEqualTo: widget.wellId!.trim(),
        );
      }

      final snapshot = await query.get();

      final result = <Map<String, dynamic>>[];

      double solarTotal = 0;
      double dieselTotal = 0;

      Duration solarTotalDuration = Duration.zero;
      Duration dieselTotalDuration = Duration.zero;

      int solarCount = 0;
      int dieselCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final status =
            data['status']?.toString().trim() ?? '';

        if (status != 'مغلق' &&
            status.toLowerCase() != 'closed') {
          continue;
        }

        final meterTypeName =
            getRawMeterTypeName(data);

        final energyType =
            detectEnergyType(data);

        final consumption =
            toDouble(data['consumption']);

        final startDate =
            toDateTime(data['startDate']);

        final endDate =
            toDateTime(data['endDate']) ??
            toDateTime(data['closedAt']);

        Duration duration = Duration.zero;

        if (startDate != null &&
            endDate != null &&
            !endDate.isBefore(startDate)) {
          duration =
              endDate.difference(startDate);
        }

        final isSolarCycle =
            isSolar(meterTypeName) ||
            isSolar(energyType);

        final isDieselCycle =
            isDiesel(meterTypeName) ||
            isDiesel(energyType);

        if (isSolarCycle) {
          solarTotal += consumption;
          solarTotalDuration += duration;
          solarCount++;
        } else if (isDieselCycle) {
          dieselTotal += consumption;
          dieselTotalDuration += duration;
          dieselCount++;
        }

        result.add({
          'id': doc.id,
          ...data,
          'energyType': energyType,
          'calculatedDuration': duration,
          'calculatedEndDate': endDate,
        });
      }

      result.sort((a, b) {
        final aDate =
            toDateTime(a['startDate']);

        final bDate =
            toDateTime(b['startDate']);

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        cycles = result;

        solarConsumption = solarTotal;
        dieselConsumption = dieselTotal;

        solarDuration = solarTotalDuration;
        dieselDuration = dieselTotalDuration;

        solarCycles = solarCount;
        dieselCycles = dieselCount;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String get wellTitle {
    if (widget.wellName == null ||
        widget.wellName!.trim().isEmpty) {
      return 'جميع البيانات';
    }

    return 'البئر: ${widget.wellName}';
  }

  Widget buildSummaryCard({
    required String title,
    required IconData icon,
    required double consumption,
    required Duration duration,
    required int cyclesCount,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: mainColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _summaryRow(
              'الاستهلاك',
              '${formatNumber(consumption)} وحدة',
              Icons.water_drop,
            ),
            const SizedBox(height: 7),
            _summaryRow(
              'عدد الساعات',
              formatDuration(duration),
              Icons.access_time,
            ),
            const SizedBox(height: 7),
            _summaryRow(
              'عدد الأدوار',
              cyclesCount.toString(),
              Icons.loop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: mainColor,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EnergyConsumptionDetailsScreen(
          wellId: widget.wellId,
          wellName: widget.wellName,
          cycles: cycles,
        ),
      ),
    );
  }

  Widget buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'لا توجد دورات مغلقة لهذا البئر',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيظهر تقرير استهلاك الطاقة بعد إغلاق الدورات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: MyAppBar(
          title: 'تقرير استهلاك الطاقة',
          subtitle: wellTitle,
          icon: Icons.bolt,
          showBackButton: true,
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: mainColor,
                ),
              )
            : errorMessage != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: loadReport,
                    color: mainColor,
                    child: ListView(
                      padding:
                          const EdgeInsets.all(16),
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child:
                                  buildSummaryCard(
                                title:
                                    'الطاقة الشمسية',
                                icon:
                                    Icons.wb_sunny,
                                consumption:
                                    solarConsumption,
                                duration:
                                    solarDuration,
                                cyclesCount:
                                    solarCycles,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  buildSummaryCard(
                                title: 'الديزل',
                                icon:
                                    Icons.local_gas_station,
                                consumption:
                                    dieselConsumption,
                                duration:
                                    dieselDuration,
                                cyclesCount:
                                    dieselCycles,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildTotalCard(),

                        const SizedBox(height: 20),

                        if (cycles.isNotEmpty)
                          _buildDetailsButton()
                        else
                          SizedBox(
                            height: 300,
                            child: buildEmpty(),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.bolt,
              color: mainColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'استهلاك الطاقة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  wellTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'الإجمالي',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _totalBox(
                    'الاستهلاك',
                    formatNumber(
                      solarConsumption +
                          dieselConsumption,
                    ),
                    'وحدة',
                    Icons.water_drop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _totalBox(
                    'الساعات',
                    formatDuration(
                      solarDuration +
                          dieselDuration,
                    ),
                    '',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: openDetails,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      mainColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: mainColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل الدورات',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'عرض جميع الدورات وتفاصيل استهلاك الطاقة',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios,
                color: mainColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 12),
            const Text(
              'حدث خطأ أثناء تحميل التقرير',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: loadReport,
              icon: const Icon(Icons.refresh),
              label:
                  const Text('إعادة المحاولة'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBox(
    String title,
    String value,
    String suffix,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: mainColor,
            size: 25,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mainColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (suffix.isNotEmpty)
            Text(
              suffix,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

