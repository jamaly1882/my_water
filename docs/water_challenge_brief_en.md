# Water Challenge Brief — English Version

**Venture:** my_water — Well Water Operations Platform
**Programme:** AYC Youth Pitches · Onboarding Session · Week 1 (2–6 November 2026)
**Submission:** Friday 6 November, 12:00 GST
**Weight:** 30% of the Round 1 score

> This brief applies the four-layer framework from the onboarding session to **my_water**.
> Its content is drawn from the actual codebase (screens, services, the OCR pipeline, the GM dashboard).
> Every bracketed tag must stay in the submitted version:
>
> - **[in code]** — provable by opening the app or a file in the repository.
> - **[target to validate]** — a target that has not yet been measured in the field.
> - **[assumption — needs your data]** — a cell only you can fill from well and subscriber records.

---

## Layer 1 · Our place on the map

**Layer question:** Where do we sit in the water system, what change do we drive, and who are the three actors around us?

### 1.1 Stage and domain

**Stage:** a working product in a limited pilot phase — not a paper idea.

**Domain:** digital — operations of well water networks: meters, readings, cycles, invoices, accounts, reporting.

**What already exists [in code]:**

| Capability | What it means in practice |
|---|---|
| Full geographic hierarchy | province → district → hamlet → village → well → subscriber |
| Reading cycle | open cycle, capture readings, review previous reading, close cycle and issue invoices |
| Photo-based meter reading | capture the meter, score image quality, crop the seven digits, recognise, confidence-gate |
| Accounts | four accounts per well: sales, cash, expenses, worker — with receipt and payment vouchers |
| Reporting | cycle reports (daily/monthly/yearly), account reports, energy consumption (diesel / solar) |
| General-manager dashboard | place and subscriber counts, monthly consumption, well and village rankings, alerts, insights |
| Arabic query agent | natural-language questions: top-consuming well, rising villages, what needs review |

In short: **we are not building a screen; we are building a complete operating record for one well that can be repeated across hundreds.**

### 1.2 The change we drive

**From:** managing a well on paper — manual readings copied later into a ledger, with the cash box kept apart from the numbers.
**To:** one live digital record linking **reading → consumption → invoice → collection → cash box**, auditable top-down by the general manager and explainable to the subscriber.

The real change is not "an app instead of paper". It is **making non-revenue water visible**: once meters are read and compared with billed volume and energy consumed, the loss that was invisible becomes a number someone can act on.

### 1.3 The problem in its system

The problem is not "there is no app". It is that an entire system runs on untrustworthy numbers:

1. **Measurement.** Readings are handwritten then transcribed. There is no trace that a figure is right, and nothing prevents entering a value lower than the previous one. Losers: the subscriber (an unfair bill) and the committee (complaints that cannot be settled with evidence).
2. **Money.** Sales, cash, expenses and the worker's share are separate boxes, so nobody knows whether the well's revenue covers its operation. Loser: the committee that discovers the deficit after month-end.
3. **Energy.** A diesel or solar pump spends before it sells. Without linking energy to cubic metres sold, **the cost per m³ stays unknown** — the one number that decides whether a well survives.
4. **Governance.** The general manager receives late paper summaries; maintenance is allocated on impression rather than data. Losers: the local authority and the funder, because unmeasured loss means water nobody is accountable for.

The error persists because **those who bear the cost of the error are not those who hold the power to fix it**: the subscriber pays, the operator reads, the committee decides, and none of them sees the whole picture.

### 1.4 The three actors around it

| Actor | Who | What they want | What they fear |
|---|---|---|---|
| **Well operator** | well committee or owner | cost recovery, fewer disputes | the cash deficit being exposed |
| **Subscriber** | the served household | a bill that is clear and fair, water that keeps flowing | paying more for less water |
| **Field supervisor / meter reader** | the operator on the ground | finishing the round with fewer errors and less effort | being blamed for errors that are not theirs |

**The invisible fourth actor:** the local authority / water institution and the funder. They are not in daily operations, but they hold the funding condition and the path to scale — they are who turns one well into a governorate programme.

---

## Layer 2 · Our technology claim

**Layer question:** What is the measurable claim, the number behind it, the evidence we hold, and the test that would strengthen it?

### 2.1 The claim in one sentence

> **Reading a water meter from a single phone photo, with a confidence gate that stops a doubtful reading from ever reaching the invoice, and connecting that reading directly to consumption and accounts.**

The claim is not "optical digit recognition" — that is a commodity. The claim is the **trust gate**: the system decides when to trust a reading, when to retake the photo, when to ask for human review, and when to refuse to post it.

### 2.2 The number

| Metric | Paper baseline | my_water target | Status |
|---|---|---|---|
| Time per meter reading (read + record) | ~3 minutes [assumption — needs your data] | under 20 seconds for an accepted reading | [target to validate] |
| Share of readings accepted automatically | — | ≥ 85% | [target to validate] |
| Reading error after review | unknown (no trace) | ≤ 1% | [target to validate] |
| Share of photos rejected on quality | — | measured and shown before recognition | [in code: quality gate] |
| Cost per reading | — | operator wage ÷ readings completed | [assumption — needs your data] |

