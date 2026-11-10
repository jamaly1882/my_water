#!/usr/bin/env python3
# ============================================================
# build_case_board.py
# يبني لوحة "Tonight's case — Technology, verification and unit
# economics" معبّأة لمشروع Azal Soft Platform، على صفحة واحدة
# جاهزة للرفع على Miro أو للطباعة.
#
#   python3 tool/build_case_board.py
# ============================================================

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    KeepTogether,
)

OUT = "docs/Azal_Soft_Case_Board.pdf"

BG = colors.HexColor("#1F2A16")        # خلفية اللوحة الخضراء الداكنة
CARD = colors.HexColor("#F6F3D6")      # بطاقات كريمية
CARD_ALT = colors.HexColor("#FBF9E7")
INK = colors.HexColor("#2B2B1E")
MUTED = colors.HexColor("#6B6A55")
ORANGE = colors.HexColor("#E8791E")
CREAM = colors.HexColor("#F6F3D6")

W, H = A4

# ------------------------------------------------------------
# القالب
# ------------------------------------------------------------

def paint(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(BG)
    canvas.rect(0, 0, W, H, stroke=0, fill=1)
    # شريط سفلي
    canvas.setFillColor(colors.HexColor("#17200F"))
    canvas.rect(0, 0, W, 12 * mm, stroke=0, fill=1)
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(
        18 * mm,
        5 * mm,
        "Azal Soft Platform — Meter reading, cycle rollover and loss ledger  ·  "
        "example figures, replace with your own before the session",
    )
    canvas.restoreState()


def build():
    doc = BaseDocTemplate(
        OUT,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=14 * mm,
        bottomMargin=16 * mm,
        title="Azal Soft Platform — Technology, verification and unit economics",
        author="Azal Soft Platform",
    )

    frame = Frame(
        doc.leftMargin,
        doc.bottomMargin,
        doc.width,
        doc.height,
        id="board",
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
    )

    doc.addPageTemplates(
        [PageTemplate(id="board", frames=[frame], onPage=paint)]
    )

    title = ParagraphStyle(
        "title",
        fontName="Helvetica-Bold",
        fontSize=15,
        leading=18,
        textColor=CREAM,
        spaceAfter=2,
    )
    sub = ParagraphStyle(
        "sub",
        fontName="Helvetica",
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#B9C7A8"),
        spaceAfter=7,
    )
    band = ParagraphStyle(
        "band",
        fontName="Helvetica-Bold",
        fontSize=10.5,
        leading=13,
        textColor=colors.white,
    )
    label = ParagraphStyle(
        "label",
        fontName="Helvetica-Bold",
        fontSize=7.2,
        leading=9,
        textColor=colors.HexColor("#7A7A5E"),
    )
    help_txt = ParagraphStyle(
        "help",
        fontName="Helvetica-Oblique",
        fontSize=6.6,
        leading=8.2,
        textColor=colors.HexColor("#9A9A7C"),
        spaceAfter=3,
    )
    body = ParagraphStyle(
        "body",
        fontName="Helvetica",
        fontSize=9,
        leading=12.4,
        textColor=INK,
    )
    big = ParagraphStyle(
        "big",
        fontName="Helvetica-Bold",
        fontSize=10.5,
        leading=13.5,
        textColor=INK,
    )

    story = []

    story.append(
        Paragraph("Azal Soft Platform — Technology, verification and unit economics", title)
    )
    story.append(
        Paragraph(
            "TRIAD 2 · Tonight's case · answers prepared against the board template",
            sub,
        )
    )

    # شريط العنوان البرتقالي
    band_tbl = Table(
        [[Paragraph("Tonight's case · Technology, verification and unit economics", band)]],
        colWidths=[doc.width],
    )
    band_tbl.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), ORANGE),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.append(band_tbl)
    story.append(Spacer(1, 6))

    # --------------------------------------------------------
    # بطاقة
    # --------------------------------------------------------

    def card(label_text, help_text, content, big_text=False, width=None):
        style = big if big_text else body
        inner = [Paragraph(label_text.upper(), label)]
        if help_text:
            inner.append(Paragraph(help_text, help_txt))
        inner.append(Paragraph(content, style))
        t = Table([[inner]], colWidths=[width or doc.width])
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), CARD),
                    ("LEFTPADDING", (0, 0), (-1, -1), 8),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                    ("TOPPADDING", (0, 0), (-1, -1), 6),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ]
            )
        )
        return t

    # 1 — المخطط
    story.append(
        card(
            "Our architecture in one diagram",
            "Inputs → core → outputs. Draw it with shapes and arrows, or paste a photo of a sketch.",
            "<b>Meter photo</b> at the well (agent's phone) → <b>digit-checked reading</b> "
            "(6 or 7 digits, operator confirms) → <b>cycle ledger</b> in Firestore, one chain per well "
            "→ <b>owner dashboard</b> and CSV/PDF export.<br/>"
            "No smart meter, no SIM, no extra energy: the phone camera is the sensor.",
            big_text=True,
        )
    )
    story.append(Spacer(1, 5))

    # 2 + 3 — ملكنا / ملك الشريك
    half = (doc.width - 5) / 2.0
    ours = card(
        "What is ours",
        "Proprietary: what we built and others cannot copy easily.",
        "The cycle and loss engine: reading capture, consumption, rollover "
        "(<b>closing = next opening</b>), loss per cycle, subscriber and well ledgers.",
        big_text=True,
        width=half,
    )
    partners = card(
        "What we partner for or buy",
        "Components, data or services we rely on others for.",
        "Firebase (Auth, Firestore, rules, hosting), a vision model for the digits, "
        "and the agent's Android phone.",
        big_text=True,
        width=half,
    )
    pair = Table([[ours, partners]], colWidths=[half, half])
    pair.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), BG),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (0, 0), 5),
                ("RIGHTPADDING", (1, 0), (1, 0), 0),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
            ]
        )
    )
    story.append(pair)
    story.append(Spacer(1, 5))

    # 4 — لماذا قابل للدفاع
    story.append(
        card(
            "Why it is defensible",
            "Patent, data, know-how, certification, a partnership, or a cost no one else can match.",
            "Not the camera — <b>the rule set</b>. An unbroken reading chain per well plus a loss "
            "figure per cycle produces a record that cannot be reconstructed afterwards, so every "
            "well we add deepens the baseline and the switching cost. Cost is also defensible: "
            "a phone and a photo instead of a smart meter and a SIM.",
            big_text=True,
        )
    )
    story.append(Spacer(1, 5))

    # 5 — خطة التحقق
    story.append(
        card(
            "Our verification plan",
            "What we will test, who checks it, by when, and the standard or certification we aim for.",
            "<b>1 · Accuracy.</b> A labelled set of real meter photos, scored per digit count (6 vs 7) "
            "and per lighting condition — the accuracy number is published, not claimed.<br/>"
            "<b>2 · Integrity.</b> The server rejects any cycle that opens at a reading other than the "
            "previous one's closing; every reading keeps operator and timestamp.<br/>"
            "<b>3 · Field proof.</b> A parallel run at one real well for one full cycle, alongside the "
            "paper register, witnessed by a local partner (water department or university).<br/>"
            "<b>4 · Third party.</b> Same evidence pack handed to an independent auditor once the "
            "parallel run is clean — the cheap order of de-risking.",
            big_text=True,
        )
    )
    story.append(Spacer(1, 5))

    # 6 — اقتصاديات الوحدة
    def eco_cell(title_txt, help_text, value_txt):
        return [
            Paragraph(title_txt.upper(), label),
            Paragraph(help_text, help_txt),
            Paragraph(value_txt, big),
        ]

    q = (doc.width - 15) / 4.0
    eco = Table(
        [
            [
                eco_cell("Our unit", "Per m³, per site, per connection.", "One well<br/>· one month<br/><font size=7 color='#6B6A55'>(≈20 subs, ≈20 cycles)</font>"),
                eco_cell("Cost per unit", "All it costs us to deliver one.", "$1.20<br/><font size=7 color='#6B6A55'>OCR + hosting + support</font>"),
                eco_cell("Price per unit", "What the customer pays.", "$12<br/><font size=7 color='#6B6A55'>per well / month</font>"),
                eco_cell("Margin per unit", "Price minus cost.", "90%<br/><font size=7 color='#6B6A55'>≈$10.8 per well / month</font>"),
            ]
        ],
        colWidths=[q, q, q, q],
    )
    eco.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), CARD_ALT),
                ("BOX", (0, 0), (-1, -1), 0.6, colors.HexColor("#C9C6A6")),
                ("INNERGRID", (0, 0), (-1, -1), 0.6, colors.HexColor("#C9C6A6")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )

    unit_block = KeepTogether(
        [
            Paragraph(
                "<font color='#F6F3D6'><b>UNIT ECONOMICS</b></font> "
                "<font color='#B9C7A8' size=7>· one unit, what it costs us, what we charge</font>",
                ParagraphStyle("ecohead", fontName="Helvetica", fontSize=9, leading=11, spaceAfter=4),
            ),
            eco,
        ]
    )
    story.append(unit_block)
    story.append(Spacer(1, 5))

    # 7 — مسارك
    story.append(
        card(
            "For your lane — digital, not hardware",
            "Hardware: energy per m³ (kWh). Digital: the cost to serve one more customer.",
            "The cost to serve <b>one more well is ≈$1 a month</b>: no hardware, no energy per m³, "
            "no installation. That is the whole point of the model — the marginal cost is flat while "
            "the recovered loss scales with every well. Pricing follows the customer's avoided loss, "
            "not our server bill.",
            big_text=True,
        )
    )
    story.append(Spacer(1, 5))

    # تذييل اللوحة
    story.append(
        Paragraph(
            "<font color='#B9C7A8' size=7.5>"
            "Two numbers to keep honest in front of the jury: "
            "<b>accuracy</b> (measured on a labelled photo set) and <b>cost per unit</b> "
            "(what it costs us, not what the customer pays). "
            "Replace every example figure above with your own before the session.</font>",
            ParagraphStyle("foot", fontName="Helvetica", fontSize=8, leading=10.5),
        )
    )

    doc.build(story)
    print("written:", OUT)


if __name__ == "__main__":
    build()
