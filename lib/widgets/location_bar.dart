// ============================================================
// location_bar.dart
//
// شريط الموقع الموحّد:
// المحافظة ← المديرية ← العزلة ← القرية (← البئر)
//
// يُستخدم في أعلى كل الصفحات التي تستقبل بيانات المشرف حتى
// يعرف المستخدم دائماً في أي موقع يعمل، ويُستخدم أيضاً داخل
// MyAppBar عبر الخاصية bottom.
// ============================================================

import 'package:flutter/material.dart';

class LocationBar extends StatelessWidget {
  final String? provinceName;
  final String? districtName;
  final String? hamletName;
  final String? villageName;
  final String? wellName;

  /// إظهار البئر في نهاية الشريط
  final bool showWell;

  /// النمط المدمج (خلفية شفافة + نص أبيض) لاستخدامه داخل AppBar
  final bool compact;

  /// اللون الأساسي (يُستخدم في النمط العادي)
  final Color color;

  const LocationBar({
    super.key,
    this.provinceName,
    this.districtName,
    this.hamletName,
    this.villageName,
    this.wellName,
    this.showWell = true,
    this.compact = false,
    this.color = Colors.blue,
  });

  /// بناء سريع من قائمة أسماء جاهزة
  factory LocationBar.fromNames(
    List<String> names, {
    Key? key,
    bool showWell = true,
    bool compact = false,
    Color color = Colors.blue,
  }) {
    final List<String> values = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String at(int index) => index < values.length ? values[index] : '';

    // إذا طُلب إخفاء البئر وكانت القائمة تحتوي 5 عناصر نحذف الأخير
    final bool hasWell = showWell && values.length > 4;

    return LocationBar(
      key: key,
      provinceName: at(0),
      districtName: at(1),
      hamletName: at(2),
      villageName: at(3),
      wellName: hasWell ? at(4) : null,
      showWell: showWell,
      compact: compact,
      color: color,
    );
  }

  // ==========================================================
  // عناصر الشريط بالترتيب
  // ==========================================================

  List<_LocationPart> get _parts {
    final List<_LocationPart> result = <_LocationPart>[];

    void add(String? value, String label, IconData icon) {
      final String text = value?.trim() ?? '';
      if (text.isNotEmpty) {
        result.add(_LocationPart(label: label, value: text, icon: icon));
      }
    }

    add(provinceName, 'المحافظة', Icons.map);
    add(districtName, 'المديرية', Icons.location_city);
    add(hamletName, 'العزلة', Icons.holiday_village);
    add(villageName, 'القرية', Icons.home_work);

    if (showWell) {
      add(wellName, 'البئر', Icons.water);
    }

    return result;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final List<_LocationPart> parts = _parts;

    // ========================================================
    // لا توجد بيانات موقع
    // ========================================================

    if (parts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: compact ? Colors.black12 : Colors.orange.shade50,
          border: Border(
            bottom: BorderSide(
              color: compact
                  ? Colors.white24
                  : Colors.orange.shade200,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_off,
              size: compact ? 16 : 18,
              color: compact ? Colors.white70 : Colors.orange.shade800,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'موقع المشرف غير محدد',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.bold,
                  color: compact ? Colors.white70 : Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ========================================================
    // النمط المدمج داخل AppBar: سطر واحد قابل للتمرير
    // ========================================================

    if (compact) {
      return Container(
        width: double.infinity,
        color: Colors.black12,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _compactChildren(parts),
          ),
        ),
      );
    }

    // ========================================================
    // النمط العادي: بطاقات صغيرة لكل مستوى
    // ========================================================

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'موقع المشرف',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: parts.map(_card).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // عناصر النمط المدمج
  // ==========================================================

  List<Widget> _compactChildren(List<_LocationPart> parts) {
    final List<Widget> children = <Widget>[];

    children.add(
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.location_on,
          color: Colors.white,
          size: 14,
        ),
      ),
    );

    for (int i = 0; i < parts.length; i++) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            parts[i].value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      if (i < parts.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_left,
              color: Colors.white54,
              size: 14,
            ),
          ),
        );
      }
    }

    children.add(const SizedBox(width: 8));

    return children;
  }

  // ==========================================================
  // بطاقة مستوى واحد (محافظة / مديرية / عزلة / قرية / بئر)
  // ==========================================================

  Widget _card(_LocationPart part) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            part.icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '${part.label}: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            part.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// عنصر واحد من عناصر الموقع
// ============================================================

class _LocationPart {
  final String label;
  final String value;
  final IconData icon;

  const _LocationPart({
    required this.label,
    required this.value,
    required this.icon,
  });
}
