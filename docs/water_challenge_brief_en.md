# Azal Soft Platform — Integrated Venture Brief and Project Proposal (English)

**Venture:** Azal Soft Platform — Well Water Operations (repository/package identifier: `my_water`)
**Programme:** AYC Youth Pitches · Onboarding Session · Week 1 (2–6 November 2026)
**Submission:** Friday 6 November, 12:00 GST
**Weight:** 30% of the Round 1 score

> This brief applies the four-layer framework from the onboarding session to **Azal Soft Platform**.
> Its content is drawn from the actual codebase (screens, services, the OCR pipeline, the GM dashboard).
> Every bracketed tag must stay in the submitted version:
>
> - **[in code]** — provable by opening the app or a file in the repository.
> - **[target to validate]** — a target that has not yet been measured in the field.
> - **[assumption — needs your data]** — a cell only you can fill from well and subscriber records.

> **Defined scope:** **10 wells** and **60 subscribers** (6 per well on average).
> Every calculation in this brief uses that scope, not generic figures. If you meant 60 subscribers
> **per well**, multiply the revenue and market lines by ten — everything else still holds.

---

## Layer 1 · Our place on the map

**Layer question:** Where do we sit in the water system, what change do we drive, and who are the three actors around us?

### 1.1 Stage and domain

**Stage:** a working product in a limited pilot phase — not a paper idea.

**Domain:** digital — operations of well water networks: meters, readings, cycles, invoices, accounts, reporting.

**Deployment scope:** 10 wells and 60 subscribers. We are not sampling inside one well; we run the system on **100% of the meters in scope**: all ten wells are created in the hierarchy (province → district → hamlet → village → well), all sixty subscribers are registered with their meters, and one cycle is opened for all of them. Small in wells, complete in readings — which is exactly what makes the resulting number defensible in front of a committee.

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

| Metric | Paper baseline | Azal Soft Platform target | Status |
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

**Design — on your scope: 10 wells and 60 subscribers:**
- **Sample:** all sixty meters across the ten wells, over four reading cycles (monthly) = **240 readings available for measurement**. No meter excluded, no "clean" wells only.
- **Ground truth:** two independent manual readings of the same meter (supervisor, then manager on the same day), recorded **before** recognition; the gap between them is reported as the human baseline — we cannot blame the machine before we know the paper error.
- **Measured:** time per reading, share accepted automatically, error after review, retake rate, quality-rejection rate, and coverage (how many of the sixty were actually read in their cycle).
- **Success:** ≥ 85% auto-acceptance, ≤ 1% error after review, ≤ 30 seconds per reading, ≥ 95% coverage each cycle.
- **Limits of inference, stated to the jury:** 60 meters × 4 cycles detects a clear shift in acceptance (about 3 points), not a 0.1% accuracy claim. Our claim is "no automatic reading reaches the invoice without confidence", not "absolute accuracy".
- **Output:** a one-page before/after over 60 meters and 240 readings, attached to the Blueprint on 13 November.

**Why this test is cheap for you:** the ten wells and sixty subscribers already exist, and one cycle makes the system run end to end. No hiring, no hardware — four cycles and one committed operator.

**A sub-test that matters:** meters in direct sun, dust-covered, or with a warped display — the real case, not the office case.

---

## Layer 3 · The institutions around us

**Layer question:** Who decides, what have they committed to, how do they buy, and where is our pilot entry point?

### 3.1 Who decides

