# User manual (EN)

- **Deliverable:** [`docs/Azal_Soft_User_Manual_EN.pdf`](../Azal_Soft_User_Manual_EN.pdf) — 11 pages
- **Page order:** page 1 = cover, **page 2 = 1. Sign in**, then the platform
  walkthrough (dashboard → setup → reading cycle → reports → vouchers → workflow).
- **Official address everywhere:** `https://azalsoftplatform.web.app/`
  (clickable on the cover, on the *Sign in* page, and in the closing
  *Platform access* panel).

## Screenshots

`source_images/` holds the captures exactly as taken (recorded on the legacy
host `water-567bb.web.app`). `images/` holds the same captures after the build
step has:

- **cropped the Android status bar** (clock, battery, network, notifications) —
  it is phone chrome, not part of the platform; the browser address bar stays
  because it carries the platform address. Captures go from 1080x2400 to
  1080x2300.
- **repainted the browser address pill** with `azalsoftplatform.web.app`.

The PDF is built from `images/`, and the aspect ratio is read from the files
(1080x2300), never hard-coded.

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
