#!/usr/bin/env python3
"""Build the Azal Soft Platform user manual PDF.

Two things this script guarantees:

1. Every screenshot shows the official platform address
   ``https://azalsoftplatform.web.app/`` in the browser address bar.
   The captured screenshots were taken on ``water-567bb.web.app``, so the
   address pill is repainted (idempotent: running it twice is safe).

2. The *Sign in* page is the **second** page of the document: page 1 is the
   cover (title, customer-facing summary, one screenshot) and page 2 starts
   the walkthrough with ``1. Sign in``.

Usage
-----
    pip install pillow reportlab
    python3 tool/build_user_manual.py                 # screenshots + PDF
    python3 tool/build_user_manual.py --pdf-only      # PDF only
    python3 tool/build_user_manual.py --images-only   # screenshots only

Inputs  : docs/user_manual/source_images/*.png  (raw captures, unchanged)
Outputs : docs/user_manual/images/*.png         (captures with the new address)
          docs/Azal_Soft_User_Manual_EN.pdf     (the deliverable)
"""

from __future__ import annotations

import argparse
import os
from typing import Iterable, Sequence

from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas

# ============================================================
# Paths / constants
# ============================================================

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SOURCE_DIR = os.path.join(ROOT, "docs", "user_manual", "source_images")
IMAGE_DIR = os.path.join(ROOT, "docs", "user_manual", "images")
PDF_PATH = os.path.join(ROOT, "docs", "Azal_Soft_User_Manual_EN.pdf")

ROBOTO = os.path.join(ROOT, "assets", "fonts", "Roboto-Regular.ttf")

PLATFORM_URL = "https://azalsoftplatform.web.app/"
PLATFORM_HOST = "azalsoftplatform.web.app"

# Colours sampled from the original screenshots (dark Chrome chrome).
BAR_BG = (14, 20, 25)
BAR_PILL = (47, 53, 59)
BAR_TEXT = (226, 226, 229)

# Address pill geometry, measured on the 1080x2400 captures.  The pill is
# widened (was 296..931) so the longer domain fits without shrinking the text.
PILL_BOX = (270, 141, 957, 236)  # left, top, right, bottom (inclusive)
PILL_RADIUS = 48
PILL_MAX_TEXT_WIDTH = 640

# ============================================================
# 1. Screenshots: repaint the browser address bar
# ============================================================


def _fit_font(draw: ImageDraw.ImageDraw, text: str, max_width: int):
    """Largest Roboto size whose ink width fits ``max_width``."""
    size = 60
    while size > 10:
        font = ImageFont.truetype(ROBOTO, size)
        left, _, right, _ = draw.textbbox((0, 0), text, font=font)
        if right - left <= max_width:
            return font
        size -= 1
    return ImageFont.truetype(ROBOTO, 10)


def stamp_platform_url(image: Image.Image) -> Image.Image:
    """Repaint the Chrome address pill so it shows ``PLATFORM_HOST``."""
    image = image.convert("RGB").copy()
    draw = ImageDraw.Draw(image)

    # Clear the old bar area.  The tab counter (ends at x=249) and the home
    # button (starts at x=981) stay untouched.
    draw.rectangle((256, 124, 978, 254), fill=BAR_BG)

    # Pill, drawn supersampled so the rounded caps stay smooth.
    left, top, right, bottom = PILL_BOX
    width, height = right - left + 1, bottom - top + 1
    scale = 4
    mask = Image.new("L", (width * scale, height * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width * scale - 1, height * scale - 1),
        radius=PILL_RADIUS * scale,
        fill=255,
    )
    mask = mask.resize((width, height), Image.LANCZOS)
    image.paste(Image.new("RGB", (width, height), BAR_PILL), (left, top), mask)

    # Domain, centred in the pill.
    font = _fit_font(draw, PLATFORM_HOST, min(PILL_MAX_TEXT_WIDTH, width - 48))
    ink = draw.textbbox((0, 0), PLATFORM_HOST, font=font)
    centre_x = (left + right) / 2
    centre_y = (top + bottom) / 2
    x = centre_x - (ink[2] - ink[0]) / 2 - ink[0]
    y = centre_y - (ink[3] - ink[1]) / 2 - ink[1]
    draw.text((x, y), PLATFORM_HOST, font=font, fill=BAR_TEXT)

    return image


