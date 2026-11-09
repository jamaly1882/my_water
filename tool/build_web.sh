#!/usr/bin/env bash
# ============================================================
# بناء نسخة الويب الجاهزة للنشر
# ============================================================
#
# الاستخدام:
#   bash tool/build_web.sh
#
# موقع على مسار فرعي (GitHub Pages مثلًا):
#   BASE_HREF=/my_water/ bash tool/build_web.sh
#
# يبني في build/web ثم يتحقق من الملفات التي
# يؤدي غيابها إلى صفحة بيضاء عند النشر.
# ============================================================

set -euo pipefail

# ============================================================
# ويندوز — Git Bash / MSYS
# ============================================================
#
# Git Bash يحوّل أي وسيط يبدأ بـ "/" إلى مسار ويندوز، فيصل
# --base-href "/" إلى Flutter على شكل:
#     --base-href "C:/Program Files/Git/"
# ويرفضه Flutter. نوقف التحويل هنا قبل أي استدعاء.
#
# (على لينكس وماك لا أثر لهذين المتغيرين.)
# ============================================================

export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

cd "$(dirname "$0")/.."

base_href="${BASE_HREF:-/}"

case "$base_href" in
  /*) ;;
  *)
    echo "!! BASE_HREF يجب أن يبدأ بـ / — القيمة الحالية: $base_href"
    exit 1
    ;;
esac

case "$base_href" in
  */) ;;
  *)
    base_href="$base_href/"
    ;;
esac

echo "==> المسار الأساسي: $base_href"

echo "==> تنظيف البناء السابق"
flutter clean

echo "==> جلب الحزم"
flutter pub get

echo "==> البناء"

build_log="$(mktemp)"
trap 'rm -f "$build_log"' EXIT

# --base-href "$base_href"     : جذر النطاق افتراضيًا
# --no-web-resources-cdn       : ملفات CanvasKit تُخدم من موقعك
#                                بدل gstatic.com (شبكات تحجبها أو تُبطئها)
# --dart2js-optimization O4    : أصغر ملف JS ممكن (بناء أبطأ قليلًا،
#                                وفتح أسرع للمستخدم)
#
# إن رفضت نسخة Flutter الخيار O4 نُعيد البناء بدونه — أمّا أي خطأ
# آخر فيتوقف السكربت عنده برسالته الحقيقية، بلا إعادة محاولة مضلِّلة.
if ! flutter build web \
  --release \
  --base-href "$base_href" \
  --no-web-resources-cdn \
  --dart2js-optimization O4 2>&1 | tee "$build_log"; then

  if grep -qi "dart2js-optimization" "$build_log"; then

    echo
    echo "    WARN نسخة Flutter هذه لا تقبل O4 — إعادة البناء بالإعداد الافتراضي"

    flutter build web \
      --release \
      --base-href "$base_href" \
      --no-web-resources-cdn

  else

    echo
    echo "!! فشل البناء — الرسالة الحقيقية أعلاه."
    echo "   على Windows/Git Bash استخدم: MSYS_NO_PATHCONV=1 bash tool/build_web.sh"
    exit 1
  fi
fi

echo "==> فحص المخرجات"

fail=0

check_file() {
  if [ -f "build/web/$1" ]; then
    echo "    ok   $1"
  else
    echo "    MISS $1"
    fail=1
  fi
}

check_dir() {
  if [ -d "build/web/$1" ]; then
    echo "    ok   $1/"
  else
    echo "    MISS $1/"
    fail=1
  fi
}

check_file "index.html"
check_file "main.dart.js"
check_file "flutter_bootstrap.js"
check_file "manifest.json"
check_dir  "canvaskit"
check_dir  "assets"

if grep -q 'FLUTTER_BASE_HREF' build/web/index.html; then
  echo "    WARN base href لم يُستبدل — تحقق من --base-href"
  fail=1
fi

if ! grep -q 'bootGuard' build/web/index.html; then
  echo "    WARN حارس الإقلاع غير موجود في index.html المبني"
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "!! البناء غير مكتمل — لا تنشر هذه النسخة."
  exit 1
fi

echo
echo "==> أحجام الملفات (ما ينزّله المستخدم قبل ظهور شاشة الدخول)"

if command -v du >/dev/null 2>&1; then
  du -h build/web/main.dart.js | awk '{print "    main.dart.js        " $1}'

  # الأجزاء المؤجَّلة: شاشات ما بعد الدخول. لا تُنزَّل عند الفتح.
  parts_total=0
  for part in build/web/main.dart.js_*.part.js; do
    [ -f "$part" ] || continue
    parts_total=$((parts_total + $(du -k "$part" | cut -f1)))
  done

  if [ "$parts_total" -gt 0 ]; then
    echo "    deferred parts      ${parts_total}K  (تُنزَّل بعد الدخول فقط)"
  fi

  du -sh build/web/canvaskit 2>/dev/null | awk '{print "    canvaskit/          " $1 "  (تُخزَّن سنة كاملة)"}'
fi

echo
echo "==> جاهز للنشر: firebase deploy --only hosting"
