import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/gm_dashboard_service.dart';
import '../../widgets/gm_ui.dart';
import '../cycle_report_menu_screen.dart';

// ============================================================
// تبويب الخريطة التفاعلية
// ============================================================

class GmMapView extends StatefulWidget {
  final GmDashboardData? data;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const GmMapView({
    super.key,
    required this.data,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<GmMapView> createState() => _GmMapViewState();
}

class _GmMapViewState extends State<GmMapView> {
  bool _showWells = true;
  bool _showVillages = true;

  @override
  Widget build(BuildContext context) {
    final GmDashboardData? value = widget.data;

    if (value == null) {
      return _placeholder();
    }

    return Column(
      children: <Widget>[
        _header(value),
        Expanded(child: _mapArea(value)),
        _footer(value),
      ],
    );
  }

  // ==========================================================
  // حالة التحميل
  // ==========================================================

  Widget _placeholder() {
    if (widget.loading) {
      return const Center(
        child: CircularProgressIndicator(color: gmPrimary),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GmCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.map_outlined,
                size: 46,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل الخريطة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: gmTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.error ??
                    'تحقق من الاتصال بالإنترنت وصلاحيات الحساب.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onRefresh();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gmPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // رأس الخريطة
  // ==========================================================

  Widget _header(GmDashboardData value) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gmBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _toggle(
                  label: 'الآبار (${value.wellCount})',
                  icon: Icons.water_drop,
                  active: _showWells,
                  color: gmPrimary,
                  onTap: () {
                    setState(() {
                      _showWells = !_showWells;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _toggle(
                  label: 'القرى (${value.villageCount})',
                  icon: Icons.home,
                  active: _showVillages,
                  color: gmAccent,
                  onTap: () {
                    setState(() {
                      _showVillages = !_showVillages;
                    });
                  },
                ),
              ),
              IconButton(
                onPressed: widget.loading
                    ? null
                    : () {
                        widget.onRefresh();
                      },
                icon: const Icon(
                  Icons.refresh,
                  size: 19,
                  color: gmPrimary,
                ),
                tooltip: 'تحديث',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                'كثافة الاستهلاك',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF26A69A),
                        Color(0xFFFFA726),
                        Color(0xFFE53935),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'مرتفع',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (value.wellsWithCoordinates.length <
              value.wellCount) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value.hasCoordinates
                        ? 'بعض الآبار بلا إحداثيات، وتظهر بموقع تخطيطي. '
                            'اضغط على أي بئر لتحديد موقعه.'
                        : 'المواقع تخطيطية حسب المحافظة والقرية. '
                            'اضغط على أي بئر لتحديد إحداثياته على الخريطة.',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.4,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggle({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 15,
              color: active ? color : Colors.grey,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? color
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // منطقة الخريطة
  // ==========================================================

  Widget _mapArea(GmDashboardData value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3FF),
            border: Border.all(color: gmBorder),
          ),
          child: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              final double side = math.max(
                1.0,
                math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              );

              return InteractiveViewer(
                minScale: 0.7,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(60),
                child: Center(
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: _mapCanvas(value, side),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _mapCanvas(
    GmDashboardData value,
    double side,
  ) {
    final List<Widget> markers = <Widget>[];

    if (_showVillages) {
      for (final GmVillageData village in value.villages) {
        markers.add(_villageMarker(village, value, side));
      }
    }

    if (_showWells) {
      for (final GmWellData well in value.wells) {
        markers.add(_wellMarker(well, value, side));
      }
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: _MapBackgroundPainter(),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _MapLinksPainter(
              villages: _showVillages
                  ? value.villages
                  : const <GmVillageData>[],
            ),
          ),
        ),
        ...markers,
      ],
    );
  }

  Widget _wellMarker(
    GmWellData well,
    GmDashboardData value,
    double side,
  ) {
    if (well.mapX < 0 || well.mapY < 0) {
      return const SizedBox.shrink();
    }

    final double maxValue = value.maxWellConsumption;

    final double ratio = maxValue <= 0
        ? 0
        : (well.consumption / maxValue)
            .clamp(0.0, 1.0)
            .toDouble();

    final double size = 24 + 14 * ratio;

    return Positioned(
      left: well.mapX * side - size / 2,
      top: well.mapY * side - size / 2,
      child: Tooltip(
        message:
            '${well.name}\n${gmFormatNumber(well.consumption)} م³',
        child: GestureDetector(
          onTap: () {
            _showWellSheet(context, well, value);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: gmHeatColor(ratio),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.water_drop,
              size: size * 0.52,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _villageMarker(
    GmVillageData village,
    GmDashboardData value,
    double side,
  ) {
    if (village.mapX < 0 || village.mapY < 0) {
      return const SizedBox.shrink();
    }

    final double maxValue = value.maxVillageConsumption;

    final double ratio = maxValue <= 0
        ? 0
        : (village.consumption / maxValue)
            .clamp(0.0, 1.0)
            .toDouble();

    const double width = 78;
    const double height = 32;

    return Positioned(
      left: village.mapX * side - width / 2,
      top: village.mapY * side - height / 2,
      child: GestureDetector(
        onTap: () {
          _showVillageSheet(context, village, value);
        },
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: gmHeatColor(ratio).withValues(alpha: 0.8),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: gmHeatColor(ratio),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      village.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: gmTextDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                '${gmFormatNumber(village.consumption)} م³',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 7.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // شريط سفلي
  // ==========================================================

  Widget _footer(GmDashboardData value) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gmBorder),
      ),
      child: Row(
        children: <Widget>[
          _footerItem(
            Icons.water_drop,
            '${value.wellCount}',
            'بئر',
            gmPrimary,
          ),
          _footerItem(
            Icons.home,
            '${value.villageCount}',
            'قرية',
            gmAccent,
          ),
          _footerItem(
            Icons.my_location,
            '${value.wellsWithCoordinates.length}',
            'بإحداثيات',
            const Color(0xFF5E35B1),
          ),
          _footerItem(
            Icons.opacity,
            gmFormatNumber(value.currentMonthConsumption),
            'م³ هذا الشهر',
            const Color(0xFFEF6C00),
          ),
        ],
      ),
    );
  }

  Widget _footerItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // بطاقة البئر
  // ==========================================================

  Future<void> _showWellSheet(
    BuildContext context,
    GmWellData well,
    GmDashboardData data,
  ) async {
    final double maxValue = data.maxWellConsumption;

    final double ratio = maxValue <= 0
        ? 0
        : (well.consumption / maxValue)
            .clamp(0.0, 1.0)
            .toDouble();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: gmHeatColor(ratio)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.water_drop,
                            color: gmHeatColor(ratio),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                well.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: gmTextDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                well.locationLabel.isEmpty
                                    ? 'موقع غير محدد'
                                    : well.locationLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.4,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        GmPill(
                          label: well.hasSupervisor
                              ? 'المشرف: ${well.supervisorName}'
                              : 'بدون مشرف',
                          color: well.hasSupervisor
                              ? gmAccent
                              : const Color(0xFFD32F2F),
                          icon: Icons.person_outline,
                        ),
                        if (well.needsReview)
                          const GmPill(
                            label: 'تحتاج مراجعة',
                            color: Color(0xFFD32F2F),
                            icon: Icons.warning_amber_rounded,
                          ),
                        GmPill(
                          label:
                              '${well.closedCycles} دورة مغلقة',
                          color: gmPrimary,
                          icon: Icons.loop,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9FF),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(color: gmBorder),
                      ),
                      child: Column(
                        children: <Widget>[
                          GmInfoRow(
                            label: 'استهلاك هذا الشهر',
                            value:
                                '${gmFormatNumber(well.currentMonthConsumption)} م³',
                            icon: Icons.calendar_month,
                            valueColor: gmPrimary,
                          ),
                          GmInfoRow(
                            label: 'الشهر الماضي',
                            value:
                                '${gmFormatNumber(well.previousMonthConsumption)} م³',
                            icon: Icons.history,
                          ),
                          GmInfoRow(
                            label: 'التغير',
                            value:
                                well.changePercentOrNull == null
                                    ? 'بدون مقارنة'
                                    : gmFormatPercent(
                                        well.changePercent,
                                      ),
                            icon: Icons.trending_up,
                            valueColor: well.changePercent < 0
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFD32F2F),
                          ),
                          GmInfoRow(
                            label: 'إجمالي الاستهلاك',
                            value:
                                '${gmFormatNumber(well.consumption)} م³',
                            icon: Icons.opacity,
                          ),
                          GmInfoRow(
                            label: 'المشتركون',
                            value:
                                gmFormatNumber(well.subscribers),
                            icon: Icons.people_alt,
                          ),
                          GmInfoRow(
                            label: 'آخر دورة',
                            value:
                                gmFormatDate(well.lastCycleDate),
                            icon: Icons.event,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (well.hasCoordinates)
                      GmInfoRow(
                        label: 'الإحداثيات',
                        value: well.coordinatesLabel,
                        icon: Icons.place,
                      )
                    else
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'لم يتم تحديد إحداثيات هذا البئر بعد.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await _editCoordinates(well);
                            },
                            icon: const Icon(
                              Icons.my_location,
                              size: 17,
                            ),
                            label: const Text(
                              'تحديد الموقع',
                              style: TextStyle(fontSize: 11.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: gmPrimary,
                              side: const BorderSide(
                                color: gmBorder,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _openReports(well);
                            },
                            icon: const Icon(
                              Icons.bar_chart,
                              size: 17,
                            ),
                            label: const Text(
                              'التقارير',
                              style: TextStyle(fontSize: 11.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gmPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // بطاقة القرية
  // ==========================================================

  Future<void> _showVillageSheet(
    BuildContext context,
    GmVillageData village,
    GmDashboardData data,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.82,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: gmAccent.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.home_work,
                              color: gmAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  village.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: gmTextDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  village.locationLabel.isEmpty
                                      ? 'موقع غير محدد'
                                      : village.locationLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.4,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: <Widget>[
                          GmPill(
                            label:
                                '${village.wellCount} آبار',
                            color: gmPrimary,
                            icon: Icons.water_drop,
                          ),
                          GmPill(
                            label:
                                '${gmFormatNumber(village.subscribers)} مشترك',
                            color: const Color(0xFF00838F),
                            icon: Icons.people_alt,
                          ),
                          if (village.needsAttention)
                            const GmPill(
                              label: 'ارتفاع غير طبيعي',
                              color: Color(0xFFEF6C00),
                              icon: Icons.warning_amber_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FF),
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(color: gmBorder),
                        ),
                        child: Column(
                          children: <Widget>[
                            GmInfoRow(
                              label: 'استهلاك هذا الشهر',
                              value:
                                  '${gmFormatNumber(village.currentMonthConsumption)} م³',
                              icon: Icons.calendar_month,
                              valueColor: gmPrimary,
                            ),
                            GmInfoRow(
                              label: 'الشهر الماضي',
                              value:
                                  '${gmFormatNumber(village.previousMonthConsumption)} م³',
                              icon: Icons.history,
                            ),
                            GmInfoRow(
                              label: 'التغير',
                              value: village
                                          .changePercentOrNull ==
                                      null
                                  ? 'بدون مقارنة'
                                  : gmFormatPercent(
                                      village.changePercent,
                                    ),
                              icon: Icons.trending_up,
                              valueColor:
                                  village.changePercent < 0
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFD32F2F),
                            ),
                            GmInfoRow(
                              label: 'إجمالي الاستهلاك',
                              value:
                                  '${gmFormatNumber(village.consumption)} م³',
                              icon: Icons.opacity,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'الآبار التابعة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: gmTextDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (village.wells.isEmpty)
                        const GmEmptyState(
                          title: 'لا توجد آبار',
                          message:
                              'لم تُسجل آبار تابعة لهذه القرية بعد.',
                          icon: Icons.water_drop_outlined,
                        )
                      else
                        ...village.wells.take(10).map(
                              (GmWellData well) => ListTile(
                                contentPadding:
                                    EdgeInsets.zero,
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 15,
                                  backgroundColor:
                                      gmPrimary.withValues(
                                    alpha: 0.10,
                                  ),
                                  child: const Icon(
                                    Icons.water_drop,
                                    size: 15,
                                    color: gmPrimary,
                                  ),
                                ),
                                title: Text(
                                  well.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: gmTextDark,
                                  ),
                                ),
                                subtitle: Text(
                                  '${gmFormatNumber(well.consumption)} م³ • '
                                  '${well.hasSupervisor ? well.supervisorName : 'بدون مشرف'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_left,
                                  size: 18,
                                ),
                                onTap: () async {
                                  Navigator.pop(sheetContext);

                                  await Future<void>.delayed(
                                    const Duration(
                                      milliseconds: 250,
                                    ),
                                  );

                                  if (!mounted) return;

                                  _showWellSheet(
                                    context,
                                    well,
                                    data,
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // تحديد إحداثيات البئر
  // ==========================================================

  Future<void> _editCoordinates(GmWellData well) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    final TextEditingController latitudeController =
        TextEditingController(
      text: well.hasCoordinates
          ? well.latitude.toStringAsFixed(6)
          : '',
    );

    final TextEditingController longitudeController =
        TextEditingController(
      text: well.hasCoordinates
          ? well.longitude.toStringAsFixed(6)
          : '',
    );

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? error;

        return StatefulBuilder(
          builder: (
            BuildContext innerContext,
            StateSetter setDialogState,
          ) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'تحديد موقع البئر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'أدخل إحداثيات البئر ليظهر في موقعه الجغرافي على الخريطة.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latitudeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'خط العرض (Latitude)',
                        hintText: 'مثال: 15.369400',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: longitudeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'خط الطول (Longitude)',
                        hintText: 'مثال: 44.191000',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final double? latitude =
                          double.tryParse(
                        latitudeController.text
                            .trim()
                            .replaceAll(',', '.'),
                      );

                      final double? longitude =
                          double.tryParse(
                        longitudeController.text
                            .trim()
                            .replaceAll(',', '.'),
                      );

                      if (latitude == null ||
                          longitude == null) {
                        setDialogState(() {
                          error =
                              'أدخل رقمين صحيحين لخط العرض وخط الطول.';
                        });
                        return;
                      }

                      if (latitude < -90 || latitude > 90) {
                        setDialogState(() {
                          error =
                              'خط العرض يجب أن يكون بين -90 و 90.';
                        });
                        return;
                      }

                      if (longitude < -180 ||
                          longitude > 180) {
                        setDialogState(() {
                          error =
                              'خط الطول يجب أن يكون بين -180 و 180.';
                        });
                        return;
                      }

                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final double? latitude = double.tryParse(
      latitudeController.text.trim().replaceAll(',', '.'),
    );

    final double? longitude = double.tryParse(
      longitudeController.text.trim().replaceAll(',', '.'),
    );

    latitudeController.dispose();
    longitudeController.dispose();

    if (saved != true ||
        latitude == null ||
        longitude == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('wells')
          .doc(well.id)
          .set(
        <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إحداثيات البئر'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await widget.onRefresh();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر حفظ الإحداثيات: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // تقارير الاستهلاك
  // ==========================================================

  void _openReports(GmWellData well) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CycleReportMenuScreen(
          wellId: well.id,
          wellName: well.name,
        ),
      ),
    );
  }
}

// ============================================================
// خلفية الخريطة
// ============================================================

class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint base = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFE9F4FF),
          Color(0xFFEAF7F1),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(rect);

    canvas.drawRect(rect, base);

    // شبكة
    final Paint grid = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const double step = 48;

    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        grid,
      );
    }

    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    // مناطق
    final Paint land = Paint()
      ..color = const Color(0xFFDCEEFF).withValues(alpha: 0.85);

    canvas.drawCircle(
      Offset(size.width * 0.26, size.height * 0.30),
      size.width * 0.24,
      land,
    );

    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.64),
      size.width * 0.28,
      Paint()
        ..color =
            const Color(0xFFE3F5E9).withValues(alpha: 0.90),
    );

    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.84),
      size.width * 0.16,
      land,
    );

    // مجرى مائي
    final Path river = Path()
      ..moveTo(-10, size.height * 0.72)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.55,
        size.height * 0.86,
        size.width + 10,
        size.height * 0.42,
      );

    canvas.drawPath(
      river,
      Paint()
        ..color =
            const Color(0xFF90CAF9).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.012,
    );

    // إطار
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(1),
        const Radius.circular(20),
      ),
      Paint()
        ..color = const Color(0xFFBBDEFB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// روابط القرية بالآبار
// ============================================================

class _MapLinksPainter extends CustomPainter {
  final List<GmVillageData> villages;

  const _MapLinksPainter({required this.villages});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint link = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (final GmVillageData village in villages) {
      if (village.mapX < 0 || village.mapY < 0) {
        continue;
      }

      final Offset center = Offset(
        village.mapX * size.width,
        village.mapY * size.height,
      );

      for (final GmWellData well in village.wells) {
        if (well.mapX < 0 || well.mapY < 0) {
          continue;
        }

        canvas.drawLine(
          center,
          Offset(
            well.mapX * size.width,
            well.mapY * size.height,
          ),
          link,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapLinksPainter oldDelegate) {
    return oldDelegate.villages != villages;
  }
}