def build_images() -> list[str]:
    os.makedirs(IMAGE_DIR, exist_ok=True)
    written: list[str] = []
    for name in sorted(os.listdir(SOURCE_DIR)):
        if not name.lower().endswith(".png"):
            continue
        with Image.open(os.path.join(SOURCE_DIR, name)) as raw:
            out = stamp_platform_url(raw)
        path = os.path.join(IMAGE_DIR, name)
        out.save(path, optimize=True)
        written.append(path)
        print(f"  screenshot ok: {os.path.relpath(path, ROOT)}")
    return written


# ============================================================
# 2. Manual content
# ============================================================

TITLE = "Azal Soft Water Management Platform"
SUBTITLE = (
    "A practical guide to managing subscribers, wells, meter readings, "
    "consumption, reports, and financial transactions."
)
EDITION = "English Edition \u00b7 Version 1.0"

SECTIONS: Sequence[dict] = (
    {
        "title": "1. Sign in",
        "image": "sign_in.png",
        "body": [
            "Open the platform in your browser, then enter your username/email "
            "and password and select Sign in. You may use the demo account "
            "option when available for evaluation.",
        ],
        "link": True,
        "bullets": [
            "Use the address above on desktop and mobile; the same account "
            "works on both.",
            "A username without @ is treated as <username>@mywater.com.",
            "The demo account opens a read-only tour of the platform.",
            "If the connection is still starting, wait for the notice to clear "
            "and press Sign in again.",
        ],
    },
    {
        "title": "2. Main dashboard",
        "image": "main_dashboard.png",
        "body": ["The dashboard provides access to the platform\u2019s main modules."],
        "bullets": [
            "Reading Cycle: record opening and closing meter readings.",
            "Setup: configure subscribers, wells, usage types, meter types, and "
            "financial accounts.",
            "Reports: view subscriber account reports and well/cycle "
            "consumption reports.",
            "Inquiry: search and review platform records.",
            "Payment Voucher and Receipt Voucher: record expenses and "
            "payments/collections.",
        ],
    },
    {
        "title": "3. Setup \u2013 Add a subscriber",
        "image": "setup_add_subscriber.png",
        "body": ["Create subscriber records before linking them to a well."],
        "bullets": [
            "Choose Setup, then Add subscriber.",
            "Enter the subscriber number, water usage type, name, phone, "
            "address, and other required details.",
            "Save the subscriber record.",
        ],
    },
    {
        "title": "4. Link a subscriber to a well",
        "image": "link_subscriber_to_well.png",
        "body": [
            "A subscriber must be linked to the relevant well to participate in "
            "its reading cycles.",
        ],
        "bullets": [
            "Open Add well subscriber.",
            "Select the village/well and choose the subscriber.",
            "Tap Add and link the subscriber to complete the association.",
        ],
    },
    {
        "title": "5. Reading Cycle",
        "image": "reading_cycle.png",
        "body": [
            "A reading cycle records the meter at the beginning and end of a "
            "service period.",
        ],
        "bullets": [
            "Open Reading Cycle and select Opening reading to record the "
            "initial meter value.",
            "At the end of the period, select Closing reading for the same "
            "subscriber.",
            "Use the camera/photo reading feature where available; AI can help "
            "extract the meter value from the image.",
            "Review the recognized value carefully and confirm it before saving.",
        ],
    },
    {
        "title": "6. Current readings and consumption",
        "image": "current_readings.png",
        "body": [
            "The current readings screen shows the selected well and its "
            "subscriber reading status.",
        ],
        "bullets": [
            "Select the well and review its open cycles.",
            "Enter or confirm the closing reading after the service period "
            "(for example after one hour or more, according to the local "
            "operating process).",
            "The platform calculates consumption from the difference between "
            "closing and opening readings.",
        ],
    },
    {
        "title": "7. Reports",
        "image": "reports.png",
        "body": ["Use Reports to monitor subscriber accounts and well consumption."],
        "bullets": [
            "Account report: review subscriber balances and financial "
            "transactions.",
            "Cycle report: review meter readings and consumption by "
            "cycle/well.",
            "Energy consumption report: review solar/diesel usage and operating "
            "hours, where configured.",
            "Accounting tree: review assets, liabilities, revenue, and "
            "expenses.",
        ],
    },
    {
        "title": "8. Receipt Voucher \u2013 Collection",
        "image": "receipt_voucher.png",
        "body": [
            "Use a receipt voucher when money is received, such as a subscriber "
            "payment.",
        ],
        "bullets": [
            "Select the village and well.",
            "Choose the subscriber and, if applicable, the related cycle.",
            "Enter the amount and complete the voucher details.",
            "Save the voucher. The transaction updates the relevant account "
            "balance.",
        ],
    },
    {
        "title": "9. Payment Voucher \u2013 Expense",
        "image": "payment_voucher.png",
        "body": ["Use a payment voucher to record money paid from the well fund."],
        "bullets": [
            "Select the village and well fund.",
            "Choose the debit account/operator or expense category.",
            "Enter the amount and description.",
            "Save the voucher to record the expense and update the accounting "
            "balance.",
        ],
    },
    {
        "title": "10. Recommended operating workflow",
        "image": None,
        "body": ["Follow this order when a village joins the platform."],
        "bullets": [
            "Configure the village, wells, usage types, meter types, and "
            "financial accounts.",
            "Register each subscriber and link them to the correct well.",
            "Record opening meter readings at the start of a cycle.",
            "Record closing readings at the end of the cycle; verify any "
            "AI-extracted values.",
            "Review calculated consumption and close the cycle according to "
            "your operating procedure.",
            "Record collections with Receipt Vouchers and expenses with Payment "
            "Vouchers.",
            "Use Account and Cycle Reports to check balances, transactions, and "
            "consumption.",
        ],
        "note": (
            "Important: AI meter recognition is an assistance feature. Always "
            "verify the displayed meter digits before saving. Screen labels and "
            "available features may vary by account permissions and platform "
            "updates."
        ),
    },
)