The number to remember: **an automatic reading is accepted only if it clears the confidence threshold and agrees across repeated attempts; anything below that goes to a human — so no invoice is ever built on a doubtful digit.**

### 2.3 How it works

Seven steps, all present in the code:

1. **Capture** — camera or file, with manual cropping to the meter frame.
2. **Quality check before recognition** — sharpness, brightness, contrast, glare, dynamic range; a pass score and user tips (we never send a bad photo to the engine).
3. **Digit segmentation** — seven digits, read digit by digit rather than as one string.
4. **Recognition** — ML Kit on Android/iOS, Tesseract.js on web (same product on both surfaces).
5. **Normalisation** — Arabic and Persian numerals (٠١٢… ۰۱۲…) and visually similar letters (O→0, I→1, S→5, G→6…) before analysis.
6. **Confidence analysis** — repeated attempts, per-digit confidence, alternatives, a message the operator understands.
7. **Posting** — previous reading pulled from the system, consumption computed, readings lower than the previous one rejected, then the invoice and the accounts.

### 2.4 The evidence we hold

- **A working Flutter app** on Android and web, connected to a cloud database, with roles (general manager, supervisor, well). [in code]
- **A full OCR pipeline** with an image-quality gate, confidence analysis and digit normalisation — not a bare engine call. [in code]
- **A closed operating loop**: cycle → reading → consumption → invoice → receipt voucher → cash box. [in code]
- **Signable reports**: cycle reports daily/monthly/yearly, account reports, energy consumption (diesel/solar). [in code]
- **A general-manager dashboard** that turns data into decisions: top-consuming wells, rising villages, what needs review. [in code]

**What we do not have yet — and we say it plainly:** no published field result for reading accuracy or reading time, and no measured cost per m³ for a single well. That is the week-one gap, and the next test is what closes it.

### 2.5 The test that would strengthen it

**Design:**
- **Sample:** 3 wells, 500 meters, 2 field supervisors, two weeks.
- **Ground truth:** double manual reading (supervisor + manager) of the same meter, recorded before recognition.
- **Measured:** reading time, share accepted automatically, error after review, retake rate, rejection due to quality.
- **Success:** ≥ 85% auto-acceptance, ≤ 1% error, ≤ 30 seconds per reading, reproducible on a second well.
- **Output:** one "before/after" page over 500 meters, attached to the Venture Blueprint on 13 November.

**A sub-test that matters:** meters in direct sun, dust-covered, or with a warped display — the real case, not the office case.

---

## Layer 3 · The institutions around us

**Layer question:** Who decides, what have they committed to, how do they buy, and where is our pilot entry point?

### 3.1 Who decides

| Decision level | Body | What they actually decide |
|---|---|---|
| Operations | well committee / owner | adopting the system in the well, appointing the operator, accepting the invoice |
| Local regulation and funding | local council / local authority | including the well in a plan, approving public funding |
| Sector | urban water and sanitation utility | reading and billing standards if we approach the urban network |
| Funding and scale | donor / international organisation | financing the pilot, requiring measurement and transparency |

[assumption — needs your data: name the well committee and local council in your area. A real name opens doors faster than a general category.]

### 3.2 What they committed to

- **SDG 6**, especially 6.4 (water-use efficiency) and 6.1 (safe drinking water) — a commitment that speaks the language of measurement.
- **National water commitments**: water strategy, emergency plans, loss-reduction programmes.
- **Donor conditions**: periodic reporting, measurable impact, financial transparency — precisely what the system produces automatically.
- **UN Water Conference (8–10 December 2026)**: voluntary commitments are registered there, and the AYC programme builds that bridge.

The practical move: **do not ask for permission — ask "which number in your monthly report do you need and do not have?"** The written commitment is your entry into the conversation.

### 3.3 How they buy

- **A paid pilot inside an existing project** — the fastest route, because the budget exists and the justification is "better collection", not "buying technology".
- **An annual service contract** with the well committee, paid from a share of improved collection once savings are proven.
- **Small tender / direct purchase** — capped by a financial threshold; we must know the cap before pricing. [assumption — needs your data]
- **Donor funding** — pays for "measurement and reporting", not for software; which means our deliverable must be a report, not an interface.

Rule: **the person who signs is not always the person who releases the cheque.** In a well, the committee decides, subscribers pay through the bill, and the donor finances the pilot.

### 3.4 Our pilot entry point

**Proposal:** one well in one district, 4–6 weeks, three before/after indicators only:

1. Share of subscribers with a digitally traceable reading.
2. Difference in reported loss between the paper record and the digital record for the same cycle.
3. Collection time and collection rate at cycle close.

**One output:** a two-page audit report the committee chair can sign — not a slide deck.

**In exchange:** a nominal fee covering operator training [assumption — needs your data: set the figure] — a free pilot buys no commitment.

---

## Layer 4 · Our market, our payer

**Layer question:** Who benefits, who decides, who pays, and how do we size the market bottom-up?

