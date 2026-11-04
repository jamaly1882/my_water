# my_water

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## ملف تحدي المياه — Water Challenge Brief

تطبيق إطار **AYC Youth Pitches** (الأسبوع الأول) على مشروع `my_water`.

**نطاق المشروع:** 10 آبار · 60 مشتركًا · 720 قراءة في السنة — كل أرقام الملف محسوبة على هذا النطاق.

| المخرج | المسار |
|---|---|
| شاشة داخل التطبيق (الطبقات الأربع + الحفظ + التصدير) | `lib/features/challenge_brief/challenge_brief_page.dart` |
| تعريف الطبقات والحقول | `lib/features/challenge_brief/challenge_brief_spec.dart` |
| المستند المُعبّأ (عربي) | `docs/water_challenge_brief_ar.md` |
| المستند المُعبّأ (إنجليزي) | `docs/water_challenge_brief_en.md` |
| نسخة Word ثنائية اللغة (للتسليم) | `docs/water_challenge_brief_ar_en.docx` |
| نسخة HTML جاهزة للطباعة / PDF | `docs/water_challenge_brief.html` |

**الوصول:** الشاشة الرئيسية ← «ملف تحدي المياه».

**التخزين:** مجموعة Firestore باسم `water_challenge_briefs`، ومستند لكل مستخدم بمعرّف `uid`.

```
match /water_challenge_briefs/{uid} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow write: if request.auth != null && request.auth.uid == uid;
}
```

**الطبقات:** موقعنا على الخريطة (الاثنين) · ادعاؤنا التقني (الثلاثاء) · المؤسسات حولنا (الأربعاء) · سوقنا ومن يدفع (الخميس) — والتصدير النصي جاهز للصق في Miro أو للتحويل إلى PDF.

---

## التحليل الذكي للمشرفين — Supervisor Insights

شاشة تُحلّل أداء كل مشرف بئر من بيانات النظام نفسها (بلا خدمة خارجية):

| الملف | الدور |
|---|---|
| `lib/features/supervisor_insights/supervisor_insight_service.dart` | قراءة `users` · `wells` · `well_customers` · `cycles` وحساب المؤشرات |
| `lib/features/supervisor_insights/supervisor_insights_page.dart` | البطاقات، الفلاتر، وتفاصيل كل مشرف |

**الدرجة من 100 على أربعة مكوّنات:**

| المكوّن | الوزن | ما يقيسه |
|---|---|---|
| النشاط | 30 | عدد الأيام منذ آخر دورة مغلقة (≤7 أيام = 30) |
| الانتظام | 25 | عدد الدورات في آخر 90 يوماً (3 فأكثر = 25) |
| التغطية | 25 | مشتركون مربوطون + وجود دورة باستهلاك فعلي |
| جودة البيانات | 20 | ربط البئر، الهاتف، الاسم، الاستهلاك |

**التصنيف:** متميز (≥85) · جيد (≥70) · يحتاج متابعة (≥50) · خطر (أقل). ولكل مشرف سطر قراءة، ومخاطر مرتّبة، وخطوات مقترحة — والترتيب يبدأ بالأدنى درجة.

**ملاحظة صريحة داخل الشاشة:** المشرف بلا دورة واحدة يُقرأ «غير مقيس» لا «سيئ»؛ المؤشرات صفرية لغياب البيانات لا لسوء الأداء.

## أسماء الوجهات بالإنجليزية فقط

عناوين البطاقات العشر إنجليزية بالكامل، ولا يوجد نص عربي عليها، وعنوان كل شاشة داخلية مطابق لعنوان بطاقتها:

| البطاقة | عنوان الشاشة الداخلية |
|---|---|
| Setup | `setup_screen.dart` |
| Reading Cycle | `cycle_screen.dart` |
| Inquiry | `search_screen.dart` |
| Reports | `reports_screen.dart` |
| Receipt Voucher | `receipt_voucher_screen.dart` |
| Payment Voucher | `payment_voucher_list_screen.dart` |
| Challenge Brief | `challenge_brief_page.dart` |
| AI Agent | `ai_agent_page.dart` |
| Supervisor Insights | `supervisor_insights_page.dart` |
| Supervisor Setup | `setup_mshrf_screen.dart` |

**التفاصيل:** النص الإنجليزي في البطاقة يُرسم بـ `textDirection: TextDirection.ltr` داخل واجهة RTL، بخط 12.5 عريض ولون الأيقونة نفسه، وسطرين كحد أقصى. الحقول والنصوص داخل الشاشات ما زالت عربية — التغيير يشمل العناوين فقط.

---

## لغة الواجهة — Interface language

الشاشات التالية إنجليزية بالكامل (لا نص عربي فيها، بما فيها رسائل الخطأ والتحقق):

| الشاشة | الملف | الحالة |
|---|---|---|
| Splash | `lib/screens/splash_screen.dart` | English |
| Sign In | `lib/screens/login_screen.dart` | English |
| Home | `lib/home_screen.dart` | English |
| Reading Cycle | `lib/screens/cycle_screen.dart` | English |
| Setup · Inquiry · Reports · Receipt Voucher · Payment Voucher · Challenge Brief · AI Agent · Supervisor Insights · Supervisor Setup | app bars فقط | English titles |

**ما لم يُترجم بعد:** نصوص الحقول والجداول والأزرار والرسائل داخل بقية الشاشات (الدور، الاستعلام، التقارير، السندات، التهيئة، لوحة المشرف)، وأسماء البيانات نفسها (الآبار، القرى، المشتركون) عربية بطبيعتها.

**ملاحظة تصميمية:** حاوية الشاشة ما زالت `TextDirection.rtl`؛ النص الإنجليزي يُعرض صحيحاً لكنه يصطف يميناً. تحويل الشاشة إلى `ltr` قرار تخطيطي منفصل — يُطلب عند الحاجة.