# ============================================================
# 3. Layout
# ============================================================

PAGE_W, PAGE_H = A4
MARGIN = 48.0
CONTENT_W = PAGE_W - 2 * MARGIN

BLUE = (22 / 255, 139 / 255, 229 / 255)
SLATE = (83 / 255, 98 / 255, 115 / 255)
HAIRLINE = (216 / 255, 228 / 255, 239 / 255)

BODY_SIZE = 10.5
BODY_LEADING = 16.0
BULLET_INDENT = 12.0
BULLET_LEADING = 16.0
BULLET_GAP = 6.0

FOOTER_BASELINE = 20.0
FOOTER_RULE_Y = 32.0


def wrap(text: str, font: str, size: float, width: float) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if stringWidth(candidate, font, size) <= width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]


def draw_footer(c: canvas.Canvas, page_no: int) -> None:
    c.setStrokeColorRGB(*HAIRLINE)
    c.setLineWidth(0.8)
    c.line(42, FOOTER_RULE_Y, PAGE_W - 42, FOOTER_RULE_Y)

    c.setFillColorRGB(*SLATE)
    c.setFont("Helvetica", 8)
    c.drawString(42, FOOTER_BASELINE, f"{TITLE} \u00b7 User Manual")
    c.drawRightString(PAGE_W - 42, FOOTER_BASELINE, f"Page {page_no}")


def draw_heading(c: canvas.Canvas, y: float, text: str, size: float = 19) -> float:
    c.setFillColorRGB(*BLUE)
    c.setFont("Helvetica-Bold", size)
    c.drawString(MARGIN, y, text)
    return y


def draw_paragraph(
    c: canvas.Canvas,
    y: float,
    text: str,
    *,
    size: float = BODY_SIZE,
    font: str = "Helvetica",
    colour: Sequence[float] = (0, 0, 0),
    leading: float = BODY_LEADING,
    width: float = CONTENT_W,
    indent: float = 0.0,
    centred: bool = False,
) -> float:
    """Draw a wrapped paragraph, return the baseline of the last line."""
    c.setFillColorRGB(*colour)
    c.setFont(font, size)
    for line in wrap(text, font, size, width):
        if centred:
            c.drawCentredString(MARGIN + CONTENT_W / 2, y, line)
        else:
            c.drawString(MARGIN + indent, y, line)
        y -= leading
    return y + leading


def draw_bullets(c: canvas.Canvas, y: float, bullets: Iterable[str]) -> float:
    for bullet in bullets:
        lines = wrap(bullet, "Helvetica", BODY_SIZE, CONTENT_W - BULLET_INDENT - 10)
        for index, line in enumerate(lines):
            c.setFillColorRGB(0, 0, 0)
            c.setFont("Helvetica", BODY_SIZE)
            if index == 0:
                c.drawString(MARGIN + BULLET_INDENT, y, "\u2022")
            c.drawString(MARGIN + BULLET_INDENT + 10, y, line)
            y -= BULLET_LEADING
        y -= BULLET_GAP
    return y + BULLET_GAP


