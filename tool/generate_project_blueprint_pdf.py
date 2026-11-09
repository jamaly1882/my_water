"""Generate the bilingual project plan; requires reportlab, arabic-reshaper, python-bidi."""
from pathlib import Path
import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import HexColor

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/project_blueprint_ar_en.pdf'
for name,file in [('Body','DejaVuSans.ttf'),('Bold','DejaVuSans-Bold.ttf')]:
    pdfmetrics.registerFont(TTFont(name,'/usr/share/fonts/truetype/dejavu/'+file))
W,H=595.28,841.89
c=canvas.Canvas(str(OUT),pagesize=(W,H))
c.setTitle('Azal Soft Platform | Bilingual Project Blueprint')
c.setAuthor('Azal Soft Platform')
AR=[
('خطة المشروع', 'منصة أزال سوفت لإدارة تشغيل مياه الآبار', [
('ملخص تنفيذي','تربط المنصة قراءات العدادات والاستهلاك والفواتير والتحصيل والمصروفات في سجل رقمي قابل للتتبع. العميل التجاري المرشح هو لجنة البئر أو الجهة المشغلة، والمستخدم هو قارئ العداد أو المحاسب، والمستفيد هو الأسر المشتركة. الهدف هو تحسين قابلية التحقق من الحسابات وكفاءة العمل؛ وهذه فوائد متوقعة وليست نتائج مثبتة.'),
('المشكلة والحل','فرضية المشكلة: فصل السجلات وتكرار نقل الأرقام يصعّبان مطابقة الفواتير والتحصيل والصندوق وحل الاعتراضات. الحل: مسار موحد يبدأ بقراءة معتمدة وينتهي بتقرير دورة ومطابقة مالية. نتحقق من السبب الجذري بمشاهدة دورة حقيقية ومراجعة سجلات منزوعة البيانات الحساسة.'),
('النطاق وحدود الادعاء','نطاق تخطيط مقترح: عشرة آبار وستون مشتركًا إجمالًا، يحتاج إلى تأكيد، وتجربة تمتد أربع دورات شهرية بعد الإعداد. وجود وظائف برمجية في المستودع لا يثبت تشغيلًا ميدانيًا أو وجود عملاء دافعين. لا ندعي توفير الماء أو خفض التسرب أو تحسن سلامته دون قياسات مناسبة.'),
('الأهداف ومخرجات المنتج الأول','تهيئة الآبار والمشتركين والعدادات؛ تسجيل القراءات ومراجعتها؛ حساب الاستهلاك والفواتير بالتعرفة المعتمدة؛ توثيق القبض والصرف؛ مطابقة الصندوق؛ إعداد تقرير وإغلاق الدورة. المخرجات: سجل تشغيل، مستندات قابلة للتتبع، تقرير تجربة، وقرار استمرار أو تعديل أو إيقاف.'),
('أساس الخطة','أُعدت في ٩ نوفمبر ٢٠٢٦ بالاستناد إلى مستندات المشروع ومراجعة محاضرات الأسبوع الأول ودراسة حالة اليوم الأول. تطبيق المحاضرة الخامسة عن العميل ونموذج العمل مقترح عملي؛ لم تُقدَّم شرائحها، ولا ننسب تفاصيله إلى المحاضر. الأسعار والنتائج غير الموثقة تظل افتراضات.')]),
('تطبيق المحاضرات الخمس','من فهم المشكلة إلى العميل ونموذج العمل',[
('١. المشكلة وموقعنا على الخريطة','المشروع ضمن البنية الرقمية لتشغيل شبكات الآبار عند التوزيع والاستخدام. التركيز المائي أساسي، ومستوى التغيير المستهدف مجتمعي. الحوار الأساسي المقترح: المياه للناس؛ والثانوي: الاستثمارات للمياه من زاوية الحوكمة المالية، لا لمجرد طلب تمويل. نفصل بين المتضرر وصاحب القرار والدافع.'),
('٢. التقنية والدليل','الادعاء القابل للاختبار: ربط القراءة المعتمدة بالفاتورة والحساب قد يقلل إعادة الإدخال ويحسن التتبع. نقيس الزمن والدقة قبل الاستخدام وبعده على قراءات مرجعية متحققة. ما لدينا وصف وظائف برمجية، وليس تحققًا مستقلًا من أثر ميداني. يشمل الاختبار إعادة التصوير والتصحيح وحالات الفشل.'),
('٣. المؤسسات والتجربة','نحدد الجهة المخولة بالتوقيع وإذن الوصول للعدادات والبيانات. يبدأ الطلب ببئر واحد، ثم يتوسع تدريجيًا وفق الجاهزية. يوفر المشغّل مسؤول تشغيل وسجلات وموافقات، ويوفر الفريق التدريب والدعم والتقرير. لا تبدأ التجربة دون خط أساس وصلاحيات وقاعدة قرار مكتوبة.'),
('٤. السوق ومن يدفع','الدافع المحتمل صاحب ميزانية تشغيل البئر. نختبر اشتراكًا لكل بئر وقد نفصل رسوم التهيئة. السوق المتاح يُحسب من عدد المشترين الممكن الوصول إليهم، ومتوسط آبارهم، والسعر السنوي، وحصة الفوز الواقعية. لا تمثل الأسر الستون ستين مشتريًا للمنصة؛ وتمويل تجربة لا يثبت طلبًا تجاريًا متكررًا.'),
('٥. العميل ونموذج العمل','نبدأ بمشغّل يعاني مشكلة متكررة ويملك صاحب قرار وميزانية وموظفًا مستعدًا للتجربة. نسأله عن آخر دورة وآخر خطأ وكلفة البديل الحالي ومسار الشراء. ثم نعرض نطاق خدمة وسعرًا محددين ونطلب خطوة فعلية. الإعجاب ليس شراءً، وخطاب النوايا ليس إيرادًا.'),
('درس الحالة: استدامة التشغيل','تُظهر حالة لايف فروم ووتر أهمية سد الفجوة بين البناء واستمرار التشغيل. تطبيقنا: تحديد من يُدخل ويراجع البيانات ويدرب ويمول الدعم. لا ننقل نتائج الحالة أو شركاءها إلى مشروعنا.')]),
('العميل ونموذج العمل','تسع لبنات مترابطة — فرضيات للاختبار',[
('العملاء والقيمة المقترحة','شرائح العملاء: لجان ومالكو وجهات تشغيل الآبار المجتمعية. المستخدمون: القراء والمحاسبون والمشرفون. القيمة: سلسلة قابلة للتتبع من القراءة إلى الصندوق، تسهل المراجعة وإغلاق الدورة. نتحقق من أن هذه المشكلة أولوية فعلية تستحق الدفع.'),
('القنوات والعلاقة بالعميل','القنوات المقترحة: التواصل المباشر والزيارات والإحالات من مشغّلين وشركاء محليين بعد موافقتهم. العلاقة: تهيئة وتدريب ودعم ومراجعة دورية. تُختبر كلفة هذه العلاقة وقدرة الفريق على تقديمها؛ لا توجد شراكات مؤكدة في هذه الخطة.'),
('الإيرادات والموارد','الإيراد المقترح: اشتراك لكل بئر، مع رسوم تهيئة اختيارية حسب العمل المطلوب. الموارد الأساسية: المنصة والاستضافة وفريق تقني ودعم ميداني وبيانات مصرح بها. لا يوجد سعر أو إيراد محقق مثبت هنا، ولا نعد بتحصيل مدفوعات إلكترونية دون التحقق من التكامل.'),
('الأنشطة والشركاء والتكاليف','الأنشطة: تطوير واختبار وإعداد وتدريب ودعم وتدقيق جودة البيانات. الشركاء المحتملون: مشغّل البئر وجهة وصول محلية وممول تجربة عند الاتفاق. التكاليف: تطوير واستضافة ومعالجة صور وتخزين ودعم وزيارات وتدريب. يجب قياس تكلفة خدمة كل بئر.'),
('خطة اكتشاف العميل','مقابلة خمس جهات تشغيل وثلاثة مستخدمين وثلاث أسر بعينة تعلم نوعية لا تمثل السوق إحصائيًا. توثيق المشكلة وتكرارها وكلفتها والبديل والميزانية وصاحب القرار والاعتراض والخطوة التالية. جمع الحد الأدنى من البيانات بموافقة؛ لا تُنشر أسماء الأسر.'),
('اختبار السعر والاقتصاديات','يُحدد عرض السعر بعد حصر الكلفة. الإيراد الشهري يساوي الآبار المدفوعة مضروبة في الاشتراك. هامش المساهمة لكل بئر هو الاشتراك ناقص التكلفة المتغيرة. نقطة التعادل هي التكلفة الثابتة مقسومة على هامش موجب، مع التقريب لأعلى. إذا لم يظهر ألم وميزانية وخطوة فعلية، نراجع الشريحة والعرض قبل إضافة مزايا.')]),
('التنفيذ والقياس','خطة تجربة تنتهي بقرار، لا بمجرد عرض تقني',[
('الجدول والمسؤوليات','الأسبوع الأول: اكتشاف العميل وخط أساس، بقيادة صاحب المشروع ومسؤول ميداني. الأسبوع الثاني: موافقة وسعر وصلاحيات واختبار جاهزية، بمشاركة المشغّل والفريق التقني. الدورة الأولى: تشغيل بئر واحد؛ الدورات الثانية إلى الرابعة: توسع مشروط حتى النطاق المتفق عليه. بعد الرابعة: مراجعة وقرار يوقعه صاحب الصلاحية. تُثبت الأسماء والتواريخ عند الموافقة.'),
('مؤشرات النجاح المقترحة','خطوط الأساس غير معروفة وتُقاس قبل البداية. الأهداف: اعتماد قراءات ٩٥٪ من العدادات النشطة المستحقة في كل دورة؛ وسيط تسجيل أقل من ٣٠ ثانية بعد التدريب مع احتساب التصحيح؛ خطأ بعد المراجعة لا يتجاوز ١٪ مقابل مرجع؛ ربط جميع الفواتير بقراءة ودورة؛ توثيق ٩٥٪ من العمليات المالية على الأقل؛ وصفر فرق صندوق غير مفسر عند الإغلاق. جميعها أهداف وليست إنجازات.'),
('طريقة التحقق وحدود العينة','نستخدم سجلات مؤرخة وتوقيتًا موحدًا ومراجعة قراءات وفواتير وسندات وعدًا فعليًا للنقد. ستون مشتركًا في أربع دورات تعطي حتى ٢٤٠ فرصة قراءة إن كان الجميع نشطًا؛ ليست عينات مستقلة، ولا تكفي وحدها لليقين بمعدل خطأ منخفض. ننشر عدد الأخطاء وحجم العينة، ونقيس الدفع الفعلي منفصلًا عن الاهتمام.'),
('المخاطر والضوابط','ضعف الاتصال: اختبار بيئة الموقع وعدم الوعد بالعمل دون اتصال قبل التحقق. أخطاء القراءة: مراجعة بشرية قبل الفوترة. بيانات افتتاحية خاطئة: تحقق مشترك. الخصوصية: أقل صلاحيات لازمة واختبار الحماية والنسخ الاحتياطي والاستعادة. رفض المستخدم أو غياب الميزانية: مقابلات وتدريب واختبار سعر مبكر.'),
('قرار الاستمرار وما يلزم تأكيده','يُشترط للتوسع: جودة مستقرة، وعدم وجود خلل فوترة أو أمن حرج غير معالج، وقدرة دعم، وموافقة مكتوبة وتكلفة مقبولة. تُعتمد العتبات قبل البداية. المطلوب من صاحب المشروع: تأكيد النطاق والموقع، وتسمية العميل والمخوّل بالتوقيع، وتوفير خط أساس وتكاليف وسعر للاختبار. الخيارات النهائية: تعاقد مدفوع أو تعديل أو إيقاف.')])]
EN=[
('PROJECT BLUEPRINT','Azal Soft Platform | Community water-well operations',[
('Executive summary','The platform connects meter readings, consumption, bills, collections and expenses in a traceable digital record. The prospective buyer is a well committee or operating entity; users include meter readers and accountants; households benefit. Better auditability and working efficiency are expected benefits, not demonstrated outcomes.'),
('Problem and solution','Working hypothesis: fragmented records and repeated transcription make it difficult to reconcile billing, collections and cash, or resolve disputes. The solution is one workflow from an approved reading to cycle reports and financial reconciliation. Validate the underlying cause through observation of a real cycle and review of de-identified records.'),
('Scope and claim boundaries','Proposed planning scope: 10 wells and 60 subscribers in total, subject to confirmation, over four monthly cycles after preparation. Repository functionality does not establish field readiness, live deployment or paying customers. No water savings, leakage reduction or water-safety improvement is claimed without appropriate measurements.'),
('Initial product and deliverables','Priorities: register wells, subscribers and meters; capture and approve readings; calculate consumption and bills under approved tariffs; record receipts and payments; reconcile cash; report and close cycles. Deliverables are an operating record, traceable documents, an evaluation report and a continue, revise or stop decision.'),
('Basis and evidence status','Prepared on 9 November 2026 using project documents and the reviewed Week 1 slides and Day 1 case. Session 5, customer and business model, is a proposed practical application: its slides were not provided. Its details are not attributed to a lecturer. Unverified prices and performance figures remain hypotheses.')]),
('FIVE SESSION APPLICATIONS','From understanding the system to testing a customer',[
('1. The problem and our place on the map','The venture sits in digital infrastructure for well operations, at distribution and use. Water focus is primary; the intended initial change level is community. Proposed dialogues: Water for People, with Investments for Water secondary because of financial governance, not fundraising alone. Separate the affected party, adoption decision-maker and payer.'),
('2. Technology and evidence','Testable claim: linking approved readings to bills and accounts may reduce duplicate entry and improve traceability. Compare time and accuracy with a verified reference and baseline. Current documents describe software functions, not independently validated field impact. Include recaptures, corrections and failures in the test.'),
('3. Institutions and pilots','Identify the authorised signatory and permission to access meters and data. Start with one well, expanding only after readiness review. The operator supplies records, permissions and a responsible staff member; the team supplies setup, training, support and evaluation. Permission, baseline and a written decision rule are prerequisites.'),
('4. Market and payer','The prospective payer controls the operating budget. Test a per-well subscription, potentially separating setup fees. Estimate reachable market from accessible buying entities, wells per entity, annual price and a defensible win share. The 60 households are not automatically 60 software buyers; grant-funded trials do not establish recurring commercial demand.'),
('5. Customer and business model','Select an operator with recurring pain, a reachable decision-maker, a budget and a willing user. Ask about the last cycle, last error, actual alternative costs and purchase route. Present a defined scope and price, then seek a concrete next step. Verbal enthusiasm is not a purchase; a letter of intent is not revenue.'),
('Case lesson: sustained operation','Life From Water illustrates the gap between construction and sustained operation. Our application is to assign data-entry, review, training and ongoing support responsibilities and funding. The case’s outcomes and partners must not be presented as ours.')]),
('CUSTOMER & BUSINESS MODEL','Nine connected building blocks | hypotheses to validate',[
('Segments and value proposition','Customer segments: committees, owners and entities operating community wells. Users: readers, accountants and supervisors. Value proposition: a traceable reading-to-cash workflow supporting review and cycle closure. Verify that this is an urgent problem worth paying to solve.'),
('Channels and relationships','Proposed channels: direct outreach, visits and referrals from operators or local partners, with permission. Relationships: onboarding, training, support and periodic review. Measure delivery cost and team capacity. No confirmed partnership is implied by this plan.'),
('Revenue and resources','Proposed revenue: a subscription per well, with a possible separate setup charge based on actual effort. Key resources: platform, hosting, technical staff, field support and authorised data. No validated price or realised revenue is established here. Do not promise payment integration without verification.'),
('Activities, partners and costs','Activities: development, testing, configuration, training, support and data-quality review. Potential partners: the operator, a local access facilitator and a trial funder if agreed. Costs: development, hosting, image processing, storage, support, visits and training. Measure the actual service cost per well.'),
('Customer discovery','Interview five operators, three users and three households as a qualitative learning sample, not a representative market survey. Record pain, recurrence, evidenced cost, alternative, budget, authority, objections and next action. Obtain consent, collect minimal data and avoid publishing household identities.'),
('Price test and economics','Set a concrete offer after estimating costs. Monthly revenue equals paying wells times subscription price. Contribution per well equals price minus variable cost. Break-even wells equal fixed monthly cost divided by positive contribution, rounded up. If interviews reveal no recurring pain, budget or practical commitment, revise the segment and offer before adding features.')]),
('EXECUTION & EVALUATION','A trial designed to produce an adoption decision',[
('Timeline and ownership','Week 1: discovery and baseline, led by the founder and a field lead. Week 2: agreement, price, permissions and readiness, with the operator and technical lead. Cycle 1: one well; cycles 2–4: conditional expansion to the agreed scope. After cycle 4: evaluation and a signatory-approved decision. Confirm names and actual dates after agreement.'),
('Proposed success targets','Baselines are unknown and must be measured first. Targets: approved readings for at least 95% of eligible active meters per cycle; median routine capture below 30 seconds after training, including corrections; reviewed error at most 1% against a reference; all bills linked to a reading and cycle; at least 95% of financial transactions documented; zero unexplained cash difference at close. These are targets, not achievements.'),
('Verification and sample limits','Use dated logs, consistent timing, reference readings, invoice and voucher checks and physical cash counts. Sixty active subscribers over four cycles provide up to 240 reading opportunities, not independent observations. This alone cannot establish a low error rate with high certainty. Publish counts and denominators. Measure actual payment separately from interest.'),
('Risks and safeguards','Connectivity: test on site; do not promise offline capability before verification. Reading errors: human review before billing. Opening-data errors: joint verification. Privacy: least-privilege access and tests of protection, backup and restoration. Adoption and budget risk: early interviews, training and a concrete price test.'),
('Decision gate and open inputs','Expand only with stable data quality, no unresolved critical billing or security issue, support capacity, acceptable costs and written approval. Agree thresholds before the trial. Required inputs: scope and location confirmation, named buyer and signatory, baseline records, costs and test price. Final options are a paid contract, revision or stop.')])]

