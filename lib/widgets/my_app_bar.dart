import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool showBackButton;
  final List<Widget>? actions;

  const MyAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.showBackButton = true,
    this.actions,
  });

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
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}