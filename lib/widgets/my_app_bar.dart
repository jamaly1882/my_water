import 'package:flutter/material.dart';

import 'location_bar.dart';

class MyAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool showBackButton;
  final List<Widget>? actions;

  // ==========================================================
  // شريط الموقع الموحّد
  // المحافظة ← المديرية ← العزلة ← القرية ← البئر
  // ==========================================================

  final String? provinceName;
  final String? districtName;
  final String? hamletName;
  final String? villageName;
  final String? wellName;

  /// إظهار البئر ضمن شريط الموقع
  final bool showWellInLocation;

  /// إظهار شريط الموقع (يتم تجاهله إذا كانت كل الأسماء فارغة)
  final bool showLocation;

  const MyAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.showBackButton = true,
    this.actions,
    this.provinceName,
    this.districtName,
    this.hamletName,
    this.villageName,
    this.wellName,
    this.showWellInLocation = true,
    this.showLocation = true,
  });

  // ==========================================================
  // هل توجد بيانات موقع لعرضها؟
  // ==========================================================

  bool get _hasLocation {
    if (!showLocation) return false;

    bool filled(String? value) =>
        value != null && value.trim().isNotEmpty;

    return filled(provinceName) ||
        filled(districtName) ||
        filled(hamletName) ||
        filled(villageName) ||
        (showWellInLocation && filled(wellName));
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,

      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,

      elevation: 2,

      centerTitle: true,

      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            )
          : null,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 30,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
          ],

          Image.asset(
            'assets/icon/water.jpg',
            width: 32,
            height: 32,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const Icon(
                Icons.water_drop,
                size: 30,
                color: Colors.white,
              );
            },
          ),

          const SizedBox(width: 8),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (subtitle != null &&
                  subtitle!.trim().isNotEmpty)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ],
      ),

      actions: actions,

      // ========================================================
      // شريط الموقع أسفل العنوان
      // ========================================================

      bottom: _hasLocation
          ? PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: LocationBar(
                provinceName: provinceName,
                districtName: districtName,
                hamletName: hamletName,
                villageName: villageName,
                wellName: wellName,
                showWell: showWellInLocation,
                compact: true,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (_hasLocation ? 28 : 0),
      );
}