def visual(t,ar): return get_display(arabic_reshaper.reshape(t),base_dir='R') if ar else t

def wrap(text,ar,size,width):
    lines=[]; line=''
    for word in text.split():
        trial=(line+' '+word).strip()
        if pdfmetrics.stringWidth(visual(trial,ar),'Body',size)>width and line:
            lines.append(line); line=word
        else: line=trial
    if line: lines.append(line)
    return lines

pages=[(True,x) for x in AR]+[(False,x) for x in EN]
for idx,(ar,(title,sub,sections)) in enumerate(pages,1):
    c.setFillColor(HexColor('#113d4b')); c.rect(0,H-132,W,132,fill=1,stroke=0)
    c.setFillColor(HexColor('#8cddd1')); c.setFont('Bold',10)
    c.drawString(44,H-30,'AZAL SOFT  /  PROJECT BLUEPRINT')
    c.setFillColorRGB(1,1,1); c.setFont('Bold',22)
    if ar: c.drawRightString(W-44,H-69,visual(title,True))
    else: c.drawString(44,H-69,title)
    c.setFont('Body',11)
    if ar: c.drawRightString(W-44,H-99,visual(sub,True))
    else: c.drawString(44,H-99,sub)
    # Fit each curated page while retaining readable typography.
    size=10.3 if ar else 10
    while True:
        height=sum(24+len(wrap(text,ar,size,W-88))*size*1.55+12 for _,text in sections)
        if height< H-188 or size<8.8: break
        size-=.2
    y=H-157
    for heading,text in sections:
        c.setFillColor(HexColor('#007d83')); c.setFont('Bold',size+1.3)
        if ar: c.drawRightString(W-44,y,visual(heading,ar))
        else: c.drawString(44,y,heading)
        y-=22
        c.setFillColor(HexColor('#263844')); c.setFont('Body',size)
        for line in wrap(text,ar,size,W-88):
            if ar: c.drawRightString(W-44,y,visual(line,ar))
            else: c.drawString(44,y,line)
            y-=size*1.55
        y-=14
    if y<43: raise RuntimeError(f'Page {idx} overflows: {y}')
    c.setStrokeColor(HexColor('#c8d9df')); c.line(44,37,W-44,37)
    c.setFillColor(HexColor('#526772')); c.setFont('Body',8)
    c.drawString(44,23,'09 NOV 2026  |  Planning draft - targets are not verified results')
    c.drawRightString(W-44,23,f'{idx} / {len(pages)}')
    c.showPage()
c.save()
print(OUT)
