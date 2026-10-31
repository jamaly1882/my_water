# my_water

نظام إدارة المياه — تطبيق Flutter مع Firebase.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter application:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## شريط الموقع الموحّد (المحافظة / المديرية / العزلة / القرية / البئر)

كانت صفحات التطبيق تستقبل **المعرفات فقط** عند تسجيل الدخول
(`provinceId`, `districtId`, `hamletId`, `villageId`) بدون الأسماء،
لذلك كانت صفحة **إضافة زبون** وبقية الصفحات تعرض «غير محدد».

### ما تم عمله

| الملف | الدور |
| --- | --- |
| `lib/services/supervisor_location.dart` | نموذج `SupervisorLocation` + محلّل يقرأ الأسماء من مستند المستخدم، ويستكمل الناقص منها من Firestore (`provinces`, `districts`, `hamlets`, `villages`, `wells`) |
| `lib/widgets/location_bar.dart` | ودجت `LocationBar` الموحّد لعرض مستويات الموقع بتسمياتها (نمط عادي + نمط مدمج `compact`) |
| `lib/widgets/my_app_bar.dart` | دعم شريط الموقع داخل `MyAppBar` عبر خصائص الأسماء، مع ضبط `preferredSize` تلقائياً |
| `lib/screens/login_screen.dart` و `lib/screens/splash_screen.dart` | تمرير الأسماء بعد تحليلها إلى `HomeScreen` |

الشريط مضاف إلى: الرئيسية، التهيئة، إضافة زبون، إضافة زبون بئر، نوع المعدة،
الدور لإدخال القراءات، اختيار زبون البئر، فتح دور (قراءة بداية الدور)،
والقراءات الحالية.

> ملاحظة: حسابات المشرفين المُنشأة حديثاً تحفظ الأسماء داخل مستند `users`،
> أما الحسابات القديمة فيتم استكمال أسمائها تلقائياً من مجموعات Firestore.

---

## قراءة بداية الدور بالذكاء الاصطناعي (AI Vision)

مسار القراءة في صفحة **قراءة بداية الدور** (`lib/screens/open_cycle_screen.dart`):

```
تصوير / اختيار صورة
   ↓
قص نافذة الأرقام السبعة
   ↓
1) الذكاء الاصطناعي (نموذج رؤية) ← يقرأ الخانات السبع
   ↓ (إذا تعذّر: لا يوجد مفتاح، شبكة، أو قراءة غير مكتملة)
2) القراءة المحلية على الجهاز (ML Kit / Tesseract.js للويب)
   ↓
نافذة مراجعة وتأكيد + فحص جودة الصورة
```

### الملفات

| الملف | الدور |
| --- | --- |
| `lib/ocr/ai_meter_ocr.dart` | `AIMeterOCR.readCroppedMeter()` لإرسال الصورة المقصوصة إلى نموذج الرؤية، مع تمرير القراءة السابقة لتقليل الأخطاء المنطقية |
| `lib/ocr/meter_analysis.dart` | `OcrEngine` (aiVision / local) و `MeterReadingResult` الذي يربط القراءة بمحرّكها |
| `lib/ocr/ocr_mobile.dart` | تجربة الذكاء الاصطناعي أولاً ثم القراءة المحلية كاحتياط (`_tryAiReading`) |
| `lib/ocr/ocr_web.dart` | نفس الترتيب على الويب + شارة توضح المحرّك |
| `lib/ocr/ocr_quality_widgets.dart` | مؤشر «جاري القراءة بالذكاء الاصطناعي» وشارة المحرّك في نافذة المراجعة |
| `lib/ocr/ocr_service.dart` | واجهة موحّدة تُرجع `MeterReadingResult?` |

### تفعيل الذكاء الاصطناعي

المفتاح يُمرَّر وقت البناء عبر `--dart-define` ولا يُخزَّن داخل المستودع:

```bash
# تشغيل
flutter run --dart-define=OPENAI_API_KEY=sk-...

# بناء APK
flutter build apk --release --dart-define=OPENAI_API_KEY=sk-...

# بناء الويب
flutter build web --release --dart-define=OPENAI_API_KEY=sk-...
```

إذا لم يُمرَّر المفتاح:

- `AIMeterOCR.isAvailable` تصبح `false`.
- تظهر ملاحظة برتقالية في تبويب القراءة بالصور.
- تعمل القراءة المحلية تلقائياً بدون أي انقطاع في الخدمة.

### ملاحظات مهمة

- قراءة الصورة يجب أن تكون **7 خانات بالضبط**، بينما الإدخال اليدوي يقبل أي عدد من الأرقام.
- أي تعديل يدوي على الخانات في نافذة المراجعة أو حقل الإدخال يُلغي نسبة القراءة إلى الذكاء الاصطناعي.
- مفتاح API المضمّن في تطبيق عميل يمكن استخراجه، لذا يُنقل لاحقاً إلى وسيط خادم
  (Firebase Functions أو واجهة Django الموجودة في `lib/services/ai_agent_query_service.dart`)
  قبل النشر العام.
