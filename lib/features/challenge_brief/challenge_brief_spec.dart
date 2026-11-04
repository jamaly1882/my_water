// ============================================================
// challenge_brief_spec.dart
// تعريف طبقات "ملف تحدي المياه" (Water Challenge Brief)
// وفق برنامج AYC Youth Pitches — أسبوع 1
//
// الطبقة 1 · الاثنين : موقعنا على الخريطة
// الطبقة 2 · الثلاثاء: ادعاؤنا التقني
// الطبقة 3 · الأربعاء: المؤسسات حولنا
// الطبقة 4 · الخميس  : سوقنا ومن يدفع
// ============================================================

import 'package:flutter/material.dart';

/// حقل واحد داخل طبقة من طبقات الملف.
class BriefFieldSpec {
  final String key;

  /// العنوان بالعربية (هو العنوان الأساسي في الواجهة).
  final String labelAr;

  /// العنوان بالإنجليزية (سطر ثانوي، لأن تسليم البرنامج ثنائي اللغة).
  final String labelEn;

  /// تلميح يشرح المطلوب بدقة.
  final String hint;

  /// عدد الأسطر المقترح لمربع الكتابة.
  final int lines;

  const BriefFieldSpec({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.hint,
    this.lines = 3,
  });
}

/// طبقة كاملة من طبقات الملف.
class BriefLayerSpec {
  final String key;

  /// اليوم والرقم، مثل: "الاثنين · الطبقة 1".
  final String dayAr;

  final String titleAr;
  final String titleEn;

  /// السؤال الذي تجيب عنه الطبقة.
  final String questionAr;
  final String questionEn;

  final IconData icon;
  final Color color;

  final List<BriefFieldSpec> fields;

  const BriefLayerSpec({
    required this.key,
    required this.dayAr,
    required this.titleAr,
    required this.titleEn,
    required this.questionAr,
    required this.questionEn,
    required this.icon,
    required this.color,
    required this.fields,
  });
}

