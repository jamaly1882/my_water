# Well agent screen

`lib/screens/well_agent_screen.dart` — لوحة واحدة لكل بئر، تُفتح بالنقر على البئر في
شاشة **Wells**.

## ما تعرضه

| القسم | المصدر | الملاحظة |
|---|---|---|
| الترويسة | `wells/{wellId}` | الاسم + المحافظة · المديرية · الحارة · القرية |
| المؤشرات | محسوبة | عدد الزبائن · الأدوار المفتوحة · الأمتار المقروءة · الفاقد م³ |
| الحسابات | `accounts` (`wellId`) | `sales` · `cash` (صندوق البئر) · `expenses` · `worker` |
| الزبائن | `well_customers` + `cycles` | آخر قراءة · استهلاك آخر دورة مغلقة · عدد الأدوار · هل لديه دورة مفتوحة |
| الفاقد | `well_losses` | إدخال **يدوي** لكل دورة: م³ + نسبة (تُحسب تلقائيًا إن تُركت فارغة) + ملاحظة |
| القراءات القديمة | `well_legacy_readings` | صورة + رقم + تاريخ — خط الأساس قبل استخدام النظام |

## المجموعتان الجديدتان

### `well_losses`

```json
{
  "wellId": "…",
  "wellName": "بئر بن شلال",
  "cycleLabel": "Cycle 3 · November",
  "volumeM3": 75.0,
  "percent": 15.0,
  "computedFromConsumption": 500,
  "note": "leak repaired",
  "supervisorId": "…",
  "createdAt": "<server timestamp>"
}
```

النسبة تُحسب كما يلي عند ترك الحقل فارغًا:
`percent = volumeM3 ÷ (مجموع استهلاك الدورات المغلقة للبئر) × 100`
وتُخزَّن قيمة المقام في `computedFromConsumption` حتى يمكن تدقيق الحساب لاحقًا.

### `well_legacy_readings`

```json
{
  "wellId": "…",
  "wellName": "…",
  "reading": "15200",
  "readingValue": 15200,
  "readingDate": "<timestamp>",
  "note": "paper register",
  "imageBase64": "…",
  "imageMime": "image/jpeg",
  "supervisorId": "…",
  "createdAt": "<server timestamp>"
}
```

الصورة تُضغط عند الالتقاط (`imageQuality: 45`, `maxWidth: 900`) وتُخزَّن
**base64 داخل الوثيقة** لأن المشروع لا يستخدم `firebase_storage`. الحجم الأقصى
المقبول ٩٠٠ ألف حرف (حد Firestore هو ١ ميجابايت للوثيقة).

## قواعد Firestore

المجموعتان جديدتان، فإن كانت قواعدك تمنع المجموعات غير المذكورة صراحةً فستفشل
الكتابة. أضف — للمشرف/الوكيل فقط — صلاحية القراءة والكتابة على:

```
well_losses
well_legacy_readings
```

## ما لم يُنفَّذ بعد

- **قاعدة عدّاد البئر** (مشترك أم لكل زبون) — ما زالت مفتوحة، ومنطق التدوير
  الحالي يعمل لكل زبون على حدة في `open_cycle_screen.dart`.
- صور الشاشة داخل دليل المستخدم: الملحق (صفحة ١٢) نصّي بلا صورة حتى يُنشر
  التطبيق وتُلتقط لقطة جديدة.
