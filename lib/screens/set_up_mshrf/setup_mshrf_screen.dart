import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/gm_dashboard_service.dart';
import '../../widgets/gm_ui.dart';
import '../../widgets/my_app_bar.dart';
import '../login_screen.dart';

import 'districts_screen.dart';
import 'gm_analytics_view.dart';
import 'gm_dashboard_view.dart';
import 'gm_map_view.dart';
import 'hamlets_screen.dart';
import 'provinces_screen.dart';
import 'supervisors_screen.dart';
import 'villages_screen.dart';
import 'wells_screen.dart';

// ============================================================
// صفحة المشرف الرئيسي (المدير العام)
//
// تحتوي على:
// 1. لوحة المدير العام: المؤشرات والإحصائيات والاستهلاك
// 2. الخريطة التفاعلية: الآبار والقرى ومؤشرات الاستهلاك
// 3. التحليل الذكي: التنبيهات والمساعد الذكي
// 4. تهيئة البيانات: المحافظات والمديريات والعُزل والقرى
//    والآبار والمشرفين
// ============================================================

class SetupMshrfScreen extends StatefulWidget {
  const SetupMshrfScreen({super.key});

  @override
  State<SetupMshrfScreen> createState() =>
      _SetupMshrfScreenState();
}

class _SetupMshrfScreenState extends State<SetupMshrfScreen> {
  static const Color mainColor = Colors.blue;
  static const Color backgroundColor = Color(0xffF5F9FF);

  static const List<String> _titles = <String>[
    'Dashboard',
    'Interactive Map',
    'Smart Analytics',
    'Data Setup',
  ];

  final GmDashboardService _service =
      GmDashboardService();

  GmDashboardData? _data;

  bool _loading = true;
  String? _error;

  int _tab = 0;

  @override
  void initState() {
    super.initState();

    _load();
  }

  // ============================================================
  // تحميل بيانات اللوحة
  // ============================================================

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final GmDashboardData data =
          await _service.load();

      if (!mounted) return;

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'تعذر تحميل بيانات لوحة المؤشرات. تحقق من الاتصال وصلاحيات الحساب.';
      });
    }
  }

  // ============================================================
  // التنقل بين التبويبات
  // ============================================================

  void _selectTab(int index) {
    if (index == _tab) return;

    setState(() {
      _tab = index;
    });

    if (index != 3 && _data == null && !_loading) {
      _load();
    }
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: MyAppBar(
          title: 'Supervisor Setup',
          subtitle: _titles[_tab],
          icon: Icons.admin_panel_settings,
          showBackButton: true,
          actions: <Widget>[
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),

        body: IndexedStack(
          index: _tab,
          children: <Widget>[
            // ==================================================
            // لوحة المدير العام
            // ==================================================

            GmDashboardView(
              data: _data,
              loading: _loading,
              error: _error,
              onRefresh: _load,
              onOpenMap: () => _selectTab(1),
              onOpenAnalytics: () => _selectTab(2),
              onOpenSetup: () => _selectTab(3),
            ),

            // ==================================================
            // الخريطة التفاعلية
            // ==================================================

            GmMapView(
              data: _data,
              loading: _loading,
              error: _error,
              onRefresh: _load,
            ),

            // ==================================================
            // التحليل الذكي
            // ==================================================

            GmAnalyticsView(
              data: _data,
              loading: _loading,
              error: _error,
              onRefresh: _load,
            ),

            // ==================================================
            // تهيئة البيانات
            // ==================================================

            _buildSetupTab(),
          ],
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD9E8FF),
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(
                Icons.dashboard,
                color: gmPrimary,
              ),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(
                Icons.map,
                color: gmPrimary,
              ),
              label: 'الخريطة',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology),
              selectedIcon: Icon(
                Icons.psychology,
                color: gmPrimary,
              ),
              label: 'التحليل',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(
                Icons.tune,
                color: gmPrimary,
              ),
              label: 'التهيئة',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // تبويب التهيئة
  // ============================================================

  Widget _buildSetupTab() {
    final GmDashboardData? data = _data;

    return RefreshIndicator(
      color: gmPrimary,
      onRefresh: _load,

      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        physics: const AlwaysScrollableScrollPhysics(),

        children: <Widget>[
          _setupHeader(data),
          const SizedBox(height: 16),

          GmSectionTitle(
            title: 'تهيئة البيانات',
            icon: Icons.account_tree,
            subtitle:
                'ينشئ المشرف الرئيسي المحافظات والمديريات والعُزل '
                'والقرى والآبار والمشرفين',
            trailing: data == null
                ? null
                : GmPill(
                    label: '${data.provinceCount} محافظة',
                    icon: Icons.location_city,
                  ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.86,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),

            children: <Widget>[
              _menuCard(
                title: 'المحافظات',
                icon: Icons.location_city,
                page: const ProvincesScreen(),
                count: data?.provinceCount,
              ),
              _menuCard(
                title: 'المديريات',
                icon: Icons.map,
                page: const DistrictsScreen(),
                count: data?.districtCount,
              ),
              _menuCard(
                title: 'العُزل',
                icon: Icons.home_work,
                page: const HamletsScreen(),
                count: data?.hamletCount,
              ),
              _menuCard(
                title: 'القرى',
                icon: Icons.home,
                page: const VillagesScreen(),
                count: data?.villageCount,
              ),
              _menuCard(
                title: 'الآبار',
                icon: Icons.water_drop,
                page: const WellsScreen(),
                count: data?.wellCount,
              ),
              _menuCard(
                title: 'المشرفون',
                icon: Icons.supervisor_account,
                page: const SupervisorsScreen(),
                count: data?.supervisorCount,
              ),
            ],
          ),

          const SizedBox(height: 16),

          const GmRolesCard(),

          const SizedBox(height: 16),

          _logoutButton(),

          const SizedBox(height: 12),

          Text(
            'نظام إدارة المياه — المشرف الرئيسي',
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

  // ============================================================
  // ترويسة التهيئة
  // ============================================================

  Widget _setupHeader(GmDashboardData? data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF1565C0),
            Color(0xFF00897B),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gmPrimary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'المشرف الرئيسي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'صلاحية كاملة: إنشاء البيانات والمشرفين '
                      'ومشاهدة جميع الآبار والقرى والإحصائيات.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _headerChip(
                  '${data.provinceCount}',
                  'محافظة',
                ),
                const SizedBox(width: 8),
                _headerChip('${data.wellCount}', 'بئر'),
                const SizedBox(width: 8),
                _headerChip(
                  '${data.supervisorCount}',
                  'مشرف',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة قائمة التهيئة
  // ============================================================

  Widget _menuCard({
    required String title,
    required IconData icon,
    required Widget page,
    int? count,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: gmBorder),
      ),
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => page,
            ),
          );

          if (!mounted) return;

          // تحديث المؤشرات بعد العودة من التهيئة
          _load();
        },

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mainColor.withValues(
                            alpha: 0.30,
                          ),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: mainColor.withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(9),
                        border: Border.all(
                          color: mainColor.withValues(
                            alpha: 0.30,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 13,
                        color: mainColor,
                      ),
                    ),
                  ],
                ),
              ),

              if (count != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mainColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // تسجيل الخروج
  // ============================================================

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC62828),
          side: const BorderSide(
            color: Color(0xFFEF9A9A),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'هل تريد تسجيل الخروج من حساب المشرف الرئيسي؟',
              style: TextStyle(fontSize: 12.5),
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
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('خروج'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
