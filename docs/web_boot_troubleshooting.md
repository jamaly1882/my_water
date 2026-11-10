# «تعذّر الاتصال بخدمات Firebase» في بعض المتصفحات

الرابط يعمل في متصفح ويظهر في آخر:

```
تعذّر الاتصال بخدمات Firebase
Null check operator used on a null value
```

الرسالة التقنية ليست عطلًا في شيفرة المنصة: مصدرها `firebase_core_web`
حين لا يستطيع تحميل سكربتات Firebase JS SDK، أو حين يجد تطبيقًا مسجّلًا
بشكل ناقص. هذا الملف يشرح السبب والإصلاح، وما صار في التطبيق لمنع تكراره.

---

## 1) ما صار في التطبيق (إصلاح تلقائي)

الملف `lib/services/app_bootstrap.dart` أُعيد بناؤه ليصبح الإقلاع مقاومًا:

| ما كان | ما صار |
|---|---|
| محاولة واحدة، وأي خطأ = شاشة «تعذّر الاتصال» دائمة | **٣ محاولات** بمهلة ٢٠ ثانية لكل محاولة وفاصل متزايد (١.٥ث ثم ٣ث) |
| إعادة المحاولة على تطبيق Firebase نصف مهيأ تفشل بـ `duplicate-app` | يُحذف التطبيق المشوّه بين المحاولات ثم يُعاد إنشاؤه |
| فشل `setPersistence` يُسقط التهيئة كلها | خطوة الجلسة صارت **غير حرجة**: فشلها لا يمنع الدخول |
| زر «إعادة المحاولة» يعيد المحاولة على نفس الحالة العالقة | المحاولة تمرّ على نفس منطق الإقلاع الكامل |
| لا شيء يمسح الكاش القديم | عند خطأ يدل على سكربت/كاش: **مسح الكاش + إلغاء service worker + إعادة تحميل واحدة** (لا حلقة) |
| نص تقني فقط | سبب عربي مفهوم + النص التقني + زرّا «إعادة المحاولة» و«مسح الكاش وإعادة التحميل» |

الدالة `window.__azalHardReload` معرّفة في `web/index.html`، ويُناديها
`lib/services/web_recovery_web.dart`. حمايتها: تُنفَّذ مرة واحدة لكل جلسة،
ويُصفَّر العلم عند رسم أول إطار (`hideGuard`)، فلا يمكن أن تتحول إلى حلقة
إعادة تحميل. اختبارها: `node --test test/web_recovery_js_test.js`.

---

## 2) الأسباب الأربعة الأكثر احتمالًا

### أ) سكربتات Firebase محجوبة (gstatic.com)

`firebase_core_web` يحقن السكربتات التالية وقت التهيئة:

```
https://www.gstatic.com/firebasejs/<version>/firebase-app.js
https://www.gstatic.com/firebasejs/<version>/firebase-auth.js
https://www.gstatic.com/firebasejs/<version>/firebase-firestore.js
```

الحقن يتم بـ `import()` من داخل سكربت مضمّن. أي مانع إعلانات، إضافة
خصوصية، سياسة CSP، أو فلترة شبكة تمنع `www.gstatic.com` أو تمنع
السكربتات المضمّنة ⇒ يفشل التحميل ويظهر الخطأ أعلاه.

**العلاج:** اسمح بـ `www.gstatic.com` لهذا الموقع، أو عطّل الحاجب، أو
استخدم شبكة أخرى. **التحقق:** افتح Console وابحث عن `firebase-app.js`
أو `net::ERR_BLOCKED_BY_CLIENT`، وفي Network رشّح بـ `gstatic`.

### ب) نسخة قديمة محفوظة في الكاش (service worker)

service worker يخدم `main.dart.js` من نشر قديم مع `index.html` جديد ⇒
حالة غير متسقة. هذا يفسّر «يعمل عند شخص، ولا يعمل عند آخر».

**العلاج التلقائي:** المحاولة الثالثة تمسح الكاش وتلغي الـ SW وتعيد
التحميل. **يدويًا:** DevTools ← Application ← Service Workers ←
`Unregister`، ثم Storage ← `Clear site data`.

### ج) وضع التصفح الخاص أو حجب التخزين

`indexedDB` / `localStorage` محجوبان ⇒ Firebase Auth لا يستطيع إنشاء
جلسة. **العلاج:** نافذة تصفح عادية، وإضافة الموقع إلى استثناءات التخزين
في إعدادات المتصفح.

### د) النطاق غير موجود في Authorized domains

Firebase Console ← Authentication ← Settings ← **Authorized domains**.
تأكد من وجود:

```
azalsoftplatform.web.app
azalsoftplatform.firebaseapp.com
water-567bb.web.app
localhost                     (للتطوير فقط)
```

بدون ذلك يعمل تسجيل الدخول بالبريد/كلمة السر عادةً، لكن أي دخول يعتمد
على إعادة التوجيه (Google وغيره) يفشل بـ `auth/unauthorized-domain`.

---

## 3) كيف تفحص متصفحًا يشتكي (٦٠ ثانية)

1. Console: هل يوجد `firebase-app.js` محجوب أو `Null check operator`؟
2. Network: فلتر `gstatic` — هل الطلب `blocked` أو `(failed)`؟
3. Application ← Service Workers: هل توجد نسخة `activated` قديمة؟
4. Application ← Clear site data، ثم تحديث الصفحة:
   - نجح ⇒ السبب (ب).
   - فشل ⇒ السبب (أ) أو (ج) أو (د).
5. من نافذة تصفح خفي (incognito) بلا إضافات:
   - نجح ⇒ إضافة/مانع إعلانات في النافذة العادية.

---

## 4) بعد التعديل: أعد البناء والنشر

```bash
flutter build web --release
bash tool/deploy_web.sh                                   # كل المواقع
FIREBASE_SITE=azalsoftplatform bash tool/deploy_web.sh    # الموقع الرسمي فقط
```

للتأكد أن النشر وصل فعلًا (يجب أن يكون الناتج أكبر من صفر):

```bash
curl -s https://azalsoftplatform.web.app/ | grep -c __azalHardReload
```

`firebase.json` يمنع تخزين `index.html` و`flutter_service_worker.js`
و`flutter_bootstrap.js` (`Cache-Control: no-cache`)، لذا يصل الإصلاح
للمستخدمين من أول تحديث بعد النشر.

---

## 5) إن بقيت المشكلة في متصفح واحد فقط

اجمع هذه المعلومات وأرسلها مع الصورة:

- اسم المتصفح وإصداره، وهل يوجد مانع إعلانات؟
- نص الخطأ الكامل من لوحة الشاشة (يظهر تحت السبب العربي).
- عدد المحاولات الظاهر أثناء التهيئة.
- نتيجة `Clear site data` ثم إعادة التحميل.