### 4.1 The beneficiary

- **The subscriber household**: a bill built on a traceable reading, and more continuous water because faults surface from the data.
- **The meter reader**: a faster round, and less blame for errors that are not theirs.
- **The well committee**: sees the deficit before month-end instead of after.

### 4.2 The decider

The **well committee** for operations; the **local council / funder** for funding. Nothing moves without the committee's signature, and nothing scales without a line in the local authority's plan.

### 4.3 The payer

| Path | Who pays | Why | When |
|---|---|---|---|
| Operating subscription | well committee, from collection fees | saves reading hours and surfaces loss | after the pilot |
| Paid pilot | donor / organisation through a water project | measurement and transparency reporting | now |
| Performance contract | local authority / donor | a share of verified savings | after savings are proven |

**The hard sentence to say to the committee:** the system does not raise revenue, it makes revenue visible — so its price must be tied to a tangible saving (labour hours, loss, maintenance), not to "better administration".

### 4.4 The market, bottom-up

**Formula:** number of wells × annual price per well = annual market.

**Worked example with declared assumptions [assumption — needs your data: replace with your records]:**

- Wells in the starting territory (one district/governorate): **300**
- Average subscribers per well: **250**
- Total connections: **75,000**
- Annual price per well: **USD 250** (≈ USD 0.33 per connection per year)
- **Annual market in one governorate = 300 × 250 = USD 75,000**

**Price test:** is USD 250 less than the value the well captures? Value = (reading hours saved × hourly wage) + (loss surfaced × price per m³). This exposes the real unit-economics question: **what is the cost of a cubic metre at the well?** Energy (diesel/solar) + operator + maintenance ÷ cubic metres sold. The app produces every term of that equation; the missing input is your numbers.

### 4.5 The first customer

**Template to fill with real names [assumption — needs your data]:**

> Well "______" in "______" district, committee chaired by "______", serving about ____ subscribers on a monthly cycle.
> Stated need: "______" (reading dispute / late collection / cash deficit).
> Offer: a six-week pilot at ____, including operator training and a final audit report.
> Expected decision date: ____ / ____ / 2026.

Never write "institutions" or "farmers" here. **One name, one place, one number, one date.**

### 4.6 The venture in 100 words

> Across many water wells, meters are read on paper, figures are copied later, and the cash box is managed apart from the numbers. The result: loss nobody sees, a bill the subscriber cannot contest with evidence, and a committee that discovers the deficit at month-end.
> my_water turns that chain into one digital record: a meter photo read automatically behind a confidence gate that refuses the doubtful digit, then consumption, then the invoice, then collection, then the cash box. Impact is measured in reading time, share of traceable readings, and the gap between paper and real loss.
> What we ask for today: one well and six weeks to prove the number.

---

## Annex A · How the code serves this brief

| Layer | Where to find it in the app |
|---|---|
| 1 · Place on the map | setup hierarchy (province → district → hamlet → village → well), GM dashboard, energy consumption report |
| 2 · Technology claim | photo meter-reading screen, image-quality analysis, confidence analysis, digit normalisation |
| 3 · Institutions | roles and permissions (GM / supervisor / well), receipt and payment vouchers, signable reports |
| 4 · Market and payer | four accounts per well, cycles and invoices, daily/monthly/yearly account reports |

**New screen:** "Water Challenge Brief" inside the app (`assignment` icon) lets you fill the four layers, store them in Firestore, and export the whole brief as text ready to paste into Miro or print to PDF.

**Suggested Firestore rule** (new collection):

```
match /water_challenge_briefs/{uid} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow write: if request.auth != null && request.auth.uid == uid;
}
```

---

## Annex B · Week-one plan (5 days, 4 layers)

| Day | Layer | Output before 19:00 | Done |
|---|---|---|---|
| Mon 2 Nov | 1 · Place on the map | stage, domain, change, problem, three actors | ☐ |
| Tue 3 Nov | 2 · Technology claim | claim, number, how it works, evidence, test | ☐ |
| Wed 4 Nov | 3 · Institutions | who decides, commitments, how they buy, entry point | ☐ |
| Thu 5 Nov | 4 · Market and payer | beneficiary, decider, payer, bottom-up market, first customer, 100 words | ☐ |
| Fri 6 Nov 12:00 | Export | one file, exported and read by the facilitation team | ☐ |

**Thirty minutes before submission, check four things:**
1. Every number in Layer 2 carries a **[in code]** or **[target to validate]** tag — no untagged number.
2. Layer 3 names one body with a real signature line, not "the stakeholders".
3. Layer 4 ends with one customer name and one date.
4. The 100 words read aloud in 40 seconds with no marketing adjective.

---

## Annex C · What to add to the app before submission day

1. **Measure reading time inside the app** (camera open → reading saved) — it produces the Layer 2 number for free.
2. **Export the brief to PDF** directly from the screen (today: text you copy).
3. **A "price per m³" field** in well settings, to compute unit economics.
4. **An audit trail for readings** (who read, which photo, what confidence, who edited) — the thing that makes the report signable.
