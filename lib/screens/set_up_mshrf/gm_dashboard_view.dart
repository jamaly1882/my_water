import 'package:flutter/material.dart';

import '../../services/gm_dashboard_service.dart';
import '../../widgets/gm_ui.dart';

// ============================================================
// تبويب لوحة المدير العام
// ============================================================

class GmDashboardView extends StatelessWidget {
  final GmDashboardData? data;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  final VoidCallback onOpenMap;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenSetup;

  const GmDashboardView({
    super.key,
    required this.data,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenMap,
    required this.onOpenAnalytics,
    required this.onOpenSetup,
  });

  @override
  Widget build(BuildContext context) {
    final GmDashboardData? value = data;

    if (value == null) {
      return _buildPlaceholder();
    }

    return RefreshIndicator(
      color: gmPrimary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          if (loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(
                color: gmPrimary,
                minHeight: 3,
              ),
            ),

          if (error != null) ...<Widget>[
            _errorBanner(),
            const SizedBox(height: 12),
          ],

          _hero(value),
          const SizedBox(height: 14),

          _statsGrid(value),
          const SizedBox(height: 14),

          _periodCard(value),
          const SizedBox(height: 14),

          _villagesCard(value),
          const SizedBox(height: 14),

          _wellsCard(value),
          const SizedBox(height: 14),

          _supervisorsCard(value),
          const SizedBox(height: 14),

          _insightsCard(value),
          const SizedBox(height: 14),

          _structureCard(value),
          const SizedBox(height: 14),

          const GmRolesCard(),

          if (value.warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _warningBanner(value.warnings),
          ],

          const SizedBox(height: 20),

          Text(
            'المصدر: بيانات Firestore المباشرة — نظام إدارة المياه',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // حالة التحميل والخطأ
  // ==========================================================

  Widget _buildPlaceholder() {
    if (loading) {
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
                Icons.cloud_off,
                size: 46,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل لوحة المؤشرات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: gmTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error ??
                    'تحقق من الاتصال بالإنترنت وصلاحيات الحساب ثم حاول مرة أخرى.',
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
                  onRefresh();
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

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            size: 17,
            color: Color(0xFFC62828),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error ?? 'تعذر تحديث البيانات',
              style: const TextStyle(
                fontSize: 10.8,
                color: Color(0xFFC62828),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onRefresh();
            },
            child: const Text(
              'تحديث',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBanner(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            size: 17,
            color: Color(0xFFF9A825),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'بعض البيانات لم تُحمّل: ${warnings.join('، ')}',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: Colors.brown.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // الترويسة
  // ==========================================================

  Widget _hero(GmDashboardData value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF00897B),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gmPrimary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'لوحة المدير العام',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'نظرة شاملة على المحافظات والقرى والآبار',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'صلاحية كاملة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _heroStat('${value.wellCount}', 'بئر'),
              _heroDivider(),
              _heroStat('${value.villageCount}', 'قرية'),
              _heroDivider(),
              _heroStat('${value.supervisorCount}', 'مشرف'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_outlined, size: 17),
                  label: const Text(
                    'الخريطة التفاعلية',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenAnalytics,
                  icon: const Icon(Icons.psychology, size: 17),
                  label: const Text(
                    'التحليل الذكي',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: gmPrimary,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'آخر تحديث: ${gmFormatDateTime(value.generatedAt)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withValues(alpha: 0.22),
    );
  }

  // ==========================================================
  // المؤشرات الرئيسية
  // ==========================================================

  Widget _statsGrid(GmDashboardData value) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        GmStatCard(
          label: 'إجمالي الآبار',
          value: gmFormatNumber(value.wellCount),
          icon: Icons.water_drop,
          color: gmPrimary,
          caption: '${value.activeWellCount} بئر باستهلاك',
        ),
        GmStatCard(
          label: 'القرى المرتبطة',
          value: gmFormatNumber(value.villageCount),
          icon: Icons.home_work,
          color: gmAccent,
          caption: '${value.hamletCount} عزلة',
        ),
        GmStatCard(
          label: 'المشرفون',
          value: gmFormatNumber(value.supervisorCount),
          icon: Icons.supervisor_account,
          color: const Color(0xFF5E35B1),
          caption: '${value.wellsWithoutSupervisor.length} بئر بدون مشرف',
        ),
        GmStatCard(
          label: 'المشتركون',
          value: gmFormatNumber(value.subscriberCount),
          icon: Icons.people_alt,
          color: const Color(0xFF00838F),
          caption: '${value.linkedSubscriberCount} مرتبط ببئر',
        ),
        GmStatCard(
          label: 'إجمالي الاستهلاك',
          value: '${gmFormatNumber(value.totalConsumption)} م³',
          icon: Icons.opacity,
          color: const Color(0xFF0277BD),
          caption: '${value.closedCycleCount} دورة مغلقة',
        ),
        GmStatCard(
          label: 'استهلاك هذا الشهر',
          value: '${gmFormatNumber(value.currentMonthConsumption)} م³',
          icon: Icons.calendar_month,
          color: const Color(0xFFEF6C00),
          caption: 'مقارنة بالفترة السابقة',
        ),
      ],
    );
  }

  // ==========================================================
  // الاستهلاك بين الفترات
  // ==========================================================

  Widget _periodCard(GmDashboardData value) {
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'الاستهلاك بين الفترات',
            icon: Icons.show_chart,
            subtitle: 'آخر ستة أشهر',
            trailing: GmChangeBadge(
              percent: value.overallChangePercent,
              showZero: true,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _periodBox(
                  'هذا الشهر',
                  value.currentMonthConsumption,
                  gmPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _periodBox(
                  'الشهر الماضي',
                  value.previousMonthConsumption,
                  Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GmBarChart(
            items: value.monthly
                .map<GmBarItem>(
                  (GmMonthPoint point) => GmBarItem(
                    label: point.label,
                    value: point.value,
                  ),
                )
                .toList(),
            height: 180,
          ),
          const SizedBox(height: 4),
          Text(
            'يُحسب الاستهلاك من الدورات المغلقة حسب تاريخ نهاية الدورة أو إغلاقها.',
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodBox(
    String label,
    double value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${gmFormatNumber(value)} م³',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // الاستهلاك حسب القرية
  // ==========================================================

  Widget _villagesCard(GmDashboardData value) {
    final List<GmVillageData> villages =
        value.topVillages(6);

    final double maxValue = villages.isEmpty
        ? 0
        : villages.first.consumption;

    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'تحليل الاستهلاك حسب القرية',
            icon: Icons.home_work,
            subtitle: villages.isEmpty
                ? 'لا توجد قرى مسجلة'
                : 'أعلى ${villages.length} قرى في الاستهلاك',
          ),
          const SizedBox(height: 14),
          if (villages.isEmpty)
            const GmEmptyState(
              title: 'لا توجد قرى',
              message: 'أضف القرى من تهيئة البيانات لتظهر هنا.',
              icon: Icons.home_outlined,
            )
          else
            ...villages.map(
              (GmVillageData village) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GmProgressBar(
                  label: village.name,
                  value: '${gmFormatNumber(village.consumption)} م³',
                  ratio: maxValue <= 0
                      ? 0
                      : village.consumption / maxValue,
                  color: gmAccent,
                  badge: GmChangeBadge(
                    percent: village.changePercentOrNull,
                  ),
                  caption:
                      '${village.wellCount} آبار • ${gmFormatNumber(village.subscribers)} مشترك',
                ),
              ),
            ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenMap,
              icon: const Icon(Icons.map_outlined, size: 17),
              label: const Text(
                'عرض القرى على الخريطة',
                style: TextStyle(fontSize: 11.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: gmPrimary,
                side: const BorderSide(color: gmBorder),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // الاستهلاك حسب البئر
  // ==========================================================

  Widget _wellsCard(GmDashboardData value) {
    final List<GmWellData> wells = value.topWells(6);

    final double maxValue =
        wells.isEmpty ? 0 : wells.first.consumption;

    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'استهلاك الآبار',
            icon: Icons.water_drop,
            subtitle: wells.isEmpty
                ? 'لا توجد آبار مسجلة'
                : 'أعلى ${wells.length} آبار في الاستهلاك',
          ),
          const SizedBox(height: 14),
          if (wells.isEmpty)
            const GmEmptyState(
              title: 'لا توجد آبار',
              message: 'أضف الآبار من تهيئة البيانات لتظهر هنا.',
              icon: Icons.water_drop_outlined,
            )
          else
            ...wells.map(
              (GmWellData well) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GmProgressBar(
                  label: well.name,
                  value: '${gmFormatNumber(well.consumption)} م³',
                  ratio: maxValue <= 0
                      ? 0
                      : well.consumption / maxValue,
                  color: gmPrimary,
                  badge: well.needsReview
                      ? const GmPill(
                          label: 'مراجعة',
                          color: Color(0xFFD32F2F),
                          icon: Icons.warning_amber_rounded,
                        )
                      : GmChangeBadge(
                          percent: well.changePercentOrNull,
                        ),
                  caption:
                      '${well.villageName.isEmpty ? well.provinceName : well.villageName} • '
                      'المشرف: ${well.hasSupervisor ? well.supervisorName : 'غير مرتبط'}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // المشرفون والآبار
  // ==========================================================

  Widget _supervisorsCard(GmDashboardData value) {
    final List<GmSupervisorData> supervisors =
        value.supervisors;

    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'المشرفون والآبار',
            icon: Icons.supervisor_account,
            subtitle:
                'كل مشرف يدير بئره فقط، وتظهر بياناته في الإحصائيات المركزية',
            trailing: GmPill(
              label: '${supervisors.length}',
              icon: Icons.people_alt,
            ),
          ),
          const SizedBox(height: 14),
          if (supervisors.isEmpty)
            const GmEmptyState(
              title: 'لا يوجد مشرفون',
              message:
                  'أضف المشرفين من تهيئة البيانات واربط كل مشرف ببئر.',
              icon: Icons.person_off,
            )
          else
            ...supervisors.take(5).map(
                  (GmSupervisorData supervisor) =>
                      _supervisorRow(supervisor),
                ),
          if (supervisors.length > 5) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'و${supervisors.length - 5} مشرفين آخرين...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenSetup,
              icon: const Icon(
                Icons.supervisor_account,
                size: 17,
              ),
              label: const Text(
                'إدارة المشرفين',
                style: TextStyle(fontSize: 11.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: gmAccent,
                side: const BorderSide(color: gmBorder),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supervisorRow(GmSupervisorData supervisor) {
    final String subtitle = supervisor.hasWell
        ? (supervisor.locationLabel.isEmpty
            ? 'البئر: ${supervisor.wellName}'
            : 'البئر: ${supervisor.wellName} • ${supervisor.locationLabel}')
        : 'غير مرتبط ببئر';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gmBorder),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 17,
            backgroundColor: gmAccent.withValues(alpha: 0.12),
            child: const Icon(
              Icons.person,
              size: 18,
              color: gmAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  supervisor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: gmTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${gmFormatNumber(supervisor.currentMonthConsumption)} م³',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: gmPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'هذا الشهر',
                style: TextStyle(
                  fontSize: 8.5,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // التنبيهات الذكية
  // ==========================================================

  Widget _insightsCard(GmDashboardData value) {
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'التنبيهات الذكية',
            icon: Icons.notifications_active,
            subtitle: 'تحليل تلقائي لبيانات النظام',
            trailing: TextButton(
              onPressed: onOpenAnalytics,
              style: TextButton.styleFrom(
                foregroundColor: gmPrimary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(38, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'الكل',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...value.insights
              .take(3)
              .map(
                (GmInsight insight) => GmInsightTile(
                  insight: insight,
                  dense: true,
                ),
              ),
        ],
      ),
    );
  }

  // ==========================================================
  // هيكل التهيئة
  // ==========================================================

  Widget _structureCard(GmDashboardData value) {
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const GmSectionTitle(
            title: 'هيكل التهيئة',
            icon: Icons.account_tree,
            subtitle:
                'المحافظات ← المديريات ← العُزل ← القرى ← الآبار',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GmPill(
                label: 'محافظات ${value.provinceCount}',
                icon: Icons.location_city,
              ),
              GmPill(
                label: 'مديريات ${value.districtCount}',
                icon: Icons.map,
                color: gmAccent,
              ),
              GmPill(
                label: 'عُزل ${value.hamletCount}',
                icon: Icons.home_work,
                color: const Color(0xFF5E35B1),
              ),
              GmPill(
                label: 'قرى ${value.villageCount}',
                icon: Icons.home,
                color: const Color(0xFF00838F),
              ),
              GmPill(
                label: 'آبار ${value.wellCount}',
                icon: Icons.water_drop,
                color: const Color(0xFF0277BD),
              ),
              GmPill(
                label: 'مشرفون ${value.supervisorCount}',
                icon: Icons.supervisor_account,
                color: const Color(0xFF6A1B9A),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenSetup,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text(
                'إدارة التهيئة والمشرفين',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gmPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