def bullets_height(bullets: Iterable[str]) -> float:
    total = 0.0
    for bullet in bullets:
        lines = wrap(bullet, "Helvetica", BODY_SIZE, CONTENT_W - BULLET_INDENT - 10)
        total += len(lines) * BULLET_LEADING + BULLET_GAP
    return total


def image_size(name: str, width: float) -> tuple[float, float]:
    with Image.open(os.path.join(IMAGE_DIR, name)) as im:
        w, h = im.size
    return width, width * h / w


def draw_cover(c: canvas.Canvas) -> None:
    centre = MARGIN + CONTENT_W / 2

    c.setFillColorRGB(*BLUE)
    c.setFont("Helvetica-Bold", 31)
    c.drawCentredString(centre, 800, "AZAL SOFT")

    c.setFont("Helvetica-Bold", 21)
    c.drawCentredString(centre, 767, "Water Management Platform")

    c.setFillColorRGB(*SLATE)
    c.setFont("Helvetica", 13)
    c.drawCentredString(centre, 741, "U S E R   M A N U A L")

    c.setStrokeColorRGB(*BLUE)
    c.setLineWidth(2)
    c.line(centre - 45, 726, centre + 45, 726)

    y = draw_paragraph(
        c,
        704,
        SUBTITLE,
        size=11,
        colour=SLATE,
        leading=15,
        width=CONTENT_W - 60,
        centred=True,
    )

    # Official platform address — clickable.
    link_y = y - 22
    c.setFillColorRGB(*BLUE)
    c.setFont("Helvetica-Bold", 13)
    c.drawCentredString(centre, link_y, PLATFORM_URL)
    url_w = stringWidth(PLATFORM_URL, "Helvetica-Bold", 13)
    c.setStrokeColorRGB(*BLUE)
    c.setLineWidth(0.7)
    c.line(centre - url_w / 2, link_y - 2.5, centre + url_w / 2, link_y - 2.5)
    c.linkURL(
        PLATFORM_URL,
        (centre - url_w / 2, link_y - 4, centre + url_w / 2, link_y + 12),
        relative=0,
        thickness=0,
    )

    width, height = image_size("main_dashboard.png", 232)
    img_top = link_y - 26
    c.drawImage(
        ImageReader(os.path.join(IMAGE_DIR, "main_dashboard.png")),
        centre - width / 2,
        img_top - height,
        width,
        height,
        preserveAspectRatio=True,
        mask=None,
    )

    c.setFillColorRGB(*SLATE)
    c.setFont("Helvetica", 10)
    c.drawCentredString(centre, img_top - height - 24, EDITION)

    draw_footer(c, 1)
    c.showPage()


def draw_access_panel(c: canvas.Canvas, ceil: float, bottom: float = 62.0) -> None:
    """Blue-tinted closing block with the official platform address."""
    text = (
        "Open the platform at the address below and sign in with your "
        "supervisor or manager account. For new accounts, roles, and "
        "permissions, contact your platform administrator."
    )
    wrapped = wrap(text, "Helvetica", 9.5, CONTENT_W - 40)
    height = 78 + 13 * (len(wrapped) - 1)
    bottom = max(min(bottom, ceil - height - 20), 50.0)
    top = bottom + height

    c.setFillColorRGB(240 / 255, 247 / 255, 255 / 255)
    c.setStrokeColorRGB(198 / 255, 222 / 255, 248 / 255)
    c.setLineWidth(1)
    c.roundRect(MARGIN, bottom, CONTENT_W, height, 8, stroke=1, fill=1)

    c.setFillColorRGB(*BLUE)
    c.setFont("Helvetica-Bold", 11)
    c.drawString(MARGIN + 16, top - 20, "Platform access")

    c.setFont("Helvetica-Bold", 11.5)
    c.drawString(MARGIN + 16, top - 42, PLATFORM_URL)
    url_w = stringWidth(PLATFORM_URL, "Helvetica-Bold", 11.5)
    c.setStrokeColorRGB(*BLUE)
    c.setLineWidth(0.7)
    c.line(MARGIN + 16, top - 44.5, MARGIN + 16 + url_w, top - 44.5)
    c.linkURL(
        PLATFORM_URL,
        (MARGIN + 16, top - 46, MARGIN + 16 + url_w, top - 31),
        relative=0,
        thickness=0,
    )

    c.setFillColorRGB(0.25, 0.30, 0.36)
    c.setFont("Helvetica", 9.5)
    ty = top - 64
    for line in wrapped:
        c.drawString(MARGIN + 16, ty, line)
        ty -= 13


