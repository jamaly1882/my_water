# الترجمة الصوتية داخل my_water — Live speech → Arabic

شاشة جديدة: **«الترجمة الصوتية»** في الصفحة الرئيسية (أيقونة `translate`).
الملفات:

| الملف | الدور |
|---|---|
| `lib/features/live_translate/voice_translate_page.dart` | الواجهة: مصدر الصوت، المحضر المباشر، النسخ، الحفظ |
| `lib/features/live_translate/speech_bridge.dart` | واجهة موحّدة للاستماع (اختيار التنفيذ حسب المنصة) |
| `lib/features/live_translate/speech_bridge_web.dart` | تنفيذ الويب عبر `window.AYCVoice` |
| `lib/features/live_translate/speech_bridge_stub.dart` | نسخة Android/iOS/سطح المكتب (رسالة واضحة، بلا انهيار) |
| `lib/features/live_translate/translation_service.dart` | نداء `POST /api/translate/` |
| `web/voice_translate.js` | Web Speech API + التقاط صوت التبويب |

---

## 1 · كيف تعمل

```
ميكروفون ──(Web Speech API، داخل المتصفح)──┐
                                           ├──► نص إنجليزي (جملة مكتملة)
صوت الاجتماع ──(MediaRecorder → WebSocket)─┘             │
                                                        ▼
                                    POST /api/translate/ (الخادم)
                                                        │
                                                        ▼
                                    «نص عربي» يظهر تحت الجملة فوراً
                                                        │
                                                        ▼
                                    حفظ المحضر في Firestore (voice_sessions)
```

---

## 2 · ما يعمل اليوم، وما يحتاج خدمة

| المسار | يعمل بلا خادم؟ | يحتاج |
|---|---|---|
| الاستماع إلى **الميكروفون** | ✅ نعم (Chrome / Edge على الحاسوب) | إذن الميكروفون، و HTTPS أو localhost |
| **ترجمة** النص إلى العربية | ❌ | خادم يملك `POST /api/translate/` |
| الاستماع إلى **صوت الاجتماع** (Zoom / Meet / تبويب) | ❌ | خدمة تفريغ صوتي عبر `WebSocket` (Whisper مثلاً) + مشاركة صوت التبويب |
| الحفظ والنسخ | ✅ (الحفظ يحتاج تسجيل دخول) | قاعدة Firestore |

**لماذا صوت الاجتماع يحتاج خدمة؟** لأن Web Speech API يستمع إلى الميكروفون فقط، ولا يقبل بثّ صوت جاهز. أما `getDisplayMedia({audio:true})` فيمنحك صوت التبويب، لكن تمريره إلى محرّك تعرّف يحتاج خادماً. لذلك الشاشة تعرض السبب بوضوح بدل أن تفشل بصمت.

> ملاحظة خصوصية تُقال للمستخدم: Web Speech API في Chrome يرسل الصوت إلى خدمة Google للتعرّف. للاجتماعات الحساسة استخدم مسار خدمة التفريغ المحلية (Whisper) بدلاً من الميكروفون.

---

## 3 · عقد الخدمات (ما يحتاجه الخادم)

### 3.1 الترجمة

```http
POST /api/translate/
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{ "text": "Water losses in this well are not measured.",
  "source": "en",
  "target": "ar" }
```

```json
{ "translation": "الفاقد في هذا البئر غير مقيس." }
```

الشاشة تقبل أيضاً أسماء بديلة للحقل: `translatedText` أو `translated_text` أو `text`.

### 3.2 تفريغ صوت الاجتماع

```
WS  /ws/transcribe/     (إطارات صوتية ثنائية: webm/opus، كل 4 ثوانٍ)

← {"text": "so the mains pipe was replaced last year", "isFinal": true}
← {"text": "and the meter", "isFinal": false}
```

الخادم يستقبل المقاطع الصوتية ويُرجع النص فور توفره. رسالة `isFinal:false` تُعرض كسطر باهت، و`true` يضيف سطراً جديداً ويُترجمه.

### 3.3 فحص الاتصال (اختياري)

```http
GET /api/health/   → 200
```

---

## 4 · مثال خادم مرجعي (FastAPI)

> كود مرجعي للتشغيل على جهازك أو على VPS، وليس جزءاً من تطبيق Flutter.

