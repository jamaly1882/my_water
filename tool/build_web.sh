#!/usr/bin/env bash
# ============================================================
# بناء نسخة الويب الجاهزة للنشر
# ============================================================
#
# الاستخدام:
#   bash tool/build_web.sh
#
# يبني في build/web ثم يتحقق من الملفات التي
# يؤدي غيابها إلى صفحة بيضاء عند النشر.
# ============================================================

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> تنظيف البناء السابق"
flutter clean

echo "==> جلب الحزم"
flutter pub get

echo "==> البناء"
# --base-href "/"            : الموقع على جذر النطاق
# --no-web-resources-cdn     : ملفات CanvasKit تُخدم من موقعك
#                              بدل gstatic.com (شبكات تحجبها)
flutter build web \
  --release \
  --base-href "/" \
  --no-web-resources-cdn

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
echo "==> جاهز للنشر: firebase deploy --only hosting"
