import 'package:flutter/material.dart';

import '../services/gm_dashboard_service.dart';

// ============================================================
// ألوان لوحة المدير العام
// ============================================================

const Color gmPrimary = Color(0xFF1565C0);
const Color gmAccent = Color(0xFF00897B);
const Color gmPageBackground = Color(0xFFF5F9FF);
const Color gmTextDark = Color(0xFF10304F);
const Color gmBorder = Color(0xFFE3ECF7);

/// لون يعبّر عن شدة الاستهلاك.
Color gmHeatColor(double ratio) {
  final double value = ratio.isNaN
      ? 0
      : ratio.clamp(0.0, 1.0).toDouble();

  if (value <= 0.5) {
    return Color.lerp(
      const Color(0xFF26A69A),
      const Color(0xFFFFA726),
      value * 2,
    )!;
  }

  return Color.lerp(
    const Color(0xFFFFA726),
    const Color(0xFFE53935),
    (value - 0.5) * 2,
  )!;
}

// ============================================================
// بطاقة موحدة
// ============================================================

class GmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const GmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: gmBorder),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

// ============================================================
// عنوان قسم
// ============================================================

class GmSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;

  const GmSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: gmPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: gmPrimary,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: gmTextDark,
                ),
              ),
              if (subtitle != null &&
                  subtitle!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

// ============================================================
// بطاقة مؤشر
// ============================================================

class GmStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;

  const GmStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = gmPrimary,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gmBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const Spacer(),
              if (caption != null)
                Flexible(
                  child: Text(
                    caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.3,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// شريط تقدم موحد
// ============================================================

class GmProgressBar extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;
  final Color color;
  final Widget? badge;
  final String? caption;

  const GmProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.ratio,
    this.color = gmPrimary,
    this.badge,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = ratio.isNaN
        ? 0
        : ratio.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: gmTextDark,
                ),
              ),
            ),
            if (badge != null) ...<Widget>[
              const SizedBox(width: 5),
              badge!,
            ],
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFEDF2F9),
            color: color,
          ),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// شارة التغير
// ============================================================

class GmChangeBadge extends StatelessWidget {
  final double? percent;
  final bool showZero;

  const GmChangeBadge({
    super.key,
    required this.percent,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final double? value = percent;

    if (value == null) {
      return _build(
        'No comparison',
        Colors.grey,
        Icons.remove,
      );
    }

    if (!showZero && value.abs() < 0.05) {
      return _build(
        'Steady',
        Colors.blueGrey,
        Icons.remove,
      );
    }

    final bool rising = value > 0;

    return _build(
      gmFormatPercent(value),
      rising
          ? const Color(0xFFD32F2F)
          : const Color(0xFF2E7D32),
      rising ? Icons.arrow_upward : Icons.arrow_downward,
    );
  }

  Widget _build(
    String text,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// رسم بياني بسيط
// ============================================================

class GmBarItem {
  final String label;
  final double value;

  const GmBarItem({
    required this.label,
    required this.value,
  });
}

class GmBarChart extends StatelessWidget {
  final List<GmBarItem> items;
  final double height;
  final Color color;
  final Color highlightColor;

  const GmBarChart({
    super.key,
    required this.items,
    this.height = 190,
    this.color = const Color(0xFF90CAF9),
    this.highlightColor = gmPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxValue = 0;

    for (final GmBarItem item in items) {
      if (item.value > maxValue) {
        maxValue = item.value;
      }
    }

    int highlightIndex = -1;

    for (int i = 0; i < items.length; i++) {
      if (maxValue > 0 && items[i].value == maxValue) {
        highlightIndex = i;
      }
    }

    const double labelSpace = 44;

    final double barMax = height > labelSpace + 8
        ? height - labelSpace
        : 20;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            items.asMap().entries.map<Widget>((MapEntry<int, GmBarItem> entry) {
          final int index = entry.key;
          final GmBarItem item = entry.value;

          final double ratio =
              maxValue <= 0 ? 0 : item.value / maxValue;

          final double barHeight = barMax * ratio;

          return Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      gmFormatNumber(item.value),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: barHeight < 4 ? 4 : barHeight,
                    decoration: BoxDecoration(
                      color: index == highlightIndex
                          ? highlightColor
                          : color,
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(7),
                        bottom: Radius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// بطاقة تنبيه / ملاحظة ذكية
// ============================================================

class GmInsightTile extends StatelessWidget {
  final GmInsight insight;
  final bool dense;

  const GmInsightTile({
    super.key,
    required this.insight,
    this.dense = false,
  });

  Color get _color => switch (insight.level) {
        GmInsightLevel.success =>
          const Color(0xFF2E7D32),
        GmInsightLevel.warning =>
          const Color(0xFFEF6C00),
        GmInsightLevel.danger =>
          const Color(0xFFD32F2F),
        GmInsightLevel.info => gmPrimary,
      };

  IconData get _icon => switch (insight.level) {
        GmInsightLevel.success =>
          Icons.check_circle_outline,
        GmInsightLevel.warning =>
          Icons.warning_amber_rounded,
        GmInsightLevel.danger => Icons.error_outline,
        GmInsightLevel.info => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final Color color = _color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(dense ? 10 : 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: dense ? 28 : 32,
            height: dense ? 28 : 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              color: color,
              size: dense ? 16 : 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: dense ? 12 : 13,
                    fontWeight: FontWeight.bold,
                    color: gmTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.message,
                  style: TextStyle(
                    fontSize: dense ? 10.8 : 11.8,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// حالة فارغة
// ============================================================

class GmEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const GmEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 40,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: gmTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// سطر معلومة
// ============================================================

class GmInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const GmInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 15,
              color: Colors.blueGrey.shade400,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? gmTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// بطاقة الصلاحيات
// ============================================================

class GmRolesCard extends StatelessWidget {
  const GmRolesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const GmSectionTitle(
            title: 'Supervisor permissions',
            icon: Icons.admin_panel_settings,
            subtitle: 'Who sees what inside the system',
          ),
          const SizedBox(height: 14),
          _role(
            Icons.workspace_premium,
            gmPrimary,
            'Main supervisor (GM)',
            'Sees every governorate, village, well, report and figure, '
                'and creates governorates, districts, sub-districts, villages, wells and supervisors.',
          ),
          const SizedBox(height: 10),
          _role(
            Icons.person_outline,
            gmAccent,
            'Well supervisor',
            'Enters and reads only their own well (readings, accounts, reports), '
                'and their numbers roll up into the GM figures.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFFF9A825),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions come from the role and wellId fields in the users collection, '
                    'and Firestore rules must mirror them to block access outside the well.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.5,
                      color: Colors.brown.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _role(
    IconData icon,
    Color color,
    String title,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: gmTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 10.8,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// شريحة صغيرة
// ============================================================

class GmPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const GmPill({
    super.key,
    required this.label,
    this.color = gmPrimary,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: filled
            ? color
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 12,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