def draw_section(c: canvas.Canvas, section: dict, page_no: int) -> None:
    y = draw_heading(c, 764, section["title"])

    last = y - 26
    for paragraph in section["body"]:
        last = draw_paragraph(c, last, paragraph)
        last -= 4

    if section.get("link"):
        link_y = last - 14
        c.setFillColorRGB(*BLUE)
        c.setFont("Helvetica-Bold", 11.5)
        c.drawString(MARGIN, link_y, PLATFORM_URL)
        url_w = stringWidth(PLATFORM_URL, "Helvetica-Bold", 11.5)
        c.setStrokeColorRGB(*BLUE)
        c.setLineWidth(0.7)
        c.line(MARGIN, link_y - 2.5, MARGIN + url_w, link_y - 2.5)
        c.linkURL(
            PLATFORM_URL,
            (MARGIN, link_y - 4, MARGIN + url_w, link_y + 11),
            relative=0,
            thickness=0,
        )
        last = link_y

    bullets = section["bullets"]
    block = bullets_height(bullets)

    if section.get("image"):
        width, height = image_size(section["image"], 205)
        image_top = last - 18
        max_height = image_top - (110 + block + 30)
        height = min(height, max(140.0, max_height))
        width = height * 0.45
        image_bottom = image_top - height
        bullets_top = image_bottom - 30
        c.drawImage(
            ImageReader(os.path.join(IMAGE_DIR, section["image"])),
            MARGIN + (CONTENT_W - width) / 2,
            image_bottom,
            width,
            height,
            preserveAspectRatio=True,
            mask=None,
        )
    else:
        bullets_top = last - 18

    end = draw_bullets(c, bullets_top, bullets)

    if section.get("note"):
        end -= 10
        text = section["note"]
        lines = wrap(text, "Helvetica-Oblique", 9.5, CONTENT_W - 24)
        box_h = len(lines) * 13 + 14
        c.setFillColorRGB(246 / 255, 249 / 255, 252 / 255)
        c.setStrokeColorRGB(*HAIRLINE)
        c.setLineWidth(0.8)
        c.roundRect(MARGIN, end - box_h + 8, CONTENT_W, box_h, 6, stroke=1, fill=1)
        ty = end - 4
        c.setFillColorRGB(0.25, 0.30, 0.36)
        c.setFont("Helvetica-Oblique", 9.5)
        for line in lines:
            c.drawString(MARGIN + 12, ty, line)
            ty -= 13
        end = end - box_h - 4

        draw_access_panel(c, end - 30)

    draw_footer(c, page_no)
    c.showPage()


def build_pdf() -> str:
    missing = [
        s["image"]
        for s in SECTIONS
        if s.get("image") and not os.path.exists(os.path.join(IMAGE_DIR, s["image"]))
    ]
    if missing:
        raise SystemExit(
            "Missing screenshots: "
            + ", ".join(missing)
            + " — run: python3 tool/build_user_manual.py --images-only"
        )

    os.makedirs(os.path.dirname(PDF_PATH), exist_ok=True)
    os.makedirs(IMAGE_DIR, exist_ok=True)

    c = canvas.Canvas(PDF_PATH, pagesize=A4)
    c.setTitle("Azal Soft Water Management Platform \u2014 User Manual")
    c.setAuthor("Azal Soft")
    c.setSubject(f"User manual \u2014 {PLATFORM_URL}")
    c.setCreator("tool/build_user_manual.py")

    draw_cover(c)
    for index, section in enumerate(SECTIONS, start=2):
        draw_section(c, section, index)

    c.save()
    print(f"  pdf ok: {os.path.relpath(PDF_PATH, ROOT)} ({len(SECTIONS) + 1} pages)")
    return PDF_PATH


# ============================================================
# 4. Entry point
# ============================================================


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--images-only", action="store_true")
    parser.add_argument("--pdf-only", action="store_true")
    args = parser.parse_args()

    # The generated screenshots live next to the sources; always make sure the
    # folder exists so --pdf-only works on a fresh clone after a PDF build.
    if not args.pdf_only:
        build_images()
    if not args.images_only:
        build_pdf()


if __name__ == "__main__":
    main()
