#!/usr/bin/env bash
# ============================================================
# بناء ونشر نسخة الويب — على الموقع الصحيح دائمًا
# ============================================================
#
# الاستخدام:
#   bash tool/deploy_web.sh              # بناء ثم نشر
#   SKIP_BUILD=1 bash tool/deploy_web.sh # نشر ما بنيته للتوّ
#
# لماذا هذا السكربت؟
#   كان `firebase deploy --only hosting` ينشر كل إدخالات hosting
#   في firebase.json. وإدخال واحد معطوب (target يشير إلى موقع غير
#   موجود) يُفشل النشر كله برسالة 404:
#
#     Request to .../sites/https-water-app-2026-web-ap-26/versions
#     had HTTP Error: 404, Requested entity was not found.
#
#   هنا نقرأ اسم الموقع الصحيح من firebase.json وننشر عليه وحده.
# ============================================================

set -euo pipefail

# Git Bash على ويندوز: لا تحويل للمسارات التي تبدأ بـ "/"
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

cd "$(dirname "$0")/.."

read_json_value() {
  # $1 = اسم المفتاح
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$2" |
    head -1
}

site="$(read_json_value site firebase.json)"

if [ -z "$site" ]; then
  echo "!! لم أجد \"site\" في firebase.json"
  echo "   كل إدخال hosting يجب أن يحدد \"site\" باسم معرّف حقيقي"
  echo "   (انظر: firebase hosting:sites:list --project water-567bb)"
  exit 1
fi

project="${FIREBASE_PROJECT:-}"
if [ -z "$project" ]; then
  project="$(read_json_value default .firebaserc)"
fi

echo "==> الموقع: $site"

if [ -n "$project" ]; then
  echo "==> المشروع: $project"
fi

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  bash tool/build_web.sh
else
  if [ ! -f build/web/index.html ]; then
    echo "!! SKIP_BUILD=1 لكن build/web غير موجود — نفّذ البناء أولًا"
    exit 1
  fi

  echo "==> تجاوز البناء (SKIP_BUILD=1)"
fi

echo
echo "==> النشر"
if [ -n "$project" ]; then
  firebase deploy --only "hosting:${site}" --project "$project"
else
  firebase deploy --only "hosting:${site}"
fi
