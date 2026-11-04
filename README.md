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
