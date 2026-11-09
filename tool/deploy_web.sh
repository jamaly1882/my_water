#!/usr/bin/env bash
# ============================================================
# بناء ونشر نسخة الويب — على جميع مواقع Hosting المعرّفة
# ============================================================
#
# الاستخدام:
#   bash tool/deploy_web.sh                                 # بناء ثم نشر على كل المواقع
#   SKIP_BUILD=1 bash tool/deploy_web.sh                    # نشر ما بنيته للتوّ
#   FIREBASE_SITE=azalsoftplatform bash tool/deploy_web.sh  # نشر على موقع واحد فقط
#
# ملاحظة:
#   كل معرّف "site" في firebase.json يجب أن يكون منشأً مسبقًا في مشروع Firebase:
#     firebase hosting:sites:create azalsoftplatform --project water-567bb
# ============================================================

set -euo pipefail

# Git Bash على ويندوز: لا تحويل للمسارات التي تبدأ بـ "/"
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

cd "$(dirname "$0")/.."

read_json_value() {
  # $1 = اسم المفتاح (أول قيمة مطابقة)
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$2" |
    head -1
}

read_json_values() {
  # $1 = اسم المفتاح (جميع القيم المطابقة)
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$2"
}

sites=()
if [ -n "${FIREBASE_SITE:-}" ]; then
  sites=("$FIREBASE_SITE")
else
  while IFS= read -r s; do
    [ -n "$s" ] && sites+=("$s")
  done < <(read_json_values site firebase.json)
fi

if [ "${#sites[@]}" -eq 0 ] || [ -z "${sites[0]}" ]; then
  echo "!! لم أجد \"site\" في firebase.json"
  echo "   كل إدخال hosting يجب أن يحدد \"site\" باسم معرّف حقيقي"
  echo "   (انظر: firebase hosting:sites:list --project water-567bb)"
  exit 1
fi

project="${FIREBASE_PROJECT:-}"
if [ -z "$project" ]; then
  project="$(read_json_value default .firebaserc)"
fi

echo "==> المواقع: ${sites[*]}"

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

failed_sites=()
for site in "${sites[@]}"; do
  echo
  echo "==> النشر على الموقع: $site"
  if [ -n "$project" ]; then
    if ! firebase deploy --only "hosting:${site}" --project "$project"; then
      failed_sites+=("$site")
      echo "!! تعذّر النشر على الموقع \"$site\"."
      echo "   إذا ظهرت رسالة 404 Requested entity was not found، أنشئ الموقع أولًا عبر:"
      echo "   firebase hosting:sites:create \"$site\" --project \"$project\""
    fi
  else
    if ! firebase deploy --only "hosting:${site}"; then
      failed_sites+=("$site")
      echo "!! تعذّر النشر على الموقع \"$site\"."
      echo "   إذا ظهرت رسالة 404 Requested entity was not found، أنشئ الموقع أولًا عبر:"
      echo "   firebase hosting:sites:create \"$site\""
    fi
  fi
done

if [ "${#failed_sites[@]}" -gt 0 ]; then
  echo
  echo "!! فشل النشر على المواقع التالية: ${failed_sites[*]}"
  exit 1
fi