/// الطبقات الأربع كما وردت في جلسة التهيئة.
const List<BriefLayerSpec> kBriefLayers = <BriefLayerSpec>[
  // ==========================================================
  // الطبقة 1 · موقعنا على الخريطة
  // ==========================================================
  BriefLayerSpec(
    key: 'place',
    dayAr: 'الاثنين · الطبقة 1',
    titleAr: 'موقعنا على الخريطة',
    titleEn: 'Our place on the map',
    questionAr:
        'أين نقف في نظام المياه؟ وما التغيير الذي نُحدثه؟ ومن هم الفاعلون الثلاثة حولنا؟',
    questionEn:
        'Where do we sit in the water system, what change do we drive, and who are the three actors around us?',
    icon: Icons.map_outlined,
    color: Color(0xFF1565C0),
    fields: <BriefFieldSpec>[
      BriefFieldSpec(
        key: 'stageDomain',
        labelAr: 'المرحلة والمجال',
        labelEn: 'Stage and domain',
        hint:
            'مثال: نموذج أولي يعمل ميدانياً — مجال رقمي (برمجيات إدارة العدادات والحسابات في الآبار). '
            'حدّد المرحلة: فكرة / نموذج أولي / إطلاق تجريبي / إيرادات أولى.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'change',
        labelAr: 'التغيير الذي نُحدثه',
        labelEn: 'The change we drive',
        hint:
            'اكتبها بصيغة "من ... إلى ...": من مبلغ ثابت غير مقيس إلى فاتورة حجمية عادلة يمكن تدقيقها.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'problemSystem',
        labelAr: 'المشكلة داخل نظامها',
        labelEn: 'The problem in its system',
        hint:
            'لا تصف المنتج، صف النظام: من يخسر ماذا اليوم؟ ولماذا يستمر الخطأ؟ '
            'مثال: قراءة العدادات على الورق تُنتج فاقداً غير مرئي وفواتير غير قابلة للتدقيق.',
        lines: 4,
      ),
      BriefFieldSpec(
        key: 'threeActors',
        labelAr: 'الفاعلون الثلاثة حولها',
        labelEn: 'The three actors around it',
        hint:
            'من يملك البئر أو يديرها؟ من يقيس ويحصّل؟ من يدفع؟ من يراقب؟ سمِّهم بأسمائهم لا بصفتهم فقط.',
        lines: 3,
      ),
    ],
  ),

  // ==========================================================
  // الطبقة 2 · ادعاؤنا التقني
  // ==========================================================
  BriefLayerSpec(
    key: 'technology',
    dayAr: 'الثلاثاء · الطبقة 2',
    titleAr: 'ادعاؤنا التقني',
    titleEn: 'Our technology claim',
    questionAr:
        'ما الادعاء القابل للقياس؟ وما الرقم الذي يثبته؟ وما الدليل المتوفر اليوم؟ وما الاختبار الذي يقوّيه؟',
    questionEn:
        'What is the measurable claim, the number behind it, the evidence we hold, and the test that would strengthen it?',
    icon: Icons.science_outlined,
    color: Color(0xFF00897B),
    fields: <BriefFieldSpec>[
      BriefFieldSpec(
        key: 'claim',
        labelAr: 'الادعاء في جملة واحدة',
        labelEn: 'The claim in one sentence',
        hint:
            'مثال: قراءة عداد الماء من صورة واحدة، مع درجة ثقة تمنع ترحيل القراءة المشكوك فيها إلى الفاتورة.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'number',
        labelAr: 'الرقم الذي يثبته',
        labelEn: 'The number',
        hint:
            'رقم واحد قابل للقياس: زمن القراءة، نسبة الخطأ، نسبة القراءات المقبولة آلياً، تكلفة القراءة. '
            'اكتب الرقم الحالي والرقم المستهدف وافصل بينهما بوضوح.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'howItWorks',
        labelAr: 'كيف يعمل',
        labelEn: 'How it works',
        hint:
            'سلسلة من 4 إلى 6 خطوات فقط: صورة ← فحص جودة ← قصّ الإطار ← تحويل الأرقام وتطبيعها ← تحليل الثقة ← ترحيل أو مراجعة بشرية.',
        lines: 4,
      ),
      BriefFieldSpec(
        key: 'evidence',
        labelAr: 'الأدلة المتوفرة اليوم',
        labelEn: 'The evidence we hold',
        hint:
            'ما الذي يعمل فعلاً الآن؟ تطبيق مبني، شاشات تعمل، تسلسل بيانات كامل، تجارب على عدادات حقيقية. '
            'كن دقيقاً: افصل بين "مبني" و"مُختبَر على عينة".',
        lines: 4,
      ),
      BriefFieldSpec(
        key: 'test',
        labelAr: 'الاختبار الذي سيقوّي الادعاء',
        labelEn: 'The test that would strengthen it',
        hint:
            'تصميم تجربة: عدد العدادات، عدد الآبار، من يجمع الحقيقة المرجعية، معيار النجاح، المدة.',
        lines: 4,
      ),
    ],
  ),

  // ==========================================================
  // الطبقة 3 · المؤسسات حولنا
  // ==========================================================
  BriefLayerSpec(
    key: 'institutions',
    dayAr: 'الأربعاء · الطبقة 3',
    titleAr: 'المؤسسات حولنا',
    titleEn: 'The institutions around us',
    questionAr:
        'من يقرر؟ وماذا التزم به؟ وكيف يشتري؟ ومن أين ندخل بالبرنامج التجريبي (pilot)؟',
    questionEn:
        'Who decides, what have they committed to, how do they buy, and where is our pilot entry point?',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF6A1B9A),
    fields: <BriefFieldSpec>[
      BriefFieldSpec(
        key: 'whoDecides',
        labelAr: 'من يقرر',
        labelEn: 'Who decides',
        hint:
            'ليست جهة واحدة: لجنة البئر، المجلس المحلي، مؤسسة المياه، الجهة المانحة. اذكر من يوقّع فعلاً.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'commitments',
        labelAr: 'ما التزمت به',
        labelEn: 'What they committed to',
        hint:
            'التزامات مكتوبة: هدف التنمية 6، سياسة المياه الوطنية، شروط المانح، خطة المحافظة. '
            'الالتزام المكتوب هو مدخلك في المحادثة.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'howTheyBuy',
        labelAr: 'كيف يشترون',
        labelEn: 'How they buy',
        hint:
            'مناقصة؟ عقد سنوي؟ مشروع ممول؟ شراء مباشر صغير؟ ما سقف الشراء المباشر؟ من يدفع الثمن النهائي؟',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'pilotEntry',
        labelAr: 'نقطة الدخول للبرنامج التجريبي',
        labelEn: 'Our pilot entry point',
        hint:
            'بئر واحد أو حيّ واحد، مدة محددة، مخرج واحد يقيسه المشتري: تقرير فاقد، تقرير تحصيل، أو تدقيق قراءات.',
        lines: 3,
      ),
    ],
  ),

  // ==========================================================
  // الطبقة 4 · سوقنا ومن يدفع
  // ==========================================================
  BriefLayerSpec(
    key: 'market',
    dayAr: 'الخميس · الطبقة 4',
    titleAr: 'سوقنا ومن يدفع',
    titleEn: 'Our market, our payer',
    questionAr:
        'من المستفيد؟ ومن صاحب القرار؟ ومن يدفع فعلاً؟ وكيف نحسب السوق من الأسفل إلى الأعلى؟',
    questionEn:
        'Who benefits, who decides, who pays, and how do we size the market bottom-up?',
    icon: Icons.payments_outlined,
    color: Color(0xFFEF6C00),
    fields: <BriefFieldSpec>[
      BriefFieldSpec(
        key: 'beneficiary',
        labelAr: 'المستفيد',
        labelEn: 'The beneficiary',
        hint: 'من تتحسن حياته؟ المشترك؟ أسرة المشترك؟ العامل الذي يقرأ العداد؟',
        lines: 2,
      ),
      BriefFieldSpec(
        key: 'decider',
        labelAr: 'صاحب القرار',
        labelEn: 'The decider',
        hint: 'من يقول "نعم" ولا يمكن المشروع أن يمضي بدون توقيعه؟',
        lines: 2,
      ),
      BriefFieldSpec(
        key: 'payer',
        labelAr: 'الدافع',
        labelEn: 'The payer',
        hint:
            'غالباً ليس صاحب القرار: المشتركون عبر الفاتورة، أو المانح عبر المشروع، أو البلدية عبر الميزانية. '
            'اكتب من يحرّر الشيك.',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'marketBottomUp',
        labelAr: 'السوق من الأسفل إلى الأعلى',
        labelEn: 'The market, bottom-up',
        hint:
            'عدد الآبار × عدد المشتركين في البئر × سعر المشترك في السنة = السوق. '
            'استخدم أرقاماً من بياناتك، وسمِّ كل افتراض بوسم "افتراض للتحقق".',
        lines: 4,
      ),
      BriefFieldSpec(
        key: 'firstCustomer',
        labelAr: 'أول عميل',
        labelEn: 'The first customer',
        hint:
            'اسم محدد، مكان محدد، وما سيدفعه في أول 90 يوماً. لا تكتب "المؤسسات" أو "المزارعون".',
        lines: 3,
      ),
      BriefFieldSpec(
        key: 'hundredWords',
        labelAr: 'المشروع في ١٠٠ كلمة',
        labelEn: 'The venture in 100 words',
        hint:
            'نسخة نهائية مكثفة تُقرأ بصوت واحد: المشكلة، الحل، الدليل، من يدفع، وما نطلبه الآن.',
        lines: 7,
      ),
    ],
  ),
];
