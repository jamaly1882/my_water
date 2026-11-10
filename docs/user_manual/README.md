# User manual (EN)

- **Deliverable:** [`docs/Azal_Soft_User_Manual_EN.pdf`](../Azal_Soft_User_Manual_EN.pdf) — 11 pages
- **Page order:** page 1 = cover, **page 2 = 1. Sign in**, then the platform
  walkthrough (dashboard → setup → reading cycle → reports → vouchers → workflow).
- **Official address everywhere:** `https://azalsoftplatform.web.app/`
  (clickable on the cover, on the *Sign in* page, and in the closing
  *Platform access* panel).

## Screenshots

`source_images/` holds the captures exactly as taken (they were recorded on the
legacy host `water-567bb.web.app`). `images/` holds the same captures after the
browser address pill is repainted with `azalsoftplatform.web.app`; the PDF is
built from `images/`.

## Rebuilding

```bash
pip install pillow reportlab
python3 tool/build_user_manual.py               # screenshots + PDF
python3 tool/build_user_manual.py --images-only # only re-stamp screenshots
python3 tool/build_user_manual.py --pdf-only    # only re-lay the PDF
```

The address-bar stamping is idempotent: it fully repaints the pill, so it can be
re-run on already-stamped files. The manual text lives at the top of
`tool/build_user_manual.py` (`SECTIONS`), so edits are made in one place.

## Why the screenshots had to be re-stamped

The app was captured on `water-567bb.web.app`, while the platform's public
address is `https://azalsoftplatform.web.app/` (second Hosting site already
declared in `firebase.json`). To capture the screenshots from the real address
instead, deploy to that site and re-capture:

```bash
FIREBASE_SITE=azalsoftplatform bash tool/deploy_web.sh
```