```python
# pip install fastapi uvicorn faster-whisper argostranslate
import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from faster_whisper import WhisperModel
import argostranslate.package, argostranslate.translate

app = FastAPI()
model = WhisperModel("small", device="cpu", compute_type="int8")

class TranslateIn(BaseModel):
    text: str
    source: str = "en"
    target: str = "ar"

@app.get("/api/health/")
def health():
    return {"ok": True}

@app.post("/api/translate/")
def translate(body: TranslateIn):
    # نموذج ترجمة محلي (بلا إنترنت). للجودة الأعلى: استبدله بنداء LLM.
    installed = argostranslate.translate.get_installed_languages()
    src = next(l for l in installed if l.code == body.source)
    dst = next(l for l in installed if l.code == body.target)
    return {"translation": src.get_translation(dst).translate(body.text)}

@app.websocket("/ws/transcribe/")
async def transcribe(ws: WebSocket):
    await ws.accept()
    buffer = bytearray()
    try:
        while True:
            chunk = await ws.receive_bytes()
            buffer.extend(chunk)
            if len(buffer) < 32_000:
                continue
            open("/tmp/chunk.webm", "wb").write(buffer)
            segments, _ = model.transcribe("/tmp/chunk.webm", language="en")
            text = " ".join(s.text.strip() for s in segments).strip()
            buffer.clear()
            if text:
                await ws.send_text(json.dumps({"text": text, "isFinal": True}))
    except WebSocketDisconnect:
        pass
```

**تنزيل حزمة الترجمة العربية مرة واحدة:**

```python
import argostranslate.package as p
p.update_package_index()
pkg = next(x for x in p.get_available_packages()
           if x.from_code == "en" and x.to_code == "ar")
p.install_from_path(pkg.download())
```

---

## 5 · التنصيب في التطبيق

1. **الشاشة:** الصفحة الرئيسية ← «الترجمة الصوتية».
2. **الإعدادات** (أيقونة `tune`) ← عنوان خادم الترجمة، وعنوان خدمة التفريغ.
   افتراضياً: `http://127.0.0.1:8000` و`ws://127.0.0.1:8000/ws/transcribe/`.
   على الهاتف أو النطاق المنشور استبدل `127.0.0.1` بعنوان حقيقي (ويفضّل `https` / `wss`).
3. **ملف الجسر:** `web/voice_translate.js` يُحمَّل تلقائياً من `web/index.html` قبل `flutter_bootstrap.js`.

**قاعدة Firestore للمحاضر المحفوظة:**

```
match /voice_sessions/{docId} {
  allow create: if request.auth != null
                && request.resource.data.ownerUid == request.auth.uid;
  allow read:   if request.auth != null
                && resource.data.ownerUid == request.auth.uid;
  allow update, delete: false;
}
```

---

## 6 · حدود يجب أن تعرفها قبل العرض على اللجنة

1. **المتصفح:** التعرّف على الكلام يعمل في Chrome وEdge على الحاسوب؛ Safari وFirefox محدودان. على Android/iOS الشاشة تعرض رسالة صريحة أن الميزة ويب-أولاً.
2. **الأمان:** الميكروفون يحتاج HTTPS أو `localhost`؛ عبر نطاق غير مشفّر سيرفض المتصفح الطلب.
3. **الأسماء والأرقام:** محرّك التعرّف يخطئ في أسماء القرى وأرقام العدادات؛ لذلك الترجمة تُعرض للمراجعة لا تُرسل إلى فاتورة — نفس مبدأ «بوابة الثقة» في قراءة العدادات.
4. **اللغة:** الافتراضي `en-US`. لتغييرها عدّل `language` في `_startListening`.
5. **التكلفة:** التفريغ عبر Web Speech مجاني، والترجمة على الخادم تعتمد على ما تشغّله (نموذج محلي = بلا تكلفة، LLM = بتكلفة لكل طلب).

---

## 7 · الخطوة التالية المقترحة

- **VAD** (كشف النشاط الصوتي) لتقطيع الجمل بدقة بدل الاعتماد على صمت المتحدث.
- **مسرد مصطلحات مياه** (فاقد، عداد، تعرفة، م³) يُمرَّر إلى المترجم ليثبّت المصطلح.
- **ملخص عربي تلقائي** لآخر 10 دقائق، يُحفظ في نفس مستند المحضر.
- **تصدير المحضر PDF** بنفس محوّل ملف التحدي، بصفحة «أصل / ترجمة» متقابلة.