| Institution (as mapped in Wednesday's session) | Who it is in your territory | What it holds and decides | Says yes to a first pilot? |
|---|---|---|---|
| **Ministry / national agency** | Ministry of Water and Environment | policy, sector plans, budgets | yes, as direction — but it neither runs a well nor reads a meter |
| **Regulator / standard-setter** | specifications and quality authority | service standards, permits | conditional: it will not object, and may require approval of the reading method |
| **Utility / operator** | the local water utility | network, data, field staff | yes if the well sits in its area — the biggest and slowest route |
| **Municipality / site owner** | **the local council of Al-Radmah district** (Ibb governorate) | the site, assets, physical access | **yes — and this is the priority:** without field access there is no pilot |
| **Industrial operator** | well, farm or plant owner | their water, their effluent, their money | yes — the fastest, because they decide and pay themselves |
| **Development partner / funder** | donor or international organisation | finance and de-risking | yes — pays for measurement and reporting |

**Of the six, only two answers matter:** the "yes" comes from the **site owner / local council** (access) and the **industrial operator** (decision and payment). The "no" can come from the **regulator** (permit) or the **utility** (refusing access to its data). So the first pilot is built on the first two, and the other two are left for the scale stage.

**The question the facilitator asks tomorrow:** which of the six can say *no* to your pilot? If you cannot name one, you have not yet identified your institutions.

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

**Proposal — staged, not in one drop:** the ten wells do not go live on the same day.

- **Week one:** the first well (about 6 subscribers) through one complete cycle, from open to close, plus operator training.
- **Weeks two to six:** the remaining nine wells, one well every two days, same operator and same pattern — so all sixty are inside the system before the end of week three.

**Three before/after indicators only:**

1. Share of subscribers with a digitally traceable reading (out of sixty).
2. Difference in reported loss between the paper record and the digital record for the same cycle.
3. Collection time and collection rate at cycle close.

**One output:** a two-page audit report the committee chair can sign — one page per well, one summary page for the ten.

**In exchange:** a nominal fee covering operator training [assumption — needs your data: set the figure] — a free pilot buys no commitment, and these ten wells are the reference for the next eleven in the district.

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

**The blunt verdict first:** at **10 wells and 60 subscribers** there is no "market" yet in the financial sense — there is **evidence**. Ten wells at USD 150 per well is USD 1,500 a year, which covers neither product development nor a month's salary. Pitching this stage as a market costs credibility with the jury; it is funded as a **paid pilot that generates evidence**, not as a commercial subscription.

**Formula:** number of wells × annual price per well = annual revenue.

**Level 1 — your current scope (proof):**

| Item | Figure | Status |
|---|---|---|
| Wells | 10 | [given] |
| Subscribers | 60 | [given] |
| Average subscribers per well | 6 | [computed] |
| Readings per year (12 cycles × 60) | 720 readings | [computed] |
| Annual price per well | USD 150 | [assumption to validate] |
| Revenue at current scope | USD 1,500 a year | [computed] |

**Level 2 — the district (first expansion):** wells in the district × price. Illustrative: **100 wells → USD 15,000 a year**.
**Level 3 — the governorate:** **300 wells × 150 = USD 45,000 a year** [assumption — needs your data: actually count your district's wells].

**Price test at 6 subscribers per well:** is USD 150 defensible? At this size the value does not come from the operator's time — six readings a month save nothing worth naming, and the honest slide says so. It comes from three things the system measures:

1. **Loss surfaced:** one cubic metre detected per day is 365 m³ a year × the local price — which can exceed the software price. That is the number to compute from your first cycle.
2. **Dispute resolution:** a reading with a photo and a timestamp ends a quarrel that was costing the committee a whole subscriber.
3. **Cash clarity:** whether the well's revenue covers diesel, maintenance and the operator — a question most wells cannot answer today.

**The unit-economics number you must supply:** **cost per m³ at the well** = (diesel + operator + maintenance) ÷ cubic metres sold. The app assembles every term from the energy report (diesel/solar) and the cycle report; the missing inputs are your price per m³ and operating costs [assumption — needs your data].

### 4.5 The first customer

You already hold what the framework asks for: **ten wells**. The first customer is not "the market" — it is **the first of the ten**, the well that goes into the setup first and opens its first cycle in the app.

**Template to fill with real names [assumption — needs your data]:**

> Well "______" — well 1 of 10, in "______" district, committee chaired by "______", serving ____ of the sixty subscribers, with "______" type meters.
> Stated need: "______" (reading dispute / late collection / cash deficit / nobody knows the loss).
> Offer: one complete cycle run on the system + operator training + a final audit report, in exchange for ____.
> Expected decision date: ____ / ____ / 2026.

**Prepare the ten-well table first** (well name, village, subscriber count, meter type, committee yes/no, cash status): that table is your first Miro board, and the first well is chosen from it — pick the one with the easiest committee and the clearest problem, not the biggest.

Never write "institutions" or "farmers" here. **One name, one place, one number, one date.**

### 4.6 The venture in 100 words

> Across ten wells and sixty subscribers, meters are read on paper, figures are copied later, and the well's cash box is managed apart from the numbers. The result: loss nobody sees, a bill the subscriber cannot contest with a photo and a timestamp, and a committee that discovers the deficit at month-end.
> Azal Soft Platform turns that chain into one digital record: the meter photo read automatically behind a confidence gate that refuses the doubtful digit before it reaches the invoice, then consumption, then the invoice, then collection, then the cash box.
> We are running it now on the ten wells and sixty subscribers, measuring three numbers only: reading time, share of traceable readings, and the gap between paper and real loss.
> What we ask for today: four cycles and forty minutes of operator training — to prove the number.

---

## Project Proposal · Expected Impact, Outputs and Financial System

This section brings the project proposal together with the four-layer pitch brief. It distinguishes the platform’s current capabilities from targets to be tested in the field.

### Proposal summary

**Azal Soft Platform** is a mobile and web platform for managing community water-well operations. It links subscriber and meter records, reading cycles, consumption, billing, collections, expenses, energy records, and management reports. Its photo-based OCR workflow includes image-quality checks and confidence review; readings that are uncertain should be checked by a person before they are used for billing.

The proposed pilot covers **10 wells and 60 subscribers**. It will verify opening data, run regular reading and billing cycles, record transactions with supporting vouchers, and measure operational and financial indicators. The purpose is to establish evidence for deciding whether and how to expand the system—not to claim unmeasured impact in advance.

**The intended change:** replace disconnected paper records with a traceable chain from meter reading to bill, and from each financial transaction to the well’s fund and operating reports.

### Expected impact and pilot indicators

The pilot should document a baseline before its first digital cycle. The following are **proposed targets**, not results already achieved:

| Impact area | Indicator | Proposed pilot target |
|---|---|---|
| Reading efficiency | Median time from starting a reading to saving it | Under 30 seconds for a routine reading after training |
| Reading coverage | Registered subscribers with an approved reading per cycle | At least 95% |
| OCR workflow | Readings accepted without manual correction | At least 85%, to be validated in the field |
| Reading quality | Error after human review against verified reference readings | At most 1%, measured on the pilot sample |
| Bill traceability | Bills linked to an approved subscriber, cycle, and reading | 100% of pilot bills, if the underlying records are complete |
| Financial control | Receipts and payments supported by a voucher and assigned to the correct well | At least 95%; document all exceptions |
| Cash reconciliation | Difference between system fund balance and cash counted | Investigate and document at every close; target no unexplained difference |
| Operating insight | Cycle, financial, and energy reports available | For every completed cycle where source data is available |

Run four monthly cycles where feasible: 60 subscribers × 4 cycles gives up to **240 reading opportunities**. Compare results with the baseline and report the actual sample size, missing data, and exceptions. The intended wider effects are more transparent bills, stronger cash accountability, improved visibility of operating and energy costs, and better-informed maintenance decisions. These outcomes also depend on governance, water availability, equipment, and adequate funding.

### Project outputs

1. A configured registry for pilot locations, wells, subscribers, meters, user roles, and verified opening readings.
2. A repeatable reading-cycle and review process, including human approval of uncertain OCR results.
3. Cycle-based consumption and billing records using a tariff approved by the responsible well committee.
4. Numbered receipt and payment vouchers linked to well-level accounts and transactions.
5. Well-level financial, cycle, and energy reports and management summaries based on available data.
6. Trained well staff and a concise operating guide for readings, corrections, billing, cash handling, and cycle closure.
7. A pilot evaluation comparing baseline and post-implementation results, user feedback, limitations, and a recommendation to continue, adjust, or expand.

### Financial system to use

Use **simple well-level double-entry bookkeeping** as the project’s proposed financial-control method, supported by the application’s well accounts, debit/credit transactions, receipt and payment vouchers, and accounting-tree reports. Keep each well’s records distinct for operational accountability; provide consolidated reports only to authorized managers.

The application already supports account categories for **sales, cash/fund, expenses, and worker/operator**, receipt and payment vouchers, debit/credit transaction records, and an accounting-tree view. The following chart and posting policy are recommendations and must be checked against the app’s actual posting behavior before formal use.

| Suggested code | Account | Classification |
|---|---|---|
| 1101 | Well cash fund | Asset |
| 1201 | Subscriber receivables | Asset |
| 2101 | Worker amounts payable | Liability |
| 3100 | Opening fund balance / accumulated result | Equity or fund balance; accountant to confirm |
| 4101 | Water sales revenue | Revenue |
| 5101 | Well operating expenses | Expense |
| 5110 | Energy and fuel expense | Expense |
| 5120 | Maintenance expense | Expense |

| Event | Debit | Credit | Required supporting record |
|---|---|---|---|
| Approved bill, if accrual basis is selected | Subscriber receivables | Water sales revenue | Approved bill and reading-cycle reference |
| Subscriber payment | Well cash fund | Subscriber receivables | Numbered receipt voucher linked to subscriber and bill/cycle |
| Expense paid from well cash | Relevant expense account | Well cash fund | Numbered payment voucher and receipt where available |
| Worker cost approved but unpaid | Relevant worker/labour expense | Worker amounts payable | Approval or payroll record |
| Worker amount paid | Worker amounts payable | Well cash fund | Payment voucher linked to approval |

Choose **either accrual-basis or cash-basis reporting** with the well committee and accountant, then apply it consistently. Do not present the application’s accounting tree as formal financial statements until the chart of accounts, opening balances, revenue treatment, and reports have been validated by an accountant familiar with applicable local requirements.

**Minimum controls:** use unique voucher numbers; retain a reason and reference for corrections; separate recording, payment approval, and reconciliation roles where practical; record date, well, amount, account, description, and supporting evidence; count and reconcile cash at every cycle close; verify subscriber balances against bills and receipts; and restrict access by role. Record the currency actually used and do not assume tariffs, exchange rates, taxes, or fees without local approval.

### Financial sustainability and budget

Do not set a software fee or claim project savings before collecting actual cost data. Track setup and data-cleaning, training and support, devices, connectivity, hosting and maintenance, meter-reading operations, financial review, and monitoring costs. Possible future funding models to test include a per-well service fee, an institution or utility subscription, or partner-funded deployment and training. Any fee must be transparent, affordable, approved by the responsible body, and kept separate from water tariffs unless explicitly authorized.

Complete the following worksheet using local quotations and state the currency and price date:

| Cost item | Unit | Quantity | Unit cost | Total |
|---|---:|---:|---:|---:|
| Initial setup and data verification | day / well | ___ | ___ | ___ |
| Training and user support | session / person | ___ | ___ | ___ |
| Devices (only if needed) | device | ___ | ___ | ___ |
| Connectivity and hosting | month | ___ | ___ | ___ |
| Meter-reading operations | cycle / well | ___ | ___ | ___ |
| Accountant / financial review | day | ___ | ___ | ___ |
| Monitoring and evaluation | day / cycle | ___ | ___ | ___ |
| Contingency (approved basis) | ___ | ___ | ___ | ___ |
| **Pilot budget** |  |  |  | **___** |

Use pilot data to calculate **annual cost per well** (annual recurring costs ÷ active wells), **cost per subscriber** (annual recurring costs ÷ active subscribers), and **cost recovery ratio** (recurring income ÷ recurring costs). Calculate a break-even scale only when a credible fee and variable cost per well are known. Do not create a forecast from invented prices.

### Pilot delivery and decision gates

| Phase | Main activity | Output / decision gate |
|---|---|---|
| Readiness | Confirm participating wells, consent, roles, tariff policy, data privacy, and baseline | Approved pilot scope and baseline sheet |
| Setup | Verify subscribers, meters, opening readings, balances, and access | Validated registry and signed opening balances |
| Training | Practise reading review, correction, receipts, payments, and reconciliation | Trained users and practice cycle |
| Operations | Run up to four monthly cycles; review readings, record vouchers, close and reconcile | Cycle datasets and monthly review notes |
| Evaluation | Compare with baseline, review exceptions and user feedback | Evaluation report and scale-up recommendation |

Key risks include incorrect opening data, OCR mistakes, incomplete financial records, weak connectivity, low adoption, unauthorized access, and unclear ownership of tariff or spending decisions. Mitigate them through on-site verification, human review, voucher and reconciliation training, a documented connectivity contingency, role-based access, and explicit committee approval of tariffs and expenditure.

For the expanded proposal, budget worksheet, and fuller explanation, see [`project_proposal_en.md`](project_proposal_en.md).

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

## Annex D · Running the ten wells and sixty subscribers in the app

The exact sequence for bringing your scope (10 wells, 60 subscribers) into the system, using the app's own screen names:

| # | Screen | What you do | Output |
|---|---|---|---|
| 1 | Setup | build the hierarchy: province → district → hamlet → village → well, with the ten real well names, not codes | 10 well records |
| 2 | Supervisor setup (manager only) | one supervisor for the ten wells, with a known username and password | a working supervisor account |
| 3 | Create sales account | for each well: sales, cash, expenses, worker | 40 accounts (4 × 10) |
| 4 | Subscribers | enter all sixty: name, phone, meter number, meter type, **signed opening reading** | 60 subscriber records |
| 5 | Reading cycle | one cycle covering the ten wells, with an explicit start date | an open cycle |
| 6 | Photo reading | per subscriber: photo → quality check → digit crop → accept or review | 60 traceable readings |
| 7 | Close cycle | close, review consumption and the invoice before issuing | 60 invoices |
| 8 | Receipt voucher | record every amount entering the cash box | a cash box that matches reality |
| 9 | Reports | cycle report (daily/monthly), account report, energy report | 3 signable reports |
| 10 | GM dashboard | monthly consumption, well ranking, alerts | one decision page |

**Three mistakes that kill the pilot before it starts:**

1. **A wrong opening reading.** If the opening reading is an estimate, every consumption figure after it is wrong. Take it from the meter in front of the subscriber and sign it.
2. **Mixed units.** If some meters read in m³ and others in litres, wells cannot be compared. Unify the unit before the first cycle, not after.
3. **Two supervisors on one cycle.** Put in writing who reads which well, or you will get two contradictory readings of the same meter — precisely the problem we came to solve.

**The tracking table to fill before the first cycle (this is your first Miro board):**

| # | Well | Village | Subscribers | Meter type | Committee? | Cash status | First cycle date |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |
| 4 | | | | | | | |
| 5 | | | | | | | |
| 6 | | | | | | | |
| 7 | | | | | | | |
| 8 | | | | | | | |
| 9 | | | | | | | |
| 10 | | | | | | | |

**What the filled table tells you:** if the ten wells average six subscribers, you now know the real expansion question — does a well in your district actually serve six subscribers, or were these ten chosen small? The answer decides whether your price per well (not per subscriber) is the right pricing model. That is one more reason to state the claim per well.

---

## Annex C · What to add to the app before submission day

1. **Measure reading time inside the app** (camera open → reading saved) — it produces the Layer 2 number for free.
2. **Export the brief to PDF** directly from the screen (today: text you copy).
3. **A "price per m³" field** in well settings, to compute unit economics.
4. **An audit trail for readings** (who read, which photo, what confidence, who edited) — the thing that makes the report signable.
