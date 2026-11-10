#!/usr/bin/env python3
# ============================================================
# build_architecture_diagram.py
# يرسم مخطط المعمارية (Input → Core → Output) لمشروع Azal Soft
# كصورة PNG جاهزة للصق في صندوق "Our architecture in one diagram"
# على لوحة Miro.
#
#   python3 tool/build_architecture_diagram.py
# ============================================================

import os

from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.pdfgen import canvas

PDF = "docs/azal_soft_architecture.pdf"
PNG = "docs/azal_soft_architecture.png"

PAGE_W = 297 * mm
PAGE_H = 114 * mm  # صفحة مقتطعة على المحتوى، بلا فراغ أسفل الصورة

INK = colors.HexColor("#23231C")
MUTED = colors.HexColor("#6E6C58")
LINE = colors.HexColor("#C9C4AE")
CALM = colors.HexColor("#F6F4EA")
ACCENT = colors.HexColor("#8A4B2A")
ACCENT2 = colors.HexColor("#2F5D50")


def wrap(text, font, size, max_w, c):
    """يقسم النص إلى أسطر بحسب عرض الصندوق."""
    words = text.split()
    lines, line = [], ""
    for w in words:
        trial = (line + " " + w).strip()
        if c.stringWidth(trial, font, size) <= max_w:
            line = trial
        else:
            if line:
                lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines


def box(c, x, y, w, h, label, body, accent):
    c.setFillColor(CALM)
    c.setStrokeColor(LINE)
    c.setLineWidth(0.8)
    c.roundRect(x, y, w, h, 3 * mm, stroke=1, fill=1)

    # شريط لوني أعلى الصندوق
    c.setFillColor(accent)
    c.roundRect(x, y + h - 2.2 * mm, w, 2.2 * mm, 1 * mm, stroke=0, fill=1)
    c.rect(x, y + h - 3.4 * mm, w, 1.2 * mm, stroke=0, fill=1)

    c.setFillColor(accent)
    c.setFont("Helvetica-Bold", 8.5)
    c.drawString(x + 3.5 * mm, y + h - 8 * mm, label.upper())

    c.setFillColor(INK)
    ty = y + h - 14 * mm
    for line in wrap(body, "Helvetica", 8, w - 9 * mm, c):
        c.drawString(x + 3.5 * mm, ty, line)
        ty -= 4.4 * mm


def arrow(c, x1, x2, y):
    c.setStrokeColor(ACCENT)
    c.setLineWidth(1.1)
    c.line(x1, y, x2 - 2.2 * mm, y)
    c.setFillColor(ACCENT)
    p = c.beginPath()
    p.moveTo(x2, y)
    p.lineTo(x2 - 3 * mm, y + 1.6 * mm)
    p.lineTo(x2 - 3 * mm, y - 1.6 * mm)
    p.close()
    c.drawPath(p, stroke=0, fill=1)


def build():
    c = canvas.Canvas(PDF, pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Azal Soft Water Platform — architecture in one diagram")

    mx = 14 * mm
    top = PAGE_H - 14 * mm

    # العنوان
    c.setFillColor(INK)
    c.setFont("Helvetica-Bold", 16)
    c.drawString(mx, top - 4 * mm, "Azal Soft Water Platform")
    c.setFont("Helvetica", 9)
    c.setFillColor(MUTED)
    c.drawString(
        mx,
        top - 10 * mm,
        "Architecture in one diagram — input → what our technology does → output",
    )

    # الصف الرئيسي
    gap = 6 * mm
    bw = (PAGE_W - 2 * mx - 4 * gap) / 5.0
    bh = 34 * mm
    by = top - 14 * mm - bh - 8 * mm

    steps = [
        (
            "INPUT",
            "Meter photo from the agent's phone, at the well. "
            "Subscriber, well and unit price attached.",
            ACCENT2,
        ),
        (
            "CAPTURE",
            "Digits read and verified: 6 or 7 drums, "
            "operator confirms before saving.",
            ACCENT2,
        ),
        (
            "CORE LEDGER",
            "Cycle per subscriber: consumption, rollover "
            "(closing = next opening), loss per cycle.",
            ACCENT,
        ),
        (
            "OUTPUT",
            "Documented reading, m³, amount, loss per cycle. "
            "One unbroken chain per well.",
            ACCENT,
        ),
        (
            "OWNER VIEW",
            "Dashboard per well plus CSV / PDF export. "
            "Subscribers, balances, before / after loss.",
            ACCENT,
        ),
    ]

    xs = []
    x = mx
    for label, body, accent in steps:
        box(c, x, by, bw, bh, label, body, accent)
        xs.append(x)
        x += bw + gap

    for i in range(4):
        arrow(c, xs[i] + bw + 1 * mm, xs[i + 1] - 1 * mm, by + bh / 2)

    # شريط Build / Buy / Partner
    band_h = 15 * mm
    band_y = by - band_h - 7 * mm
    c.setFillColor(colors.HexColor("#EFEAD8"))
    c.roundRect(mx, band_y, PAGE_W - 2 * mx, band_h, 2.5 * mm, stroke=0, fill=1)

    cols = [
        (
            "BUILD",
            "Cycle and loss engine \u00b7 the app \u00b7 reports \u00b7 security rules",
        ),
        (
            "BUY",
            "Firebase (Auth, Firestore, hosting) \u00b7 vision model \u00b7 the phone",
        ),
        (
            "PARTNER",
            "Well owners for pilots \u00b7 water department or university for the audit",
        ),
    ]
    col_w = (PAGE_W - 2 * mx) / 3.0
    for i, (head, txt) in enumerate(cols):
        cx = mx + i * col_w + 4 * mm
        c.setFillColor(INK)
        c.setFont("Helvetica-Bold", 7.5)
        c.drawString(cx, band_y + 9.2 * mm, head)
        c.setFillColor(MUTED)
        c.setFont("Helvetica", 7.2)
        ty = band_y + 5.2 * mm
        for line in wrap(txt, "Helvetica", 7.2, col_w - 8 * mm, c):
            c.drawString(cx, ty, line)
            ty -= 3.2 * mm

    # ملاحظة الحدود
    c.setFillColor(ACCENT)
    c.setFont("Helvetica-Bold", 8.5)
    c.drawString(
        mx,
        band_y - 7.5 * mm,
        "System boundary: a phone at the well and a cloud backend — "
        "no smart meter, no SIM, no energy per cubic metre.",
    )

    c.setFillColor(MUTED)
    c.setFont("Helvetica", 8)
    c.drawString(
        mx,
        band_y - 12.5 * mm,
        "The defensible part is the middle of the diagram: the cycle ledger rule "
        "(closing reading = next opening) and the loss it produces.",
    )

    c.showPage()
    c.save()
    print("written:", PDF)


def to_png():
    try:
        import pymupdf
    except ImportError:  # pragma: no cover
        import fitz as pymupdf

    doc = pymupdf.open(PDF)
    page = doc[0]
    pix = page.get_pixmap(dpi=200)
    pix.save(PNG)
    print("written:", PNG, pix.width, "x", pix.height)


if __name__ == "__main__":
    os.makedirs("docs", exist_ok=True)
    build()
    to_png()
