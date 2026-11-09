#!/usr/bin/env bash
# ============================================================
# تنزيل محرك قراءة العدادات محليًا (اختياري لكنه يوصى به)
# ============================================================
#
# لماذا؟
#   شاشة قراءة العدادات على الويب تعتمد على Tesseract.js.
#   افتراضيًا يُحمَّل من الشبكة العامة (jsDelivr / unpkg)، وهذا
#   يفشل كليًا على الشبكات البطيئة أو التي تحجب هذه النطاقات.
#
#   هذا السكربت ينزّل الملفات مرة واحدة من npm ويضعها داخل
#   web/ocr، فيصبح المحرك يعمل من موقعك نفسه بلا أي اتصال خارجي.
#   ترتيب المحاولات في index.html يفضّل المجلد المحلي تلقائيًا.
#
# الاستخدام:
#   bash tool/fetch_ocr_assets.sh
#   ثم أعد البناء والنشر:
#   bash tool/build_web.sh && firebase deploy --only hosting
#
# الحجم المتوقع: ~11 ميغابايت في web/ocr (تُنزَّل مرة واحدة
# وتُخزَّن في المتصفح سنة كاملة، ولا تُطلب عند فتح شاشة الدخول).
# ============================================================

set -euo pipefail

cd "$(dirname "$0")/.."

root="$(pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "==> تنزيل الحزم من npm"
(
  cd "$work"
  npm pack tesseract.js@5 tesseract.js-core@5 @tesseract.js-data/eng --silent >/dev/null
)

echo "==> فكّ الحزم"
mkdir -p "$work/js" "$work/core" "$work/lang"

tar xf "$work"/tesseract.js-[0-9]*.tgz -C "$work/js"
tar xf "$work"/tesseract.js-core-*.tgz -C "$work/core"
tar xf "$work"/tesseract.js-data-eng-*.tgz -C "$work/lang"

echo "==> نسخ الملفات إلى web/ocr"
mkdir -p web/ocr/core web/ocr/lang

cp "$work/js/package/dist/tesseract.min.js" web/ocr/tesseract.min.js
cp "$work/js/package/dist/worker.min.js" web/ocr/worker.min.js

# oem = 1 (LSTM فقط) — نحتاج النسختين: مع SIMD وبدونه.
cp "$work/core/package/tesseract-core-lstm.wasm.js" web/ocr/core/
cp "$work/core/package/tesseract-core-simd-lstm.wasm.js" web/ocr/core/

cp "$work/lang/package/4.0.0_best_int/eng.traineddata.gz" web/ocr/lang/eng.traineddata.gz

echo "==> النتيجة"
du -sh web/ocr
find web/ocr -type f -exec du -h {} + | sort -h

cat <<'TXT'

تم. الآن:
  bash tool/build_web.sh
  firebase deploy --only hosting

للتأكد بعد النشر، افتح:
  https://<نطاقك>/ocr/tesseract.min.js
  https://<نطاقك>/ocr/lang/eng.traineddata.gz
ويجب أن يعيدا 200.
TXT
